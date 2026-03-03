import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NoiseEstimationScreen extends StatefulWidget {
  const NoiseEstimationScreen({super.key});

  @override
  State<NoiseEstimationScreen> createState() => _NoiseEstimationScreenState();
}

class _NoiseEstimationScreenState extends State<NoiseEstimationScreen> {
  Uint8List? _audioBytes;
  String _fileName = '';
  bool _loading = false;
  Map<String, dynamic> _noiseInfo = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noise Estimator')),
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
                      'Noise Estimator',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Estimate noise levels and signal-to-noise ratio using statistical analysis. '
                      'Get recommendations for noise reduction.',
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
                        Icon(Icons.noise_aware, color: Colors.teal),
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
                              _noiseInfo = {};
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

            // Analysis Button
            if (_audioBytes != null) ...[
              ElevatedButton(
                onPressed: _loading ? null : _estimateNoise,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
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
                        'Estimate Noise',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
            ],

            // Results
            if (_noiseInfo.isNotEmpty) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            'Noise Analysis Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Noise Level Summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          children: [
                            _buildNoiseIndicator(_noiseInfo['snrDb'] ?? 0.0),
                            const SizedBox(height: 16),
                            _buildMetricRow('SNR (Signal-to-Noise Ratio)',
                                '${_noiseInfo['snrDb']?.toStringAsFixed(1) ?? 'N/A'} dB'),
                            _buildMetricRow('Noise Level',
                                '${_noiseInfo['noiseLevel']?.toStringAsFixed(4) ?? 'N/A'}'),
                            _buildMetricRow('Audio Quality',
                                _getQualityLabel(_noiseInfo['snrDb'] ?? 0.0)),
                            _buildMetricRow('Spectral Flatness',
                                '${_noiseInfo['spectralFlatness']?.toStringAsFixed(3) ?? 'N/A'}'),
                            _buildMetricRow('Confidence',
                                '${((_noiseInfo['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Recommendation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.tertiary),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  'Recommendation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _noiseInfo['recommendation'] ??
                                  'No recommendation available',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Detailed Analysis
                      const Text(
                        'Detailed Analysis:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildAnalysisRow('Is Noisy',
                                _noiseInfo['isNoisy'] == true ? 'Yes' : 'No'),
                            _buildAnalysisRow('Noise Type',
                                _noiseInfo['noiseType'] ?? 'Unknown'),
                            _buildAnalysisRow(
                                'Analysis Method', 'Statistical + Spectral'),
                            _buildAnalysisRow(
                                'Silence Detection', 'Used for noise sampling'),
                            _buildAnalysisRow('Spectral Analysis',
                                'Flatness indicates noise-like spectrum'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.clean_hands),
                              label: const Text('Suggest Cleanup'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.teal),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.compare),
                              label: const Text('Compare'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.teal),
                              ),
                            ),
                          ),
                        ],
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
                    Icons.noise_aware,
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
                    'Please select an audio file to estimate noise levels',
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
                      'This tool uses classical AI techniques for noise estimation:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildHowItWorksItem('1. Silence Detection',
                        'Identifies silent segments for noise sampling'),
                    _buildHowItWorksItem('2. Statistical Analysis',
                        'Calculates RMS and statistical properties'),
                    _buildHowItWorksItem('3. Spectral Analysis',
                        'Analyzes frequency distribution using FFT'),
                    _buildHowItWorksItem('4. SNR Calculation',
                        'Signal-to-Noise Ratio in decibels'),
                    _buildHowItWorksItem('5. Pattern Recognition',
                        'Identifies noise types and patterns'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoiseIndicator(double snrDb) {
    Color color;
    String label;
    IconData icon;

    if (snrDb < 10) {
      color = Colors.red;
      label = 'High Noise';
      icon = Icons.warning;
    } else if (snrDb < 20) {
      color = Colors.orange;
      label = 'Moderate Noise';
      icon = Icons.info;
    } else if (snrDb < 30) {
      color = Colors.blue;
      label = 'Low Noise';
      icon = Icons.check_circle;
    } else {
      color = Colors.green;
      label = 'Clean';
      icon = Icons.verified;
    }

    return Column(
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${snrDb.toStringAsFixed(1)} dB SNR',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
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

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
          const Icon(Icons.circle, size: 8, color: Colors.teal),
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

  String _getQualityLabel(double snrDb) {
    if (snrDb < 10) return 'Poor';
    if (snrDb < 20) return 'Fair';
    if (snrDb < 30) return 'Good';
    return 'Excellent';
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

  Future<void> _estimateNoise() async {
    if (_audioBytes == null) return;

        setState(() {
          _loading = true;
        });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Noise Estimator',
        module: 'Audio AI',
        input: _audioBytes,
      );

      if (result is Map) {
        setState(() {
          _noiseInfo = Map<String, dynamic>.from(result);
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
}
