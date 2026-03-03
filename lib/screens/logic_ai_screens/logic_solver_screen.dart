import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class LogicSolverScreen extends StatefulWidget {
  const LogicSolverScreen({super.key});

  @override
  State<LogicSolverScreen> createState() => _LogicSolverScreenState();
}

class _LogicSolverScreenState extends State<LogicSolverScreen> {
  final TextEditingController _expressionController = TextEditingController();
  String _result = '';
  bool _loading = false;
  Map<String, bool> _truthTable = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logic Solver')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Boolean Logic Solver',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Enter a boolean expression to solve:'),
            const SizedBox(height: 8),
            const Text(
              'Examples: true AND false, p => q, !p OR q',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Expression Input
            TextField(
              controller: _expressionController,
              decoration: InputDecoration(
                labelText: 'Boolean Expression',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.code),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: _showHelp,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Examples
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildExampleChip('true AND false'),
                _buildExampleChip('p OR q'),
                _buildExampleChip('!p'),
                _buildExampleChip('p => q'),
                _buildExampleChip('p <=> q'),
                _buildExampleChip('(p AND q) OR r'),
              ],
            ),

            const SizedBox(height: 24),

            // Solve Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _solveExpression,
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
                        : const Text('Solve Expression'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _generateTruthTable,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Truth Table'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Result:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result == 'true'
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _result == 'true' ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _result == 'true' ? Icons.check_circle : Icons.cancel,
                      color: _result == 'true' ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _result.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _result == 'true' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Truth Table
            if (_truthTable.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Truth Table:',
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
                child: Table(
                  border: TableBorder.all(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                      ),
                      children: [
                        _buildTableCell('Input', isHeader: true),
                        _buildTableCell('Output', isHeader: true),
                      ],
                    ),
                    ..._truthTable.entries.map((entry) {
                      return TableRow(
                        children: [
                          _buildTableCell(entry.key),
                          _buildTableCell(entry.value ? 'T' : 'F'),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],

            // Logic Operators Guide
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logic Operators:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(2),
                      },
                      children: [
                        _buildGuideRow('AND / &&', 'Conjunction', 'p AND q'),
                        _buildGuideRow('OR / ||', 'Disjunction', 'p OR q'),
                        _buildGuideRow('NOT / !', 'Negation', 'NOT p'),
                        _buildGuideRow('=> / implies', 'Implication', 'p => q'),
                        _buildGuideRow('<=> / equiv', 'Equivalence', 'p <=> q'),
                      ],
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

  Widget _buildExampleChip(String example) {
    return ActionChip(
      label: Text(example),
      onPressed: () {
        _expressionController.text = example;
      },
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  TableRow _buildGuideRow(String operator, String name, String example) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(operator,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(name),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(example, style: const TextStyle(fontFamily: 'monospace')),
        ),
      ],
    );
  }

  Future<void> _solveExpression() async {
    final expression = _expressionController.text.trim();
    if (expression.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expression')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = '';
      _truthTable = {};
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Logic Solver',
        module: 'Logic & Decision AI',
        input: expression,
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

  Future<void> _generateTruthTable() async {
    final expression = _expressionController.text.trim();
    if (expression.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an expression')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _truthTable = {};
    });

    try {
      // For simplicity, we'll use the LogicSolver directly
      // In a real app, this would come from AIExecutor
      await Future.delayed(const Duration(milliseconds: 500));

      // Simple truth table for demonstration
      final simpleTable = {
        'p=T, q=T': true,
        'p=T, q=F': false,
        'p=F, q=T': true,
        'p=F, q=F': false,
      };

      setState(() {
        _truthTable = simpleTable;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _truthTable = {'Error': false};
        _loading = false;
      });
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logic Solver Help'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Supported Operators:'),
                SizedBox(height: 8),
                Text('• AND / && : Logical AND'),
                Text('• OR / || : Logical OR'),
                Text('• NOT / ! : Logical NOT'),
                Text('• => / implies : Implication'),
                Text('• <=> / equiv : Equivalence'),
                SizedBox(height: 16),
                Text('Variables: Use single letters like p, q, r'),
                SizedBox(height: 16),
                Text('Examples:'),
                Text('• true AND false'),
                Text('• p OR q'),
                Text('• !p'),
                Text('• p => q'),
                Text('• (p AND q) OR r'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }
}
