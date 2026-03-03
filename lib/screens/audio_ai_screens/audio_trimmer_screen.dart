import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioTrimmerScreen extends StatefulWidget {
  const AudioTrimmerScreen({super.key});

  @override
  State<AudioTrimmerScreen> createState() => _AudioTrimmerScreenState();
}

class _AudioTrimmerScreenState extends State<AudioTrimmerScreen> {
  Uint8List? _audioBytes;
  String _fileName = '';
  bool _loading = false;
  double _startTime = 0.0;
  double _endTime = 10.0;
  double _maxDuration = 30.0;
  String _trimMode = 'manual'; // 'manual', 'silence', 'loudest', 'segments'
  Map<String, dynamic> _trimInfo = {};
  List<int>? _trimmedAudio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Trimmer')),
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
                      'Audio Trimmer',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Trim audio files using energy-based segmentation and silence detection. '
                      'Multiple trimming modes available.',
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
                        Icon(Icons.cut, color: Colors.red),
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
                              _trimInfo = {};
                              _trimmedAudio = null;
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

            // Trimming Mode Selection
            if (_audioBytes != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trimming Mode',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildModeChip('manual', 'Manual Trim', Icons.edit),
                          _buildModeChip(
                              'silence', 'Auto Silence', Icons.volume_off),
                          _buildModeChip(
                              'loudest', 'Loudest Part', Icons.volume_up),
                          _buildModeChip(
                              'segments', 'Remove Pauses', Icons.pause_circle),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Mode Description
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getModeDescription(_trimMode),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Trim Controls based on mode
              if (_trimMode == 'manual') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manual Trim Controls',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),

                        // Start Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Start Time:'),
                                Text(
                                  '${_startTime.toStringAsFixed(2)}s',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _startTime,
                              min: 0.0,
                              max: _maxDuration,
                              divisions: (_maxDuration * 10).round(),
                              onChanged: (value) {
                                setState(() {
                                  _startTime = value;
                                  if (_endTime <= _startTime) {
                                    _endTime = _startTime + 0.1;
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        // End Time
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('End Time:'),
                                Text(
                                  '${_endTime.toStringAsFixed(2)}s',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _endTime,
                              min: 0.0,
                              max: _maxDuration,
                              divisions: (_maxDuration * 10).round(),
                              onChanged: (value) {
                                setState(() {
                                  _endTime = value;
                                  if (_endTime <= _startTime) {
                                    _startTime = _endTime - 0.1;
                                  }
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('0.0s', style: const TextStyle(fontSize: 12)),
                            Text('${_maxDuration.toStringAsFixed(1)}s',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Duration Preview
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trim Duration:'),
                              Text(
                                '${(_endTime - _startTime).toStringAsFixed(2)}s',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_trimMode == 'silence') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Silence Detection Settings',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        const Text('Threshold (lower = more sensitive):'),
                        Slider(
                          value: 0.01,
                          min: 0.001,
                          max: 0.05,
                          divisions: 50,
                          label: '0.01',
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 12),
                        const Text('Padding (seconds):'),
                        Slider(
                          value: 0.1,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          label: '0.1s',
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This will automatically detect and trim silence from the beginning and end of the audio.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_trimMode == 'loudest') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Loudest Segment Settings',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        const Text('Segment Duration:'),
                        Slider(
                          value: 10.0,
                          min: 5.0,
                          max: 30.0,
                          divisions: 25,
                          label: '10.0s',
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This will extract the loudest segment of the specified duration. Useful for highlights.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_trimMode == 'segments') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pause Removal Settings',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        const Text('Min Segment Length:'),
                        Slider(
                          value: 1.0,
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          label: '1.0s',
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 12),
                        const Text('Max Silence Length:'),
                        Slider(
                          value: 2.0,
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          label: '2.0s',
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This will remove long silent pauses while keeping short natural pauses.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Trim Button
              ElevatedButton(
                onPressed: _loading ? null : _trimAudio,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
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
                    : Text(
                        'Trim Audio',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],

            // Results
            if (_trimInfo.isNotEmpty) ...[
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
                            'Trimming Complete',
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
                                '${_trimInfo['originalDuration']?.toStringAsFixed(2) ?? 'N/A'}s'),
                            _buildResultRow('Trimmed Duration',
                                '${_trimInfo['trimmedDuration']?.toStringAsFixed(2) ?? 'N/A'}s'),
                            _buildResultRow('Removed',
                                '${_trimInfo['removedDuration']?.toStringAsFixed(2) ?? 'N/A'}s'),
                            _buildResultRow('Percentage Kept',
                                '${_trimInfo['trimmedPercentage']?.toStringAsFixed(1) ?? 'N/A'}%'),
                          ],
                        ),
                      ),

                      // Segments
                      if (_trimInfo['segments'] != null &&
                          _trimInfo['segments'].length > 1) ...[
                        const SizedBox(height: 16),
                        const Text('Resulting Segments:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        ...(_trimInfo['segments'] as List).map((segment) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  const Icon(Icons.audiotrack, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${segment['start']?.toStringAsFixed(2)}s - ${segment['end']?.toStringAsFixed(2)}s',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Duration: ${segment['duration']?.toStringAsFixed(2)}s',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],

                      const SizedBox(height: 16),

                      // Download Button
                      ElevatedButton.icon(
                        onPressed: _downloadTrimmedAudio,
                        icon: const Icon(Icons.download),
                        label: const Text('Download Trimmed Audio'),
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
                    Icons.cut,
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
                    'Please select an audio file to trim',
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
                      'This tool uses classical AI techniques for audio trimming:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildHowItWorksItem('1. Energy Detection',
                        'Calculates audio energy in sliding windows'),
                    _buildHowItWorksItem('2. Threshold Analysis',
                        'Identifies silent vs. active regions'),
                    _buildHowItWorksItem('3. Segmentation',
                        'Divides audio into logical segments'),
                    _buildHowItWorksItem('4. Pattern Recognition',
                        'Identifies repeating patterns'),
                    _buildHowItWorksItem('5. Smart Padding',
                        'Adds buffers to prevent cutting mid-word'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String mode, String label, IconData icon) {
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      selected: _trimMode == mode,
      onSelected: (selected) {
        setState(() {
          _trimMode = mode;
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
          const Icon(Icons.circle, size: 8, color: Colors.red),
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

  String _getModeDescription(String mode) {
    switch (mode) {
      case 'manual':
        return 'Manually select start and end points for precise trimming.';
      case 'silence':
        return 'Automatically trim silence from beginning and end.';
      case 'loudest':
        return 'Extract the loudest segment for highlights.';
      case 'segments':
        return 'Remove long silent pauses while keeping short ones.';
      default:
        return 'Select a trimming mode to continue.';
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
            _trimInfo = {};
            _trimmedAudio = null;
            _maxDuration = file.size / (44100 * 2 * 2); // Rough estimate
            _endTime = _maxDuration > 10.0 ? 10.0 : _maxDuration;
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

  Future<void> _trimAudio() async {
    if (_audioBytes == null) return;

    setState(() {
      _loading = true;
      _trimInfo = {};
    });

    try {
      final params = {
        'trimMode': _trimMode,
        'startTime': _startTime,
        'endTime': _endTime,
        'maxDuration': _maxDuration,
      };

      final result = await AIExecutor.runTool(
        toolName: 'Audio Trimmer',
        module: 'Audio AI',
        input: _audioBytes,
        parameters: params,
      );

      if (result is Map) {
        setState(() {
          _trimInfo = Map<String, dynamic>.from(result);
          _trimmedAudio = _trimInfo['trimmedAudio'];
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

  Future<void> _downloadTrimmedAudio() async {
    if (_trimmedAudio == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Trimmed audio ready (${_trimmedAudio!.length ~/ 1024} KB)'),
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
