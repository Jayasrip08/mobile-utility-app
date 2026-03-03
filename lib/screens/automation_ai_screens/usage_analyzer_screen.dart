import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class UsageAnalyzerScreen extends StatefulWidget {
  const UsageAnalyzerScreen({super.key});

  @override
  State<UsageAnalyzerScreen> createState() => _UsageAnalyzerScreenState();
}

class _UsageAnalyzerScreenState extends State<UsageAnalyzerScreen> {
  final TextEditingController _numericDataController =
      TextEditingController(text: '70, 72, 75, 78, 80, 82, 85, 78, 76, 74');
  final Map<String, TextEditingController> _behaviorControllers = {
    'timePatterns':
        TextEditingController(text: 'Morning:5,Afternoon:8,Evening:12,Night:3'),
    'frequency': TextEditingController(text: '15'),
    'duration': TextEditingController(text: '45'),
    'features': TextEditingController(
        text: 'Dashboard:8,Reports:5,Analytics:12,Settings:2'),
  };
  final TextEditingController _logsController = TextEditingController(
      text:
          'timestamp:2024-01-01 09:00,action:login,metric1:10|timestamp:2024-01-01 12:00,action:report,metric1:25');

  String _analysisResult = '';
  bool _loading = false;
  String _selectedInputType = 'numeric';
  Map<String, dynamic> _predictionResult = {};
  List<Map<String, dynamic>> _analysisHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usage Pattern Analyzer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Usage Pattern Analysis System',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Analyze usage patterns, behaviors, and predict future trends',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Input Type Selection
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
                        _buildInputTypeChip('Numeric', Icons.numbers),
                        _buildInputTypeChip('Behavior', Icons.person),
                        _buildInputTypeChip('Logs', Icons.analytics),
                        _buildInputTypeChip('Predict', Icons.timeline),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Numeric Data Input
            if (_selectedInputType == 'numeric') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Numeric Pattern Analysis',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Analyze numeric usage patterns over time'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _numericDataController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Numeric values (comma separated)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 70, 72, 75, 78, 80, 82, 85',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildNumericExampleChip(
                              'Increasing', '60, 65, 70, 75, 80'),
                          _buildNumericExampleChip(
                              'Decreasing', '80, 75, 70, 65, 60'),
                          _buildNumericExampleChip(
                              'Spike', '70, 72, 75, 85, 74'),
                          _buildNumericExampleChip(
                              'Stable', '75, 74, 76, 75, 74'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Behavior Input
            if (_selectedInputType == 'behavior') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Behavior Pattern Analysis',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Analyze user behavior patterns'),
                      const SizedBox(height: 16),

                      // Behavior Input Fields
                      Column(
                        children: _behaviorControllers.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 120,
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
                                  child: TextField(
                                    controller: entry.value,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      hintText:
                                          'Enter ${_formatLabel(entry.key)} data',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Logs Input
            if (_selectedInputType == 'logs') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Log Analysis',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Analyze complex log data'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _logsController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Log entries (pipe separated)',
                          border: OutlineInputBorder(),
                          hintText:
                              'timestamp:2024-01-01 09:00,action:login,metric1:10|timestamp:2024-01-01 12:00,action:report,metric1:25',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Format: key:value pairs separated by commas, entries separated by |',
                        style: TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Prediction Input (uses numeric data)
            if (_selectedInputType == 'predict') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Usage Prediction',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                          'Predict future usage based on historical data'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _numericDataController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Historical values (comma separated)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 70, 72, 75, 78, 80, 82, 85',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Number of future periods to predict:',
                        style: TextStyle(fontSize: 14),
                      ),
                      Slider(
                        value: 5,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '5 periods',
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Analyze Button
            ElevatedButton(
              onPressed: _loading ? null : _analyzeUsage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_selectedInputType == 'predict'
                            ? Icons.timeline
                            : Icons.analytics),
                        const SizedBox(width: 8),
                        Text(
                          _selectedInputType == 'predict'
                              ? 'Predict Usage'
                              : 'Analyze Patterns',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_analysisResult.isNotEmpty &&
                _selectedInputType != 'predict') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analysis Results:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Text(
                          _analysisResult,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Prediction Results
            if (_predictionResult.isNotEmpty &&
                _selectedInputType == 'predict') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prediction Results:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Predicted Value: ${_predictionResult['prediction'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Confidence: ${_predictionResult['confidence'] ?? '0'}%',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._predictionResult.entries.map((entry) {
                        if (entry.key == 'prediction' ||
                            entry.key == 'confidence') {
                          return const SizedBox();
                        }
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

            // Save to History Button
            if (_analysisResult.isNotEmpty || _predictionResult.isNotEmpty)
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _analysisHistory.insert(0, {
                      'type': _selectedInputType,
                      'result': _selectedInputType == 'predict'
                          ? _predictionResult
                          : _analysisResult,
                      'timestamp': DateTime.now(),
                    });
                  });
                },
                child: const Text('Save to Analysis History'),
              ),

            const SizedBox(height: 20),

            // Analysis History
            if (_analysisHistory.isNotEmpty) ...[
              const Text(
                'Analysis History:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ..._analysisHistory.map((analysis) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.analytics),
                    title: Text(
                        '${analysis['type']?.toString().toUpperCase()} Analysis'),
                    subtitle: Text(analysis['timestamp']?.toString() ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _analysisHistory.remove(analysis);
                        });
                      },
                    ),
                    onTap: () {
                      if (analysis['type'] == 'predict') {
                        setState(() {
                          _selectedInputType = 'predict';
                          _predictionResult =
                              analysis['result'] as Map<String, dynamic>;
                        });
                      } else {
                        setState(() {
                          _selectedInputType = analysis['type'] as String;
                          _analysisResult = analysis['result'].toString();
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 20),

            // Pattern Detection Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pattern Detection:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Increasing Trend: Values consistently increasing\n'
                      '• Decreasing Trend: Values consistently decreasing\n'
                      '• Cyclical Pattern: Regular up-down patterns\n'
                      '• Spike Pattern: Sudden high values\n'
                      '• Stable Pattern: Minimal variation\n\n'
                      '• High Usage: Average > 70%\n'
                      '• Moderate Usage: 30% < Average ≤ 70%\n'
                      '• Low Usage: Average ≤ 30%\n\n'
                      '• High Variability: Std Dev > 50% of mean\n'
                      '• Consistent Usage: Std Dev ≤ 50% of mean',
                      style: TextStyle(fontSize: 14, height: 1.5),
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

  Widget _buildInputTypeChip(String label, IconData icon) {
    bool selected = _selectedInputType == label.toLowerCase();
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
          _selectedInputType = label.toLowerCase();
          _analysisResult = '';
          _predictionResult = {};
        });
      },
    );
  }

  Widget _buildNumericExampleChip(String label, String data) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _numericDataController.text = data;
        });
      },
    );
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

  Future<void> _analyzeUsage() async {
    setState(() {
      _loading = true;
      _analysisResult = '';
      _predictionResult = {};
    });

    try {
      dynamic input;

      if (_selectedInputType == 'numeric') {
        List<num> numericData = _numericDataController.text
            .split(',')
            .map((item) => num.tryParse(item.trim()) ?? 0)
            .toList();
        input = numericData;
      } else if (_selectedInputType == 'behavior') {
        Map<String, dynamic> behaviorData = {};
        for (var entry in _behaviorControllers.entries) {
          if (entry.key == 'timePatterns' || entry.key == 'features') {
            // Parse key:value pairs
            Map<String, dynamic> parsed = {};
            var parts = entry.value.text.split(',');
            for (var part in parts) {
              var keyValue = part.split(':');
              if (keyValue.length == 2) {
                parsed[keyValue[0].trim()] =
                    int.tryParse(keyValue[1].trim()) ?? 0;
              }
            }
            behaviorData[entry.key] = parsed;
          } else if (entry.key == 'frequency' || entry.key == 'duration') {
            behaviorData[entry.key] = int.tryParse(entry.value.text) ?? 0;
          }
        }
        input = behaviorData;
      } else if (_selectedInputType == 'logs') {
        // Parse log entries
        List<Map<String, dynamic>> logs = [];
        var entries = _logsController.text.split('|');
        for (var entry in entries) {
          Map<String, dynamic> logEntry = {};
          var parts = entry.split(',');
          for (var part in parts) {
            var keyValue = part.split(':');
            if (keyValue.length == 2) {
              var value = keyValue[1].trim();
              if (int.tryParse(value) != null) {
                logEntry[keyValue[0].trim()] = int.parse(value);
              } else {
                logEntry[keyValue[0].trim()] = value;
              }
            }
          }
          if (logEntry.isNotEmpty) {
            logs.add(logEntry);
          }
        }
        input = logs;
      } else if (_selectedInputType == 'predict') {
        List<num> historicalData = _numericDataController.text
            .split(',')
            .map((item) => num.tryParse(item.trim()) ?? 0)
            .toList();
        input = {
          'historicalData': historicalData,
          'periods': 5,
        };
      }

      final result = await AIExecutor.runTool(
        toolName: _selectedInputType == 'predict'
            ? 'Usage Prediction'
            : 'Usage Analyzer',
        module: 'Analytics AI',
        input: input,
      );

      setState(() {
        if (_selectedInputType == 'predict') {
          _predictionResult = result as Map<String, dynamic>;
        } else {
          _analysisResult = result.toString();
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _analysisResult = 'Error in analysis: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _numericDataController.dispose();
    _logsController.dispose();
    for (var controller in _behaviorControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
