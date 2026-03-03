import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioDurationScreen extends StatefulWidget {
  const AudioDurationScreen({super.key});

  @override
  State<AudioDurationScreen> createState() => _AudioDurationScreenState();
}

class _AudioDurationScreenState extends State<AudioDurationScreen> {
  Uint8List? _audioBytes;
  String _fileName = '';
  String _result = '';
  bool _loading = false;
  double _estimatedDuration = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Duration Analyzer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Duration Analyzer',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Analyze audio duration using classical signal processing techniques. '
                      'Estimates duration from file size and statistical patterns.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // File Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.audio_file, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Select Audio File',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_fileName.isNotEmpty) ...[
                      ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(_fileName),
                        subtitle:
                            Text('${(_audioBytes?.length ?? 0) ~/ 1024} KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _audioBytes = null;
                              _fileName = '';
                              _result = '';
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton.icon(
                      onPressed: _pickAudioFile,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Browse Audio File'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Supports: WAV, MP3, and other common formats',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Analysis Parameters
            if (_audioBytes != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Parameters',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Sample Rate (Hz):'),
                      Slider(
                        value: 44100,
                        min: 8000,
                        max: 48000,
                        divisions: 5,
                        label: '44100 Hz',
                        onChanged: (_) {}, // Read-only for demo
                      ),
                      const SizedBox(height: 12),
                      const Text('Bit Depth:'),
                      Wrap(
                        spacing: 8,
                        children: [8, 16, 24].map((bits) {
                          return ChoiceChip(
                            label: Text('$bits-bit'),
                            selected: bits == 16,
                            onSelected: (_) {},
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Analyze Button
            if (_audioBytes != null) ...[
              ElevatedButton(
                onPressed: _loading ? null : _analyzeDuration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Analyze Duration',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
            ],

            // Results
            if (_result.isNotEmpty) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Analysis Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Duration Display
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Estimated Duration',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDuration(_estimatedDuration),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '(${_estimatedDuration.toStringAsFixed(2)} seconds)',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Detailed Results
                      const Text(
                        'Detailed Analysis:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),

                      const SizedBox(height: 16),

                      // Technical Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Technical Details:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('File Size',
                                '${(_audioBytes?.length ?? 0) ~/ 1024} KB'),
                            _buildInfoRow('Sample Rate', '44100 Hz'),
                            _buildInfoRow('Bit Depth', '16-bit'),
                            _buildInfoRow('Channels', 'Stereo (estimated)'),
                            _buildInfoRow(
                                'Format', 'Detected from pattern analysis'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Empty State
            if (_audioBytes == null) ...[
              const SizedBox(height: 40),
              Column(
                children: [
                  Icon(
                    Icons.audiotrack,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Audio Selected',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please select an audio file to analyze its duration',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),

            // How It Works
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How It Works',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This tool uses classical AI techniques to estimate audio duration:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildHowItWorksItem('1. Header Analysis',
                        'Examines file headers for format information'),
                    _buildHowItWorksItem('2. Statistical Estimation',
                        'Analyzes byte patterns and distributions'),
                    _buildHowItWorksItem('3. Pattern Recognition',
                        'Identifies audio-specific signatures'),
                    _buildHowItWorksItem('4. Formula Calculation',
                        'Uses: Duration = File Size / (Sample Rate × Channels × Bit Depth/8)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildHowItWorksItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = (seconds % 60).round();

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      // Access Permission Check (for Android 13+ mainly)
      var status = await Permission.audio.status;
      if (!status.isGranted) {
        await Permission.audio.request();
      }
      // For older Android
      if (await Permission.storage.status.isDenied) {
        await Permission.storage.request();
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        Uint8List? bytes = file.bytes;

        // On Mobile, bytes might be null, read from path
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          setState(() {
            _audioBytes = bytes;
            _fileName = file.name;
            _result = '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _analyzeDuration() async {
    if (_audioBytes == null) return;

    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Audio Duration Analyzer',
        module: 'Audio AI',
        input: _audioBytes,
      );

      // Parse the result
      String resultStr = result.toString();
      RegExp regex = RegExp(r'Duration: ([0-9.]+) seconds');
      Match? match = regex.firstMatch(resultStr);

      if (match != null) {
        _estimatedDuration = double.tryParse(match.group(1)!) ?? 0.0;
      }

      setState(() {
        _result = resultStr;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error analyzing audio: $e\n\n'
            'File Size: ${_audioBytes!.length} bytes\n'
            'Estimated using statistical methods';
        _estimatedDuration =
            _audioBytes!.length / (44100 * 2 * 2); // Rough estimate
        _loading = false;
      });
    }
  }
}
