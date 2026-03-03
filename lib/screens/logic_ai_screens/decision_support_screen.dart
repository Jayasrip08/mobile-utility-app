import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class DecisionSupportScreen extends StatefulWidget {
  const DecisionSupportScreen({super.key});

  @override
  State<DecisionSupportScreen> createState() => _DecisionSupportScreenState();
}

class _DecisionSupportScreenState extends State<DecisionSupportScreen> {
  final Map<String, String> _factors = {
    'budget': 'adequate',
    'roi': 'medium',
    'risk': 'medium',
    'experience': 'medium',
    'timeline': 'reasonable',
    'resources': 'available',
    'demand': 'medium',
    'competition': 'medium',
  };

  final List<String> _options = [
    'low',
    'medium',
    'high',
    'adequate',
    'limited',
    'reasonable',
    'tight',
    'available'
  ];

  String _result = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decision Support System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Evaluate Decision Factors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Adjust the factors below to analyze your decision:'),
            const SizedBox(height: 20),

            // Factors input
            ..._factors.keys.map((factor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatFactorName(factor),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _factors[factor],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        items: _options.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _factors[factor] = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Analyze Button
            ElevatedButton(
              onPressed: _loading ? null : _analyzeDecision,
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
                      'Analyze Decision',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Analysis Result:',
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

  String _formatFactorName(String factor) {
    return factor[0].toUpperCase() + factor.substring(1).replaceAll('_', ' ');
  }

  Future<void> _analyzeDecision() async {
    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Decision Support System',
        module: 'Logic & Decision AI',
        input: _factors,
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
