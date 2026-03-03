import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class DecisionTreeScreen extends StatefulWidget {
  const DecisionTreeScreen({super.key});

  @override
  State<DecisionTreeScreen> createState() => _DecisionTreeScreenState();
}

class _DecisionTreeScreenState extends State<DecisionTreeScreen> {
  final TextEditingController _scoreController =
      TextEditingController(text: '75');
  final Map<String, TextEditingController> _criteriaControllers = {
    'creditScore': TextEditingController(text: '700'),
    'income': TextEditingController(text: '75000'),
    'employmentStatus': TextEditingController(text: 'Full-time'),
    'debtRatio': TextEditingController(text: '0.3'),
    'experience': TextEditingController(text: '5'),
    'collateral': TextEditingController(text: 'true'),
  };
  final TextEditingController _categoryController =
      TextEditingController(text: 'high priority');

  String _result = '';
  bool _loading = false;
  String _selectedInputType = 'score';
  List<Map<String, dynamic>> _decisionHistory = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decision Tree Engine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Intelligent Decision Making',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make decisions based on rules, scores, and multi-criteria analysis',
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
                      'Decision Type:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildInputTypeChip('Score', Icons.score),
                        _buildInputTypeChip('Criteria', Icons.checklist),
                        _buildInputTypeChip('Category', Icons.category),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Score Input
            if (_selectedInputType == 'score') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score-Based Decision',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Make decision based on numerical score'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _scoreController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Enter score (0-100)',
                          border: OutlineInputBorder(),
                          hintText: 'Enter score between 0 and 100',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildExampleChip('Score: 95', '95'),
                          _buildExampleChip('Score: 65', '65'),
                          _buildExampleChip('Score: 35', '35'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Criteria Input
            if (_selectedInputType == 'criteria') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Multi-Criteria Decision',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Evaluate based on multiple factors'),
                      const SizedBox(height: 16),

                      // Criteria Input Fields
                      Column(
                        children: _criteriaControllers.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 140,
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
                                          'Enter ${_formatLabel(entry.key)}',
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

            // Category Input
            if (_selectedInputType == 'category') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category-Based Decision',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Decision based on priority or category'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Enter category/priority',
                          border: OutlineInputBorder(),
                          hintText:
                              'e.g., urgent, high, medium, low, informational',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildExampleChip('Urgent', 'urgent'),
                          _buildExampleChip('High Priority', 'high'),
                          _buildExampleChip('Medium Priority', 'medium'),
                          _buildExampleChip('Informational', 'informational'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Evaluate Decision Button
            ElevatedButton(
              onPressed: _loading ? null : _evaluateDecision,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_tree),
                        SizedBox(width: 8),
                        Text(
                          'Evaluate Decision',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Decision Result:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _result,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
              ),

              // Decision Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Decision Summary:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      _buildDecisionSummary(_result),
                    ],
                  ),
                ),
              ),

              // Save to History Button
              if (_decisionHistory.length < 10)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _decisionHistory.insert(0, {
                        'type': _selectedInputType,
                        'input': _getCurrentInput(),
                        'result': _result,
                        'timestamp': DateTime.now(),
                      });
                    });
                  },
                  child: const Text('Save to Decision History'),
                ),
            ],

            const SizedBox(height: 20),

            // Decision History
            if (_decisionHistory.isNotEmpty) ...[
              const Text(
                'Decision History:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ..._decisionHistory.map((decision) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                        '${decision['type']?.toString().toUpperCase()} Decision'),
                    subtitle: Text(decision['timestamp']?.toString() ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _decisionHistory.remove(decision);
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _result = decision['result'].toString();
                      });
                    },
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 20),

            // Decision Tree Rules
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Decision Rules:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Score ≥ 90: APPROVE WITH HIGHEST PRIORITY\n'
                      '• 75 ≤ Score < 90: APPROVE WITH STANDARD PROCESSING\n'
                      '• 60 ≤ Score < 75: REVIEW WITH ADDITIONAL CHECKS\n'
                      '• 40 ≤ Score < 60: REJECT WITH OPTION TO APPEAL\n'
                      '• Score < 40: REJECT IMMEDIATELY',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Multi-criteria decisions use weighted scoring with thresholds.',
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

  Widget _buildExampleChip(String label, String value) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          if (_selectedInputType == 'score') {
            _scoreController.text = value;
          } else if (_selectedInputType == 'category') {
            _categoryController.text = value;
          }
        });
      },
    );
  }

  Widget _buildDecisionSummary(String result) {
    String decisionType = 'Unknown';
    String color = 'Blue';

    if (result.contains('APPROVE')) {
      decisionType = 'Approval';
      color = 'Green';
    } else if (result.contains('REVIEW')) {
      decisionType = 'Review';
      color = 'Yellow';
    } else if (result.contains('REJECT')) {
      decisionType = 'Rejection';
      color = 'Red';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Decision Type: $decisionType'),
        Text('Status Color: $color'),
        Text('Action Required: ${_determineAction(result)}'),
        Text('Priority: ${_determinePriority(result)}'),
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

  String _determineAction(String result) {
    if (result.contains('IMMEDIATE')) return 'Immediate Action';
    if (result.contains('PRIORITY')) return 'Priority Processing';
    if (result.contains('STANDARD')) return 'Standard Processing';
    if (result.contains('BACKGROUND')) return 'Background Processing';
    return 'Documentation';
  }

  String _determinePriority(String result) {
    if (result.contains('HIGHEST')) return 'Highest';
    if (result.contains('HIGH')) return 'High';
    if (result.contains('STANDARD')) return 'Medium';
    return 'Low';
  }

  dynamic _getCurrentInput() {
    if (_selectedInputType == 'score') {
      return int.tryParse(_scoreController.text) ?? 0;
    } else if (_selectedInputType == 'criteria') {
      Map<String, dynamic> criteria = {};
      for (var entry in _criteriaControllers.entries) {
        var value = entry.value.text;
        if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
          criteria[entry.key] = value.toLowerCase() == 'true';
        } else if (double.tryParse(value) != null) {
          criteria[entry.key] = double.parse(value);
        } else if (int.tryParse(value) != null) {
          criteria[entry.key] = int.parse(value);
        } else {
          criteria[entry.key] = value;
        }
      }
      return criteria;
    } else if (_selectedInputType == 'category') {
      return _categoryController.text;
    }
    return null;
  }

  Future<void> _evaluateDecision() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      dynamic input = _getCurrentInput();

      final result = await AIExecutor.runTool(
        toolName: 'Decision Tree',
        module: 'Automation AI',
        input: input,
      );

      setState(() {
        _result = result.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error evaluating decision: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _categoryController.dispose();
    for (var controller in _criteriaControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
