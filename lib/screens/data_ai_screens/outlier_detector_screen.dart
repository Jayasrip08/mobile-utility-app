import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class OutlierDetectorScreen extends StatefulWidget {
  const OutlierDetectorScreen({super.key});

  @override
  State<OutlierDetectorScreen> createState() => _OutlierDetectorScreenState();
}

class _OutlierDetectorScreenState extends State<OutlierDetectorScreen> {
  final TextEditingController _dataController = TextEditingController();
  List<double> _data = [];
  Map<String, dynamic> _result = {};
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Sample data with outliers
    _dataController.text = '10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 100, 120';
    _parseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outlier Detector')),
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
                      'Detect Outliers in Data',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Identify unusual values using multiple statistical methods',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dataController,
                      maxLines: 5,
                      decoration: InputDecoration(
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
                    if (_data.isNotEmpty) ...[
                      Row(
                        children: [
                          Chip(
                            label: Text('${_data.length} values'),
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
                                'Std Dev: ${_calculateStdDev().toStringAsFixed(2)}'),
                            backgroundColor: Colors.orange.shade50,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          _data.isEmpty || _loading ? null : _detectOutliers,
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
                          : const Text('Detect Outliers'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Examples
            const Text(
              'Test Cases:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Normal Data'),
                  onPressed: () {
                    _dataController.text =
                        '68, 70, 71, 72, 72, 73, 74, 75, 75, 76, 77, 78, 79, 80, 82';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Single Outlier'),
                  onPressed: () {
                    _dataController.text =
                        '10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 100';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Multiple Outliers'),
                  onPressed: () {
                    _dataController.text =
                        '10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 80, 90, 100';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Extreme Outliers'),
                  onPressed: () {
                    _dataController.text =
                        '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1000';
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

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Outlier Detection Results',
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
                        'Summary',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Consensus Outliers',
                              _result['count']?.toString() ?? '0',
                              Colors.red,
                              Icons.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Percentage',
                              '${_result['percentage'] ?? '0'}%',
                              Colors.orange,
                              Icons.percent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getSeverityBorderColor()),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getSeverityIcon(),
                              color: _getSeverityIconColor(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Severity: ${(_result['severity'] ?? 'low').toString().toUpperCase()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getSeverityTextColor(),
                                    ),
                                  ),
                                  if (_result.containsKey('analysis'))
                                    Text(
                                      _result['analysis'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getSeverityTextColor(),
                                      ),
                                    ),
                                ],
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

              // Detected Outliers Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Outliers',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_result.containsKey('consensusOutliers') &&
                          (_result['consensusOutliers'] as List).isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_result['consensusOutliers'] as List)
                              .map<Widget>((outlier) {
                            return Chip(
                              label: Text(outlier.toStringAsFixed(2)),
                              backgroundColor: const Color(0xFFFFEBEE),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                // Remove this outlier from data
                                setState(() {
                                  _data.remove(outlier);
                                  _dataController.text = _data.join(', ');
                                });
                              },
                            );
                          }).toList(),
                        )
                      else
                        const Text('No outliers detected by consensus methods'),
                      const SizedBox(height: 16),
                      const Text(
                        'All Potential Outliers:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      if (_result.containsKey('allOutliers') &&
                          (_result['allOutliers'] as List).isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_result['allOutliers'] as List)
                              .map<Widget>((outlier) {
                            bool isConsensus =
                                (_result['consensusOutliers'] as List)
                                    .contains(outlier);
                            return Chip(
                              label: Text(outlier.toStringAsFixed(2)),
                              backgroundColor: isConsensus
                                  ? const Color(0xFFFFEBEE)
                                  : Colors.orange.shade50,
                              labelStyle: TextStyle(
                                color: isConsensus
                                    ? const Color(0xFFB71C1C)
                                    : Colors.orange.shade900,
                                fontWeight: isConsensus
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Method Comparison Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detection Methods Comparison',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Different statistical methods may detect different outliers:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      _buildMethodComparison(
                          'Z-Score Method', _result['zScoreOutliers']),
                      const SizedBox(height: 8),
                      _buildMethodComparison(
                          'IQR Method (Tukey)', _result['iqrOutliers']),
                      const SizedBox(height: 8),
                      _buildMethodComparison('Modified Z-Score',
                          _result['modifiedZScoreOutliers']),
                      const SizedBox(height: 8),
                      _buildMethodComparison(
                          'Standard Deviation', _result['stdDevOutliers']),
                      const SizedBox(height: 8),
                      _buildMethodComparison(
                          'Percentile Method', _result['percentileOutliers']),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Best Method',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    _result['bestMethod'] ?? 'Consensus',
                                    style: const TextStyle(
                                        color: Color(0xFF0D47A1)),
                                  ),
                                ],
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

              // Statistics Card
              if (_result.containsKey('statistics'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data Statistics',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(3),
                          },
                          children: [
                            _buildStatTableRow(
                                'Mean',
                                _result['statistics']['mean']
                                    .toStringAsFixed(4)),
                            _buildStatTableRow(
                                'Standard Deviation',
                                _result['statistics']['stdDev']
                                    .toStringAsFixed(4)),
                            _buildStatTableRow(
                                'Median',
                                _result['statistics']['median']
                                    .toStringAsFixed(4)),
                            _buildStatTableRow('Q1 (25th percentile)',
                                _result['statistics']['q1'].toStringAsFixed(4)),
                            _buildStatTableRow('Q3 (75th percentile)',
                                _result['statistics']['q3'].toStringAsFixed(4)),
                            _buildStatTableRow(
                                'IQR (Q3 - Q1)',
                                _result['statistics']['iqr']
                                    .toStringAsFixed(4)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Suggestions Card
              if (_result.containsKey('suggestions'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Handling Suggestions',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...(_result['suggestions'] as List)
                            .map<Widget>((suggestion) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.arrow_right,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(child: Text(suggestion)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Visualization
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Outlier Visualization',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _buildBoxPlot(),
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

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodComparison(String methodName, dynamic outliers) {
    List<double> outlierList = [];
    if (outliers is List) {
      outlierList = List<double>.from(outliers);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              methodName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${outlierList.length} outliers',
            style: TextStyle(
              color: outlierList.isEmpty ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildStatTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(value, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ],
    );
  }

  Widget _buildBoxPlot() {
    if (_data.isEmpty) return const Center(child: Text('No data'));

    List<double> sortedData = List.from(_data)..sort();
    int n = sortedData.length;

    if (n < 5)
      return const Center(child: Text('Insufficient data for box plot'));

    double q1 = sortedData[n ~/ 4];
    double median = sortedData[n ~/ 2];
    double q3 = sortedData[(3 * n) ~/ 4];
    double iqr = q3 - q1;

    double lowerWhisker = sortedData.firstWhere((x) => x >= q1 - 1.5 * iqr,
        orElse: () => sortedData.first);
    double upperWhisker = sortedData.lastWhere((x) => x <= q3 + 1.5 * iqr,
        orElse: () => sortedData.last);

    List<double> outliers =
        sortedData.where((x) => x < lowerWhisker || x > upperWhisker).toList();

    double minVal = sortedData.first;
    double maxVal = sortedData.last;
    double range = maxVal - minVal;

    if (range == 0) return const Center(child: Text('All values identical'));

    return Column(
      children: [
        // Box plot
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                // Whiskers
                Positioned(
                  left: ((lowerWhisker - minVal) / range) * 100,
                  right: 100 - ((upperWhisker - minVal) / range) * 100,
                  top: 40,
                  bottom: 40,
                  child: Container(
                    color: const Color(0xFFE0E0E0),
                    height: 2,
                  ),
                ),

                // Box
                Positioned(
                  left: ((q1 - minVal) / range) * 100,
                  right: 100 - ((q3 - minVal) / range) * 100,
                  top: 20,
                  bottom: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Container(
                        width: 2,
                        color: Colors.red,
                        child: Center(
                          child: Text(
                            median.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 10, color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Median line
                Positioned(
                  left: ((median - minVal) / range) * 100,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 2,
                    color: Colors.red,
                  ),
                ),

                // Outliers
                ...outliers.map((outlier) {
                  return Positioned(
                    left: ((outlier - minVal) / range) * 100,
                    top: 30,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),

        // Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minVal.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10)),
              Text('Q1: ${q1.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10)),
              Text('Median: ${median.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10, color: Colors.red)),
              Text('Q3: ${q3.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10)),
              Text(maxVal.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 12,
                      height: 12,
                      color: Colors.blue.withValues(alpha: 0.2)),
                  const SizedBox(width: 4),
                  const Text('IQR', style: TextStyle(fontSize: 10)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 2, height: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  const Text('Median', style: TextStyle(fontSize: 10)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Colors.red)),
                  const SizedBox(width: 4),
                  const Text('Outlier', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return const Color(0xFFFFEBEE);
      case 'high':
        return Colors.orange.shade50;
      case 'moderate':
        return Colors.yellow.shade50;
      case 'low':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFFAFAFA);
    }
  }

  Color _getSeverityBorderColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityIconColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityTextColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return const Color(0xFFB71C1C);
      case 'high':
        return Colors.orange.shade900;
      case 'moderate':
        return Colors.yellow.shade900;
      case 'low':
        return const Color(0xFF1B5E20);
      default:
        return const Color(0xFF212121);
    }
  }

  IconData _getSeverityIcon() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'moderate':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
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

  Future<void> _detectOutliers() async {
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
        toolName: 'Outlier Detector',
        module: 'Data AI',
        input: _data,
      );

      setState(() {
        _result = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error detecting outliers: $e';
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

