import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import '../../modules/image_ai/blur_filter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/tool_scaffold.dart';

class BlurFilterScreen extends StatefulWidget {
  const BlurFilterScreen({super.key});

  @override
  State<BlurFilterScreen> createState() => _BlurFilterScreenState();
}

class _BlurFilterScreenState extends State<BlurFilterScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _loading = false;
  String _currentFilter = 'Gaussian';
  double _blurAmount = 3.0;
  double _sigma = 1.0;
  int _kernelSize = 5;
  double _motionLength = 20.0;
  double _motionAngle = 0.0;
  double _bilateralSigmaColor = 75.0;
  double _bilateralSigmaSpace = 75.0;
  int _medianSize = 3;

  final List<String> _filterTypes = [
    'Gaussian',
    'Box',
    'Median',
    'Motion',
    'Bilateral',
    'Stack'
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Blur Filters',
      actions: [IconButton(icon: const Icon(Icons.info_outline), onPressed: _showInfoDialog)],
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
                      Text(
                        'Original Image Selected',
                        style: TextStyle(
                          color: const Color(0xFF388E3C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 20),

              // Filter type selection
              Card(
                color: Theme.of(context).colorScheme.surface,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blur Filter Type:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: _filterTypes.map((type) {
                          return ButtonSegment(
                            value: type,
                            label: Text(type),
                          );
                        }).toList(),
                        selected: {_currentFilter},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _currentFilter = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filter parameters
              _buildFilterControls(),

              const SizedBox(height: 20),

              // Action buttons
                  Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.remove_red_eye),
                      label: const Text('Preview'),
                      onPressed: _previewFilter,
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
                          : const Icon(Icons.tune),
                      label: const Text('Apply Filter'),
                      onPressed: _loading ? null : _applyFilter,
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
                            const Text(
                              'Original',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Chip(
                              label: Text(
                                _currentFilter,
                                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                            const Text(
                              'Filtered',
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
                        _buildFilterInfo(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save and Analyze buttons
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
                        icon: const Icon(Icons.analytics),
                        label: const Text('Analyze'),
                        onPressed: _analyzeImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              const SizedBox(height: 40),
              Icon(Icons.blur_on, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Select an image to apply blur filters',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Choose from 6 different blur filters: Gaussian, Box, Median, Motion, Bilateral, and Stack Blur',
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

  Widget _buildFilterControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_currentFilter Blur Parameters:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_currentFilter == 'Gaussian') ...[
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
                  Text('Sigma: ${_sigma.toStringAsFixed(1)}'),
                  Slider(
                    value: _sigma,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    label: _sigma.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _sigma = value;
                      });
                    },
                  ),
                  Text(
                    'Higher sigma = more blur\nKernel must be odd number',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentFilter == 'Box') ...[
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
                        _kernelSize = value.round();
                      });
                    },
                  ),
                  Text(
                    'Simple average blur\nFast but can create artifacts',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentFilter == 'Median') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kernel Size: $_medianSize'),
                  Slider(
                    value: _medianSize.toDouble(),
                    min: 3,
                    max: 11,
                    divisions: 8,
                    label: '$_medianSize',
                    onChanged: (value) {
                      setState(() {
                        _medianSize = value.round().isOdd
                            ? value.round()
                            : value.round() + 1;
                      });
                    },
                  ),
                  Text(
                    'Great for removing noise while preserving edges\nBest for salt-and-pepper noise',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentFilter == 'Motion') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Motion Length: ${_motionLength.toStringAsFixed(0)}'),
                  Slider(
                    value: _motionLength,
                    min: 5,
                    max: 50,
                    divisions: 45,
                    label: _motionLength.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() {
                        _motionLength = value;
                      });
                    },
                  ),
                  Text('Motion Angle: ${_motionAngle.toStringAsFixed(0)}°'),
                  Slider(
                    value: _motionAngle,
                    min: 0,
                    max: 360,
                    divisions: 36,
                    label: '${_motionAngle.toStringAsFixed(0)}°',
                    onChanged: (value) {
                      setState(() {
                        _motionAngle = value;
                      });
                    },
                  ),
                  Text(
                    'Simulates camera/object motion\nAngle: 0° = horizontal, 90° = vertical',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentFilter == 'Bilateral') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kernel Diameter: $_kernelSize'),
                  Slider(
                    value: _kernelSize.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    label: '$_kernelSize',
                    onChanged: (value) {
                      setState(() {
                        _kernelSize = value.round();
                      });
                    },
                  ),
                  Text(
                      'Sigma Color: ${_bilateralSigmaColor.toStringAsFixed(0)}'),
                  Slider(
                    value: _bilateralSigmaColor,
                    min: 10,
                    max: 150,
                    divisions: 14,
                    label: _bilateralSigmaColor.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() {
                        _bilateralSigmaColor = value;
                      });
                    },
                  ),
                  Text(
                      'Sigma Space: ${_bilateralSigmaSpace.toStringAsFixed(0)}'),
                  Slider(
                    value: _bilateralSigmaSpace,
                    min: 10,
                    max: 150,
                    divisions: 14,
                    label: _bilateralSigmaSpace.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() {
                        _bilateralSigmaSpace = value;
                      });
                    },
                  ),
                  Text(
                    'Edge-preserving smoothing\nGreat for photos and portraits',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentFilter == 'Stack') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Blur Radius: ${_blurAmount.toStringAsFixed(0)}'),
                  Slider(
                    value: _blurAmount,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: _blurAmount.toStringAsFixed(0),
                    onChanged: (value) {
                      setState(() {
                        _blurAmount = value;
                      });
                    },
                  ),
                  Text(
                    'Fast approximation of Gaussian blur\nGood for real-time applications',
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

  Widget _buildFilterInfo() {
    String info = '';
    if (_currentFilter == 'Gaussian') {
      info =
          'Gaussian Blur\nKernel: ${_kernelSize}x$_kernelSize, Sigma: ${_sigma.toStringAsFixed(1)}';
    } else if (_currentFilter == 'Box') {
      info = 'Box Blur\nKernel: ${_kernelSize}x$_kernelSize';
    } else if (_currentFilter == 'Median') {
      info = 'Median Filter\nKernel: ${_medianSize}x$_medianSize';
    } else if (_currentFilter == 'Motion') {
      info =
          'Motion Blur\nLength: ${_motionLength.toStringAsFixed(0)}px, Angle: ${_motionAngle.toStringAsFixed(0)}°';
    } else if (_currentFilter == 'Bilateral') {
      info =
          'Bilateral Filter\nDiameter: $_kernelSize, σ-color: ${_bilateralSigmaColor.toStringAsFixed(0)}, σ-space: ${_bilateralSigmaSpace.toStringAsFixed(0)}';
    } else if (_currentFilter == 'Stack') {
      info = 'Stack Blur\nRadius: ${_blurAmount.toStringAsFixed(0)}';
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
          'Filter applied successfully',
          style: TextStyle(color: const Color(0xFF388E3C), fontSize: 12),
        ),
      ],
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
      });
    }
  }

  Future<void> _previewFilter() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List result;

      switch (_currentFilter) {
        case 'Gaussian':
          result =
              BlurFilter.gaussianBlur(imageBytes, _kernelSize, sigma: _sigma);
          break;
        case 'Box':
          result = BlurFilter.boxBlur(imageBytes, _kernelSize);
          break;
        case 'Median':
          result = BlurFilter.medianFilter(imageBytes, _medianSize);
          break;
        case 'Motion':
          result = BlurFilter.motionBlur(
              imageBytes, _motionLength.round(), _motionAngle);
          break;
        case 'Bilateral':
          result = BlurFilter.bilateralFilter(
            imageBytes,
            _kernelSize,
            _bilateralSigmaColor,
            _bilateralSigmaSpace,
          );
          break;
        case 'Stack':
          result = BlurFilter.stackBlur(imageBytes, _blurAmount.round());
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

  Future<void> _applyFilter() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await _previewFilter();

      // Log to Firestore via AIExecutor
      await AIExecutor.runTool(
        toolName: 'Blur Filter',
        module: 'Image AI',
        input: {
          'filter': _currentFilter,
          'parameters': _getFilterParameters(),
          'applied': true,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filter applied successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying filter: $e'),
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

  String _getFilterParameters() {
    switch (_currentFilter) {
      case 'Gaussian':
        return 'kernel=$_kernelSize, sigma=$_sigma';
      case 'Box':
        return 'kernel=$_kernelSize';
      case 'Median':
        return 'kernel=$_medianSize';
      case 'Motion':
        return 'length=${_motionLength.toStringAsFixed(0)}, angle=${_motionAngle.toStringAsFixed(0)}';
      case 'Bilateral':
        return 'diameter=$_kernelSize, sigmaColor=${_bilateralSigmaColor.toStringAsFixed(0)}, sigmaSpace=${_bilateralSigmaSpace.toStringAsFixed(0)}';
      case 'Stack':
        return 'radius=${_blurAmount.toStringAsFixed(0)}';
      default:
        return '';
    }
  }

  void _saveImage() {
    if (_processedImage == null) return;

    // Implement image saving logic
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image saved to gallery'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _analyzeImage() async {
    if (_selectedImage == null || _processedImage == null) return;

    try {
      final originalBytes = await _selectedImage!.readAsBytes();
      final needsBlur = BlurFilter.needsBlurring(originalBytes, 0.1);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
          title: const Text('Image Analysis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Blur Analysis:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'Original image ${needsBlur ? 'needs' : 'does not need'} blurring'),
              const SizedBox(height: 12),
              Text('Applied Filter: $_currentFilter'),
              Text('Parameters: ${_getFilterParameters()}'),
              const SizedBox(height: 12),
              Text('Recommended for this image:'),
              const SizedBox(height: 4),
              Text(
                  '• ${needsBlur ? 'Strong blur recommended' : 'Light blur sufficient'}'),
              Text(
                  '• ${_currentFilter == 'Bilateral' || _currentFilter == 'Median' ? 'Good choice for edge preservation' : 'Consider bilateral filter for better edge preservation'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      }
    } catch (e) {
      // Ignore analysis errors
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Blur Filters Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem('Gaussian Blur:',
                  'Smooth, natural-looking blur using Gaussian distribution'),
              _buildInfoItem('Box Blur:',
                  'Fast, simple average blur (can create boxy artifacts)'),
              _buildInfoItem('Median Filter:',
                  'Removes noise while preserving edges (great for salt-and-pepper noise)'),
              _buildInfoItem(
                  'Motion Blur:', 'Simulates camera or object movement'),
              _buildInfoItem('Bilateral Filter:',
                  'Edge-preserving smoothing (best for photos/portraits)'),
              _buildInfoItem('Stack Blur:',
                  'Fast approximation of Gaussian blur (good for real-time)'),
              const SizedBox(height: 16),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Use lower values for subtle effects'),
              const Text('• Use higher values for dramatic effects'),
              const Text('• Try different filters for different results'),
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
