import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/tool_scaffold.dart';

class SpellCheckerScreen extends StatefulWidget {
  const SpellCheckerScreen({super.key});

  @override
  State<SpellCheckerScreen> createState() => _SpellCheckerScreenState();
}

class _SpellCheckerScreenState extends State<SpellCheckerScreen> {
  final TextEditingController _textController = TextEditingController();
  List<String> _mistakes = [];
  bool _loading = false;
  String _originalText = '';

  // Statistics
  int _wordCount = 0;
  int _mistakeCount = 0;
  double _accuracy = 100.0;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Spell Checker',
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfo,
        ),
      ],
      child: Column(
        children: [
          // Statistics Card
          ThemedCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Spell Check Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Words', _wordCount.toString(),
                        Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    _buildStatCard(
                        'Mistakes', _mistakeCount.toString(), Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatCard('Accuracy',
                        '${_accuracy.toStringAsFixed(1)}%',
                        _accuracy > 90 ? Colors.green : Colors.red),
                  ],
                ),
                const SizedBox(height: 12),
                if (_mistakeCount > 0)
                  LinearProgressIndicator(
                    value: _accuracy / 100,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(_accuracy > 90
                        ? Colors.green
                        : _accuracy > 70
                            ? Colors.orange
                            : Colors.red),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Input and Results Section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input Panel
                  SizedBox(
                    height: 300,
                    child: ThemedCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Enter Text:',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                hintText: 'Type or paste text to check spelling...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                              onChanged: (value) {
                                _calculateStats(value);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _textController.text.isEmpty ||
                                          _loading
                                      ? null
                                      : _checkSpelling,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text('Check Spelling'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _textController.text.isEmpty
                                    ? null
                                    : _clearText,
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results Panel
                  ThemedCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.spellcheck,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Spelling Results',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_mistakes.isNotEmpty)
                              Text(
                                '$_mistakeCount found',
                                style: TextStyle(
                                  color: _mistakeCount > 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_mistakes.isEmpty && _originalText.isNotEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  'Perfect Spelling!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All $_wordCount words are correctly spelled',
                                  style: const TextStyle(color: Color(0xFF757575)),
                                ),
                              ],
                            ),
                          )
                        else if (_mistakes.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _mistakes.length,
                            itemBuilder: (context, index) {
                              final mistake = _mistakes[index];
                              final parts = mistake.split(':');
                              final word = parts.isNotEmpty
                                  ? parts[0].replaceAll("'", '')
                                  : '';
                              final suggestion = parts.length > 1 ? parts[1] : '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFFFCDD2),
                                    child: const Icon(Icons.error_outline,
                                        color: Colors.red, size: 20),
                                  ),
                                  title: Text(
                                    word.isNotEmpty ? word : mistake,
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: suggestion.isNotEmpty
                                      ? Text('Suggestion: $suggestion')
                                      : null,
                                  trailing: suggestion.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                              Icons.auto_fix_normal,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _applyCorrection(word, suggestion),
                                        )
                                      : null,
                                ),
                              );
                            },
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.spellcheck,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Text to Check',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter text to check for spelling errors',
                                  style: TextStyle(color: const Color(0xFF9E9E9E)),
                                ),
                              ],
                            ),
                          ),
                        if (_mistakes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _autoCorrect,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Apply All Corrections'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateStats(String text) {
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    setState(() {
      _wordCount = words;
    });
  }

  Future<void> _checkSpelling() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _originalText = text;
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Spell Checker',
        module: 'Text AI',
        input: text,
      );

      final mistakes =
          result.toString().split(', ').where((m) => m.isNotEmpty).toList();

      setState(() {
        _mistakes = mistakes;
        _mistakeCount = mistakes.length;
        _accuracy = _wordCount > 0
            ? ((_wordCount - _mistakeCount) / _wordCount * 100)
            : 100;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _mistakes = ['Error checking spelling: $e'];
        _loading = false;
      });
    }
  }

  void _autoCorrect() {
    if (_textController.text.isEmpty) return;

    // Simple auto-correction based on suggestions
    String correctedText = _textController.text;

    for (var mistake in _mistakes) {
      final parts = mistake.split(':');
      if (parts.length >= 2) {
        final word = parts[0].replaceAll("'", '').trim();
        final suggestion = parts[1].trim();

        if (word.isNotEmpty && suggestion.isNotEmpty) {
          correctedText = correctedText.replaceAll(word, suggestion);
        }
      }
    }

    setState(() {
      _textController.text = correctedText;
      _mistakes = [];
      _mistakeCount = 0;
      _accuracy = 100;
      _calculateStats(correctedText);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto-correct applied')),
    );
  }

  void _applyCorrection(String word, String suggestion) {
    if (word.isEmpty || suggestion.isEmpty) return;

    final currentText = _textController.text;
    final correctedText = currentText.replaceAll(word, suggestion);

    setState(() {
      _textController.text = correctedText;
      // Remove this mistake from the list
      _mistakes = _mistakes.where((m) => !m.contains(word)).toList();
      _mistakeCount = _mistakes.length;
      _accuracy = _wordCount > 0
          ? ((_wordCount - _mistakeCount) / _wordCount * 100)
          : 100;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Corrected "$word" to "$suggestion"')),
    );
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _mistakes = [];
      _originalText = '';
      _wordCount = 0;
      _mistakeCount = 0;
      _accuracy = 100;
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Spell Checker Info'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This tool uses Classical AI techniques:'),
                SizedBox(height: 8),
                Text('• Dictionary-based spell checking'),
                Text('• Pattern matching for common misspellings'),
                Text('• Statistical analysis for suggestions'),
                SizedBox(height: 16),
                Text('Features:'),
                Text('• 500+ word dictionary'),
                Text('• Common misspelling detection'),
                Text('• Intelligent suggestions'),
                Text('• Auto-correction capability'),
                SizedBox(height: 16),
                Text('Accuracy: ~95% for common English words'),
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
    _textController.dispose();
    super.dispose();
  }
}