import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class PriorityAnalyzerScreen extends StatefulWidget {
  const PriorityAnalyzerScreen({super.key});

  @override
  State<PriorityAnalyzerScreen> createState() => _PriorityAnalyzerScreenState();
}

class _PriorityAnalyzerScreenState extends State<PriorityAnalyzerScreen> {
  final List<Map<String, dynamic>> _tasks = [
    {
      'name': 'Task 1',
      'urgency': 5,
      'importance': 5,
      'effort': 5,
      'daysLeft': 7,
      'dependencies': false,
    },
  ];

  final TextEditingController _taskNameController = TextEditingController();
  String _result = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Priority Analyzer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Task Priority Analyzer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Add and analyze tasks based on multiple factors:'),
            const SizedBox(height: 20),

            // Add Task Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _taskNameController,
                      decoration: const InputDecoration(
                        labelText: 'Task Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSliderInput('Urgency', 'urgency', 5),
                        const SizedBox(width: 12),
                        _buildSliderInput('Importance', 'importance', 5),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSliderInput('Effort', 'effort', 5),
                        const SizedBox(width: 12),
                        _buildDaysInput(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _tasks.isNotEmpty
                              ? _tasks.last['dependencies']
                              : false,
                          onChanged: (value) {
                            if (_tasks.isNotEmpty) {
                              setState(() {
                                _tasks.last['dependencies'] = value;
                              });
                            }
                          },
                        ),
                        const Text('Has Dependencies'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _addTask,
                      child: const Text('Add Task'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Task List
            if (_tasks.isNotEmpty) ...[
              const Text(
                'Tasks to Analyze:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ..._tasks.asMap().entries.map((entry) {
                final index = entry.key;
                final task = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(task['name']),
                    subtitle: Text(
                      'Urgency: ${task['urgency']}/10, Importance: ${task['importance']}/10\n'
                      'Effort: ${task['effort']}/10, Days Left: ${task['daysLeft']}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeTask(index),
                    ),
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 24),

            // Analyze Button
            ElevatedButton(
              onPressed: _tasks.isEmpty || _loading ? null : _analyzePriorities,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Analyze Priorities',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Priority Analysis:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliderInput(String label, String field, int initialValue) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '$label: ${_tasks.isNotEmpty ? _tasks.last[field] : initialValue}/10'),
          Slider(
            value: _tasks.isNotEmpty
                ? _tasks.last[field].toDouble()
                : initialValue.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) {
              if (_tasks.isNotEmpty) {
                setState(() {
                  _tasks.last[field] = value.toInt();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDaysInput() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Days Left:'),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            initialValue: _tasks.isNotEmpty ? _tasks.last['daysLeft'] : 7,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [1, 2, 3, 5, 7, 10, 14, 30].map((days) {
              return DropdownMenuItem(
                value: days,
                child: Text('$days days'),
              );
            }).toList(),
            onChanged: (value) {
              if (_tasks.isNotEmpty) {
                setState(() {
                  _tasks.last['daysLeft'] = value!;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _addTask() {
    final name = _taskNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name')),
      );
      return;
    }

    setState(() {
      _tasks.add({
        'name': name,
        'urgency': 5,
        'importance': 5,
        'effort': 5,
        'daysLeft': 7,
        'dependencies': false,
      });
      _taskNameController.clear();
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  Future<void> _analyzePriorities() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Priority Analyzer',
        module: 'Logic & Decision AI',
        input: _tasks,
      );

      setState(() {
        _result = result.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }
}
