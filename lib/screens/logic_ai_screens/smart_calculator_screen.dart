import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class SmartCalculatorScreen extends StatefulWidget {
  const SmartCalculatorScreen({super.key});

  @override
  State<SmartCalculatorScreen> createState() => _SmartCalculatorScreenState();
}

class _SmartCalculatorScreenState extends State<SmartCalculatorScreen> {
  final TextEditingController _expressionController = TextEditingController();
  final List<String> _history = [];
  String _result = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Calculator')),
      body: Column(
        children: [
          // Display Area
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFAFAFA),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _expressionController,
                  decoration: InputDecoration(
                    hintText: 'Enter expression (e.g., 2+2, 10*5, sqrt(4))',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _expressionController.clear();
                        setState(() {
                          _result = '';
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.right,
                  onSubmitted: (_) => _calculate(),
                ),
                const SizedBox(height: 8),
                if (_result.isNotEmpty)
                  Text(
                    '= $_result',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
              ],
            ),
          ),

          // Calculator Buttons
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // Operation Buttons
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 4,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        _buildCalculatorButton('7'),
                        _buildCalculatorButton('8'),
                        _buildCalculatorButton('9'),
                        _buildCalculatorButton('÷', isOperation: true),
                        _buildCalculatorButton('4'),
                        _buildCalculatorButton('5'),
                        _buildCalculatorButton('6'),
                        _buildCalculatorButton('×', isOperation: true),
                        _buildCalculatorButton('1'),
                        _buildCalculatorButton('2'),
                        _buildCalculatorButton('3'),
                        _buildCalculatorButton('-', isOperation: true),
                        _buildCalculatorButton('0'),
                        _buildCalculatorButton('.'),
                        _buildCalculatorButton('=', isSpecial: true),
                        _buildCalculatorButton('+', isOperation: true),
                      ],
                    ),
                  ),

                  // Advanced Operations
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildAdvancedButton('Clear', Icons.backspace),
                        _buildAdvancedButton('(', Icons.code),
                        _buildAdvancedButton(')', Icons.code),
                        _buildAdvancedButton('^', Icons.exposure),
                        _buildAdvancedButton('%', Icons.percent),
                        _buildAdvancedButton('sqrt', Icons.functions),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // History
          if (_history.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: const Color(0xFFE0E0E0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        return Text(
                          _history[_history.length - 1 - index],
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _calculate,
        child: _loading
            ? const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              )
            : const Icon(Icons.calculate),
      ),
    );
  }

  Widget _buildCalculatorButton(String text,
      {bool isOperation = false, bool isSpecial = false}) {
    return ElevatedButton(
      onPressed: () => _handleButtonPress(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSpecial
            ? Colors.blue
            : isOperation
                ? Colors.orange
                : const Color(0xFFEEEEEE),
        foregroundColor: isSpecial || isOperation ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: isSpecial ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAdvancedButton(String text, IconData icon) {
    return OutlinedButton.icon(
      onPressed: () => _handleAdvancedOperation(text),
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _handleButtonPress(String text) {
    if (text == '=') {
      _calculate();
    } else {
      setState(() {
        _expressionController.text += text;
      });
    }
  }

  void _handleAdvancedOperation(String operation) {
    if (operation == 'Clear') {
      _expressionController.clear();
      setState(() {
        _result = '';
      });
    } else {
      setState(() {
        _expressionController.text += operation;
      });
    }
  }

  Future<void> _calculate() async {
    final expression = _expressionController.text.trim();
    if (expression.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Smart Calculator',
        module: 'Logic & Decision AI',
        input: expression,
      );

      setState(() {
        _result = result.toString();
        _history.add('$expression = $_result');
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }
}
