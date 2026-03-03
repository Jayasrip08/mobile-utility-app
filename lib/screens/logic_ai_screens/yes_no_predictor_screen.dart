import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class YesNoPredictorScreen extends StatefulWidget {
  const YesNoPredictorScreen({super.key});

  @override
  State<YesNoPredictorScreen> createState() => _YesNoPredictorScreenState();
}

class _YesNoPredictorScreenState extends State<YesNoPredictorScreen> {
  final TextEditingController _questionController = TextEditingController();
  final Map<String, String> _context = {
    'confidence': 'medium',
    'urgency': 'medium',
    'complexity': 'medium',
  };

  String _result = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yes/No Predictor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ask a Yes/No Question',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Your question',
                hintText: 'e.g., Should I invest in this project?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Context Factors:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            // Context factors
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Confidence'),
                      DropdownButtonFormField<String>(
                        initialValue: _context['confidence'],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['low', 'medium', 'high'].map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _context['confidence'] = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Urgency'),
                      DropdownButtonFormField<String>(
                        initialValue: _context['urgency'],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['low', 'medium', 'high'].map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _context['urgency'] = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Complexity'),
                      DropdownButtonFormField<String>(
                        initialValue: _context['complexity'],
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['simple', 'medium', 'complex'].map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _context['complexity'] = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Predict Button
            ElevatedButton(
              onPressed: _loading ? null : _predict,
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
                      'Get Prediction',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _result.contains('YES')
                      ? const Color(0xFFE8F5E9)
                      : _result.contains('NO')
                          ? const Color(0xFFFFEBEE)
                          : Colors.yellow.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _result.contains('YES')
                        ? Colors.green
                        : _result.contains('NO')
                            ? Colors.red
                            : Colors.orange,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _result.contains('YES')
                          ? Icons.check_circle
                          : _result.contains('NO')
                              ? Icons.cancel
                              : Icons.help,
                      color: _result.contains('YES')
                          ? Colors.green
                          : _result.contains('NO')
                              ? Colors.red
                              : Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5),
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

  Future<void> _predict() async {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = '';
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Yes/No Predictor',
        module: 'Logic & Decision AI',
        input: {
          'question': _questionController.text,
          'context': _context,
        },
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
    _questionController.dispose();
    super.dispose();
  }
}
