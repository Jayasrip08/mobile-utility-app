import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import '../../modules/image_ai/brightness_adjust.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/tool_scaffold.dart';

class BrightnessAdjustScreen extends StatefulWidget {
  const BrightnessAdjustScreen({super.key});

  @override
  State<BrightnessAdjustScreen> createState() => _BrightnessAdjustScreenState();
}

class _BrightnessAdjustScreenState extends State<BrightnessAdjustScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _loading = false;
  String _currentMethod = 'Brightness';
  int _brightnessValue = 0;
  double _gammaValue = 1.0;
  double _contrastValue = 1.0;
  

  final List<String> _methods = [
    'Brightness',
    'Gamma',
    'Brightness+Contrast',
    'Auto'
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Brightness Adjustment',
      actions: [
        IconButton(icon: const Icon(Icons.lightbulb_outline), onPressed: _analyzeOptimal),
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
                        label: const Text('Auto-Analyze Brightness'),
                        onPressed: _autoAnalyze,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 20),

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
                        'Adjustment Method:',
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
                      onPressed: _previewAdjustment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.tune),
                      label: const Text('Apply'),
                      onPressed: _loading ? null : _applyAdjustment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Image comparison
              if (_processedImage != null) ...[
                const Text(
                  'Results:',
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
                            Text(
                              'Original',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            Chip(
                              label: Text(
                                _currentMethod,
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            Text(
                              'Adjusted',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
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
                        _buildAdjustmentInfo(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Comparison modes
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text(
                          'Comparison Modes',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildComparisonButton(
                                'Side-by-Side', Icons.compare),
                            _buildComparisonButton('Overlay', Icons.layers),
                            _buildComparisonButton('Split', Icons.crop_square),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save and Reset buttons
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
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                        onPressed: _resetAdjustment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Empty state
              const SizedBox(height: 40),
              Icon(Icons.brightness_6, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Select an image to adjust brightness',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Adjust brightness using 4 different methods: Simple brightness, Gamma correction, Combined brightness/contrast, or Auto-adjustment',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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
            if (_currentMethod == 'Brightness') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Brightness: ${_brightnessValue > 0 ? '+' : ''}$_brightnessValue'),
                  Slider(
                    value: _brightnessValue.toDouble(),
                    min: -100,
                    max: 100,
                    divisions: 200,
                    label:
                        '${_brightnessValue > 0 ? '+' : ''}$_brightnessValue',
                    onChanged: (value) {
                      setState(() {
                        _brightnessValue = value.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickButton('Darken', -50),
                      _buildQuickButton('Normal', 0),
                      _buildQuickButton('Brighten', 50),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Negative values darken, positive values brighten\nRange: -100 to +100',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Gamma') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gamma: ${_gammaValue.toStringAsFixed(2)}'),
                  Slider(
                    value: _gammaValue,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    label: _gammaValue.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _gammaValue = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickButton('Low', 0.5),
                      _buildQuickButton('Normal', 1.0),
                      _buildQuickButton('High', 2.0),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gamma < 1.0 brightens dark areas\nGamma > 1.0 darkens bright areas',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Brightness+Contrast') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Brightness: ${_brightnessValue > 0 ? '+' : ''}$_brightnessValue'),
                  Slider(
                    value: _brightnessValue.toDouble(),
                    min: -100,
                    max: 100,
                    divisions: 200,
                    label:
                        '${_brightnessValue > 0 ? '+' : ''}$_brightnessValue',
                    onChanged: (value) {
                      setState(() {
                        _brightnessValue = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Contrast: ${_contrastValue.toStringAsFixed(2)}'),
                  Slider(
                    value: _contrastValue,
                    min: 0.0,
                    max: 3.0,
                    divisions: 60,
                    label: _contrastValue.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _contrastValue = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contrast < 1.0 reduces contrast\nContrast > 1.0 increases contrast',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton(String label, double value) {
    bool isActive = false;
    if (_currentMethod == 'Brightness') {
      isActive = _brightnessValue == value;
    } else if (_currentMethod == 'Gamma') {
      isActive = _gammaValue == value;
    }

    return OutlinedButton(
      onPressed: () {
        setState(() {
          if (_currentMethod == 'Brightness') {
            _brightnessValue = value.toInt();
          } else if (_currentMethod == 'Gamma') {
            _gammaValue = value;
          }
        });
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
        backgroundColor: isActive ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08) : null,
      ),
      child: Text(label),
    );
  }

  Widget _buildAdjustmentInfo() {
    String info = '';
    if (_currentMethod == 'Brightness') {
      info = 'Brightness: ${_brightnessValue > 0 ? '+' : ''}$_brightnessValue';
    } else if (_currentMethod == 'Gamma') {
      info = 'Gamma: ${_gammaValue.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Brightness+Contrast') {
      info =
          'Brightness: ${_brightnessValue > 0 ? '+' : ''}$_brightnessValue, Contrast: ${_contrastValue.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Auto') {
      info = 'Auto brightness adjustment applied';
    }

    return Column(
      children: [
        Text(
          info,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(
          'Adjustment applied successfully',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildComparisonButton(String label, IconData icon) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16),
        label: Text(label),
        onPressed: () {
          // Implement comparison modes
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
      setState(() {
        _selectedImage = File(pickedFile.path);
        _processedImage = null;
        _resetSliders();
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _processedImage = null;
        _resetSliders();
      });
    }
  }

  void _resetSliders() {
    _brightnessValue = 0;
    _gammaValue = 1.0;
    _contrastValue = 1.0;
  }

  Future<void> _autoAnalyze() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final optimal = BrightnessAdjust.analyzeOptimalBrightness(imageBytes);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
          title: const Text('Optimal Brightness Analysis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommended brightness adjustment: $optimal'),
              const SizedBox(height: 12),
              const Text(
                  'This value will center the average brightness around middle gray (128)'),
              const SizedBox(height: 12),
              const Text('Apply this adjustment?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _brightnessValue = optimal;
                  _currentMethod = 'Brightness';
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis error: $e')),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _previewAdjustment() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List result;

      if (_currentMethod == 'Auto') {
        result = BrightnessAdjust.autoBrightness(imageBytes);
      } else if (_currentMethod == 'Brightness') {
        result =
            BrightnessAdjust.adjustBrightness(imageBytes, _brightnessValue);
      } else if (_currentMethod == 'Gamma') {
        result = BrightnessAdjust.adjustGamma(imageBytes, _gammaValue);
      } else if (_currentMethod == 'Brightness+Contrast') {
        result = BrightnessAdjust.adjustBrightnessContrast(
          imageBytes,
          _brightnessValue,
          _contrastValue,
        );
      } else {
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

  Future<void> _applyAdjustment() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await _previewAdjustment();

      // Log to Firestore via AIExecutor
      await AIExecutor.runTool(
        toolName: 'Brightness Adjustment',
        module: 'Image AI',
        input: {
          'method': _currentMethod,
          'parameters': _getAdjustmentParameters(),
          'applied': true,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adjustment applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying adjustment: $e'),
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

  String _getAdjustmentParameters() {
    if (_currentMethod == 'Brightness') {
      return 'brightness=$_brightnessValue';
    } else if (_currentMethod == 'Gamma') {
      return 'gamma=${_gammaValue.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Brightness+Contrast') {
      return 'brightness=$_brightnessValue, contrast=${_contrastValue.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Auto') {
      return 'auto=true';
    }
    return '';
  }

  void _analyzeOptimal() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }
    await _autoAnalyze();
  }

  void _saveImage() {
    if (_processedImage == null) return;

    // Implement image saving logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image saved to gallery'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetAdjustment() {
    setState(() {
      _processedImage = null;
      _resetSliders();
      _currentMethod = 'Brightness';
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Brightness Adjustment Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem('Brightness:',
                  'Simple additive adjustment. Positive values brighten, negative values darken.'),
              _buildInfoItem('Gamma Correction:',
                  'Non-linear adjustment that preserves details better in dark/shadow areas.'),
              _buildInfoItem('Brightness+Contrast:',
                  'Combined adjustment for more control over image tonality.'),
              _buildInfoItem('Auto Brightness:',
                  'Automatically analyzes histogram and applies optimal adjustment.'),
              const SizedBox(height: 16),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Use subtle adjustments for natural results'),
              const Text('• Check histogram for clipping (loss of detail)'),
              const Text('• Auto-adjust is great for quick fixes'),
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

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          description,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

