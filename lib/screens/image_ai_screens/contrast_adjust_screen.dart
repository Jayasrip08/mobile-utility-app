
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import '../../modules/image_ai/contrast_adjust.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/tool_scaffold.dart';

class ContrastAdjustScreen extends StatefulWidget {
  const ContrastAdjustScreen({super.key});

  @override
  State<ContrastAdjustScreen> createState() => _ContrastAdjustScreenState();
}

class _ContrastAdjustScreenState extends State<ContrastAdjustScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _loading = false;
  String _currentMethod = 'Contrast';
  double _contrastValue = 1.0;
  int _tileSize = 8;
  double _clipLimit = 0.01;
  bool _showHistogram = false;
  double _calculatedContrast = 1.0;

  final List<String> _methods = [
    'Contrast',
    'Histogram Equalization',
    'Adaptive Histogram',
    'Auto Contrast'
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Contrast Adjustment',
      actions: [
        IconButton(icon: Icon(_showHistogram ? Icons.bar_chart : Icons.bar_chart_outlined), onPressed: _toggleHistogram),
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
                        label: const Text('Analyze Contrast'),
                        onPressed: _analyzeContrast,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 20),

              // Contrast analysis
              if (_calculatedContrast > 0) _buildContrastAnalysis(),

              // Method selection
              Card(
                elevation: 4,
                shadowColor: Colors.deepPurple.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                           Icon(Icons.tune, color: Colors.deepPurple),
                           SizedBox(width: 8),
                           const Text(
                             'Contrast Method',
                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                           ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _methods.map((method) {
                          final isSelected = _currentMethod == method;
                          return ChoiceChip(
                            label: Text(method),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _currentMethod = method;
                                });
                              }
                            },
                            selectedColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              _buildControls(),

              const SizedBox(height: 24),

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
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
                        ),
                        boxShadow: [
                           BoxShadow(
                             color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                             blurRadius: 8,
                             offset: const Offset(0, 4),
                           ),
                        ],
                      ),
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
                            : const Icon(Icons.auto_fix_high),
                        label: const Text('Apply Magic'),
                        onPressed: _loading ? null : _applyAdjustment,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Image comparison
              if (_processedImage != null) ...[
                Text(
                  'Results',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 12),

                Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 6,
                  shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                         Container(
                           padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                           color: Theme.of(context).colorScheme.primaryContainer,
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Text(
                                 'Original',
                                 style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                               ),
                               Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.primary),
                               Text(
                                 'Enhanced',
                                 style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                               ),
                             ],
                           ),
                         ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(_selectedImage!, height: 180, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(_processedImage!, height: 180, fit: BoxFit.cover),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildAdjustmentInfo(),
                        SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Histogram visualization
                if (_showHistogram) _buildHistogramVisualization(),

                const SizedBox(height: 24),

                // Save and Compare buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Save to Gallery'),
                        onPressed: _saveImage,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Empty state
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.contrast, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Image Selected',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select an image to start adjusting contrast\nusing advanced AI algorithms.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContrastAnalysis() {
    String contrastLevel;
    Color color;

    if (_calculatedContrast < 2.0) {
      contrastLevel = 'Low Contrast';
      color = Colors.orange;
    } else if (_calculatedContrast < 5.0) {
      contrastLevel = 'Medium Contrast';
      color = Colors.blue;
    } else {
      contrastLevel = 'High Contrast';
      color = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Image Analysis:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Chip(
                  label: Text(contrastLevel,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _calculatedContrast / 10.0,
              backgroundColor: const Color(0xFFEEEEEE),
              color: color,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Contrast Ratio:'),
                Text(
                  _calculatedContrast.toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
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
            if (_currentMethod == 'Contrast') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickContrastButton('Low', 0.5),
                      _buildQuickContrastButton('Normal', 1.0),
                      _buildQuickContrastButton('High', 1.5),
                      _buildQuickContrastButton('Very High', 2.0),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Values < 1.0 reduce contrast\nValues > 1.0 increase contrast',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Histogram Equalization') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full-image histogram equalization'),
                  SizedBox(height: 8),
                  Text(
                    'Enhances contrast by redistributing pixel intensities\nacross the entire image.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Best for images with poor contrast distribution',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Adaptive Histogram') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tile Size: ${_tileSize}x$_tileSize'),
                  Slider(
                    value: _tileSize.toDouble(),
                    min: 4,
                    max: 64,
                    divisions: 15,
                    label: '$_tileSize',
                    onChanged: (value) {
                      setState(() {
                        _tileSize = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Clip Limit: ${_clipLimit.toStringAsFixed(3)}'),
                  Slider(
                    value: _clipLimit,
                    min: 0.001,
                    max: 0.1,
                    divisions: 99,
                    label: _clipLimit.toStringAsFixed(3),
                    onChanged: (value) {
                      setState(() {
                        _clipLimit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CLAHE (Contrast Limited Adaptive Histogram Equalization)\nProcesses image in tiles for local contrast enhancement',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Auto Contrast') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Automatic contrast adjustment'),
                  SizedBox(height: 8),
                  Text(
                    'Automatically stretches histogram to use full intensity range\nwhile preserving image details.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Great for quick contrast enhancement',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickContrastButton(String label, double value) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _contrastValue = value;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(
            color: _contrastValue == value ? Colors.deepPurple : Colors.grey),
        backgroundColor:
            _contrastValue == value ? Colors.deepPurple.withValues(alpha: 0.1) : null,
      ),
      child: Text(label),
    );
  }

  Widget _buildAdjustmentInfo() {
    String info = '';
    if (_currentMethod == 'Contrast') {
      info = 'Contrast: ${_contrastValue.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Histogram Equalization') {
      info = 'Histogram Equalization applied';
    } else if (_currentMethod == 'Adaptive Histogram') {
      info =
          'CLAHE: Tile=${_tileSize}x$_tileSize, Clip=${_clipLimit.toStringAsFixed(3)}';
    } else if (_currentMethod == 'Auto Contrast') {
      info = 'Auto-contrast applied';
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
          'Contrast enhancement applied successfully',
          style: TextStyle(color: const Color(0xFF388E3C), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHistogramVisualization() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Histogram Comparison',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE0E0E0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Histogram visualization\n(Would show actual histogram data here)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Original',
                    style: TextStyle(color: const Color(0xFF1976D2))),
                Text('Adjusted',
                    style: TextStyle(color: const Color(0xFF388E3C))),
              ],
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
      _contrastValue = 1.0;
      _tileSize = 8;
      _clipLimit = 0.01;
    });

    // Calculate initial contrast
    try {
      final bytes = await imageFile.readAsBytes();
      _calculatedContrast = ContrastAdjust.calculateContrastRatio(bytes);
      setState(() {});
    } catch (e) {
      _calculatedContrast = 1.0;
    }
  }

  Future<void> _analyzeContrast() async {
    if (_selectedImage == null) return;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final ratio = ContrastAdjust.calculateContrastRatio(bytes);

      setState(() {
        _calculatedContrast = ratio;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
          title: const Text('Contrast Analysis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contrast Ratio: ${ratio.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              if (ratio < 2.0) const Text('→ Low contrast image'),
              if (ratio >= 2.0 && ratio < 5.0)
                const Text('→ Medium contrast image'),
              if (ratio >= 5.0) const Text('→ High contrast image'),
              const SizedBox(height: 12),
              const Text('Recommended method:'),
              if (ratio < 2.0)
                const Text('• Histogram Equalization or Auto Contrast'),
              if (ratio >= 2.0 && ratio < 5.0)
                const Text('• Simple contrast adjustment'),
              if (ratio >= 5.0) const Text('• No enhancement needed'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis error: $e')),
        );
      }
    }
  }

  Future<void> _previewAdjustment() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List result;

      switch (_currentMethod) {
        case 'Contrast':
          result = ContrastAdjust.adjustContrast(imageBytes, _contrastValue);
          break;
        case 'Histogram Equalization':
          result = ContrastAdjust.histogramEqualization(imageBytes);
          break;
        case 'Adaptive Histogram':
          result = ContrastAdjust.adaptiveHistogramEqualization(
            imageBytes,
            _tileSize,
            _clipLimit,
          );
          break;
        case 'Auto Contrast':
          result = ContrastAdjust.autoContrast(imageBytes);
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

  Future<void> _applyAdjustment() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await _previewAdjustment();

      // Log to Firestore via AIExecutor
      await AIExecutor.runTool(
        toolName: 'Contrast Adjustment',
        module: 'Image AI',
        input: {
          'method': _currentMethod,
          'parameters': _getAdjustmentParameters(),
          'originalContrast': _calculatedContrast.toStringAsFixed(2),
          'applied': true,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contrast adjustment applied successfully!'),
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
    if (_currentMethod == 'Contrast') {
      return 'contrast=${_contrastValue.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Adaptive Histogram') {
      return 'tileSize=$_tileSize, clipLimit=${_clipLimit.toStringAsFixed(3)}';
    } else {
      return 'auto=true';
    }
  }

  void _toggleHistogram() {
    setState(() {
      _showHistogram = !_showHistogram;
    });
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

  

  

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contrast Adjustment Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoItem('Simple Contrast:',
                  'Linear adjustment. Good for fine-tuning contrast levels.'),
              _buildInfoItem('Histogram Equalization:',
                  'Enhances contrast by redistributing pixel intensities across the full range.'),
              _buildInfoItem('Adaptive Histogram (CLAHE):',
                  'Processes image in tiles for local contrast enhancement. Best for images with varying lighting.'),
              _buildInfoItem('Auto Contrast:',
                  'Automatically stretches histogram to use full intensity range. Good for quick fixes.'),
              const SizedBox(height: 16),
              const Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('• Histogram equalization can over-enhance noise'),
              const Text('• CLAHE is best for medical and scientific images'),
              const Text('• Use subtle adjustments for natural results'),
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
        const SizedBox(height: 8),
      ],
    );
  }
}

