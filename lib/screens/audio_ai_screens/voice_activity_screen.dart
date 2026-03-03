import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VoiceActivityScreen extends StatefulWidget {
  const VoiceActivityScreen({super.key});

  @override
  State<VoiceActivityScreen> createState() => _VoiceActivityScreenState();
}

class _VoiceActivityScreenState extends State<VoiceActivityScreen> {
  Uint8List? _audioBytes;
  String _fileName = '';
  bool _loading = false;
  Map<String, dynamic> _vadInfo = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Activity Detector')),
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
                      'Voice Activity Detector',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Detect voice activity using multiple audio features. '
                      'Classify audio type and identify speech segments.',
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
                        Icon(Icons.record_voice_over, color: Colors.indigo),
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
                              _vadInfo = {};
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
                onPressed: _loading ? null : _detectVoiceActivity,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
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
                        'Detect Voice Activity',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 20),
            ],

            // Results
            if (_vadInfo.isNotEmpty) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            'Voice Activity Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Summary Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          children: [
                            _buildClassificationCard(
                                _vadInfo['classification'] ?? 'unknown'),
                            const SizedBox(height: 16),
                            _buildMetricRow('Has Voice',
                                _vadInfo['hasVoice'] == true ? 'Yes' : 'No'),
                            _buildMetricRow('Confidence',
                                '${((_vadInfo['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                            _buildMetricRow('Voice Duration',
                                '${_vadInfo['voiceDuration']?.toStringAsFixed(2) ?? 'N/A'}s'),
                            _buildMetricRow('Voice Ratio',
                                '${((_vadInfo['voiceRatio'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
                            _buildMetricRow('Segments Found',
                                '${_vadInfo['voiceSegments']?.length ?? 0}'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Recommendation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.1),
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
                              _vadInfo['recommendation'] ??
                                  'No recommendation available',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      // Voice Segments
                      if (_vadInfo['voiceSegments'] != null &&
                          _vadInfo['voiceSegments'].isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Voice Segments:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 200,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _vadInfo['voiceSegments'].length,
                            itemBuilder: (context, index) {
                              var segment = _vadInfo['voiceSegments'][index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(Icons.record_voice_over,
                                        color: Theme.of(context).colorScheme.primary, size: 20),
                                  ),
                                  title: Text(
                                    'Segment ${index + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    '${segment['start']?.toStringAsFixed(2)}s - ${segment['end']?.toStringAsFixed(2)}s (${segment['duration']?.toStringAsFixed(2)}s)',
                                  ),
                                  trailing: const Icon(Icons.play_arrow),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Audio Features
                      const Text(
                        'Audio Features:',
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
                            if (_vadInfo['features'] != null) ...[
                              _buildFeatureRow('Zero Crossing Rate',
                                  _vadInfo['features']['zcr']),
                              _buildFeatureRow('Short-term Energy',
                                  _vadInfo['features']['energy']),
                              _buildFeatureRow('Spectral Centroid',
                                  _vadInfo['features']['spectralCentroid']),
                              _buildFeatureRow('Spectral Rolloff',
                                  _vadInfo['features']['spectralRolloff']),
                              _buildFeatureRow('Spectral Flux',
                                  _vadInfo['features']['spectralFlux']),
                              _buildFeatureRow(
                                  'RMS', _vadInfo['features']['rms']),
                              _buildFeatureRow('Peak to RMS',
                                  _vadInfo['features']['peakToRMS']),
                            ],
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
                              label: const Text('Show Waveform'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.indigo),
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
                                side: BorderSide(color: Colors.indigo),
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
                    Icons.record_voice_over,
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
                    'Please select an audio file to detect voice activity',
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
                      'This tool uses classical AI techniques for voice activity detection:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildHowItWorksItem('1. Feature Extraction',
                        'Calculates multiple audio features'),
                    _buildHowItWorksItem('2. Zero Crossing Rate',
                        'Measures signal zero crossings'),
                    _buildHowItWorksItem('3. Spectral Analysis',
                        'Analyzes frequency characteristics'),
                    _buildHowItWorksItem(
                        '4. Energy Analysis', 'Measures signal energy levels'),
                    _buildHowItWorksItem('5. Rule-based Classification',
                        'Uses thresholds for decision making'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationCard(String classification) {
    Map<String, Map<String, dynamic>> classificationData = {
      'silence': {
        'color': Colors.grey,
        'icon': Icons.volume_off,
        'label': 'Silence',
      },
      'continuous_speech': {
        'color': Colors.green,
        'icon': Icons.record_voice_over,
        'label': 'Continuous Speech',
      },
      'speech_with_pauses': {
        'color': Colors.blue,
        'icon': Icons.pause,
        'label': 'Speech with Pauses',
      },
      'music': {
        'color': Colors.purple,
        'icon': Icons.music_note,
        'label': 'Music',
      },
      'noise': {
        'color': Colors.orange,
        'icon': Icons.noise_aware,
        'label': 'Noise',
      },
    };

    var data = classificationData[classification] ??
        {
          'color': Colors.grey,
          'icon': Icons.help,
          'label': 'Unknown',
        };

    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: data['color']!.withValues(alpha: 0.1),
          child: Icon(data['icon'], size: 32, color: data['color']),
        ),
        const SizedBox(height: 8),
        Text(
          data['label']!,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: data['color'],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Classification',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  Widget _buildFeatureRow(String label, dynamic value) {
    String formattedValue = value != null ? value.toStringAsFixed(4) : 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(formattedValue,
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
          const Icon(Icons.circle, size: 8, color: Colors.indigo),
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
            _vadInfo = {};
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

  Future<void> _detectVoiceActivity() async {
    if (_audioBytes == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Voice Activity Detector',
        module: 'Audio AI',
        input: _audioBytes,
      );

      if (result is Map) {
        setState(() {
          _vadInfo = Map<String, dynamic>.from(result);
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

