import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class CentralTendencyScreen extends StatefulWidget {
  const CentralTendencyScreen({super.key});

  @override
  State<CentralTendencyScreen> createState() => _CentralTendencyScreenState();
}

class _CentralTendencyScreenState extends State<CentralTendencyScreen> {
  final TextEditingController _dataController = TextEditingController();
  List<double> _data = [];
  Map<String, dynamic> _result = {};
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Sample data with some skew
    _dataController.text = '10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 100';
    _parseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mean-Median-Mode Analyzer')),
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
                      'Analyze Central Tendency',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Compare different measures of central tendency',
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
                            label: Text('n = ${_data.length}'),
                            backgroundColor: const Color(0xFFE3F2FD),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                                'Sum = ${_data.reduce((a, b) => a + b).toStringAsFixed(1)}'),
                            backgroundColor: const Color(0xFFE8F5E9),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _data.isEmpty || _loading ? null : _analyze,
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
                          : const Text('Analyze Central Tendency'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Examples
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
                  label: const Text('Right Skewed'),
                  onPressed: () {
                    _dataController.text =
                        '10, 15, 20, 25, 30, 35, 40, 50, 60, 80, 100';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Left Skewed'),
                  onPressed: () {
                    _dataController.text =
                        '100, 80, 60, 50, 40, 35, 30, 25, 20, 15, 10';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Bimodal'),
                  onPressed: () {
                    _dataController.text =
                        '10, 10, 10, 20, 20, 20, 30, 30, 30, 100, 100, 100';
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
                'Central Tendency Analysis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Comparison Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comparison of Measures',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Mean
                      _buildMeasureCard(
                        'Arithmetic Mean',
                        _result['mean'].toStringAsFixed(4),
                        'Average of all values',
                        Colors.blue,
                        Icons.calculate,
                      ),

                      const SizedBox(height: 12),

                      // Median
                      _buildMeasureCard(
                        'Median',
                        _result['median'].toStringAsFixed(4),
                        'Middle value (50th percentile)',
                        Colors.green,
                        Icons.line_weight,
                      ),

                      const SizedBox(height: 12),

                      // Mode
                      _buildMeasureCard(
                        'Mode',
                        (_result['mode'] as List).join(', '),
                        'Most frequent value(s)',
                        Colors.orange,
                        Icons.bar_chart,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Other Measures Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Other Central Tendency Measures',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                          _buildSmallMeasureCard(
                            'Geometric Mean',
                            _result['geometricMean'].toStringAsFixed(4),
                            Colors.purple,
                          ),
                          _buildSmallMeasureCard(
                            'Harmonic Mean',
                            _result['harmonicMean'].toStringAsFixed(4),
                            Colors.teal,
                          ),
                          _buildSmallMeasureCard(
                            'Trimmed Mean (10%)',
                            _result['trimmedMean'].toStringAsFixed(4),
                            Colors.pink,
                          ),
                          _buildSmallMeasureCard(
                            'Winsorized Mean (10%)',
                            _result['winsorizedMean'].toStringAsFixed(4),
                            Colors.amber,
                          ),
                          _buildSmallMeasureCard(
                            'Midrange',
                            _result['midrange'].toStringAsFixed(4),
                            Colors.cyan,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Analysis Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis & Recommendation',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      // Visual comparison
                      Container(
                        height: 60,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: _buildVisualComparison(),
                      ),

                      const SizedBox(height: 16),

                      // Text analysis
                      Text(
                        _result['analysis'] ?? 'No analysis available',
                        style: const TextStyle(height: 1.5),
                      ),

                      const SizedBox(height: 16),

                      // Recommendation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb,
                                    size: 20, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Recommendation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _result['recommendation'] ??
                                  'Use arithmetic mean',
                              style: const TextStyle(
                                  color: Color(0xFF0D47A1)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Data Visualization
              if (_data.length >= 3)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data Distribution',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: _buildDotPlot(),
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

  Widget _buildMeasureCard(String title, String value, String description,
      Color color, IconData icon) {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMeasureCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildVisualComparison() {
    if (_result.isEmpty) return const SizedBox();

    double mean = (_result['mean'] as double?) ?? 0;
    double median = (_result['median'] as double?) ?? 0;
    double mode =
        (_result['mode'] is List && (_result['mode'] as List).isNotEmpty)
            ? (_result['mode'] as List).first
            : 0;

    double minVal = _data.reduce((a, b) => a < b ? a : b);
    double maxVal = _data.reduce((a, b) => a > b ? a : b);
    double range = maxVal - minVal;

    if (range == 0) return const Center(child: Text('All values identical'));

    return Column(
      children: [
        // Scale
        SizedBox(
          height: 4,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Points
        SizedBox(
          height: 30,
          child: Stack(
            children: [
              // Mean
              Positioned(
                left: ((mean - minVal) / range) * 100,
                child: Column(
                  children: [
                    Icon(Icons.circle, color: Colors.blue, size: 16),
                    const SizedBox(height: 4),
                    const Text('Mean',
                        style: TextStyle(fontSize: 10, color: Colors.blue)),
                  ],
                ),
              ),

              // Median
              Positioned(
                left: ((median - minVal) / range) * 100,
                child: Column(
                  children: [
                    Icon(Icons.circle, color: Colors.green, size: 16),
                    const SizedBox(height: 4),
                    const Text('Median',
                        style: TextStyle(fontSize: 10, color: Colors.green)),
                  ],
                ),
              ),

              // Mode
              Positioned(
                left: ((mode - minVal) / range) * 100,
                child: Column(
                  children: [
                    Icon(Icons.circle, color: Colors.orange, size: 16),
                    const SizedBox(height: 4),
                    const Text('Mode',
                        style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Min/Max labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minVal.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10)),
            Text(maxVal.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildDotPlot() {
    if (_data.isEmpty) return const Center(child: Text('No data'));

    // Sort and count frequencies
    Map<double, int> frequency = {};
    for (var value in _data) {
      frequency[value] = (frequency[value] ?? 0) + 1;
    }

    List<double> uniqueValues = frequency.keys.toList()..sort();
    int maxFreq = frequency.values.reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: uniqueValues.length,
      itemBuilder: (context, index) {
        double value = uniqueValues[index];
        int freq = frequency[value]!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Frequency indicator
              Container(
                width: 20,
                height: (freq / maxFreq) * 150,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Center(
                  child: Text(
                    freq.toString(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Value label
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
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

  Future<void> _analyze() async {
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
        toolName: 'Mean–Median–Mode Analyzer',
        module: 'Data AI',
        input: _data,
      );

      setState(() {
        _result = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error analyzing data: $e';
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

