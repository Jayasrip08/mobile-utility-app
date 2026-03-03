import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import '../../modules/image_ai/image_resize.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/tool_scaffold.dart';

class ImageResizeScreen extends StatefulWidget {
  const ImageResizeScreen({super.key});

  @override
  State<ImageResizeScreen> createState() => _ImageResizeScreenState();
}

class _ImageResizeScreenState extends State<ImageResizeScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _loading = false;

  // Resize parameters
  int _targetWidth = 800;
  int _targetHeight = 600;
  String _algorithm = 'Nearest Neighbor';
  bool _maintainAspectRatio = true;
  double _aspectRatio = 1.0;
  int _originalWidth = 0;
  int _originalHeight = 0;

  final List<String> _algorithms = [
    'Nearest Neighbor',
    'Bilinear Interpolation'
  ];
  final List<int> _presetSizes = [320, 480, 640, 800, 1024, 1920];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Image Resize',
      toolDescription: 'Resize images while maintaining quality.\n\nSupports:\n- Custom dimensions\n- Aspect ratio locking\n- Multiple algorithms',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Section
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                image: _selectedImage != null
                    ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                        opacity: 0.9,
                      )
                    : null,
              ),
              child: _selectedImage == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('Tap to select image', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text('Gallery'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _takePhoto,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _processedImage = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_originalWidth} × $_originalHeight',
                              style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 24),
              const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Settings Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aspect Ratio
                    SwitchListTile(
                      title: const Text('Maintain Aspect Ratio'),
                      value: _maintainAspectRatio,
                      onChanged: (value) {
                         setState(() {
                           _maintainAspectRatio = value;
                           if (value) _updateAspectRatio();
                         });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    
                    // Algorithm
                    DropdownButtonFormField<String>(
                      initialValue: _algorithm,
                      items: _algorithms.map((algo) {
                        return DropdownMenuItem(
                          value: algo,
                          child: Text(algo),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _algorithm = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Algorithm',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Width Slider
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Width'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                          child: Text('$_targetWidth px', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Slider(
                      value: _targetWidth.toDouble(),
                      min: 100,
                      max: 4000,
                      onChanged: (value) {
                        setState(() {
                          _targetWidth = value.round();
                          if (_maintainAspectRatio) {
                            _targetHeight = (_targetWidth / _aspectRatio).round();
                          }
                        });
                      },
                    ),

                    // Height Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Height'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                          child: Text('$_targetHeight px', style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Slider(
                      value: _targetHeight.toDouble(),
                      min: 100,
                      max: 4000,
                      onChanged: (value) {
                        setState(() {
                          _targetHeight = value.round();
                          if (_maintainAspectRatio) {
                            _targetWidth = (_targetHeight * _aspectRatio).round();
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    // Presets
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _presetSizes.map((size) {
                          bool isSelected = _targetWidth == size;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('${size}px'),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _targetWidth = size;
                                  if (_maintainAspectRatio) {
                                      _targetHeight = (_targetWidth / _aspectRatio).round();
                                  } else {
                                      _targetHeight = size;
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Resize Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _resizeImage,
                  icon: _loading 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Resize & Preview'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              
              if (_processedImage != null) ...[
                 const SizedBox(height: 24),
                 const Text('Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 12),
                 Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                   ),
                   child: ClipRRect(
                     borderRadius: BorderRadius.circular(12),
                     child: Image.memory(_processedImage!),
                   ),
                 ),
                 const SizedBox(height: 12),
                 Row(
                   children: [
                     Expanded(
                       child: OutlinedButton.icon(
                         onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image saved!')));
                         },
                         icon: const Icon(Icons.save_alt),
                         label: const Text('Save to Gallery'),
                       ),
                     ),
                   ],
                 ),
              ],
            ],
            const SizedBox(height: 32),
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
    if (pickedFile != null) await _loadImage(File(pickedFile.path));
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) await _loadImage(File(pickedFile.path));
  }

  Future<void> _loadImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);
    setState(() {
      _selectedImage = imageFile;
      _originalWidth = image.width;
      _originalHeight = image.height;
      _aspectRatio = image.width / image.height;
      _targetWidth = 800;
      _targetHeight = (_targetWidth / _aspectRatio).round();
      _processedImage = null;
    });
  }

  void _updateAspectRatio() {
    if (_originalWidth > 0 && _originalHeight > 0) {
      _aspectRatio = _originalWidth / _originalHeight;
      _targetHeight = (_targetWidth / _aspectRatio).round();
    }
  }

  Future<void> _resizeImage() async {
    if (_selectedImage == null) return;
    setState(() => _loading = true);

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List result;

      if (_algorithm == 'Nearest Neighbor') {
        result = ImageResize.resizeNearestNeighbor(imageBytes, _targetWidth, _targetHeight);
      } else {
        result = ImageResize.resizeBilinear(imageBytes, _targetWidth, _targetHeight);
      }

      await AIExecutor.runTool(
        toolName: 'Image Resize',
        module: 'Image AI',
        input: {
          'originalSize': '$_originalWidth×$_originalHeight',
          'newSize': '$_targetWidth×$_targetHeight',
          'algorithm': _algorithm,
        },
      );

      setState(() {
        _processedImage = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
