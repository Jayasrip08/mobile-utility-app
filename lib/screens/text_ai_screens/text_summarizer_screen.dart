import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';
import '../../widgets/tool_scaffold.dart';

class TextSummarizerScreen extends StatefulWidget {
  const TextSummarizerScreen({super.key});

  @override
  State<TextSummarizerScreen> createState() => _TextSummarizerScreenState();
}

class _TextSummarizerScreenState extends State<TextSummarizerScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic> _analysis = {};

  @override
  void dispose() {
    _textController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final originalSentences = _analysis['originalLength'] ?? 0;
    final summarySentences = _analysis['summaryLength'] ?? 0;

    return ToolScaffold(
      title: 'Text Summarizer',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Original Text', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 220,
                      child: TextField(
                        controller: _textController,
                        expands: true,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Paste or type text to summarize...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading ? null : _summarizeText,
                            child: _loading
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Summarize'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: _clearAll, child: const Text('Clear')),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text('Generated Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (summarySentences > 0) ...[
                          IconButton(onPressed: _copySummary, icon: const Icon(Icons.copy, size: 18)),
                          IconButton(onPressed: _shareSummary, icon: const Icon(Icons.share, size: 18)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: TextField(
                        controller: _summaryController,
                        expands: true,
                        maxLines: null,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Summary will appear here...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (originalSentences > 0)
                      Text('Original: $originalSentences sentences — Summary: $summarySentences sentences',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _summarizeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Text Summarizer',
        module: 'Text AI',
        input: {'text': text},
      );

      setState(() {
        _analysis = result is Map<String, dynamic> ? Map<String, dynamic>.from(result) : {};
        _summaryController.text = (result is Map && result['summary'] != null) ? result['summary'].toString() : '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _analysis = {'error': e.toString()};
        _summaryController.text = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _copySummary() {
    final text = _summaryController.text;
    if (text.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Summary copied to clipboard')));
  }

  void _shareSummary() {
    final text = _summaryController.text;
    if (text.isEmpty) return;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Share'),
        content: const Text('Share action placeholder'),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _summaryController.clear();
      _analysis = {};
    });
  }
}
