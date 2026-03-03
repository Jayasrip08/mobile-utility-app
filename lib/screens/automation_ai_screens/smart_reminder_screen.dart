import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class SmartReminderScreen extends StatefulWidget {
  const SmartReminderScreen({super.key});

  @override
  State<SmartReminderScreen> createState() => _SmartReminderScreenState();
}

class _SmartReminderScreenState extends State<SmartReminderScreen> {
  final TextEditingController _daysController =
      TextEditingController(text: '5');
  final Map<String, TextEditingController> _taskControllers = {
    'name': TextEditingController(text: 'Quarterly Report'),
    'dueDate': TextEditingController(text: '2024-12-31'),
    'priority': TextEditingController(text: 'high'),
  };
  final TextEditingController _tasksController =
      TextEditingController(text: 'Project Review,Team Meeting,Client Call');

  String _result = '';
  bool _loading = false;
  String _selectedInputType = 'days';
  List<Map<String, dynamic>> _scheduledReminders = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Reminder Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Intelligent Reminder System',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate smart reminders based on inactivity, tasks, and schedules',
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
                      'Reminder Type:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildInputTypeChip('Days', Icons.calendar_today),
                        _buildInputTypeChip('Task', Icons.task),
                        _buildInputTypeChip('Multiple', Icons.list),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Days Input
            if (_selectedInputType == 'days') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inactivity Reminder',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                          'Generate reminder based on days of inactivity'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _daysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Days inactive',
                          border: OutlineInputBorder(),
                          hintText: 'Enter number of days since last activity',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildDaysExampleChip('1 day', '1'),
                          _buildDaysExampleChip('3 days', '3'),
                          _buildDaysExampleChip('10 days', '10'),
                          _buildDaysExampleChip('15 days', '15'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Task Input
            if (_selectedInputType == 'task') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Task Reminder',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Generate reminder for specific task'),
                      const SizedBox(height: 16),

                      // Task Input Fields
                      Column(
                        children: _taskControllers.entries.map((entry) {
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

            // Multiple Tasks Input
            if (_selectedInputType == 'multiple') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Multiple Tasks',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Generate reminders for multiple tasks'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _tasksController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Task names (comma separated)',
                          border: OutlineInputBorder(),
                          hintText:
                              'e.g., Project Review, Team Meeting, Client Call',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTasksExampleChip('Report, Meeting, Review'),
                          _buildTasksExampleChip(
                              'Deadline, Follow-up, Check-in'),
                          _buildTasksExampleChip('Email, Call, Documentation'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Generate Reminder Button
            ElevatedButton(
              onPressed: _loading ? null : _generateReminder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_active),
                        SizedBox(width: 8),
                        Text(
                          'Generate Reminder',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Reminder Details:',
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

              // Reminder Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reminder Summary:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      _buildReminderSummary(_result),
                    ],
                  ),
                ),
              ),

              // Schedule Reminder Button
              ElevatedButton(
                onPressed: () {
                  _scheduleReminder();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Schedule This Reminder'),
              ),
            ],

            const SizedBox(height: 20),

            // Scheduled Reminders
            if (_scheduledReminders.isNotEmpty) ...[
              const Text(
                'Scheduled Reminders:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ..._scheduledReminders.map((reminder) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: _getUrgencyColor(reminder['urgency'] ?? ''),
                    ),
                    title: Text(reminder['title'] ?? 'Reminder'),
                    subtitle:
                        Text('${reminder['urgency']} - ${reminder['time']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _scheduledReminders.remove(reminder);
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ],

            const SizedBox(height: 20),

            // Reminder Rules
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reminder Rules:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 1-3 days: Gentle reminder\n'
                      '• 4-7 days: Regular reminder\n'
                      '• 8-14 days: Important reminder\n'
                      '• 15+ days: Critical reminder\n\n'
                      '• Critical: Multiple reminders, immediate action\n'
                      '• High: Regular reminders, priority action\n'
                      '• Medium: Scheduled reminders, standard action\n'
                      '• Low: Background reminders, optional action',
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

  Widget _buildDaysExampleChip(String label, String value) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _daysController.text = value;
        });
      },
    );
  }

  Widget _buildTasksExampleChip(String tasks) {
    return ActionChip(
      label: Text(tasks),
      onPressed: () {
        setState(() {
          _tasksController.text = tasks;
        });
      },
    );
  }

  Widget _buildReminderSummary(String result) {
    String urgency = _extractUrgency(result);
    String type = _selectedInputType == 'days' ? 'Inactivity' : 'Task';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reminder Type: $type'),
        Text('Urgency Level: $urgency'),
        Text('Action Required: ${_determineAction(urgency)}'),
        Text('Timeline: ${_determineTimeline(urgency)}'),
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

  String _extractUrgency(String result) {
    if (result.contains('Critical')) return 'Critical';
    if (result.contains('Important')) return 'High';
    if (result.contains('Regular')) return 'Medium';
    if (result.contains('Gentle')) return 'Low';
    return 'Standard';
  }

  String _determineAction(String urgency) {
    switch (urgency) {
      case 'Critical':
        return 'Immediate Action';
      case 'High':
        return 'Priority Action';
      case 'Medium':
        return 'Standard Action';
      case 'Low':
        return 'Optional Action';
      default:
        return 'Monitor';
    }
  }

  String _determineTimeline(String urgency) {
    switch (urgency) {
      case 'Critical':
        return 'Immediate - 1 hour';
      case 'High':
        return 'Today';
      case 'Medium':
        return 'This week';
      case 'Low':
        return 'When convenient';
      default:
        return 'Flexible';
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _generateReminder() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      dynamic input;

      if (_selectedInputType == 'days') {
        input = int.tryParse(_daysController.text) ?? 0;
      } else if (_selectedInputType == 'task') {
        Map<String, dynamic> taskData = {};
        for (var entry in _taskControllers.entries) {
          if (entry.key == 'dueDate') {
            taskData[entry.key] = entry.value.text;
          } else if (entry.key == 'priority') {
            taskData[entry.key] = entry.value.text.toLowerCase();
          } else {
            taskData[entry.key] = entry.value.text;
          }
        }
        input = taskData;
      } else if (_selectedInputType == 'multiple') {
        input = _tasksController.text
            .split(',')
            .map((item) => item.trim())
            .toList();
      }

      final result = await AIExecutor.runTool(
        toolName: 'Smart Reminder',
        module: 'Automation AI',
        input: input,
      );

      setState(() {
        _result = result.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error generating reminder: $e';
        _loading = false;
      });
    }
  }

  void _scheduleReminder() {
    String urgency = _extractUrgency(_result);
    String title = '';

    if (_selectedInputType == 'days') {
      title = 'Follow-up after ${_daysController.text} days';
    } else if (_selectedInputType == 'task') {
      title = _taskControllers['name']?.text ?? 'Task Reminder';
    } else {
      title = 'Multiple Tasks Reminder';
    }

    setState(() {
      _scheduledReminders.add({
        'title': title,
        'urgency': urgency,
        'time': DateTime.now().add(const Duration(hours: 1)).toString(),
        'details': _result,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder scheduled successfully')),
    );
  }

  @override
  void dispose() {
    _daysController.dispose();
    _tasksController.dispose();
    for (var controller in _taskControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
