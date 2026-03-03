import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class RiskAnalysisScreen extends StatefulWidget {
  const RiskAnalysisScreen({super.key});

  @override
  State<RiskAnalysisScreen> createState() => _RiskAnalysisScreenState();
}

class _RiskAnalysisScreenState extends State<RiskAnalysisScreen> {
  final Map<String, String> _parameters = {
    'investment': 'medium',
    'complexity': 'medium',
    'competition': 'medium',
    'timeline': 'reasonable',
    'resources': 'adequate',
    'compliance': 'not_required',
  };

  String _result = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Risk Analysis Tool')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Risk Analysis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Evaluate potential risks based on project parameters:'),
            const SizedBox(height: 20),

            // Risk Parameters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _parameters.keys.map((param) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatParamName(param),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: _parameters[param],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              items: _getOptionsForParam(param).map((option) {
                                return DropdownMenuItem(
                                  value: option,
                                  child: Text(_formatOptionName(option)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _parameters[param] = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Additional Notes
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Any additional context or concerns...',
              ),
            ),

            const SizedBox(height: 24),

            // Analyze Button
            ElevatedButton(
              onPressed: _loading ? null : _analyzeRisk,
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
                      'Analyze Risk',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getRiskColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBorderColor()),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getRiskIcon(),
                          color: _getIconColor(),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getRiskLevel(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getTextColor(),
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
          ],
        ),
      ),
    );
  }

  List<String> _getOptionsForParam(String param) {
    switch (param) {
      case 'investment':
        return ['low', 'medium', 'high'];
      case 'complexity':
        return ['simple', 'medium', 'high'];
      case 'competition':
        return ['low', 'medium', 'high'];
      case 'timeline':
        return ['comfortable', 'reasonable', 'tight'];
      case 'resources':
        return ['adequate', 'limited', 'scarce'];
      case 'compliance':
        return ['not_required', 'standard', 'required', 'complex'];
      default:
        return ['low', 'medium', 'high'];
    }
  }

  String _formatParamName(String param) {
    final names = {
      'investment': 'Investment Level',
      'complexity': 'Technical Complexity',
      'competition': 'Market Competition',
      'timeline': 'Project Timeline',
      'resources': 'Available Resources',
      'compliance': 'Compliance Requirements',
    };
    return names[param] ?? param;
  }

  String _formatOptionName(String option) {
    return option.replaceAll('_', ' ').toUpperCase();
  }

  Color _getRiskColor() {
    if (_result.contains('CRITICAL')) return const Color(0xFFFFEBEE);
    if (_result.contains('HIGH')) return Colors.orange.shade50;
    if (_result.contains('MODERATE')) return Colors.yellow.shade50;
    if (_result.contains('LOW')) return const Color(0xFFE8F5E9);
    return const Color(0xFFFAFAFA);
  }

  Color _getBorderColor() {
    if (_result.contains('CRITICAL')) return Colors.red;
    if (_result.contains('HIGH')) return Colors.orange;
    if (_result.contains('MODERATE')) return Colors.yellow;
    if (_result.contains('LOW')) return Colors.green;
    return Colors.grey;
  }

  Color _getIconColor() {
    if (_result.contains('CRITICAL')) return Colors.red;
    if (_result.contains('HIGH')) return Colors.orange;
    if (_result.contains('MODERATE')) return Colors.yellow.shade700;
    if (_result.contains('LOW')) return Colors.green;
    return Colors.grey;
  }

  Color _getTextColor() {
    if (_result.contains('CRITICAL')) return const Color(0xFFB71C1C);
    if (_result.contains('HIGH')) return Colors.orange.shade900;
    if (_result.contains('MODERATE')) return Colors.yellow.shade900;
    if (_result.contains('LOW')) return const Color(0xFF1B5E20);
    return const Color(0xFF212121);
  }

  IconData _getRiskIcon() {
    if (_result.contains('CRITICAL')) return Icons.warning;
    if (_result.contains('HIGH')) return Icons.error_outline;
    if (_result.contains('MODERATE')) return Icons.info_outline;
    if (_result.contains('LOW')) return Icons.check_circle_outline;
    return Icons.help_outline;
  }

  String _getRiskLevel() {
    if (_result.contains('CRITICAL')) return 'CRITICAL RISK';
    if (_result.contains('HIGH')) return 'HIGH RISK';
    if (_result.contains('MODERATE')) return 'MODERATE RISK';
    if (_result.contains('LOW')) return 'LOW RISK';
    if (_result.contains('MINIMAL')) return 'MINIMAL RISK';
    return 'RISK ANALYSIS';
  }

  Future<void> _analyzeRisk() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Risk Analysis Tool',
        module: 'Logic & Decision AI',
        input: _parameters,
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
}
