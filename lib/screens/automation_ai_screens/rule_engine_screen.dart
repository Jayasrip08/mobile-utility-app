import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class RuleEngineScreen extends StatefulWidget {
  const RuleEngineScreen({super.key});

  @override
  State<RuleEngineScreen> createState() => _RuleEngineScreenState();
}

class _RuleEngineScreenState extends State<RuleEngineScreen> {
  final Map<String, TextEditingController> _controllers = {
    'temperature': TextEditingController(text: '25'),
    'humidity': TextEditingController(text: '60'),
    'pressure': TextEditingController(text: '1013'),
    'windSpeed': TextEditingController(text: '15'),
  };

  String _result = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rule Engine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Rule-Based Decision Engine',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure rules and evaluate conditions using classical AI techniques',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Environmental Parameters',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    // Temperature
                    _buildParameterInput(
                      label: 'Temperature (°C)',
                      controller: _controllers['temperature']!,
                      icon: Icons.thermostat,
                      min: -50,
                      max: 100,
                    ),

                    const SizedBox(height: 12),

                    // Humidity
                    _buildParameterInput(
                      label: 'Humidity (%)',
                      controller: _controllers['humidity']!,
                      icon: Icons.water_drop,
                      min: 0,
                      max: 100,
                    ),

                    const SizedBox(height: 12),

                    // Pressure
                    _buildParameterInput(
                      label: 'Pressure (hPa)',
                      controller: _controllers['pressure']!,
                      icon: Icons.compress,
                      min: 800,
                      max: 1100,
                    ),

                    const SizedBox(height: 12),

                    // Wind Speed
                    _buildParameterInput(
                      label: 'Wind Speed (km/h)',
                      controller: _controllers['windSpeed']!,
                      icon: Icons.air,
                      min: 0,
                      max: 200,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Rule Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rule Configuration',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rules are evaluated using classical AI techniques:\n'
                      '• Temperature > 30°C: High alert\n'
                      '• Humidity > 80%: High alert\n'
                      '• Pressure < 1000 hPa: Low pressure system\n'
                      '• Wind Speed > 20 km/h: Strong winds',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Evaluate Button
            ElevatedButton(
              onPressed: _loading ? null : _evaluateRules,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology),
                        SizedBox(width: 8),
                        Text(
                          'Evaluate Rules',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Evaluation Results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getResultColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getResultIcon(),
                          color: _getIconColor(),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getResultTitle(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getTextColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: _getTextColor(),
                      ),
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
                      '• Rule-Based System: IF-THEN rules for decision making\n'
                      '• Expert System: Domain knowledge encoded in rules\n'
                      '• Heuristic Evaluation: Rule scoring and weighting\n'
                      '• Pattern Matching: Condition evaluation\n'
                      '• Decision Logic: Multi-factor analysis',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No machine learning models or neural networks used.',
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

  Widget _buildParameterInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required double min,
    required double max,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 4),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: label.contains('Temperature')
                      ? '°C'
                      : label.contains('Humidity')
                          ? '%'
                          : label.contains('Pressure')
                              ? 'hPa'
                              : 'km/h',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                double value = double.tryParse(controller.text) ?? min;
                value = (value + 1).clamp(min, max);
                controller.text = value.toStringAsFixed(1);
              },
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                double value = double.tryParse(controller.text) ?? min;
                value = (value - 1).clamp(min, max);
                controller.text = value.toStringAsFixed(1);
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _evaluateRules() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      // Prepare input data
      Map<String, dynamic> rules = {};
      for (var key in _controllers.keys) {
        double value = double.tryParse(_controllers[key]!.text) ?? 0;
        rules[key] = value;
      }

      final result = await AIExecutor.runTool(
        toolName: 'Rule Engine',
        module: 'Automation AI',
        input: rules,
      );

      setState(() {
        _result = result.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error evaluating rules: $e';
        _loading = false;
      });
    }
  }

  Color _getResultColor() {
    if (_result.contains('HIGH ALERT')) return const Color(0xFFFFEBEE);
    if (_result.contains('MEDIUM ALERT')) return Colors.orange.shade50;
    if (_result.contains('LOW ALERT')) return Colors.yellow.shade50;
    return const Color(0xFFE8F5E9);
  }

  Color _getBorderColor() {
    if (_result.contains('HIGH ALERT')) return Colors.red;
    if (_result.contains('MEDIUM ALERT')) return Colors.orange;
    if (_result.contains('LOW ALERT')) return Colors.yellow;
    return Colors.green;
  }

  Color _getIconColor() {
    if (_result.contains('HIGH ALERT')) return Colors.red;
    if (_result.contains('MEDIUM ALERT')) return Colors.orange;
    if (_result.contains('LOW ALERT')) return Colors.yellow.shade700;
    return Colors.green;
  }

  Color _getTextColor() {
    if (_result.contains('HIGH ALERT')) return const Color(0xFFB71C1C);
    if (_result.contains('MEDIUM ALERT')) return Colors.orange.shade900;
    if (_result.contains('LOW ALERT')) return Colors.yellow.shade900;
    return const Color(0xFF1B5E20);
  }

  IconData _getResultIcon() {
    if (_result.contains('HIGH ALERT')) return Icons.warning;
    if (_result.contains('MEDIUM ALERT')) return Icons.error_outline;
    if (_result.contains('LOW ALERT')) return Icons.info_outline;
    return Icons.check_circle;
  }

  String _getResultTitle() {
    if (_result.contains('HIGH ALERT')) return 'HIGH ALERT';
    if (_result.contains('MEDIUM ALERT')) return 'MEDIUM ALERT';
    if (_result.contains('LOW ALERT')) return 'LOW ALERT';
    return 'NORMAL CONDITIONS';
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
