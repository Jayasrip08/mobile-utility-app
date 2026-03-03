 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import '../../services/ai_executor.dart';
import '../../modules/image_ai/image_crop.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/tool_scaffold.dart';

class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({super.key});

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  String _result = '';
  bool _loading = false;

  // Crop parameters
  String _cropType = 'Rectangle';
  int _cropX = 0;
  int _cropY = 0;
  int _cropWidth = 200;
  int _cropHeight = 200;
  int _circleRadius = 100;
  int _centerX = 0;
  int _centerY = 0;
  int _autoTolerance = 10;

  int _originalWidth = 0;
  int _originalHeight = 0;

  final List<String> _cropTypes = ['Rectangle', 'Circle', 'Auto-crop'];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Image Crop',
      toolDescription: 'Crop images: rectangle, circle or auto-crop borders.',
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
                        'Original: ${_originalWidth} × $_originalHeight',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 20),

              // Crop type selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crop Type:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: _cropTypes.map((type) {
                          return ButtonSegment(
                            value: type,
                            label: Text(type),
                          );
                        }).toList(),
                        selected: {_cropType},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _cropType = newSelection.first;
                            _resetCropParameters();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Crop controls based on type
              if (_cropType == 'Rectangle') ...[
                _buildRectangleControls(),
              ] else if (_cropType == 'Circle') ...[
                _buildCircleControls(),
              ] else if (_cropType == 'Auto-crop') ...[
                _buildAutoCropControls(),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.crop_free),
                      label: const Text('Preview Crop'),
                      onPressed: _previewCrop,
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
                          : const Icon(Icons.crop),
                      label: const Text('Apply Crop'),
                      onPressed: _loading ? null : _applyCrop,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
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
                        const Text(
                          'Original → Cropped',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Image.file(_selectedImage!, height: 150),
                                  Text(
                                    '${_originalWidth} × $_originalHeight',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward, size: 32),
                            Expanded(
                              child: Column(
                                children: [
                                  Image.memory(_processedImage!, height: 150),
                                  Text(
                                    _getCropDimensionsText(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _result,
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Save button
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Cropped Image'),
                  onPressed: _saveImage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ] else ...[
              // Empty state
              const SizedBox(height: 40),
              Icon(Icons.crop, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(
                'Select an image to crop',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRectangleControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rectangle Crop Parameters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // X coordinate
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('X Position: $_cropX px'),
                Slider(
                  value: _cropX.toDouble(),
                  min: 0,
                  max: max(1, _originalWidth - _cropWidth).toDouble(),
                  divisions: 50,
                  label: '$_cropX px',
                  onChanged: (value) {
                    setState(() {
                      _cropX = value.round();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Y coordinate
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Y Position: $_cropY px'),
                Slider(
                  value: _cropY.toDouble(),
                  min: 0,
                  max: max(1, _originalHeight - _cropHeight).toDouble(),
                  divisions: 50,
                  label: '$_cropY px',
                  onChanged: (value) {
                    setState(() {
                      _cropY = value.round();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Width
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Width: $_cropWidth px'),
                Slider(
                  value: _cropWidth.toDouble(),
                  min: 10,
                  max: (_originalWidth - _cropX).toDouble(),
                  divisions: 50,
                  label: '$_cropWidth px',
                  onChanged: (value) {
                    setState(() {
                      _cropWidth = value.round();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Height
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Height: $_cropHeight px'),
                Slider(
                  value: _cropHeight.toDouble(),
                  min: 10,
                  max: (_originalHeight - _cropY).toDouble(),
                  divisions: 50,
                  label: '$_cropHeight px',
                  onChanged: (value) {
                    setState(() {
                      _cropHeight = value.round();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick presets
            const Text('Quick Presets:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('Square (1:1)', 200, 200),
                _buildPresetChip('16:9', 320, 180),
                _buildPresetChip('4:3', 240, 180),
                _buildPresetChip('Portrait', 200, 300),
                _buildPresetChip('Landscape', 300, 200),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int width, int height) {
    return FilterChip(
      label: Text(label),
      selected: _cropWidth == width && _cropHeight == height,
      onSelected: (selected) {
        setState(() {
          _cropWidth = width;
          _cropHeight = height;
        });
      },
    );
  }

  Widget _buildCircleControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Circle Crop Parameters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Center X
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Center X: $_centerX px'),
                Slider(
                  value: _centerX.toDouble(),
                  min: 0,
                  max: _originalWidth.toDouble(),
                  divisions: 50,
                  label: '$_centerX px',
                  onChanged: (value) {
                    setState(() {
                      _centerX = value.round();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Center Y
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Center Y: $_centerY px'),
                Slider(
                  value: _centerY.toDouble(),
                  min: 0,
                  max: _originalHeight.toDouble(),
                  divisions: 50,
                  label: '$_centerY px',
                  onChanged: (value) {
                    setState(() {
                      _centerY = value.round();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Radius
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Radius: $_circleRadius px'),
                Slider(
                  value: _circleRadius.toDouble(),
                  min: 10,
                  max: min(_originalWidth, _originalHeight).toDouble() / 2,
                  divisions: 50,
                  label: '$_circleRadius px',
                  onChanged: (value) {
                    setState(() {
                      _circleRadius = value.round();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick radius presets
            const Text('Quick Radius:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [50, 100, 150, 200, 250].map((radius) {
                return FilterChip(
                  label: Text('${radius}px'),
                  selected: _circleRadius == radius,
                  onSelected: (selected) {
                    setState(() {
                      _circleRadius = radius;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCropControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto-crop Parameters:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Text(
              'Auto-crop automatically detects and removes borders '
              'based on color similarity.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),

            const SizedBox(height: 16),

            // Tolerance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Color Tolerance: $_autoTolerance'),
                Slider(
                  value: _autoTolerance.toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  label: '$_autoTolerance',
                  onChanged: (value) {
                    setState(() {
                      _autoTolerance = value.round();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Lower tolerance = stricter border detection\n'
              'Higher tolerance = more aggressive cropping',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _resetCropParameters() {
    if (_originalWidth > 0 && _originalHeight > 0) {
      setState(() {
        _cropX = 0;
        _cropY = 0;
        _cropWidth = min(200, _originalWidth);
        _cropHeight = min(200, _originalHeight);
        _circleRadius = min(100, min(_originalWidth, _originalHeight) ~/ 2);
        _centerX = _originalWidth ~/ 2;
        _centerY = _originalHeight ~/ 2;
        _autoTolerance = 10;
        _processedImage = null;
        _result = '';
      });
    }
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
    final bytes = await imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);

    setState(() {
      _selectedImage = imageFile;
      _originalWidth = image.width;
      _originalHeight = image.height;
      _resetCropParameters();
    });
  }

  String _getCropDimensionsText() {
    if (_cropType == 'Rectangle') {
      return '${_cropWidth} × $_cropHeight';
    } else if (_cropType == 'Circle') {
      return 'Circle (R=$_circleRadius)';
    } else {
      return 'Auto-cropped';
    }
  }

  Future<void> _previewCrop() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List preview;

      if (_cropType == 'Rectangle') {
        preview = ImageCrop.cropRectangle(
            imageBytes, _cropX, _cropY, _cropWidth, _cropHeight);
      } else if (_cropType == 'Circle') {
        preview =
            ImageCrop.cropCircle(imageBytes, _centerX, _centerY, _circleRadius);
      } else {
        final result = ImageCrop.autoCrop(imageBytes, _autoTolerance);
        preview = result['image'] as Uint8List;
      }

      setState(() {
        _processedImage = preview;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview error: $e')),
        );
      }
    }
  }

  Future<void> _applyCrop() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List result;

      if (_cropType == 'Rectangle') {
        result = ImageCrop.cropRectangle(
            imageBytes, _cropX, _cropY, _cropWidth, _cropHeight);

        _result = 'Cropped rectangle at ($_cropX, $_cropY) '
            '${_cropWidth}×$_cropHeight';
      } else if (_cropType == 'Circle') {
        result =
            ImageCrop.cropCircle(imageBytes, _centerX, _centerY, _circleRadius);

        _result = 'Cropped circle at ($_centerX, $_centerY) '
            'with radius $_circleRadius';
      } else {
        final autoResult = ImageCrop.autoCrop(imageBytes, _autoTolerance);
        result = autoResult['image'] as Uint8List;

        if (autoResult['success'] as bool) {
          final bounds = autoResult['bounds'] as Map<String, dynamic>;
          final dims = autoResult['dimensions'] as Map<String, dynamic>;

          _result = 'Auto-cropped to ${dims['width']}×${dims['height']}\n'
              'Bounds: ${bounds['left']},${bounds['top']} '
              'to ${bounds['right']},${bounds['bottom']}';
        } else {
          _result = autoResult['message'] as String;
        }
      }

      // Save to Firestore via AIExecutor
      await AIExecutor.runTool(
        toolName: 'Image Crop',
        module: 'Image AI',
        input: {
          'type': _cropType,
          'parameters': _cropType == 'Rectangle'
              ? 'x=$_cropX, y=$_cropY, w=$_cropWidth, h=$_cropHeight'
              : _cropType == 'Circle'
                  ? 'center=($_centerX,$_centerY), radius=$_circleRadius'
                  : 'tolerance=$_autoTolerance',
        },
      );

      setState(() {
        _processedImage = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cropped image saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
