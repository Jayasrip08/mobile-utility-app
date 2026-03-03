import 'package:flutter/material.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/tool_scaffold.dart';

/*
Simplified Word Counter screen to replace a malformed original file.

This implementation avoids complex spreads and const-eval issues and provides
basic local analysis (word/char/sentence/paragraph counts).
*/

class WordCounterScreen extends StatefulWidget {
  const WordCounterScreen({super.key});

  @override
  State<WordCounterScreen> createState() => _WordCounterScreenState();
}

class _WordCounterScreenState extends State<WordCounterScreen> {
  final TextEditingController _textController = TextEditingController();
  Map<String, dynamic> _stats = {};
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Word Counter',
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ThemedCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter text to analyze', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        onChanged: (v) => _analyzeText(v),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _textController.text.trim().isEmpty ? null : _countWords,
                            child: _loading ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Analyze'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: _clearText, child: const Text('Clear')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              if (_stats.isNotEmpty) ...[
                ThemedCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2,
                        children: [
                          _buildStatTile('Words', '${_stats['wordCount'] ?? 0}'),
                          _buildStatTile('Chars', '${_stats['characterCount'] ?? 0}'),
                          _buildStatTile('No-spaces', '${_stats['characterCountNoSpaces'] ?? 0}'),
                          _buildStatTile('Sentences', '${_stats['sentenceCount'] ?? 0}'),
                          _buildStatTile('Paragraphs', '${_stats['paragraphCount'] ?? 0}'),
                          _buildStatTile('Reading (min)', '${(_stats['readingTimeMinutes'] ?? 0).toString()}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).colorScheme.surface),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _analyzeText(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final chars = text.length;
    final noSpaces = text.replaceAll(RegExp(r'\s+'), '').length;
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
    final paragraphs = text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;

    setState(() {
      _stats = {
        'wordCount': words,
        'characterCount': chars,
        'characterCountNoSpaces': noSpaces,
        'sentenceCount': sentences,
        'paragraphCount': paragraphs,
        'readingTimeMinutes': words / 250.0,
      };
    });
  }

  Future<void> _countWords() async {
    _analyzeText(_textController.text);
  }

  void _clearText() {
    _textController.clear();
    setState(() {
      _stats = {};
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

