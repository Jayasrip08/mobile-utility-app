import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioSpeedScreen extends StatefulWidget {
  const AudioSpeedScreen({super.key});

  @override
  State<AudioSpeedScreen> createState() => _AudioSpeedScreenState();
}

class _AudioSpeedScreenState extends State<AudioSpeedScreen> {
  Uint8List? _audioBytes;
  String _fileName = '';
  bool _loading = false;
  double _speedFactor = 1.0;
  bool _preservePitch = true;
  String _contentType = 'speech';
  double _estimatedDuration = 0.0;
  List<int>? _processedAudio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Speed Modifier')),
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
                      'Audio Speed Modifier',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Change audio playback speed using time-scale modification techniques. '
                      'Includes pitch preservation options.',
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
                        Icon(Icons.speed, color: Colors.orange),
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
                              _processedAudio = null;
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Speed Controls
            if (_audioBytes != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Speed Settings',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),

                      // Speed Factor Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Speed Factor:'),
                              Text(
                                '${_speedFactor.toStringAsFixed(2)}x',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _speedFactor,
                            min: 0.25,
                            max: 4.0,
                            divisions: 15,
                            label: '${_speedFactor.toStringAsFixed(2)}x',
                            onChanged: (value) {
                              setState(() {
                                _speedFactor = value;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('0.25x (Slow)',
                                  style: TextStyle(fontSize: 12)),
                              Text('1.0x (Normal)',
                                  style: TextStyle(fontSize: 12)),
                              Text('4.0x (Fast)',
                                  style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Pitch Preservation
                      SwitchListTile(
                        title: const Text('Preserve Pitch'),
                        subtitle: const Text(
                            'Maintain original pitch when changing speed'),
                        value: _preservePitch,
                        onChanged: (value) {
                          setState(() {
                            _preservePitch = value;
                          });
                        },
                        secondary: const Icon(Icons.timeline),
                      ),

                      const SizedBox(height: 20),

                      // Content Type
                      const Text('Content Type:'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildContentTypeChip('speech', 'Speech'),
                          _buildContentTypeChip('music', 'Music'),
                          _buildContentTypeChip('podcast', 'Podcast'),
                          _buildContentTypeChip('lecture', 'Lecture'),
                        ],
                      ),

                      if (_contentType != 'default') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getContentTypeDescription(_contentType),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Duration Preview
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Duration Preview',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('Original',
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(_estimatedDuration),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.orange),
                          Column(
                            children: [
                              const Text('After Speed Change',
                                  style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(
                                    _estimatedDuration / _speedFactor),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 1.0 / _speedFactor,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time saved: ${_formatDuration(_estimatedDuration - (_estimatedDuration / _speedFactor))}',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Process Button
              ElevatedButton(
                onPressed: _loading ? null : _changeSpeed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
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
                        'Apply Speed Change',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],

            // Results
            if (_processedAudio != null) ...[
              const SizedBox(height: 20),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Speed Change Applied',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          children: [
                            _buildResultRow('Original Duration',
                                _formatDuration(_estimatedDuration)),
                            _buildResultRow(
                                'New Duration',
                                _formatDuration(
                                    _estimatedDuration / _speedFactor)),
                            _buildResultRow('Speed Factor',
                                '${_speedFactor.toStringAsFixed(2)}x'),
                            _buildResultRow('Pitch Preservation',
                                _preservePitch ? 'Enabled' : 'Disabled'),
                            _buildResultRow('File Size Change',
                                '${(_processedAudio!.length / _audioBytes!.length * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Download Button
                      ElevatedButton.icon(
                        onPressed: _downloadProcessedAudio,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Processed Audio'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
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
                    Icons.speed,
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
                    'Please select an audio file to modify its speed',
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
                      'This tool uses classical AI techniques for time-scale modification:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildHowItWorksItem('1. Overlap-Add (OLA)',
                        'Classical time-scaling method'),
                    _buildHowItWorksItem(
                        '2. Phase Vocoder', 'Pitch-preserving time scaling'),
                    _buildHowItWorksItem(
                        '3. PSOLA Algorithm', 'Pitch Synchronous Overlap Add'),
                    _buildHowItWorksItem('4. Window Functions',
                        'Hann window for smooth transitions'),
                    _buildHowItWorksItem('5. Interpolation',
                        'Linear interpolation for resampling'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentTypeChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _contentType == type,
      onSelected: (selected) {
        setState(() {
          _contentType = type;
          // Set recommended speed for content type
          switch (type) {
            case 'speech':
              _speedFactor = 1.0;
              break;
            case 'music':
              _speedFactor = 1.0;
              break;
            case 'podcast':
              _speedFactor = 1.2;
              break;
            case 'lecture':
              _speedFactor = 1.5;
              break;
          }
        });
      },
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          const Icon(Icons.circle, size: 8, color: Colors.orange),
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
    if (seconds < 60) {
      return '${seconds.toStringAsFixed(1)}s';
    } else if (seconds < 3600) {
      int minutes = seconds ~/ 60;
      int secs = (seconds % 60).round();
      return '${minutes}m ${secs}s';
    } else {
      int hours = seconds ~/ 3600;
      int minutes = ((seconds % 3600) ~/ 60).round();
      return '${hours}h ${minutes}m';
    }
  }

  String _getContentTypeDescription(String type) {
    switch (type) {
      case 'speech':
        return 'Recommended: 0.8x - 1.5x. Natural speech intelligibility requires moderate speeds.';
      case 'music':
        return 'Recommended: 0.75x - 1.25x. Musical integrity preserved at original speed.';
      case 'podcast':
        return 'Recommended: 0.9x - 1.8x. Slightly faster speeds improve engagement.';
      case 'lecture':
        return 'Recommended: 0.8x - 2.0x. Educational content can be sped up for review.';
      default:
        return 'General audio content. Recommended: 0.5x - 2.0x.';
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      // Permission Handling
      var status = await Permission.audio.status;
      if (!status.isGranted) await Permission.audio.request();
      if (await Permission.storage.status.isDenied) await Permission.storage.request();

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
            _processedAudio = null;
            _estimatedDuration = file.size / (44100 * 2 * 2); // Rough estimate
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

  Future<void> _changeSpeed() async {
    if (_audioBytes == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final params = {
        'speedFactor': _speedFactor,
        'preservePitch': _preservePitch,
        'contentType': _contentType,
        'originalDuration': _estimatedDuration,
      };

      final result = await AIExecutor.runTool(
        toolName: 'Audio Speed Modifier',
        module: 'Audio AI',
        input: _audioBytes,
        parameters: params,
      );

      if (result is List<int>) {
        setState(() {
          _processedAudio = result;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _downloadProcessedAudio() async {
    if (_processedAudio == null) return;

    // In a real app, you would save the file and provide download options
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Processed audio ready (${_processedAudio!.length ~/ 1024} KB)'),
        action: SnackBarAction(
          label: 'Save',
          onPressed: () {
            // Implement file saving logic
          },
        ),
      ),
    );
  }
}
