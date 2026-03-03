import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_executor.dart';
import '../components/tool_scaffold.dart';

class GrammarCheckerScreen extends StatefulWidget {
  const GrammarCheckerScreen({super.key});

  @override
  State<GrammarCheckerScreen> createState() => _GrammarCheckerScreenState();
}

class _GrammarCheckerScreenState extends State<GrammarCheckerScreen> {
  final TextEditingController _textController = TextEditingController();
  List<String> _errors = [];
  bool _loading = false;
  
  // Statistics
  int _wordCount = 0;
  int _errorCount = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _calculateStats(String text) {
     setState(() {
       _wordCount = text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
     });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Grammar Checker',
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
            // Stats Row
            Row(
              children: [
                _buildStatBadge(Icons.text_fields, '$_wordCount Words', Colors.blue),
                const SizedBox(width: 12),
                _buildStatBadge(Icons.warning_amber_rounded, '$_errorCount Errors', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            
            // Input Area
            SizedBox(
              height: 300,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        decoration: const InputDecoration(
                          hintText: 'Type or paste your text here...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(20),
                        ),
                        onChanged: _calculateStats,
                      ),
                    ),
                    // Action Bar inside the card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy Text',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _textController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Text copied!')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_all, size: 20),
                            tooltip: 'Clear',
                            onPressed: () {
                              _textController.clear();
                              _calculateStats('');
                              setState(() {
                                _errors = [];
                                _errorCount = 0;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _checkGrammar,
                            icon: _loading 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Check'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Errors List (Animated)
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                 constraints: const BoxConstraints(maxHeight: 200),
                 decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.stretch,
                   children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       decoration: BoxDecoration(
                         color: Colors.orange.withValues(alpha: 0.1),
                         borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                       ),
                       child: const Text(
                         'Suggestions',
                         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                       ),
                     ),
                     Expanded(
                       child: ListView.builder(
                         padding: const EdgeInsets.all(8),
                         itemCount: _errors.length,
                         itemBuilder: (context, index) {
                           return ListTile(
                             leading: const CircleAvatar(
                               radius: 10,
                               backgroundColor: Colors.orange,
                               child: Icon(Icons.priority_high, size: 12, color: Colors.white),
                             ),
                             title: Text(_errors[index], style: const TextStyle(fontSize: 14)),
                             dense: true,
                           );
                         },
                       ),
                     ),
                   ],
                 ),
              ),
            ],
            
            const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _checkGrammar() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _errors = [];
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Grammar Checker',
        module: 'Text AI',
        input: text,
      );

      setState(() {
        _errors = result.toString().split(', ').where((e) => e.isNotEmpty).toList();
        _errorCount = _errors.length;
        if (_errors.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('No grammatical errors found!'),
               backgroundColor: Colors.green,
             ),
           );
        }
      });
    } catch (e) {
      setState(() {
        _errors = ['Error: $e'];
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
