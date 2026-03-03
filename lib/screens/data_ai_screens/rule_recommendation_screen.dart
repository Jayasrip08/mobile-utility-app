import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class RuleRecommendationScreen extends StatefulWidget {
  const RuleRecommendationScreen({super.key});

  @override
  State<RuleRecommendationScreen> createState() =>
      _RuleRecommendationScreenState();
}

class _RuleRecommendationScreenState extends State<RuleRecommendationScreen> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  List<double> _data = [];
  Map<String, dynamic> _result = {};
  bool _loading = false;
  String _error = '';
  String _selectedContext = 'general';

  final Map<String, String> _contexts = {
    'general': 'General Analysis',
    'timeseries': 'Time Series',
    'percentages': 'Percentages (0-100)',
    'probabilities': 'Probabilities (0-1)',
    'ratings': 'Ratings/Scores (1-10)',
    'returns': 'Returns/Changes',
    'financial': 'Financial Data',
    'scientific': 'Scientific Measurements',
  };

  @override
  void initState() {
    super.initState();
    // Sample data for analysis
    _dataController.text = '10, 15, 20, 25, 30, 35, 40, 50, 60, 80, 100';
    _parseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rule-based Recommendation')),
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
                      'Get AI Recommendations for Data Analysis',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Receive intelligent suggestions based on data characteristics',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),

                    // Context Selection
                    const Text('Data Context:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedContext,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: _contexts.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedContext = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Custom Context (optional)
                    TextField(
                      controller: _contextController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Context (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText:
                            'e.g., Customer satisfaction scores, monthly revenue...',
                      ),
                    ),

                    const SizedBox(height: 16),

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
                                'Range: ${_calculateRange().toStringAsFixed(2)}'),
                            backgroundColor: Colors.orange.shade50,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Button
                    ElevatedButton(
                      onPressed: _data.isEmpty || _loading
                          ? null
                          : _getRecommendations,
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
                          : const Text('Get Recommendations'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Examples
            const Text(
              'Example Scenarios:',
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
                    _selectedContext = 'general';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('With Outliers'),
                  onPressed: () {
                    _dataController.text =
                        '10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 100';
                    _selectedContext = 'general';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Percentages'),
                  onPressed: () {
                    _dataController.text =
                        '85, 90, 92, 88, 95, 87, 91, 89, 93, 94';
                    _selectedContext = 'percentages';
                    _parseData();
                  },
                ),
                ActionChip(
                  label: const Text('Time Series'),
                  onPressed: () {
                    _dataController.text =
                        '100, 105, 110, 108, 115, 120, 125, 130, 135, 140';
                    _selectedContext = 'timeseries';
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
                'AI Recommendations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Confidence Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Confidence',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _getConfidenceBorderColor()),
                        ),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              value: (_result['confidence'] ?? 0) / 100,
                              strokeWidth: 8,
                              backgroundColor: const Color(0xFFEEEEEE),
                              valueColor: AlwaysStoppedAnimation(
                                  _getConfidenceProgressColor()),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(_result['confidence'] ?? 0).toStringAsFixed(1)}% Confidence',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getConfidenceTextColor(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Based on ${_result['rulesTriggered']?.length ?? 0} rules triggered',
                              style: TextStyle(
                                color: _getConfidenceTextColor(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Severity
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

              // Recommendations Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key Recommendations',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_result.containsKey('recommendations'))
                        ...(_result['recommendations'] as List)
                            .asMap()
                            .entries
                            .map((entry) {
                          int index = entry.key;
                          String recommendation = entry.value;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getRecommendationColor(index),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: _getRecommendationBorderColor(index)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _getRecommendationNumberColor(index),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (index + 1).toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(recommendation)),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action Items Card
              if (_result.containsKey('actionItems'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Action Items',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...(_result['actionItems'] as List).map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle,
                                    size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Rules Triggered Card
              if (_result.containsKey('rulesTriggered'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rules Triggered',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_result['rulesTriggered'] as List)
                              .map<Widget>((rule) {
                            return Chip(
                              label: Text(rule),
                              backgroundColor: _getRuleColor(rule),
                            );
                          }).toList(),
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
                            _buildStatTableRow('Sample Size',
                                _result['statistics']['n'].toString()),
                            _buildStatTableRow(
                                'Mean',
                                _result['statistics']['mean']
                                    .toStringAsFixed(4)),
                            _buildStatTableRow(
                                'Median',
                                _result['statistics']['median']
                                    .toStringAsFixed(4)),
                            _buildStatTableRow(
                                'Standard Deviation',
                                _result['statistics']['stdDev']
                                    .toStringAsFixed(4)),
                            _buildStatTableRow('Range',
                                '${_result['statistics']['min'].toStringAsFixed(2)} - ${_result['statistics']['max'].toStringAsFixed(2)}'),
                            _buildStatTableRow('Coefficient of Variation',
                                '${_result['statistics']['cv'].toStringAsFixed(1)}%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Patterns Card
              if (_result.containsKey('patterns'))
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detected Patterns',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ..._result['patterns'].entries.map<Widget>((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key
                                            .toString()
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        entry.value.toString(),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Visualization Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Visualization',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _buildDataVisualization(),
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

  Widget _buildDataVisualization() {
    if (_data.isEmpty) return const Center(child: Text('No data'));

    List<double> sortedData = List.from(_data)..sort();
    double minVal = sortedData.first;
    double maxVal = sortedData.last;
    double range = maxVal - minVal;

    if (range == 0) return const Center(child: Text('All values identical'));

    // Calculate percentiles
    int n = sortedData.length;
    double q1 = sortedData[n ~/ 4];
    double median = sortedData[n ~/ 2];
    double q3 = sortedData[(3 * n) ~/ 4];

    return Column(
      children: [
        // Box plot
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                // Range line
                Positioned(
                  left: 0,
                  right: 0,
                  top: 20,
                  child: Container(
                    height: 2,
                    color: const Color(0xFFBDBDBD),
                  ),
                ),

                // Box
                Positioned(
                  left: ((q1 - minVal) / range) * 100,
                  right: 100 - ((q3 - minVal) / range) * 100,
                  top: 10,
                  bottom: 10,
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
                      ),
                    ),
                  ),
                ),

                // Median line
                Positioned(
                  left: ((median - minVal) / range) * 100,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Colors.red,
                  ),
                ),

                // Min/Max points
                Positioned(
                  left: 0,
                  top: 18,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  right: 0,
                  top: 18,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
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
              Column(
                children: [
                  const Text('Min',
                      style: TextStyle(fontSize: 10, color: Colors.green)),
                  Text(minVal.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  const Text('Q1',
                      style: TextStyle(fontSize: 10, color: Colors.blue)),
                  Text(q1.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  const Text('Median',
                      style: TextStyle(fontSize: 10, color: Colors.red)),
                  Text(median.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  const Text('Q3',
                      style: TextStyle(fontSize: 10, color: Colors.blue)),
                  Text(q3.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
              Column(
                children: [
                  const Text('Max',
                      style: TextStyle(fontSize: 10, color: Colors.green)),
                  Text(maxVal.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
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
                          shape: BoxShape.circle, color: Colors.green)),
                  const SizedBox(width: 4),
                  const Text('Min/Max', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor() {
    double confidence = _result['confidence'] ?? 0;
    if (confidence >= 80) return const Color(0xFFE8F5E9);
    if (confidence >= 60) return Colors.yellow.shade50;
    return const Color(0xFFFFEBEE);
  }

  Color _getConfidenceBorderColor() {
    double confidence = _result['confidence'] ?? 0;
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.yellow;
    return Colors.red;
  }

  Color _getConfidenceProgressColor() {
    double confidence = _result['confidence'] ?? 0;
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.yellow;
    return Colors.red;
  }

  Color _getConfidenceTextColor() {
    double confidence = _result['confidence'] ?? 0;
    if (confidence >= 80) return const Color(0xFF1B5E20);
    if (confidence >= 60) return Colors.yellow.shade900;
    return const Color(0xFFB71C1C);
  }

  Color _getSeverityColor() {
    String severity = _result['severity'] ?? 'low';
    switch (severity) {
      case 'high':
        return const Color(0xFFFFEBEE);
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
      case 'high':
        return Colors.red;
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
      case 'high':
        return Colors.red;
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
      case 'high':
        return const Color(0xFFB71C1C);
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

  Color _getRecommendationColor(int index) {
    List<Color> colors = [
      const Color(0xFFE3F2FD),
      const Color(0xFFE8F5E9),
      Colors.orange.shade50,
      Colors.purple.shade50,
      Colors.teal.shade50,
    ];
    return colors[index % colors.length];
  }

  Color _getRecommendationBorderColor(int index) {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  Color _getRecommendationNumberColor(int index) {
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  Color _getRuleColor(String rule) {
    Map<String, Color> ruleColors = {
      'OutlierDetection': const Color(0xFFFFEBEE),
      'HighVariability': Colors.orange.shade50,
      'LowVariability': const Color(0xFFE8F5E9),
      'HighSkewness': Colors.purple.shade50,
      'SmallSample': const Color(0xFFE3F2FD),
      'LargeSample': Colors.teal.shade50,
      'NonNormal': Colors.yellow.shade50,
      'TrendDetected': Colors.pink.shade50,
      'ClusteredData': Colors.cyan.shade50,
      'RangeAnalysis': Colors.indigo[50]!,
    };
    return ruleColors[rule] ?? const Color(0xFFFAFAFA);
  }

  double _calculateMean() {
    if (_data.isEmpty) return 0;
    return _data.reduce((a, b) => a + b) / _data.length;
  }

  double _calculateRange() {
    if (_data.isEmpty) return 0;
    double minVal = _data.reduce((a, b) => a < b ? a : b);
    double maxVal = _data.reduce((a, b) => a > b ? a : b);
    return maxVal - minVal;
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

  Future<void> _getRecommendations() async {
    if (_data.isEmpty) {
      setState(() => _error = 'Please enter some data');
      return;
    }

    setState(() {
      _loading = true;
      _result = {};
    });

    try {
      String context = _selectedContext;
      if (_contextController.text.isNotEmpty) {
        context = _contextController.text;
      }

      final result = await AIExecutor.runTool(
        toolName: 'Rule-based Recommendation',
        module: 'Data AI',
        input: {
          'data': _data,
          'context': context,
        },
      );

      setState(() {
        _result = result as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error getting recommendations: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    _contextController.dispose();
    super.dispose();
  }
}

