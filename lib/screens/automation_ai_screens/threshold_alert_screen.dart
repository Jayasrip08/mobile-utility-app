import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class ThresholdAlertScreen extends StatefulWidget {
  const ThresholdAlertScreen({super.key});

  @override
  State<ThresholdAlertScreen> createState() => _ThresholdAlertScreenState();
}

class _ThresholdAlertScreenState extends State<ThresholdAlertScreen> {
  final TextEditingController _valueController =
      TextEditingController(text: '85');
  final TextEditingController _thresholdController =
      TextEditingController(text: '75');
  final TextEditingController _contextController =
      TextEditingController(text: 'CPU Usage');
  final TextEditingController _historicalDataController =
      TextEditingController(text: '70, 72, 75, 78, 80, 82, 85');

  String _alertResult = '';
  bool _loading = false;
  String _selectedAnalysis = 'check';
  Map<String, dynamic> _trendAnalysis = {};
  Map<String, dynamic> _optimizationResult = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Threshold Alert System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Threshold Monitoring & Alert System',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Monitor values against thresholds and generate intelligent alerts',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Analysis Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analysis Type:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildAnalysisChip(
                            'Threshold Check', Icons.check_circle),
                        _buildAnalysisChip('Trend Analysis', Icons.trending_up),
                        _buildAnalysisChip('Optimization', Icons.tune),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Common Inputs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Threshold Configuration',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _valueController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Current Value',
                              border: OutlineInputBorder(),
                              hintText: 'Enter current value',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _thresholdController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Threshold',
                              border: OutlineInputBorder(),
                              hintText: 'Enter threshold value',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contextController,
                      decoration: const InputDecoration(
                        labelText: 'Context (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., CPU Usage, Temperature, Response Time',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildExampleChip(
                            'CPU: 85/75', '85', '75', 'CPU Usage'),
                        _buildExampleChip(
                            'Temp: 40/35', '40', '35', 'Temperature'),
                        _buildExampleChip(
                            'Memory: 90/80', '90', '80', 'Memory Usage'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Historical Data Input (for trend analysis)
            if (_selectedAnalysis == 'trend' ||
                _selectedAnalysis == 'optimization') ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historical Data',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _historicalDataController,
                        decoration: const InputDecoration(
                          labelText: 'Historical Values (comma separated)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 70, 72, 75, 78, 80, 82, 85',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildHistoricalExampleChip(
                              'Increasing', '60, 65, 70, 75, 80'),
                          _buildHistoricalExampleChip(
                              'Decreasing', '85, 80, 75, 70, 65'),
                          _buildHistoricalExampleChip(
                              'Stable', '75, 74, 76, 75, 74'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Run Analysis Button
            ElevatedButton(
              onPressed: _loading ? null : _runAnalysis,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_selectedAnalysis == 'check'
                            ? Icons.warning
                            : _selectedAnalysis == 'trend'
                                ? Icons.trending_up
                                : Icons.tune),
                        const SizedBox(width: 8),
                        Text(
                          _selectedAnalysis == 'check'
                              ? 'Check Threshold'
                              : _selectedAnalysis == 'trend'
                                  ? 'Analyze Trend'
                                  : 'Optimize Threshold',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_alertResult.isNotEmpty && _selectedAnalysis == 'check') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alert Result:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getAlertColor(_alertResult),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _alertResult,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: _getTextColor(_alertResult),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAlertSummary(),
                    ],
                  ),
                ),
              ),
            ],

            // Trend Analysis Results
            if (_trendAnalysis.isNotEmpty && _selectedAnalysis == 'trend') ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Trend Analysis:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      ..._trendAnalysis.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 150,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatLabel(entry.key),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: const TextStyle(fontSize: 14),
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
            ],

            // Optimization Results
            if (_optimizationResult.isNotEmpty &&
                _selectedAnalysis == 'optimization') ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Threshold Optimization:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      ..._optimizationResult.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 150,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatLabel(entry.key),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value.toString(),
                                  style: const TextStyle(fontSize: 14),
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
            ],

            const SizedBox(height: 20),

            // Alert Severity Guide
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alert Severity Guide:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        _buildSeverityItem(
                            'CRITICAL', '>200% of threshold', Colors.red),
                        _buildSeverityItem(
                            'HIGH', '150-200% of threshold', Colors.orange),
                        _buildSeverityItem(
                            'MEDIUM', '120-150% of threshold', Colors.yellow),
                        _buildSeverityItem(
                            'LOW', '100-120% of threshold', Colors.green),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Actions are recommended based on severity level and breach percentage.',
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisChip(String label, IconData icon) {
    String key = label.toLowerCase().split(' ')[0];
    bool selected = _selectedAnalysis == key;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (selected) {
        setState(() {
          _selectedAnalysis = key;
          _alertResult = '';
          _trendAnalysis = {};
          _optimizationResult = {};
        });
      },
    );
  }

  Widget _buildExampleChip(
      String label, String value, String threshold, String context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _valueController.text = value;
          _thresholdController.text = threshold;
          _contextController.text = context;
        });
      },
    );
  }

  Widget _buildHistoricalExampleChip(String label, String data) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _historicalDataController.text = data;
        });
      },
    );
  }

  Widget _buildAlertSummary() {
    double value = double.tryParse(_valueController.text) ?? 0;
    double threshold = double.tryParse(_thresholdController.text) ?? 0;
    double percentage = threshold > 0 ? (value / threshold * 100) : 0;
    String severity = _determineSeverity(percentage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Value: $value'),
        Text('Threshold: $threshold'),
        Text('Percentage: ${percentage.toStringAsFixed(1)}%'),
        Text('Severity: $severity'),
        Text('Breach Amount: ${(value - threshold).toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildSeverityItem(String label, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _determineSeverity(double percentage) {
    if (percentage > 200) return 'CRITICAL';
    if (percentage > 150) return 'HIGH';
    if (percentage > 120) return 'MEDIUM';
    return 'LOW';
  }

  Color _getAlertColor(String alert) {
    if (alert.contains('CRITICAL')) return const Color(0xFFFFCDD2);
    if (alert.contains('HIGH')) return Colors.orange.shade100;
    if (alert.contains('MEDIUM')) return Colors.yellow.shade100;
    return const Color(0xFFC8E6C9);
  }

  Color _getTextColor(String alert) {
    if (alert.contains('CRITICAL')) return const Color(0xFFB71C1C);
    if (alert.contains('HIGH')) return Colors.orange.shade900;
    if (alert.contains('MEDIUM')) return Colors.yellow.shade900;
    return const Color(0xFF1B5E20);
  }

  String _formatLabel(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        )
        .replaceFirstMapped(
            RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase());
  }

  Future<void> _runAnalysis() async {
    setState(() {
      _loading = true;
      _alertResult = '';
      _trendAnalysis = {};
      _optimizationResult = {};
    });

    try {
      if (_selectedAnalysis == 'check') {
        double value = double.tryParse(_valueController.text) ?? 0;
        double threshold = double.tryParse(_thresholdController.text) ?? 0;
        String? context =
            _contextController.text.isNotEmpty ? _contextController.text : null;

        final result = await AIExecutor.runTool(
          toolName: 'Threshold Alert',
          module: 'Monitoring AI',
          input: {
            'value': value,
            'threshold': threshold,
            'context': context,
          },
        );

        setState(() {
          _alertResult = result.toString();
          _loading = false;
        });
      } else if (_selectedAnalysis == 'trend') {
        List<double> historicalData = _historicalDataController.text
            .split(',')
            .map((item) => double.tryParse(item.trim()) ?? 0)
            .toList();
        double threshold = double.tryParse(_thresholdController.text) ?? 0;

        final result = await AIExecutor.runTool(
          toolName: 'Threshold Trend Analysis',
          module: 'Monitoring AI',
          input: {
            'historicalData': historicalData,
            'threshold': threshold,
          },
        );

        setState(() {
          _trendAnalysis = result as Map<String, dynamic>;
          _loading = false;
        });
      } else if (_selectedAnalysis == 'optimization') {
        List<double> historicalData = _historicalDataController.text
            .split(',')
            .map((item) => double.tryParse(item.trim()) ?? 0)
            .toList();
        double targetCoverage = 0.95; // 95% coverage

        final result = await AIExecutor.runTool(
          toolName: 'Threshold Optimization',
          module: 'Monitoring AI',
          input: {
            'historicalData': historicalData,
            'targetCoverage': targetCoverage,
          },
        );

        setState(() {
          _optimizationResult = result as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _alertResult = 'Error in analysis: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    _thresholdController.dispose();
    _contextController.dispose();
    _historicalDataController.dispose();
    super.dispose();
  }
}

