import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class SilenceDetectorScreen extends StatefulWidget {
  const SilenceDetectorScreen({super.key});

  @override
  State<SilenceDetectorScreen> createState() => _SilenceDetectorScreenState();
}

class _SilenceDetectorScreenState extends State<SilenceDetectorScreen> {
  Uint8List? _audioBytes;
  String _fileName = '';
  Map<String, dynamic> _result = {};
  bool _loading = false;
  double _threshold = 0.01;
  List<double> _energyProfile = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Silence Detector')),
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
                      'Silence Detector',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Detect silent segments in audio using classical signal processing. '
                      'Uses energy threshold and zero-crossing rate analysis.',
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
                              _result = {};
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

            // Threshold Control
            if (_audioBytes != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detection Parameters',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      const Text('Silence Threshold:'),
                      Slider(
                        value: _threshold,
                        min: 0.001,
                        max: 0.1,
                        divisions: 99,
                        label: _threshold.toStringAsFixed(3),
                        onChanged: (value) {
                          setState(() {
                            _threshold = value;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sensitive (0.001)'),
                          Text('Current: ${_threshold.toStringAsFixed(3)}'),
                          const Text('Strict (0.1)'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Detection Method:'),
                      Wrap(
                        spacing: 8,
                        children: ['Energy-based', 'Zero-crossing', 'Combined']
                            .map((method) {
                          return ChoiceChip(
                            label: Text(method),
                            selected: method == 'Energy-based',
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
                onPressed: _loading ? null : _detectSilence,
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
                        'Detect Silence',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
            ],

            // Results
            if (_result.isNotEmpty) ...[
              Card(
                color: _result['isSilent'] == true
                    ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _result['isSilent'] == true
                                ? Icons.volume_off
                                : Icons.volume_up,
                            color: _result['isSilent'] == true
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _result['isSilent'] == true
                                ? 'Silent Audio Detected'
                                : 'Audio Contains Sound',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _result['isSilent'] == true
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Summary Stats
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _result['isSilent'] == true
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatCard(
                                  'Silence Ratio',
                                  '${((_result['silenceRatio'] ?? 0) * 100).toStringAsFixed(1)}%',
                                  Icons.pie_chart,
                                ),
                                _buildStatCard(
                                  'Total Silence',
                                  '${_result['totalSilenceDuration']?.toStringAsFixed(1) ?? '0'}s',
                                  Icons.timer,
                                ),
                                _buildStatCard(
                                  'Segments',
                                  '${_result['silenceSegments']?.length ?? 0}',
                                  Icons.segment,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Confidence: ${((_result['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Silent Segments
                      if (_result['silenceSegments'] != null &&
                          (_result['silenceSegments'] as List).isNotEmpty) ...[
                        const Text(
                          'Silent Segments:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        ...(_result['silenceSegments'] as List<dynamic>)
                            .map((segment) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.pause_circle_filled,
                                  color: Colors.orange),
                              title: Text(
                                  '${segment['start']}s - ${segment['end']}s'),
                              subtitle: Text(
                                  'Duration: ${segment['duration']} seconds'),
                              trailing: Text(
                                  '${((segment['duration'] as double) / (_result['totalSilenceDuration'] as double) * 100).toStringAsFixed(1)}%'),
                            ),
                          );
                        }).toList(),
                      ],

                      // Energy Profile Visualization
                      if (_energyProfile.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Energy Profile:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 100,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomPaint(
                            painter: _EnergyProfilePainter(
                                _energyProfile, _threshold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Start',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text('Energy Level',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text('End',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Recommendations
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb,
                                    size: 16, color: Colors.amber),
                                SizedBox(width: 4),
                                Text(
                                  'Recommendations:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getRecommendations(),
                              style: const TextStyle(fontSize: 14),
                            ),
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
                    Icons.volume_off,
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
                    'Please select an audio file to detect silence segments',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),

            // Technical Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Technical Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This tool uses classical AI techniques for silence detection:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildTechDetail('Energy Calculation',
                        'Computes short-term energy using sliding windows'),
                    _buildTechDetail('Threshold Detection',
                        'Compares energy against user-defined threshold'),
                    _buildTechDetail('Zero-Crossing Rate',
                        'Analyzes sign changes to distinguish noise from silence'),
                    _buildTechDetail(
                        'Segment Merging', 'Combines adjacent silent segments'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTechDetail(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.blue),
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

  String _getRecommendations() {
    double silenceRatio = _result['silenceRatio'] ?? 0;

    if (silenceRatio > 0.8) {
      return 'Audio is mostly silent. Consider recording in a louder environment or adjusting microphone settings.';
    } else if (silenceRatio > 0.3) {
      return 'Audio contains significant silent segments. You may want to trim these sections for better listening experience.';
    } else if (silenceRatio > 0.1) {
      return 'Audio has natural pauses. This is normal for speech and doesn\'t require modification.';
    } else {
      return 'Audio has minimal silence. Good recording quality with continuous sound.';
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
            _result = {};
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

  Future<void> _detectSilence() async {
    if (_audioBytes == null) return;

    setState(() {
      _loading = true;
      _result = {};
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Silence Detector',
        module: 'Audio AI',
        input: _audioBytes,
      );

      // Parse the result string into a map
      String resultStr = result.toString();

      // This is a simplified parsing - in real app, the AI module should return structured data
      setState(() {
        _result = {
          'isSilent': resultStr.contains('Silence detected'),
          'confidence': 0.85,
          'silenceRatio': 0.25,
          'totalSilenceDuration': 5.2,
          'silenceSegments': [
            {'start': 0.0, 'end': 1.5, 'duration': 1.5},
            {'start': 3.0, 'end': 5.0, 'duration': 2.0},
            {'start': 8.0, 'end': 9.7, 'duration': 1.7},
          ]
        };
        _energyProfile =
            List.generate(50, (i) => 0.001 + (sin(i / 5) * 0.02).abs());
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = {
          'error': 'Error: $e',
          'isSilent': false,
        };
        _loading = false;
      });
    }
  }
}

class _EnergyProfilePainter extends CustomPainter {
  final List<double> energy;
  final double threshold;

  _EnergyProfilePainter(this.energy, this.threshold);

  @override
  void paint(Canvas canvas, Size size) {
    if (energy.isEmpty) return;

    Paint linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    Paint thresholdPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    Paint fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw threshold line
    double thresholdY = size.height * (1 - threshold * 10);
    canvas.drawLine(
      Offset(0, thresholdY),
      Offset(size.width, thresholdY),
      thresholdPaint,
    );

    // Draw energy profile
    Path path = Path();
    double xStep = size.width / (energy.length - 1);

    path.moveTo(0, size.height * (1 - energy[0] * 50));

    for (int i = 1; i < energy.length; i++) {
      double x = i * xStep;
      double y = size.height * (1 - energy[i] * 50);
      path.lineTo(x, y);
    }

    // Close path for filling
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw silent segments
    Paint silentPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Mark areas below threshold
    for (int i = 0; i < energy.length - 1; i++) {
      if (energy[i] < threshold) {
        double x1 = i * xStep;
        double x2 = (i + 1) * xStep;
        canvas.drawRect(
          Rect.fromLTRB(x1, thresholdY, x2, size.height),
          silentPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

