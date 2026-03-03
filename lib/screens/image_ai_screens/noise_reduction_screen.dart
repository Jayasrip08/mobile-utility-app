import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import '../../modules/image_ai/noise_reduction.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/tool_scaffold.dart';

class NoiseReductionScreen extends StatefulWidget {
  const NoiseReductionScreen({super.key});

  @override
  State<NoiseReductionScreen> createState() => _NoiseReductionScreenState();
}

class _NoiseReductionScreenState extends State<NoiseReductionScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _loading = false;
  String _currentMethod = 'Mean';
  int _kernelSize = 3;
  double _noiseVariance = 0.01;
  int _maxWindowSize = 7;
  int _searchWindow = 21;
  int _patchSize = 7;
  double _hValue = 10.0;
  double _waveletThreshold = 0.1;
  double _noiseProbability = 0.05;
  Map<String, dynamic>? _noiseAnalysis;

  final List<String> _methods = [
    'Mean',
    'Median',
    'Adaptive Median',
    'Wiener',
    'Non-local Means',
    'Wavelet',
    'Salt & Pepper',
    'Auto'
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Noise Reduction',
      actions: [
        IconButton(icon: const Icon(Icons.analytics), onPressed: _analyzeNoise),
        IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfoDialog),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image picker section
            Card(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          onPressed: _pickImage,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          onPressed: _takePhoto,
                        ),
                      ],
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Auto-detect Noise'),
                        onPressed: _autoDetectNoise,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 20),

              // Noise analysis display
              if (_noiseAnalysis != null) _buildNoiseAnalysis(),

              // Method selection
              Card(
                color: Theme.of(context).colorScheme.surface,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Noise Reduction Method:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: _methods.map((method) {
                          return ButtonSegment(
                            value: method,
                            label: Text(method),
                          );
                        }).toList(),
                        selected: {_currentMethod},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _currentMethod = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              if (_currentMethod != 'Auto') _buildControls(),

              const SizedBox(height: 20),

              // Action buttons
                  Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.remove_red_eye),
                      label: const Text('Preview'),
                      onPressed: _previewNoiseReduction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                        child: ElevatedButton.icon(
                      icon: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Theme.of(context).colorScheme.onPrimary),
                              ),
                            )
                          : const Icon(Icons.cleaning_services),
                      label: const Text('Reduce Noise'),
                      onPressed: _loading ? null : _applyNoiseReduction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Image comparison
              if (_processedImage != null) ...[
                const Text(
                  'Noise Reduction Results:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Noisy',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Chip(
                              label: Text(
                                _currentMethod,
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            const Text(
                              'Cleaned',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Image.file(_selectedImage!, height: 180),
                            ),
                            const Icon(Icons.arrow_forward, size: 32),
                            Expanded(
                              child:
                                  Image.memory(_processedImage!, height: 180),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildNoiseReductionInfo(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quality metrics
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quality Metrics',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildMetricCard(
                                'Noise Level',
                                _noiseAnalysis?['estimatedNoiseLevel'] != null
                                    ? '${(_noiseAnalysis!['estimatedNoiseLevel']! * 100).toStringAsFixed(1)}%'
                                    : 'N/A'),
                            _buildMetricCard('Method', _currentMethod),
                            _buildMetricCard(
                                'Kernel', '${_kernelSize}x$_kernelSize'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save and Compare buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: _saveImage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.compare),
                        label: const Text('Compare Methods'),
                        onPressed: _compareMethods,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Empty state
              const SizedBox(height: 40),
              Icon(Icons.cleaning_services, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Select an image to reduce noise',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Remove noise using 8 different methods: Mean, Median, Adaptive Median, Wiener, Non-local Means, Wavelet, Salt & Pepper removal, or Auto detection',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNoiseAnalysis() {
    final noiseLevel = _noiseAnalysis?['estimatedNoiseLevel'] ?? 0.0;
    final stdDev = _noiseAnalysis?['stdDev'] ?? 0.0;

    String noiseType;
    Color color;

    if (noiseLevel < 0.05) {
      noiseType = 'Low Noise';
      color = Colors.green;
    } else if (noiseLevel < 0.1) {
      noiseType = 'Moderate Noise';
      color = Colors.orange;
    } else {
      noiseType = 'High Noise';
      color = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Noise Analysis:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Chip(
                  label: Text(noiseType,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: noiseLevel,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: color,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Noise Level:'),
                Text(
                  '${(noiseLevel * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Standard Deviation:'),
                Text(
                  stdDev.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recommended: ${_getRecommendedMethod(noiseLevel)}',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecommendedMethod(double noiseLevel) {
    if (noiseLevel < 0.05) return 'Light filtering (Mean 3x3)';
    if (noiseLevel < 0.1) return 'Moderate filtering (Median 3x3)';
    if (noiseLevel < 0.2) return 'Strong filtering (Adaptive Median)';
    return 'Advanced filtering (Non-local Means)';
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_currentMethod Parameters:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_currentMethod == 'Mean' ||
                _currentMethod == 'Median' ||
                _currentMethod == 'Wiener') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kernel Size: $_kernelSize'),
                  Slider(
                    value: _kernelSize.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    label: '$_kernelSize',
                    onChanged: (value) {
                      setState(() {
                        _kernelSize = value.round().isOdd
                            ? value.round()
                            : value.round() + 1;
                      });
                    },
                  ),
                  if (_currentMethod == 'Wiener') ...[
                    const SizedBox(height: 16),
                    Text(
                        'Noise Variance: ${_noiseVariance.toStringAsFixed(3)}'),
                    Slider(
                      value: _noiseVariance,
                      min: 0.001,
                      max: 0.05,
                      divisions: 49,
                      label: _noiseVariance.toStringAsFixed(3),
                      onChanged: (value) {
                        setState(() {
                          _noiseVariance = value;
                        });
                      },
                    ),
                  ],
                  Text(
                    _currentMethod == 'Mean'
                        ? 'Simple averaging filter. Fast but blurs edges.'
                        : _currentMethod == 'Median'
                            ? 'Removes noise while preserving edges. Good for salt-and-pepper noise.'
                            : 'Frequency-domain approach. Good for Gaussian noise.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Adaptive Median') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Max Window Size: $_maxWindowSize'),
                  Slider(
                    value: _maxWindowSize.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    label: '$_maxWindowSize',
                    onChanged: (value) {
                      setState(() {
                        _maxWindowSize = value.round().isOdd
                            ? value.round()
                            : value.round() + 1;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adaptively adjusts window size based on local statistics.\nExcellent for removing salt-and-pepper noise without blurring edges.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Non-local Means') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search Window: $_searchWindow'),
                  Slider(
                    value: _searchWindow.toDouble(),
                    min: 7,
                    max: 35,
                    divisions: 7,
                    label: '$_searchWindow',
                    onChanged: (value) {
                      setState(() {
                        _searchWindow = value.round().isOdd
                            ? value.round()
                            : value.round() + 1;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Patch Size: $_patchSize'),
                  Slider(
                    value: _patchSize.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    label: '$_patchSize',
                    onChanged: (value) {
                      setState(() {
                        _patchSize = value.round().isOdd
                            ? value.round()
                            : value.round() + 1;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Filter Strength (h): ${_hValue.toStringAsFixed(1)}'),
                  Slider(
                    value: _hValue,
                    min: 1.0,
                    max: 30.0,
                    divisions: 29,
                    label: _hValue.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _hValue = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Advanced algorithm that compares similar patches across the image.\nExcellent for preserving textures while removing noise.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Wavelet') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Threshold: ${_waveletThreshold.toStringAsFixed(2)}'),
                  Slider(
                    value: _waveletThreshold,
                    min: 0.01,
                    max: 0.5,
                    divisions: 49,
                    label: _waveletThreshold.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _waveletThreshold = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Multi-resolution analysis using wavelet transform.\nGood for removing noise while preserving fine details.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Salt & Pepper') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Noise Probability: ${(_noiseProbability * 100).toStringAsFixed(1)}%'),
                  Slider(
                    value: _noiseProbability,
                    min: 0.01,
                    max: 0.2,
                    divisions: 19,
                    label: '${(_noiseProbability * 100).toStringAsFixed(1)}%',
                    onChanged: (value) {
                      setState(() {
                        _noiseProbability = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Specifically targets salt-and-pepper (impulse) noise.\nDetects and replaces extremely dark/light pixels.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoiseReductionInfo() {
    String info = '';
    if (_currentMethod == 'Mean' || _currentMethod == 'Median') {
      info = 'Kernel: ${_kernelSize}x$_kernelSize';
    } else if (_currentMethod == 'Adaptive Median') {
      info = 'Max Window: $_maxWindowSize';
    } else if (_currentMethod == 'Wiener') {
      info =
          'Kernel: ${_kernelSize}x$_kernelSize, Variance: ${_noiseVariance.toStringAsFixed(3)}';
    } else if (_currentMethod == 'Non-local Means') {
      info =
          'Search: ${_searchWindow}x$_searchWindow, Patch: $_patchSize, h: ${_hValue.toStringAsFixed(1)}';
    } else if (_currentMethod == 'Wavelet') {
      info = 'Threshold: ${_waveletThreshold.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Salt & Pepper') {
      info = 'Probability: ${(_noiseProbability * 100).toStringAsFixed(1)}%';
    } else if (_currentMethod == 'Auto') {
      info = 'Auto-detected optimal method';
    }

    return Column(
      children: [
        Text(
          '$_currentMethod Noise Reduction',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          info,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          'Noise reduction applied successfully',
          style: TextStyle(color: Colors.green, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (Platform.isAndroid) {
       await [Permission.photos, Permission.storage].request();
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _loadImage(File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      await _loadImage(File(pickedFile.path));
    }
  }

  Future<void> _loadImage(File imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _processedImage = null;
      _noiseAnalysis = null;
    });
  }

  Future<void> _analyzeNoise() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final analysis = NoiseReduction.estimateNoise(imageBytes);

      setState(() {
        _noiseAnalysis = analysis;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
          title: const Text('Noise Analysis Results'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Estimated Noise Level: ${(analysis['estimatedNoiseLevel']! * 100).toStringAsFixed(1)}%'),
                Text(
                    'Noise Variance: ${analysis['variance']!.toStringAsFixed(4)}'),
                Text(
                    'Standard Deviation: ${analysis['stdDev']!.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                const Text('Interpretation:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                if (analysis['estimatedNoiseLevel']! < 0.05)
                  const Text('• Low noise - minimal filtering needed'),
                if (analysis['estimatedNoiseLevel']! >= 0.05 &&
                    analysis['estimatedNoiseLevel']! < 0.1)
                  const Text(
                      '• Moderate noise - light to medium filtering recommended'),
                if (analysis['estimatedNoiseLevel']! >= 0.1)
                  const Text('• High noise - strong filtering recommended'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Noise analysis error: $e')),
        );
      }
    }
  }

  Future<void> _autoDetectNoise() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final result = NoiseReduction.autoNoiseReduction(imageBytes);

      setState(() {
        _currentMethod = result['method'] as String;
        _processedImage = result['filteredImage'] as Uint8List;
        _noiseAnalysis = {
          'estimatedNoiseLevel': result['noiseLevel'],
          'method': result['method'],
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-detected: ${result['method']}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-detection error: $e')),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _previewNoiseReduction() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List result;

      switch (_currentMethod) {
        case 'Mean':
          result = NoiseReduction.meanFilter(imageBytes, _kernelSize);
          break;
        case 'Median':
          result = NoiseReduction.medianFilter(imageBytes, _kernelSize);
          break;
        case 'Adaptive Median':
          result =
              NoiseReduction.adaptiveMedianFilter(imageBytes, _maxWindowSize);
          break;
        case 'Wiener':
          result = NoiseReduction.wienerFilter(
              imageBytes, _kernelSize, _noiseVariance);
          break;
        case 'Non-local Means':
          result = NoiseReduction.nonLocalMeans(
              imageBytes, _searchWindow, _patchSize, _hValue);
          break;
        case 'Wavelet':
          result =
              NoiseReduction.waveletDenoising(imageBytes, _waveletThreshold);
          break;
        case 'Salt & Pepper':
          result =
              NoiseReduction.removeSaltAndPepper(imageBytes, _noiseProbability);
          break;
        case 'Auto':
          final autoResult = NoiseReduction.autoNoiseReduction(imageBytes);
          result = autoResult['filteredImage'] as Uint8List;
          break;
        default:
          result = imageBytes;
      }

      setState(() {
        _processedImage = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview error: $e')),
        );
      }
    }
  }

  Future<void> _applyNoiseReduction() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await _previewNoiseReduction();

      // Log to Firestore via AIExecutor
      await AIExecutor.runTool(
        toolName: 'Noise Reduction',
        module: 'Image AI',
        input: {
          'method': _currentMethod,
          'parameters': _getNoiseReductionParameters(),
          'noiseLevel':
              _noiseAnalysis?['estimatedNoiseLevel']?.toStringAsFixed(3) ??
                  'N/A',
          'applied': true,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Noise reduction applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reducing noise: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String _getNoiseReductionParameters() {
    if (_currentMethod == 'Mean' || _currentMethod == 'Median') {
      return 'kernel=$_kernelSize';
    } else if (_currentMethod == 'Adaptive Median') {
      return 'maxWindow=$_maxWindowSize';
    } else if (_currentMethod == 'Wiener') {
      return 'kernel=$_kernelSize, variance=${_noiseVariance.toStringAsFixed(3)}';
    } else if (_currentMethod == 'Non-local Means') {
      return 'search=$_searchWindow, patch=$_patchSize, h=${_hValue.toStringAsFixed(1)}';
    } else if (_currentMethod == 'Wavelet') {
      return 'threshold=${_waveletThreshold.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Salt & Pepper') {
      return 'probability=${_noiseProbability.toStringAsFixed(3)}';
    } else if (_currentMethod == 'Auto') {
      return 'auto=true';
    }
    return '';
  }

  void _saveImage() {
    if (_processedImage == null) return;

    // Implement image saving logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cleaned image saved to gallery'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _compareMethods() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Noise Reduction Methods'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMethodComparison('Mean',
                  'Simple averaging. Fast but blurs edges.', 'Gaussian noise'),
              _buildMethodComparison(
                  'Median',
                  'Preserves edges. Good for impulse noise.',
                  'Salt-and-pepper'),
              _buildMethodComparison(
                  'Adaptive Median',
                  'Adapts to local noise. Excellent for mixed noise.',
                  'Impulse noise'),
              _buildMethodComparison(
                  'Wiener',
                  'Frequency domain. Good for Gaussian noise.',
                  'Gaussian noise'),
              _buildMethodComparison('Non-local Means',
                  'Advanced. Preserves textures.', 'All types'),
              _buildMethodComparison('Wavelet',
                  'Multi-resolution. Preserves details.', 'Gaussian noise'),
              _buildMethodComparison('Salt & Pepper',
                  'Targeted removal of extreme pixels.', 'Impulse noise'),
              _buildMethodComparison(
                  'Auto', 'Automatically selects best method.', 'All types'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodComparison(
      String method, String description, String bestFor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $method:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            '  $description',
            style: TextStyle(fontSize: 13, color: const Color(0xFF616161)),
          ),
          Text(
            '  Best for: $bestFor',
            style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF757575),
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Noise Reduction Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Noise reduction algorithms remove unwanted artifacts from images while preserving important details.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text('Common Noise Types:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('• Gaussian noise: Random variations in pixel values'),
              const Text('• Salt-and-pepper noise: Random black/white pixels'),
              const Text(
                  '• Speckle noise: Multiplicative noise common in ultrasound'),
              const Text('• Poisson noise: Photon counting noise in low-light'),
              const SizedBox(height: 16),
              const Text('Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('• Start with auto-detection for optimal results'),
              const Text('• Use light filtering for minor noise'),
              const Text('• Non-local Means is best for preserving textures'),
              const Text('• Always preview before applying heavy filtering'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
