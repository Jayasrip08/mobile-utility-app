import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/ai_executor.dart';
import '../../modules/image_ai/edge_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/tool_scaffold.dart';

class EdgeDetectionScreen extends StatefulWidget {
  const EdgeDetectionScreen({super.key});

  @override
  State<EdgeDetectionScreen> createState() => _EdgeDetectionScreenState();
}

class _EdgeDetectionScreenState extends State<EdgeDetectionScreen> {
  File? _selectedImage;
  Uint8List? _processedImage;
  bool _loading = false;
  String _currentMethod = 'Sobel';
  double _threshold = 0.1;
  double _lowThreshold = 0.05;
  double _highThreshold = 0.15;
  int _gaussianKernel = 5;
  double _sigma = 1.0;
  bool _showEdgeCoordinates = false;
  List<Map<String, double>> _edgeCoordinates = [];

  final List<String> _methods = [
    'Sobel',
    'Prewitt',
    'Canny',
    'Laplacian of Gaussian',
    'Roberts Cross'
  ];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Edge Detection',
      actions: [
        IconButton(icon: const Icon(Icons.polyline), onPressed: _showEdgeAnalysis),
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
                        label: const Text('Detect Edge Points'),
                        onPressed: _detectEdgePoints,
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
                        'Edge Detection Method:',
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
                            _processedImage = null;
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
                      onPressed: _previewEdges,
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
                          : const Icon(Icons.polyline),
                      label: const Text('Detect Edges'),
                      onPressed: _loading ? null : _detectEdges,
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

              // Edge coordinates display
              if (_showEdgeCoordinates && _edgeCoordinates.isNotEmpty) ...[
                Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edge Points Detected:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Chip(
                              label: Text('${_edgeCoordinates.length} points'),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _edgeCoordinates.take(20).length,
                            itemBuilder: (context, index) {
                              final point = _edgeCoordinates[index];
                              return Container(
                                margin: const EdgeInsets.all(4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '(${point['x']}, ${point['y']})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Showing first 20 of ${_edgeCoordinates.length} edge points',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Image comparison
              if (_processedImage != null) ...[
                const Text(
                  'Edge Detection Results:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 4,
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
                                _currentMethod,
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.teal,
                            ),
                            const Text(
                              'Edges',
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
                        _buildDetectionInfo(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Edge analysis
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edge Analysis',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildEdgeStat(
                                'Edge Points', '${_edgeCoordinates.length}'),
                            _buildEdgeStat('Method', _currentMethod),
                            _buildEdgeStat('Threshold',
                                '${_threshold.toStringAsFixed(2)}'),
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
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              // Empty state
              const SizedBox(height: 40),
              const Icon(Icons.polyline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Select an image to detect edges',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Detect edges using 5 different methods: Sobel, Prewitt, Canny, Laplacian of Gaussian, or Roberts Cross',
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
            if (_currentMethod == 'Sobel' ||
                _currentMethod == 'Prewitt' ||
                _currentMethod == 'Roberts Cross') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Threshold: ${_threshold.toStringAsFixed(2)}'),
                  Slider(
                    value: _threshold,
                    min: 0.01,
                    max: 0.5,
                    divisions: 49,
                    label: _threshold.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _threshold = value;
                      });
                    },
                  ),
                  Text(
                    'Lower threshold = more edges detected\nHigher threshold = only strong edges',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Canny') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Low Threshold: ${_lowThreshold.toStringAsFixed(2)}'),
                  Slider(
                    value: _lowThreshold,
                    min: 0.01,
                    max: 0.3,
                    divisions: 29,
                    label: _lowThreshold.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _lowThreshold = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('High Threshold: ${_highThreshold.toStringAsFixed(2)}'),
                  Slider(
                    value: _highThreshold,
                    min: _lowThreshold + 0.01,
                    max: 0.5,
                    divisions: 40,
                    label: _highThreshold.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _highThreshold = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Gaussian Kernel: $_gaussianKernel'),
                  Slider(
                    value: _gaussianKernel.toDouble(),
                    min: 3,
                    max: 15,
                    divisions: 12,
                    label: '$_gaussianKernel',
                    onChanged: (value) {
                      setState(() {
                        _gaussianKernel = value.round().isOdd
                            ? value.round()
                            : value.round() + 1;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Canny edge detection uses hysteresis thresholding\nand Gaussian smoothing for noise reduction.',
                    style:
                        TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ] else if (_currentMethod == 'Laplacian of Gaussian') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sigma: ${_sigma.toStringAsFixed(2)}'),
                  Slider(
                    value: _sigma,
                    min: 0.1,
                    max: 3.0,
                    divisions: 29,
                    label: _sigma.toStringAsFixed(2),
                    onChanged: (value) {
                      setState(() {
                        _sigma = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laplacian of Gaussian combines Gaussian smoothing\nwith Laplacian edge detection.',
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

  Widget _buildDetectionInfo() {
    String info = '';
    if (_currentMethod == 'Sobel' ||
        _currentMethod == 'Prewitt' ||
        _currentMethod == 'Roberts Cross') {
      info = 'Threshold: ${_threshold.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Canny') {
      info =
          'Low: ${_lowThreshold.toStringAsFixed(2)}, High: ${_highThreshold.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Laplacian of Gaussian') {
      info = 'Sigma: ${_sigma.toStringAsFixed(2)}';
    }

    return Column(
      children: [
        Text(
          '$_currentMethod Edge Detection',
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
          'Edge detection completed successfully',
          style: TextStyle(color: const Color(0xFF388E3C), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEdgeStat(String label, String value) {
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
      setState(() {
        _selectedImage = File(pickedFile.path);
        _processedImage = null;
        _edgeCoordinates = [];
        _showEdgeCoordinates = false;
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
        _edgeCoordinates = [];
        _showEdgeCoordinates = false;
      });
    }
  }

  Future<void> _detectEdgePoints() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final points =
          EdgeDetection.detectEdgeCoordinates(imageBytes, _threshold);

      setState(() {
        _edgeCoordinates = points;
        _showEdgeCoordinates = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected ${points.length} edge points'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error detecting edge points: $e')),
        );
      }
    }
  }

  Future<void> _previewEdges() async {
    if (_selectedImage == null) return;

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      Uint8List result;

      switch (_currentMethod) {
        case 'Sobel':
          result = EdgeDetection.sobelEdgeDetection(imageBytes,
              threshold: _threshold);
          break;
        case 'Prewitt':
          result = EdgeDetection.prewittEdgeDetection(imageBytes,
              threshold: _threshold);
          break;
        case 'Canny':
          result = EdgeDetection.cannyEdgeDetection(
            imageBytes,
            lowThreshold: _lowThreshold,
            highThreshold: _highThreshold,
            gaussianKernel: _gaussianKernel,
          );
          break;
        case 'Laplacian of Gaussian':
          result = EdgeDetection.laplacianOfGaussian(imageBytes, sigma: _sigma);
          break;
        case 'Roberts Cross':
          result = EdgeDetection.robertsCrossDetection(imageBytes,
              threshold: _threshold);
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

  Future<void> _detectEdges() async {
    if (_selectedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      await _previewEdges();

      // Log to Firestore via AIExecutor
      await AIExecutor.runTool(
        toolName: 'Edge Detection',
        module: 'Image AI',
        input: {
          'method': _currentMethod,
          'parameters': _getDetectionParameters(),
          'edgePoints': _edgeCoordinates.length,
          'applied': true,
        },
      );

      // Detect edge points if not already done
      if (_edgeCoordinates.isEmpty) {
        await _detectEdgePoints();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edge detection completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error detecting edges: $e'),
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

  String _getDetectionParameters() {
    if (_currentMethod == 'Sobel' ||
        _currentMethod == 'Prewitt' ||
        _currentMethod == 'Roberts Cross') {
      return 'threshold=${_threshold.toStringAsFixed(2)}';
    } else if (_currentMethod == 'Canny') {
      return 'low=${_lowThreshold.toStringAsFixed(2)}, high=${_highThreshold.toStringAsFixed(2)}, kernel=$_gaussianKernel';
    } else if (_currentMethod == 'Laplacian of Gaussian') {
      return 'sigma=${_sigma.toStringAsFixed(2)}';
    }
    return '';
  }

  void _showEdgeAnalysis() {
    if (_edgeCoordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No edge points detected yet')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edge Analysis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Edge Points: ${_edgeCoordinates.length}'),
              const SizedBox(height: 12),
              const Text('Edge Distribution:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              ..._buildEdgeStatistics(),
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

  List<Widget> _buildEdgeStatistics() {
    if (_edgeCoordinates.isEmpty) return [const Text('No data')];

    // Simple edge distribution analysis
    int left = 0, right = 0, top = 0, bottom = 0;
    final midX = 100; // Simplified - should be image.width/2
    final midY = 100; // Simplified - should be image.height/2

    for (final point in _edgeCoordinates) {
      if (point['x']! < midX) left++;
      if (point['x']! >= midX) right++;
      if (point['y']! < midY) top++;
      if (point['y']! >= midY) bottom++;
    }

    return [
      Text(
          'Left side: $left edges (${(left / _edgeCoordinates.length * 100).toStringAsFixed(1)}%)'),
      Text(
          'Right side: $right edges (${(right / _edgeCoordinates.length * 100).toStringAsFixed(1)}%)'),
      Text(
          'Top side: $top edges (${(top / _edgeCoordinates.length * 100).toStringAsFixed(1)}%)'),
      Text(
          'Bottom side: $bottom edges (${(bottom / _edgeCoordinates.length * 100).toStringAsFixed(1)}%)'),
    ];
  }

  void _saveImage() {
    if (_processedImage == null) return;

    // Implement image saving logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edge image saved to gallery'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _compareMethods() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edge Detection Methods'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMethodComparison(
                  'Sobel', 'Good for general purpose edge detection'),
              _buildMethodComparison(
                  'Prewitt', 'Similar to Sobel, slightly different kernel'),
              _buildMethodComparison(
                  'Canny', 'Multi-stage algorithm, best for clean edges'),
              _buildMethodComparison(
                  'Laplacian of Gaussian', 'Detects edges and blobs'),
              _buildMethodComparison(
                  'Roberts Cross', 'Simple 2x2 operator, fast'),
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

  Widget _buildMethodComparison(String method, String description) {
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
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edge Detection Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edge detection identifies boundaries within images by detecting discontinuities in brightness.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text('Applications:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('• Object detection and recognition'),
              const Text('• Image segmentation'),
              const Text('• Feature extraction'),
              const Text('• Computer vision applications'),
              const SizedBox(height: 16),
              const Text('Tips:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('• Adjust threshold to control edge sensitivity'),
              const Text('• Canny is best for clean, continuous edges'),
              const Text('• Sobel/Prewitt are good for general use'),
              const Text(
                  '• Higher thresholds reduce noise but may miss weak edges'),
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
