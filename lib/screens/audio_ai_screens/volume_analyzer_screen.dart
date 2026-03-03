import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VolumeAnalyzerScreen extends StatefulWidget {
  const VolumeAnalyzerScreen({super.key});

  @override
  State<VolumeAnalyzerScreen> createState() => _VolumeAnalyzerScreenState();
}

class _VolumeAnalyzerScreenState extends State<VolumeAnalyzerScreen> {
  Uint8List? _audioBytes;
  String _fileName = '';
  bool _loading = false;
  Map<String, dynamic> _volumeInfo = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volume Analyzer')),
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
                      'Volume Analyzer',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Analyze audio volume levels using signal processing techniques. '
                      'Calculate RMS, peak amplitude, loudness, and dynamic range.',
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
                        Icon(Icons.volume_up, color: Colors.deepOrange),
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
                              _volumeInfo = {};
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
                onPressed: _loading ? null : _analyzeVolume,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.deepOrange,
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
                        'Analyze Volume',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
            ],

            // Results
            if (_volumeInfo.isNotEmpty) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.deepOrange),
                          SizedBox(width: 8),
                          Text(
                            'Volume Analysis Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Main Volume Indicators
                      Row(
                        children: [
                          Expanded(
                            child: _buildVolumeIndicator(
                              'RMS',
                              _volumeInfo['rms'] ?? 0.0,
                              Colors.blue,
                              Icons.bar_chart,
                            ),
                          ),
                          Expanded(
                            child: _buildVolumeIndicator(
                              'Peak',
                              _volumeInfo['peak'] ?? 0.0,
                              Colors.red,
                              Icons.arrow_upward,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Loudness
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.volume_down,
                                    color: Colors.deepOrange),
                                SizedBox(width: 8),
                                Text(
                                  'Loudness (LUFS)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _volumeInfo['loudness']?.toStringAsFixed(1) ??
                                  'N/A',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildLoudnessMeter(
                                _volumeInfo['loudness'] ?? -50.0),
                            const SizedBox(height: 8),
                            Text(
                              _getLoudnessDescription(
                                  _volumeInfo['loudness'] ?? -50.0),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Dynamic Range
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.compare, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Dynamic Range',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_volumeInfo['dynamicRange']?.toStringAsFixed(1) ?? 'N/A'} dB',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getDynamicRangeDescription(
                                  _volumeInfo['dynamicRange'] ?? 0.0),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Detailed Metrics
                      const Text(
                        'Detailed Metrics:',
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
                            _buildDetailRow('RMS Volume',
                                '${_volumeInfo['rms']?.toStringAsFixed(4) ?? 'N/A'}'),
                            _buildDetailRow('Peak Amplitude',
                                '${_volumeInfo['peak']?.toStringAsFixed(4) ?? 'N/A'}'),
                            _buildDetailRow(
                                'Peak to RMS Ratio',
                                _volumeInfo['peakToRMS'] != null
                                    ? _volumeInfo['peakToRMS']
                                        .toStringAsFixed(2)
                                    : 'N/A'),
                            _buildDetailRow(
                                'Loudness Range',
                                _getLoudnessRange(
                                    _volumeInfo['loudness'] ?? -50.0)),
                            _buildDetailRow(
                                'Clipping Detection',
                                _volumeInfo['peak'] != null &&
                                        _volumeInfo['peak']! > 0.95
                                    ? 'Possible'
                                    : 'No'),
                            _buildDetailRow(
                                'Normalization Needed',
                                _getNormalizationRecommendation(
                                    _volumeInfo['rms'] ?? 0.0)),
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
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Recommendation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getVolumeRecommendation(
                                _volumeInfo['rms'] ?? 0.0,
                                _volumeInfo['loudness'] ?? -50.0,
                                _volumeInfo['dynamicRange'] ?? 0.0,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
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
                              icon: const Icon(Icons.auto_graph),
                              label: const Text('Volume Graph'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.deepOrange),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.graphic_eq),
                              label: const Text('Normalize'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.deepOrange),
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
                    Icons.volume_up,
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
                    'Please select an audio file to analyze volume levels',
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
                      'This tool uses classical signal processing techniques for volume analysis:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildHowItWorksItem('1. RMS Calculation',
                        'Root Mean Square for average volume'),
                    _buildHowItWorksItem(
                        '2. Peak Detection', 'Identifies maximum amplitude'),
                    _buildHowItWorksItem(
                        '3. LUFS Loudness', 'ITU-R BS.1770 inspired algorithm'),
                    _buildHowItWorksItem(
                        '4. Dynamic Range', 'Peak to RMS ratio in decibels'),
                    _buildHowItWorksItem('5. Statistical Analysis',
                        'Volume distribution and patterns'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeIndicator(
      String label, double value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value.toStringAsFixed(4),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: value.clamp(0, 1),
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoudnessMeter(double loudness) {
    double normalizedValue = ((loudness + 50) / 70).clamp(0, 1);
    Color color;

    if (loudness > -10) {
      color = Colors.red;
    } else if (loudness > -20) {
      color = Colors.orange;
    } else if (loudness > -30) {
      color = Colors.yellow;
    } else {
      color = Colors.green;
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: normalizedValue,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 20,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('-50 dB', style: TextStyle(fontSize: 10)),
            Text('-20 dB', style: TextStyle(fontSize: 10)),
            Text('0 dB', style: TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
          const Icon(Icons.circle, size: 8, color: Colors.deepOrange),
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

  String _getLoudnessDescription(double loudness) {
    if (loudness > -10) return 'Very Loud - May cause distortion';
    if (loudness > -20) return 'Loud - Good for music';
    if (loudness > -30) return 'Moderate - Suitable for speech';
    if (loudness > -40) return 'Quiet - May need amplification';
    return 'Very Quiet - Likely needs normalization';
  }

  String _getDynamicRangeDescription(double dynamicRange) {
    if (dynamicRange > 30) return 'Excellent - Great depth and clarity';
    if (dynamicRange > 20) return 'Good - Clear sound with good contrast';
    if (dynamicRange > 10) return 'Fair - Some compression present';
    return 'Poor - Highly compressed or limited';
  }

  String _getLoudnessRange(double loudness) {
    if (loudness > -10) return 'Broadcast Loud';
    if (loudness > -20) return 'Streaming Loud';
    if (loudness > -30) return 'Standard';
    return 'Quiet';
  }

  String _getNormalizationRecommendation(double rms) {
    if (rms < 0.1) return 'Yes - Audio is too quiet';
    if (rms > 0.3) return 'No - Audio is at good level';
    return 'Optional - Could be normalized';
  }

  String _getVolumeRecommendation(
      double rms, double loudness, double dynamicRange) {
    List<String> recommendations = [];

    if (rms < 0.1) {
      recommendations.add(
          'Consider amplifying the audio (RMS: ${rms.toStringAsFixed(4)})');
    } else if (rms > 0.3) {
      recommendations.add('Volume is good, no normalization needed');
    }

    if (loudness < -30) {
      recommendations
          .add('Audio is quiet (${loudness.toStringAsFixed(1)} LUFS)');
    } else if (loudness > -10) {
      recommendations.add('Audio may be too loud, check for clipping');
    }

    if (dynamicRange < 10) {
      recommendations.add(
          'Dynamic range is limited (${dynamicRange.toStringAsFixed(1)} dB)');
    }

    if (recommendations.isEmpty) {
      return 'Audio volume levels are well-balanced and within optimal ranges.';
    }

    return '${recommendations.join('. ')}.';
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

  Future<void> _analyzeVolume() async {
    if (_audioBytes == null) return;

        setState(() {
          _loading = true;
        });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Volume Analyzer',
        module: 'Audio AI',
        input: _audioBytes,
      );

      if (result is Map) {
        setState(() {
          _volumeInfo = Map<String, dynamic>.from(result);
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

