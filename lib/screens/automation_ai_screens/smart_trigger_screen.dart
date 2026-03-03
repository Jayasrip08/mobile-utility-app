import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class SmartTriggerScreen extends StatefulWidget {
  const SmartTriggerScreen({super.key});

  @override
  State<SmartTriggerScreen> createState() => _SmartTriggerScreenState();
}

class _SmartTriggerScreenState extends State<SmartTriggerScreen> {
  final TextEditingController _countController =
      TextEditingController(text: '12');
  final Map<String, TextEditingController> _conditionControllers = {
    'condition1': TextEditingController(text: 'true'),
    'condition2': TextEditingController(text: 'false'),
    'condition3': TextEditingController(text: 'true'),
    'value1': TextEditingController(text: '45'),
    'value2': TextEditingController(text: 'Completed'),
  };
  final TextEditingController _patternController =
      TextEditingController(text: '10, 20, 30, 40, 50');
  final TextEditingController _textController =
      TextEditingController(text: 'System alert: Warning detected');

  bool _triggerResult = false;
  bool _loading = false;
  String _selectedInputType = 'count';
  String _sensitivityLevel = 'Medium';
  List<Map<String, dynamic>> _triggerHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Trigger System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pattern-Based Trigger Detection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Detect triggers based on patterns, conditions, and thresholds',
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
                      'Trigger Type:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildInputTypeChip('Count', Icons.timeline),
                        _buildInputTypeChip('Conditions', Icons.check_box),
                        _buildInputTypeChip('Pattern', Icons.show_chart),
                        _buildInputTypeChip('Text', Icons.text_fields),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sensitivity Slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensitivity Level:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _getSensitivityValue(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: _sensitivityLevel,
                      onChanged: (value) {
                        setState(() {
                          _sensitivityLevel = _getSensitivityLabel(value);
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Low'),
                        Text('Medium'),
                        Text('High'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Count Input
            if (_selectedInputType == 'count') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Count-Based Trigger',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Trigger based on count threshold'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _countController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Enter count value',
                          border: OutlineInputBorder(),
                          hintText: 'Enter numerical count',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildCountExampleChip('Low (5)', '5'),
                          _buildCountExampleChip('Medium (15)', '15'),
                          _buildCountExampleChip('High (25)', '25'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Conditions Input
            if (_selectedInputType == 'conditions') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Multi-Condition Trigger',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Trigger based on multiple conditions'),
                      const SizedBox(height: 16),

                      // Conditions Input Fields
                      Column(
                        children: _conditionControllers.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
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
                                          'Enter value for ${_formatLabel(entry.key)}',
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

            // Pattern Input
            if (_selectedInputType == 'pattern') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pattern-Based Trigger',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Detect patterns in numerical data'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _patternController,
                        decoration: const InputDecoration(
                          labelText: 'Pattern values (comma separated)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., 10, 20, 30, 40, 50',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildPatternExampleChip(
                              'Increasing', '10, 20, 30, 40, 50'),
                          _buildPatternExampleChip(
                              'Decreasing', '50, 40, 30, 20, 10'),
                          _buildPatternExampleChip(
                              'Spike', '10, 15, 12, 45, 18'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Text Input
            if (_selectedInputType == 'text') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Text-Based Trigger',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Detect triggers in text content'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _textController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Enter text to analyze',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., System alert: Warning detected',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTextExampleChip('Emergency',
                              'Emergency: System failure detected!'),
                          _buildTextExampleChip('Warning',
                              'Warning: Temperature above threshold'),
                          _buildTextExampleChip(
                              'Normal', 'System operating normally'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Check Trigger Button
            ElevatedButton(
              onPressed: _loading ? null : _checkTrigger,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.purple,
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on),
                        SizedBox(width: 8),
                        Text(
                          'Check Trigger',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trigger Status:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _triggerResult
                            ? const Color(0xFFFFCDD2)
                            : const Color(0xFFC8E6C9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _triggerResult ? Icons.warning : Icons.check_circle,
                            color: _triggerResult ? Colors.red : Colors.green,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _triggerResult
                                      ? 'TRIGGER ACTIVATED'
                                      : 'NO TRIGGER',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _triggerResult
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _triggerResult
                                      ? 'Action required'
                                      : 'No action needed',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Analysis Details:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    _buildAnalysisDetails(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Add to History Button
            if (_triggerHistory.length < 20)
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _triggerHistory.insert(0, {
                      'type': _selectedInputType,
                      'result': _triggerResult,
                      'sensitivity': _sensitivityLevel,
                      'timestamp': DateTime.now(),
                    });
                  });
                },
                child: const Text('Save to Trigger History'),
              ),

            const SizedBox(height: 20),

            // Trigger History
            if (_triggerHistory.isNotEmpty) ...[
              const Text(
                'Trigger History:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ..._triggerHistory.map((trigger) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      trigger['result'] ? Icons.warning : Icons.check_circle,
                      color: trigger['result'] ? Colors.red : Colors.green,
                    ),
                    title: Text(
                        '${trigger['type']?.toString().toUpperCase()} Trigger'),
                    subtitle: Text('Sensitivity: ${trigger['sensitivity']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _triggerHistory.remove(trigger);
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 20),

            // Trigger Patterns Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Patterns:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Increasing Pattern: Values consistently increasing\n'
                      '• Decreasing Pattern: Values consistently decreasing\n'
                      '• Spike Pattern: Sudden high value after normal values\n'
                      '• Threshold Crossing: Value exceeds predefined limit\n\n'
                      '• Emergency Words: emergency, urgent, critical, help\n'
                      '• Warning Words: warning, caution, problem, error\n'
                      '• Multi-condition: 60%+ conditions must be true',
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
        });
      },
    );
  }

  Widget _buildCountExampleChip(String label, String value) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _countController.text = value;
        });
      },
    );
  }

  Widget _buildPatternExampleChip(String label, String pattern) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _patternController.text = pattern;
        });
      },
    );
  }

  Widget _buildTextExampleChip(String label, String text) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _textController.text = text;
        });
      },
    );
  }

  Widget _buildAnalysisDetails() {
    String inputDescription = '';
    String criteria = '';

    if (_selectedInputType == 'count') {
      inputDescription = 'Count-based analysis';
      criteria = 'Threshold varies by time of day';
    } else if (_selectedInputType == 'conditions') {
      inputDescription = 'Multi-condition analysis';
      criteria = '60%+ conditions must be true';
    } else if (_selectedInputType == 'pattern') {
      inputDescription = 'Pattern recognition';
      criteria = 'Detects trends, spikes, and thresholds';
    } else if (_selectedInputType == 'text') {
      inputDescription = 'Text analysis';
      criteria = 'Keyword and pattern detection';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analysis Type: $inputDescription'),
        Text('Sensitivity: $_sensitivityLevel'),
        Text('Criteria: $criteria'),
        Text('Time: ${DateTime.now().toLocal()}'),
      ],
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

  double _getSensitivityValue() {
    switch (_sensitivityLevel) {
      case 'Low':
        return 3;
      case 'High':
        return 8;
      default:
        return 5;
    }
  }

  String _getSensitivityLabel(double value) {
    if (value <= 3) return 'Low';
    if (value >= 8) return 'High';
    return 'Medium';
  }

  Future<void> _checkTrigger() async {
    setState(() {
      _loading = true;
    });

    try {
      dynamic input;

      if (_selectedInputType == 'count') {
        input = int.tryParse(_countController.text) ?? 0;
      } else if (_selectedInputType == 'conditions') {
        Map<String, dynamic> conditions = {};
        for (var entry in _conditionControllers.entries) {
          var value = entry.value.text;
          if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
            conditions[entry.key] = value.toLowerCase() == 'true';
          } else if (double.tryParse(value) != null) {
            conditions[entry.key] = double.parse(value);
          } else {
            conditions[entry.key] = value;
          }
        }
        input = conditions;
      } else if (_selectedInputType == 'pattern') {
        input = _patternController.text
            .split(',')
            .map((item) => int.tryParse(item.trim()) ?? 0)
            .toList();
      } else if (_selectedInputType == 'text') {
        input = _textController.text;
      }

      final result = await AIExecutor.runTool(
        toolName: 'Smart Trigger',
        module: 'Automation AI',
        input: input,
      );

      setState(() {
        _triggerResult = result == true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _triggerResult = false;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking trigger: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _countController.dispose();
    _patternController.dispose();
    _textController.dispose();
    for (var controller in _conditionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
