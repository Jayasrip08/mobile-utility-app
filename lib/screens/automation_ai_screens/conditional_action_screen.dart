import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class ConditionalActionScreen extends StatefulWidget {
  const ConditionalActionScreen({super.key});

  @override
  State<ConditionalActionScreen> createState() =>
      _ConditionalActionScreenState();
}

class _ConditionalActionScreenState extends State<ConditionalActionScreen> {
  bool _booleanCondition = true;
  final Map<String, TextEditingController> _conditionControllers = {
    'temperature': TextEditingController(text: '22'),
    'humidity': TextEditingController(text: '50'),
    'presence': TextEditingController(text: 'true'),
    'lightLevel': TextEditingController(text: '500'),
  };
  final TextEditingController _commandController = TextEditingController();

  String _result = '';
  bool _loading = false;
  String _selectedActionType = 'boolean';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conditional Action Executor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Conditional Action Executor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Execute actions based on conditions using rule-based logic',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Action Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Action Type:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildActionTypeChip('Boolean', Icons.toggle_on),
                        _buildActionTypeChip('Environmental', Icons.thermostat),
                        _buildActionTypeChip('Command', Icons.terminal),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Boolean Action
            if (_selectedActionType == 'boolean') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Boolean Condition',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                          'Execute actions based on true/false condition'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Condition:'),
                          const SizedBox(width: 16),
                          Switch(
                            value: _booleanCondition,
                            onChanged: (value) {
                              setState(() {
                                _booleanCondition = value;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _booleanCondition ? 'TRUE' : 'FALSE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  _booleanCondition ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () =>
                                _executeAction('boolean', _booleanCondition),
                        child: const Text('Execute Boolean Action'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Environmental Action
            if (_selectedActionType == 'environmental') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Environmental Conditions',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                          'Execute actions based on multiple environmental factors'),
                      const SizedBox(height: 16),

                      // Temperature
                      _buildConditionInput(
                        label: 'Temperature (°C)',
                        controller: _conditionControllers['temperature']!,
                        icon: Icons.thermostat,
                      ),

                      const SizedBox(height: 12),

                      // Humidity
                      _buildConditionInput(
                        label: 'Humidity (%)',
                        controller: _conditionControllers['humidity']!,
                        icon: Icons.water_drop,
                      ),

                      const SizedBox(height: 12),

                      // Presence
                      _buildConditionInput(
                        label: 'Presence (true/false)',
                        controller: _conditionControllers['presence']!,
                        icon: Icons.person,
                      ),

                      const SizedBox(height: 12),

                      // Light Level
                      _buildConditionInput(
                        label: 'Light Level (lux)',
                        controller: _conditionControllers['lightLevel']!,
                        icon: Icons.lightbulb,
                      ),

                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () => _executeAction(
                                'environmental', _getEnvironmentalConditions()),
                        child: const Text('Execute Environmental Action'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Command Action
            if (_selectedActionType == 'command') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Command Execution',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                          'Execute predefined action sequences based on commands'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commandController,
                        decoration: const InputDecoration(
                          labelText: 'Enter command',
                          border: OutlineInputBorder(),
                          hintText:
                              'e.g., emergency, maintenance, optimize, monitor',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildCommandChip('emergency'),
                          _buildCommandChip('maintenance'),
                          _buildCommandChip('optimize'),
                          _buildCommandChip('monitor'),
                          _buildCommandChip('shutdown'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () => _executeAction(
                                'command', _commandController.text),
                        child: const Text('Execute Command'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Execute All Button
            ElevatedButton(
              onPressed: _loading ? null : _executeAllActions,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow),
                        SizedBox(width: 8),
                        Text(
                          'Execute All Selected Actions',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Action Execution Results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _result.contains('EMERGENCY')
                              ? Icons.warning
                              : Icons.check_circle,
                          color: _result.contains('EMERGENCY')
                              ? Colors.red
                              : Colors.green,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _result.contains('EMERGENCY')
                              ? 'EMERGENCY ACTIONS'
                              : 'ACTION EXECUTED',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _result.contains('EMERGENCY')
                                ? Colors.red
                                : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Classical AI Explanation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Classical AI Techniques Used:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Rule-Based Execution: IF-THEN action sequences\n'
                      '• Multi-factor Analysis: Environmental condition evaluation\n'
                      '• Command Pattern: Predefined action sequences\n'
                      '• Heuristic Scheduling: Optimal action timing\n'
                      '• Validation Logic: Action sequence verification',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Actions are executed based on evaluated conditions without machine learning.',
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

  Widget _buildActionTypeChip(String label, IconData icon) {
    bool selected = _selectedActionType == label.toLowerCase();
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
          _selectedActionType = label.toLowerCase();
        });
      },
    );
  }

  Widget _buildConditionInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommandChip(String command) {
    return ActionChip(
      label: Text(command),
      onPressed: () {
        _commandController.text = command;
      },
    );
  }

  Map<String, dynamic> _getEnvironmentalConditions() {
    return {
      'temperature':
          double.tryParse(_conditionControllers['temperature']!.text) ?? 22.0,
      'humidity':
          double.tryParse(_conditionControllers['humidity']!.text) ?? 50.0,
      'presence':
          _conditionControllers['presence']!.text.toLowerCase() == 'true',
      'lightLevel':
          double.tryParse(_conditionControllers['lightLevel']!.text) ?? 500.0,
      'time': DateTime.now(),
    };
  }

  Future<void> _executeAction(String type, dynamic input) async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Conditional Action Executor',
        module: 'Automation AI',
        input: input,
      );

      setState(() {
        _result = result.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error executing action: $e';
        _loading = false;
      });
    }
  }

  Future<void> _executeAllActions() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      List<String> results = [];

      // Execute boolean action
      if (_selectedActionType == 'boolean' || _selectedActionType == 'all') {
        var result = await AIExecutor.runTool(
          toolName: 'Conditional Action Executor',
          module: 'Automation AI',
          input: _booleanCondition,
        );
        results.add('Boolean: ${result.toString().substring(0, 50)}...');
      }

      // Execute environmental action
      if (_selectedActionType == 'environmental' ||
          _selectedActionType == 'all') {
        var result = await AIExecutor.runTool(
          toolName: 'Conditional Action Executor',
          module: 'Automation AI',
          input: _getEnvironmentalConditions(),
        );
        results.add('Environmental: ${result.toString().substring(0, 50)}...');
      }

      // Execute command action
      if (_selectedActionType == 'command' || _selectedActionType == 'all') {
        var result = await AIExecutor.runTool(
          toolName: 'Conditional Action Executor',
          module: 'Automation AI',
          input: _commandController.text.isEmpty
              ? 'status'
              : _commandController.text,
        );
        results.add('Command: ${result.toString().substring(0, 50)}...');
      }

      setState(() {
        _result = 'Multiple Actions Executed:\n\n${results.join('\n\n')}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error executing actions: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _commandController.dispose();
    for (var controller in _conditionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
