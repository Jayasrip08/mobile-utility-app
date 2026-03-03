import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_executor.dart';

class DataNormalizerScreen extends StatefulWidget {
  const DataNormalizerScreen({super.key});

  @override
  State<DataNormalizerScreen> createState() => _DataNormalizerScreenState();
}

class _DataNormalizerScreenState extends State<DataNormalizerScreen> {
  final TextEditingController _dataController = TextEditingController();
  List<double> _data = [];
  Map<String, dynamic> _result = {};
  bool _loading = false;
  String _error = '';
  String _selectedMethod = 'auto';

  final List<String> _methods = [
    'auto',
    'minmax',
    'zscore',
    'decimal',
    'log',
    'robust',
    'unit'
  ];

  final Map<String, String> _methodDescriptions = {
    'auto': 'Automatic method selection based on data characteristics',
    'minmax': 'Scale data to [0, 1] range (Min-Max normalization)',
    'zscore': 'Standardize data to mean=0, std=1 (Z-Score)',
    'decimal': 'Scale by powers of 10 (Decimal scaling)',
    'log': 'Logarithmic transformation for skewed data',
    'robust': 'Use median and IQR (robust to outliers)',
    'unit': 'Normalize to unit vector (L2 norm)',
  };

  @override
  void initState() {
    super.initState();
    // Sample data with different scales
    _dataController.text = '1000, 1200, 1500, 1800, 2000, 2500, 3000';
    _parseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Normalizer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Normalize Numerical Data',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Transform data to common scale using different normalization techniques',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Method Selection
                    const Text('Normalization Method:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMethod,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: _methods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(
                            method == 'auto'
                                ? 'Auto (Recommended)'
                                : method.toUpperCase(),
                            style: TextStyle(
                              fontWeight: method == 'auto'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 8),
                    Text(
                      _methodDescriptions[_selectedMethod] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),

                    const SizedBox(height: 16),

                    // Data Input
                    TextField(
                      controller: _dataController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Original Data',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter numerical data...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _dataController.clear();
                            setState(() {
                              _data = [];
                              _result = {};
                            });
                          },
                        ),
                      ),
                      onChanged: (_) => _parseData(),
                    ),

                    const SizedBox(height: 12),

                    // Statistics
                    if (_data.isNotEmpty) ...[
                      Row(
                        children: [
                          Chip(
                            label: Text('n = ${_data.length}'),
                            backgroundColor: const Color(0xFFE3F2FD),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                                'Mean: ${_calculateMean().toStringAsFixed(2)}'),
                            backgroundColor: const Color(0xFFE8F5E9),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                                'Std: ${_calculateStdDev().toStringAsFixed(2)}'),
                            backgroundColor: Colors.orange.shade50,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Button
                    ElevatedButton(
                      onPressed:
                          _data.isEmpty || _loading ? null : _normalizeData,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Normalize (${_selectedMethod.toUpperCase()})'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Examples
            const Text(
              'Example Datasets:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Large Values'),
                  onPressed: () {
                    _dataController.text = '1000, 2000, 3000, 4000, 5000, 6000';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('With Outliers'),
                  onPressed: () {
                    _dataController.text =
                        '10, 12, 14, 15, 16, 17, 18, 19, 20, 100';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Skewed Data'),
                  onPressed: () {
                    _dataController.text = '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 50';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Small Range'),
                  onPressed: () {
                    _dataController.text = '0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7';
                    _parseData();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Error Display
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error)),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Results Display
            if (_result.isNotEmpty) ...[
              const Text(
                'Normalization Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Normalization Summary',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Method Used',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        (_result['method'] ?? 'Unknown')
                                            .toString()
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildResultStat(
                                    'Success',
                                    _result['successful'] == true
                                        ? '✅ Yes'
                                        : '❌ No',
                                    _result['successful'] == true
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildResultStat(
                                    'Data Points',
                                    _data.length.toString(),
                                    Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Method Description
                      if (_result.containsKey('recommendation'))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _result['recommendation'],
                                  style: const TextStyle(
                                      color: Color(0xFF1B5E20)),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Statistics Comparison Card
              if (_result.containsKey('statistics'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Statistics Comparison',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                          },
                          border: TableBorder.all(
                            color: const Color(0xFFE0E0E0),
                            width: 1,
                          ),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                              ),
                              children: [
                                _buildTableCell('Statistic', isHeader: true),
                                _buildTableCell('Original', isHeader: true),
                                _buildTableCell('Normalized', isHeader: true),
                              ],
                            ),
                            _buildStatTableRow('Mean', 'statistics',
                                'originalMean', 'normalizedMean'),
                            _buildStatTableRow('Std Dev', 'statistics',
                                'originalStdDev', 'normalizedStdDev'),
                            _buildStatTableRow('Range', 'statistics',
                                'rangeBefore', 'rangeAfter'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Data Comparison Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Comparison',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_result.containsKey('original') &&
                          _result.containsKey('normalized'))
                        SizedBox(
                          height: 300,
                          child: _buildComparisonChart(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Normalized Data Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Normalized Data',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      if (_result.containsKey('normalized'))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_result['normalized'] as List)
                                .map<Widget>((value) {
                              return Chip(
                                label: Text(value.toStringAsFixed(4)),
                                backgroundColor: _getValueColor(value),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Copy button
                      ElevatedButton.icon(
                        onPressed: () {
                            if (_result.containsKey('normalized')) {
                            String normalizedText =
                                (_result['normalized'] as List)
                                    .map((v) => v.toStringAsFixed(6))
                                    .join(', ');
                            Clipboard.setData(ClipboardData(text: normalizedText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Copied normalized data to clipboard')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Normalized Data'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Analysis Card
              if (_result.containsKey('analysis'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analysis',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          _result['analysis'],
                          style: const TextStyle(height: 1.5),
                        ),

                        const SizedBox(height: 16),

                        // Success indicators
                        if (_result.containsKey('successful') &&
                            _result['successful'] == true)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Normalization successful! Data is ready for analysis.',
                                    style: TextStyle(
                                        color: const Color(0xFF1B5E20)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_result.containsKey('successful') &&
                            _result['successful'] == false)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Normalization failed. Try a different method.',
                                    style: TextStyle(
                                        color: const Color(0xFFB71C1C)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Method Details Card
              if (_result.containsKey('parameters'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Method Parameters',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_result['parameters'] as Map)
                              .entries
                              .map<Widget>((entry) {
                            return Chip(
                              label: Text('${entry.key}: ${entry.value}'),
                              backgroundColor: const Color(0xFFE3F2FD),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  TableRow _buildStatTableRow(
      String label, String statsKey, String originalKey, String normalizedKey) {
    Map<String, dynamic> stats = _result[statsKey] ?? {};
    return TableRow(
      children: [
        _buildTableCell(label),
        _buildTableCell(stats[originalKey]?.toStringAsFixed(4) ?? '0'),
        _buildTableCell(stats[normalizedKey]?.toStringAsFixed(4) ?? '0'),
      ],
    );
  }

  Widget _buildComparisonChart() {
    if (!_result.containsKey('original') ||
        !_result.containsKey('normalized')) {
      return const Center(child: Text('No comparison data'));
    }

    List<double> original = List<double>.from(_result['original']);
    List<double> normalized = List<double>.from(_result['normalized']);

    if (original.isEmpty || normalized.isEmpty) {
      return const Center(child: Text('Empty data'));
    }

    // Find ranges for scaling
    double origMin = original.reduce((a, b) => a < b ? a : b);
    double origMax = original.reduce((a, b) => a > b ? a : b);

    double normMin = normalized.reduce((a, b) => a < b ? a : b);
    double normMax = normalized.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        // Chart
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                // Original data
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Original',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ListView.builder(
                            itemCount: original.length,
                            itemBuilder: (context, index) {
                              double value = original[index];
                              

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(right: 4),
                                            child: Text(
                                              value.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey),
                ),

                // Normalized data
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'Normalized',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ListView.builder(
                            itemCount: normalized.length,
                            itemBuilder: (context, index) {
                              double value = normalized[index];
                              

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.6),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(right: 4),
                                            child: Text(
                                              value.toStringAsFixed(4),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scale indicators
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    origMax.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    origMin.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    normMax.toStringAsFixed(4),
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    normMin.toStringAsFixed(4),
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getValueColor(double value) {
    if (value >= 0.8) return const Color(0xFFC8E6C9);
    if (value >= 0.6) return const Color(0xFFBBDEFB);
    if (value >= 0.4) return Colors.yellow.shade100;
    if (value >= 0.2) return Colors.orange.shade100;
    return const Color(0xFFFFCDD2);
  }

  double _calculateMean() {
    if (_data.isEmpty) return 0;
    return _data.reduce((a, b) => a + b) / _data.length;
  }

  double _calculateStdDev() {
    if (_data.length < 2) return 0;
    double mean = _calculateMean();
    double variance =
        _data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            _data.length;
    return sqrt(variance);
  }

  void _parseData() {
    setState(() {
      _error = '';
      String text = _dataController.text;

      if (text.isEmpty) {
        _data = [];
        return;
      }

      try {
        List<String> parts = text.split(RegExp(r'[,\s\n]+'));
        _data = parts
            .where((part) => part.trim().isNotEmpty)
            .map((part) => double.parse(part.trim()))
            .toList();

        if (_data.isEmpty) {
          _error = 'No valid numbers found';
        }
      } catch (e) {
        _error = 'Error parsing data: $e';
        _data = [];
      }
    });
  }

  Future<void> _normalizeData() async {
    if (_data.isEmpty) {
      setState(() => _error = 'Please enter some data');
      return;
    }

    setState(() {
      _loading = true;
      _result = {};
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Data Normalizer',
        module: 'Data AI',
        input: {
          'data': _data,
          'method': _selectedMethod,
        },
      );

      setState(() {
        _result = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error normalizing data: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }
}

