import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class DataSummaryScreen extends StatefulWidget {
  const DataSummaryScreen({super.key});

  @override
  State<DataSummaryScreen> createState() => _DataSummaryScreenState();
}

class _DataSummaryScreenState extends State<DataSummaryScreen> {
  final TextEditingController _dataController = TextEditingController();
  List<double> _data = [];
  Map<String, dynamic> _result = {};
  bool _loading = false;
  String _error = '';
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    // Sample data
    _dataController.text =
        '68, 70, 71, 72, 72, 73, 74, 75, 75, 76, 77, 78, 79, 80, 82';
    _parseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistical Summary Analyzer')),
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
                      'Generate Statistical Summary',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comprehensive statistical analysis of numerical data',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Data Input
                    TextField(
                      controller: _dataController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Data for Analysis',
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

                    // Advanced Options Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: _showAdvanced,
                          onChanged: _data.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _showAdvanced = value ?? false;
                                  });
                                },
                        ),
                        const Text('Advanced Statistics'),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Quick Statistics
                    if (_data.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text('n = ${_data.length}'),
                            backgroundColor: const Color(0xFFE3F2FD),
                          ),
                          Chip(
                            label: Text(
                                'Mean = ${_calculateMean().toStringAsFixed(2)}'),
                            backgroundColor: const Color(0xFFE8F5E9),
                          ),
                          Chip(
                            label: Text(
                                'SD = ${_calculateStdDev().toStringAsFixed(2)}'),
                            backgroundColor: Colors.orange.shade50,
                          ),
                          Chip(
                            label: Text(
                                'Range = ${_calculateRange().toStringAsFixed(2)}'),
                            backgroundColor: Colors.purple.shade50,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Button
                    ElevatedButton(
                      onPressed:
                          _data.isEmpty || _loading ? null : _generateSummary,
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
                          : const Text('Generate Summary'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Examples
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
                  label: const Text('Normal Distribution'),
                  onPressed: () {
                    _dataController.text =
                        '68, 70, 71, 72, 72, 73, 74, 75, 75, 76, 77, 78, 79, 80, 82';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Skewed Data'),
                  onPressed: () {
                    _dataController.text =
                        '10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 100';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Uniform'),
                  onPressed: () {
                    _dataController.text =
                        '10, 20, 30, 40, 50, 60, 70, 80, 90, 100';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Small Sample'),
                  onPressed: () {
                    _dataController.text = '5, 7, 8, 9, 12';
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
                'Statistical Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sample Size
                      Row(
                        children: [
                          const Icon(Icons.format_list_numbered,
                              color: Colors.blue),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sample Size',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '${_result['count']} values',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Sum',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                (_result['sum'] as double).toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Central Tendency
                      const Text(
                        'Central Tendency',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              'Mean',
                              (_result['mean'] as double).toStringAsFixed(4),
                              'Arithmetic average',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Median',
                              (_result['median'] as double).toStringAsFixed(4),
                              'Middle value',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              'Mode',
                              (_result['mode'] as double).toStringAsFixed(4),
                              'Most frequent',
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Dispersion Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dispersion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildSmallMetricCard(
                            'Std Deviation',
                            (_result['stdDev'] as double).toStringAsFixed(4),
                            'Spread of data',
                            Colors.purple,
                          ),
                          _buildSmallMetricCard(
                            'Variance',
                            (_result['variance'] as double).toStringAsFixed(4),
                            'StdDev squared',
                            Colors.teal,
                          ),
                          _buildSmallMetricCard(
                            'Range',
                            (_result['range'] as double).toStringAsFixed(4),
                            'Max - Min',
                            Colors.pink,
                          ),
                          _buildSmallMetricCard(
                            'IQR',
                            (_result['iqr'] as double).toStringAsFixed(4),
                            'Q3 - Q1',
                            Colors.amber,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quartiles Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quartiles & Percentiles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPercentileCard(
                              'Minimum',
                              (_result['min'] as double).toStringAsFixed(4),
                              '0th percentile',
                              Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPercentileCard(
                              'Q1 (25%)',
                              (_result['q1'] as double).toStringAsFixed(4),
                              'First quartile',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPercentileCard(
                              'Median (50%)',
                              (_result['median'] as double).toStringAsFixed(4),
                              'Second quartile',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPercentileCard(
                              'Q3 (75%)',
                              (_result['q3'] as double).toStringAsFixed(4),
                              'Third quartile',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPercentileCard(
                              'Maximum',
                              (_result['max'] as double).toStringAsFixed(4),
                              '100th percentile',
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Shape of Distribution
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shape of Distribution',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getSkewnessColor(
                                    (_result['skewness'] as double)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Skewness',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (_result['skewness'] as double)
                                        .toStringAsFixed(4),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getSkewnessDescription(
                                        (_result['skewness'] as double)),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _getKurtosisColor(
                                    (_result['kurtosis'] as double)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Kurtosis',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (_result['kurtosis'] as double)
                                        .toStringAsFixed(4),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getKurtosisDescription(
                                        (_result['kurtosis'] as double)),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Skewness/Kurtosis Explanation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Interpretation Guide',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Skewness = 0: Symmetric distribution\n'
                              '• Skewness > 0: Right-skewed (tail on right)\n'
                              '• Skewness < 0: Left-skewed (tail on left)\n'
                              '• Kurtosis = 0: Normal peak (mesokurtic)\n'
                              '• Kurtosis > 0: Sharper peak (leptokurtic)\n'
                              '• Kurtosis < 0: Flatter peak (platykurtic)',
                              style: TextStyle(fontSize: 12, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Box Plot Visualization
              if (_data.length >= 5)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Box Plot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: _buildBoxPlot(),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Summary Text
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _result['summary'] ?? 'No summary available',
                        style: const TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              // Advanced Statistics (conditional)
              if (_showAdvanced && _result.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Advanced Statistics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          childAspectRatio: 1.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildAdvancedCard('Coefficient of Variation',
                                '${((_result['stdDev'] as double) / (_result['mean'] as double).abs() * 100).toStringAsFixed(1)}%'),
                            _buildAdvancedCard('Mean Absolute Deviation',
                                _calculateMAD().toStringAsFixed(4)),
                            _buildAdvancedCard('Standard Error',
                                '${((_result['stdDev'] as double) / sqrt(_data.length)).toStringAsFixed(4)}'),
                            _buildAdvancedCard('Geometric Mean',
                                _calculateGeometricMean().toStringAsFixed(4)),
                            _buildAdvancedCard('Harmonic Mean',
                                _calculateHarmonicMean().toStringAsFixed(4)),
                            _buildAdvancedCard('Trimmed Mean (10%)',
                                _calculateTrimmedMean().toStringAsFixed(4)),
                          ],
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

  Widget _buildMetricCard(
      String title, String value, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.7).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetricCard(
      String title, String value, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentileCard(
      String title, String value, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 9,
              color: color.withValues(alpha: 0.7).withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxPlot() {
    if (_data.isEmpty ||
        !_result.containsKey('q1') ||
        !_result.containsKey('q3')) {
      return const Center(child: Text('Insufficient data for box plot'));
    }

    List<double> sortedData = List.from(_data)..sort();
    double minVal = sortedData.first;
    double maxVal = sortedData.last;
    double q1 = _result['q1'] as double;
    double median = _result['median'] as double;
    double q3 = _result['q3'] as double;

    // Calculate IQR and whiskers
    double iqr = q3 - q1;
    double lowerWhisker = max(minVal, q1 - 1.5 * iqr);
    double upperWhisker = min(maxVal, q3 + 1.5 * iqr);

    // Find outliers
    List<double> outliers = _data
        .where((value) => value < lowerWhisker || value > upperWhisker)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        double scale(double value) =>
            (value - minVal) / (maxVal - minVal) * constraints.maxWidth;

        return Stack(
          children: [
            // Whiskers
            Positioned(
              left: scale(lowerWhisker),
              width: scale(upperWhisker) - scale(lowerWhisker),
              child: Container(
                height: 2,
                color: const Color(0xFFBDBDBD),
              ),
            ),

            // Box
            Positioned(
              left: scale(q1),
              width: scale(q3) - scale(q1),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.blue),
                ),
              ),
            ),

            // Median line
            Positioned(
              left: scale(median) - 1,
              child: Container(
                width: 2,
                height: 40,
                color: Colors.red,
              ),
            ),

            // Whisker caps
            Positioned(
              left: scale(lowerWhisker) - 5,
              child: Container(
                width: 10,
                height: 2,
                color: const Color(0xFF757575),
              ),
            ),
            Positioned(
              left: scale(upperWhisker) - 5,
              child: Container(
                width: 10,
                height: 2,
                color: const Color(0xFF757575),
              ),
            ),

            // Outliers
            for (double outlier in outliers)
              Positioned(
                left: scale(outlier) - 4,
                top: 20,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getSkewnessColor(double skewness) {
    if (skewness.abs() < 0.5) return Colors.green;
    if (skewness.abs() < 1.0) return Colors.orange;
    return Colors.red;
  }

  Color _getKurtosisColor(double kurtosis) {
    if (kurtosis.abs() < 1.0) return Colors.green;
    if (kurtosis.abs() < 2.0) return Colors.orange;
    return Colors.red;
  }

  String _getSkewnessDescription(double skewness) {
    if (skewness.abs() < 0.5) return 'Symmetric';
    if (skewness > 0.5) return 'Right-skewed';
    if (skewness < -0.5) return 'Left-skewed';
    return 'Moderate';
  }

  String _getKurtosisDescription(double kurtosis) {
    if (kurtosis.abs() < 0.5) return 'Normal';
    if (kurtosis > 0.5) return 'Peaked';
    if (kurtosis < -0.5) return 'Flat';
    return 'Moderate';
  }

  double _calculateMean() {
    if (_data.isEmpty) return 0;
    return _data.reduce((a, b) => a + b) / _data.length;
  }

  double _calculateStdDev() {
    if (_data.isEmpty) return 0;
    double mean = _calculateMean();
    double variance =
        _data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            _data.length;
    return sqrt(variance);
  }

  double _calculateRange() {
    if (_data.isEmpty) return 0;
    return _data.reduce((a, b) => a > b ? a : b) -
        _data.reduce((a, b) => a < b ? a : b);
  }

  double _calculateMAD() {
    if (_data.isEmpty) return 0;
    double mean = _calculateMean();
    return _data.map((x) => (x - mean).abs()).reduce((a, b) => a + b) /
        _data.length;
  }

  double _calculateGeometricMean() {
    if (_data.isEmpty) return 0;
    double product = _data.reduce((a, b) => a * b);
    return pow(product, 1 / _data.length).toDouble();
  }

  double _calculateHarmonicMean() {
    if (_data.isEmpty) return 0;
    double sumReciprocals = _data.map((x) => 1 / x).reduce((a, b) => a + b);
    return _data.length / sumReciprocals;
  }

  double _calculateTrimmedMean() {
    if (_data.length < 3) return _calculateMean();
    List<double> sorted = List.from(_data)..sort();
    int trimCount = (_data.length * 0.1).floor();
    List<double> trimmed = sorted.sublist(trimCount, _data.length - trimCount);
    if (trimmed.isEmpty) return _calculateMean();
    return trimmed.reduce((a, b) => a + b) / trimmed.length;
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

  Future<void> _generateSummary() async {
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
        toolName: 'Data Summary',
        module: 'Data AI',
        input: _data,
      );

      setState(() {
        _result = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error generating summary: $e';
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

