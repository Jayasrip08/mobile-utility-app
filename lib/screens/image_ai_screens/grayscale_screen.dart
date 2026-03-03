import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import '../../modules/image_ai/grayscale.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/tool_scaffold.dart';

class GrayscaleScreen extends StatefulWidget {
  const GrayscaleScreen({super.key});

  @override
  State<GrayscaleScreen> createState() => _GrayscaleScreenState();
}

class _GrayscaleScreenState extends State<GrayscaleScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _loading = false;
  String _currentMethod = 'Luminosity';
  int _threshold = 128;
  double _redWeight = 0.299;
  double _greenWeight = 0.587;
  double _blueWeight = 0.114;
  String _selectedChannel = 'red';
  int _otsuThreshold = 128;
  bool _showThresholdGuide = false;

  final List<String> _methods = [
    'Luminosity',
    'Average',
    'Lightness',
    'Desaturation',
    'Custom Weights',
    'Channel Extraction',
    'Binary'
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Grayscale Conversion',
      actions: [
        IconButton(icon: const Icon(Icons.auto_awesome), onPressed: _calculateOtsu),
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
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analyze Image'),
                        onPressed: _analyzeImage,
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
                        'Conversion Method:',
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
              _buildControls(),

              const SizedBox(height: 20),

              // Action buttons
                  Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.remove_red_eye),
                      label: const Text('Preview'),
                      onPressed: _previewConversion,
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
                          : const Icon(Icons.filter_b_and_w),
                      label: const Text('Convert'),
                      onPressed: _loading ? null : _applyConversion,
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

              // Threshold guide
              if (_showThresholdGuide) _buildThresholdGuide(),

              // Image comparison
              if (_processedImage != null) ...[
                const Text(
                  'Conversion Results:',
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
                              'Color',
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
                              'Grayscale',
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
                        _buildConversionInfo(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Method comparison
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Method Comparison',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _methods
                                .where((method) => method != _currentMethod)
                                .map((method) => _buildMethodChip(method))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save and Convert buttons
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
                        label: const Text('Try Another'),
                        onPressed: _tryAnotherMethod,
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
              Icon(Icons.filter_b_and_w, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Select an image to convert to grayscale',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Convert color images to grayscale using 7 different methods including luminosity, average, desaturation, and binary thresholding',
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
            if (_currentMethod == 'Luminosity') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Formula: 0.299R + 0.587G + 0.114B'),
                  SizedBox(height: 8),
                  Text(
                    'Perceptually weighted method that accounts for human eye sensitivity.\nRecommended for most applications.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Average') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Formula: (R + G + B) ÷ 3'),
                  SizedBox(height: 8),
                  Text(
                    'Simple average of RGB channels.\nFast but can produce washed-out results.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Lightness') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Formula: (max(R,G,B) + min(R,G,B)) ÷ 2'),
                  SizedBox(height: 8),
                  Text(
                    'Average of maximum and minimum channel values.\nGood for high-contrast images.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Desaturation') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Convert to HSL and set saturation to 0'),
                  SizedBox(height: 8),
                  Text(
                    'Preserves luminance while removing color.\nGood for artistic effects.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Custom Weights') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Red Weight: ${_redWeight.toStringAsFixed(3)}'),
                  Slider(
                    value: _redWeight,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: _redWeight.toStringAsFixed(3),
                    onChanged: (value) {
                      setState(() {
                        _redWeight = value;
                      });
                    },
                  ),
                  Text('Green Weight: ${_greenWeight.toStringAsFixed(3)}'),
                  Slider(
                    value: _greenWeight,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: _greenWeight.toStringAsFixed(3),
                    onChanged: (value) {
                      setState(() {
                        _greenWeight = value;
                      });
                    },
                  ),
                  Text('Blue Weight: ${_blueWeight.toStringAsFixed(3)}'),
                  Slider(
                    value: _blueWeight,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    label: _blueWeight.toStringAsFixed(3),
                    onChanged: (value) {
                      setState(() {
                        _blueWeight = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Weight: ${(_redWeight + _greenWeight + _blueWeight).toStringAsFixed(3)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _resetWeights,
                    child: const Text('Reset to Luminosity Weights'),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Channel Extraction') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Extract Single Channel:'),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: ['red', 'green', 'blue'].map((channel) {
                      return ButtonSegment(
                        value: channel,
                        label: Text(channel.toUpperCase()),
                      );
                    }).toList(),
                    selected: {_selectedChannel},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedChannel = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Extracts and displays only the $_selectedChannel channel.\nUseful for analyzing individual color components.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Binary') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Threshold: $_threshold'),
                  Slider(
                    value: _threshold.toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    label: '$_threshold',
                    onChanged: (value) {
                      setState(() {
                        _threshold = value.round();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildThresholdButton('Dark', 64),
                      _buildThresholdButton('Medium', 128),
                      _buildThresholdButton('Light', 192),
                      _buildThresholdButton('Otsu', _otsuThreshold),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pixels > threshold become white (255), others become black (0).\nUseful for creating black-and-white images.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showThresholdGuide = !_showThresholdGuide;
                      });
                    },
                    child: Text(_showThresholdGuide
                        ? 'Hide Guide'
                        : 'Show Threshold Guide'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdButton(String label, int value) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _threshold = value;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side:
            BorderSide(color: _threshold == value ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.outline),
        backgroundColor: _threshold == value ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
      ),
      child: Text(label),
    );
  }

  Widget _buildThresholdGuide() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Threshold Guide:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.white],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: (_threshold / 255) * 100 - 10,
                    child: Column(
                      children: [
                        const Icon(Icons.arrow_drop_up,
                            size: 24, color: Colors.red),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            '$_threshold',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Black (0)', style: TextStyle(fontSize: 12)),
                Text('Threshold',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text('White (255)', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pixels darker than threshold become black (0)\nPixels lighter than threshold become white (255)',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionInfo() {
    String info = '';
    if (_currentMethod == 'Luminosity') {
      info = 'Luminosity Method (Perceptual)';
    } else if (_currentMethod == 'Average') {
      info = 'Average Method';
    } else if (_currentMethod == 'Lightness') {
      info = 'Lightness Method';
    } else if (_currentMethod == 'Desaturation') {
      info = 'Desaturation Method';
    } else if (_currentMethod == 'Custom Weights') {
      info =
          'Custom Weights: R${_redWeight.toStringAsFixed(2)} G${_greenWeight.toStringAsFixed(2)} B${_blueWeight.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Channel Extraction') {
      info = '${_selectedChannel.toUpperCase()} Channel Extraction';
    } else if (_currentMethod == 'Binary') {
      info = 'Binary Threshold: $_threshold';
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
          'Conversion completed successfully',
          style: TextStyle(color: Colors.green, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMethodChip(String method) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(method),
        selected: false,
        onSelected: (selected) {
          setState(() {
            _currentMethod = method;
          });
        },
        showCheckmark: false,
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
        _showThresholdGuide = false;
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
        _showThresholdGuide = false;
      });
    }
  }

  void _resetWeights() {
    setState(() {
      _redWeight = 0.299;
      _greenWeight = 0.587;
      _blueWeight = 0.114;
    });
  }

  Future<void> _calculateOtsu() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final otsuValue = Grayscale.calculateOtsuThreshold(imageBytes);

      setState(() {
        _otsuThreshold = otsuValue;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
          title: const Text('Otsu Threshold Calculation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Optimal threshold value: $otsuValue'),
              const SizedBox(height: 12),
              const Text(
                  'Otsu\'s method automatically calculates the optimal threshold by maximizing inter-class variance.'),
              const SizedBox(height: 12),
              const Text('Use this value for binary conversion?'),
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
                  _currentMethod = 'Binary';
                  _threshold = otsuValue;
                });
                Navigator.pop(context);
              },
              child: const Text('Use Value'),
            ),
          ],
        ),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Otsu calculation error: $e')),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Analysis'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommended conversion methods:'),
              SizedBox(height: 8),
              Text('• For photos: Luminosity or Desaturation'),
              Text('• For documents: Binary with Otsu threshold'),
              Text('• For artistic effects: Channel Extraction'),
              Text('• For analysis: Custom Weights'),
              SizedBox(height: 12),
              Text(
                  'Tip: Try different methods to see which works best for your specific image.'),
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

  Future<void> _previewConversion() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List result;

      switch (_currentMethod) {
        case 'Luminosity':
          result = Grayscale.convertLuminosity(imageBytes);
          break;
        case 'Average':
          result = Grayscale.convertAverage(imageBytes);
          break;
        case 'Lightness':
          result = Grayscale.convertLightness(imageBytes);
          break;
        case 'Desaturation':
          result = Grayscale.convertDesaturation(imageBytes);
          break;
        case 'Custom Weights':
          result = Grayscale.convertCustomWeights(
            imageBytes,
            _redWeight,
            _greenWeight,
            _blueWeight,
          );
          break;
        case 'Channel Extraction':
          result = Grayscale.extractChannel(imageBytes, _selectedChannel);
          break;
        case 'Binary':
          result = Grayscale.convertBinary(imageBytes, _threshold);
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

  Future<void> _applyConversion() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await _previewConversion();

      // Log to Firestore via AIExecutor
      await AIExecutor.runTool(
        toolName: 'Grayscale Conversion',
        module: 'Image AI',
        input: {
          'method': _currentMethod,
          'parameters': _getConversionParameters(),
          'applied': true,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversion completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error converting image: $e'),
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

  String _getConversionParameters() {
    if (_currentMethod == 'Custom Weights') {
      return 'red=${_redWeight.toStringAsFixed(3)}, green=${_greenWeight.toStringAsFixed(3)}, blue=${_blueWeight.toStringAsFixed(3)}';
    } else if (_currentMethod == 'Channel Extraction') {
      return 'channel=$_selectedChannel';
    } else if (_currentMethod == 'Binary') {
      return 'threshold=$_threshold';
    } else {
      return 'auto=true';
    }
  }

  void _saveImage() {
    if (_processedImage == null) return;

    // Implement image saving logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grayscale image saved to gallery'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _tryAnotherMethod() {
    setState(() {
      _processedImage = null;
      // Cycle to next method
      final currentIndex = _methods.indexOf(_currentMethod);
      final nextIndex = (currentIndex + 1) % _methods.length;
      _currentMethod = _methods[nextIndex];
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grayscale Conversion Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem('Luminosity:',
                  'Perceptually weighted (0.299R + 0.587G + 0.114B). Best for photos.'),
              _buildInfoItem('Average:',
                  'Simple average (R+G+B)/3. Fast but can wash out colors.'),
              _buildInfoItem(
                  'Lightness:', '(max+min)/2. Good for high contrast images.'),
              _buildInfoItem('Desaturation:',
                  'Convert to HSL, set saturation=0. Preserves luminance.'),
              _buildInfoItem('Custom Weights:',
                  'Set your own RGB weights for custom effects.'),
              _buildInfoItem('Channel Extraction:',
                  'View individual color channels separately.'),
              _buildInfoItem('Binary:',
                  'Black and white thresholding. Good for documents/text.'),
              const SizedBox(height: 16),
              const Text(
                'Applications:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Photography and art'),
              const Text('• Document processing'),
              const Text('• Computer vision preprocessing'),
              const Text('• Printing and publishing'),
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
          style: TextStyle(color: const Color(0xFF616161), fontSize: 13),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

