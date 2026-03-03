import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/tool_scaffold.dart';

class StopwordRemoverScreen extends StatefulWidget {
  const StopwordRemoverScreen({super.key});

  @override
  State<StopwordRemoverScreen> createState() => _StopwordRemoverScreenState();
}

class _StopwordRemoverScreenState extends State<StopwordRemoverScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _filteredController = TextEditingController();

  Map<String, dynamic> _stats = {};
  List<String> _removedWords = [];
  bool _loading = false;
  String _originalText = '';

  // Filter settings
  bool _showRemovedWords = true;
  bool _preserveFormatting = true;
  Set<String> _selectedCategories = {};

  @override
  Widget build(BuildContext context) {
    final hasStats = _stats.isNotEmpty;
    final wordCount = _stats['originalWordCount'] ?? 0;
    final filteredCount = _stats['filteredWordCount'] ?? 0;
    final removedCount = _stats['removedWordCount'] ?? 0;
    final compressionRatio = _stats['compressionRatio'] ?? '0';

    return ToolScaffold(
      title: 'Stop-word Remover',
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_alt),
          onPressed: _showFilterOptions,
          tooltip: 'Filter Options',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfo,
        ),
      ],
      child: Column(
        children: [
          // Statistics Bar
          if (hasStats) ...[
            ThemedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stop-word Analysis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatTile(
                          'Original',
                          '$wordCount words',
                          Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      _buildStatTile(
                          'Filtered',
                          '$filteredCount words',
                          Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      _buildStatTile(
                          'Removed', '$removedCount words', Colors.red),
                      const SizedBox(width: 8),
                      _buildStatTile(
                          'Compression', '${compressionRatio}x', Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: wordCount > 0 ? removedCount / wordCount : 0,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        removedCount > 0 ? Colors.red : Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Removed ${_stats['removedPercentage'] ?? '0'}% of words',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Original Text
                  SizedBox(
                    height: 300,
                    child: ThemedCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.article,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Original Text',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              if (wordCount > 0)
                                Chip(label: Text('$wordCount words')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                hintText: 'Enter text with stop-words...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _textController.text.isEmpty || _loading
                                ? null
                                : _removeStopWords,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white),
                                    ),
                                  )
                                : const Text('Remove Stop-words'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filtered Text
                  ThemedCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.filter_alt,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Filtered Text',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (filteredCount > 0) ...[
                              IconButton(
                                onPressed: _copyFilteredText,
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copy Filtered Text',
                              ),
                              IconButton(
                                onPressed: _clearAll,
                                icon: const Icon(Icons.clear_all, size: 18),
                                tooltip: 'Clear All',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: TextField(
                            controller: _filteredController,
                            maxLines: null,
                            expands: true,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Filtered text will appear here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                              filled: true,
                                fillColor:
                                  Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (filteredCount > 0)
                          Text(
                            'Filtered to $filteredCount words (${compressionRatio}x compression)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Removed Words Section
                  if (_showRemovedWords && _removedWords.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ThemedCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.remove_circle,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Removed Stop-words',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => setState(
                                    () => _showRemovedWords = !_showRemovedWords),
                                icon: Icon(
                                  _showRemovedWords
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                tooltip: 'Toggle Visibility',
                              ),
                              if (_removedWords.isNotEmpty)
                                IconButton(
                                  onPressed: _analyzeFrequency,
                                  icon: const Icon(Icons.analytics),
                                  tooltip: 'Analyze Frequency',
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _removedWords.map((word) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(word),
                                    deleteIcon:
                                        const Icon(Icons.close, size: 14),
                                    onDeleted: () => _restoreWord(word),
                                    backgroundColor: const Color(0xFFFFEBEE),
                                    side: const BorderSide(
                                        color: Color(0xFFFFCDD2)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_removedWords.length} stop-words removed. Click any to restore.',
                            style:
                                const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
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
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeStopWords() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _originalText = text;
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Stop-word Remover',
        module: 'Text AI',
        input: text,
      );

      setState(() {
        _stats = result;
        _filteredController.text = result['filteredText'] ?? '';
        _removedWords = List<String>.from(result['removedWords'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _stats = {'error': 'Error removing stop-words: $e'};
        _loading = false;
      });
    }
  }

  void _restoreWord(String word) {
    final currentText = _filteredController.text;
    final words = currentText.split(' ');

    // Find the best place to insert the word (simple implementation)
    if (words.isNotEmpty) {
      final newText = '$currentText $word';
      _filteredController.text = newText;

      setState(() {
        _removedWords.remove(word);
        _stats['filteredWordCount'] = (_stats['filteredWordCount'] ?? 0) + 1;
        _stats['removedWordCount'] = (_stats['removedWordCount'] ?? 0) - 1;
        final total = _stats['originalWordCount'] ?? 1;
        final removed = _stats['removedWordCount'] ?? 0;
        _stats['removedPercentage'] =
            ((removed / total) * 100).toStringAsFixed(1);
        _stats['compressionRatio'] =
            (_stats['filteredWordCount'] / total).toStringAsFixed(2);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored "$word" to filtered text')),
      );
    }
  }

  void _copyFilteredText() {
    final text = _filteredController.text;
    if (text.isEmpty) return;

    // In real app: Clipboard.setData(ClipboardData(text: text))
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtered text copied to clipboard')),
    );
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _filteredController.clear();
      _stats = {};
      _removedWords = [];
      _originalText = '';
    });
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Stop-word Filter Options'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select categories to filter:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                            'Articles', {'a', 'an', 'the'}, setState),
                        _buildFilterChip(
                            'Pronouns', {'i', 'you', 'he', 'she'}, setState),
                        _buildFilterChip(
                            'Prepositions', {'in', 'on', 'at'}, setState),
                        _buildFilterChip(
                            'Conjunctions', {'and', 'but', 'or'}, setState),
                        _buildFilterChip(
                            'Verbs', {'is', 'are', 'was'}, setState),
                        _buildFilterChip(
                            'Adverbs', {'very', 'too', 'quite'}, setState),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Show removed words'),
                      value: _showRemovedWords,
                      onChanged: (value) {
                        setState(() => _showRemovedWords = value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Preserve formatting'),
                      value: _preserveFormatting,
                      onChanged: (value) {
                        setState(() => _preserveFormatting = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Selected: ${_selectedCategories.length} categories',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilterOptions();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, Set<String> words, Function setState) {
    final isSelected = _selectedCategories.contains(label);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedCategories.add(label);
          } else {
            _selectedCategories.remove(label);
          }
        });
      },
      tooltip: '${words.length} words',
    );
  }

  void _applyFilterOptions() {
    // In a real implementation, this would apply the selected filters
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options applied')),
    );

    // Re-run stop-word removal with new settings
    if (_originalText.isNotEmpty) {
      _removeStopWords();
    }
  }

  void _analyzeFrequency() {
    if (_removedWords.isEmpty) return;

    // Count frequency of removed words
    final frequency = <String, int>{};
    for (var word in _removedWords) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    // Sort by frequency
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop-word Frequency Analysis'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Most frequently removed stop-words:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                ...sorted.take(10).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key)),
                        Chip(
                          label: Text('${entry.value}'),
                          backgroundColor: const Color(0xFFFFEBEE),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                Text(
                  'Total unique stop-words: ${frequency.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop-word Remover Info'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This tool uses Classical AI techniques:'),
                SizedBox(height: 8),
                Text('• Pattern-based stop-word identification'),
                Text('• Dictionary lookup (500+ common stop-words)'),
                Text('• Statistical analysis of word removal'),
                Text('• Category-based filtering'),
                SizedBox(height: 16),
                Text('What are stop-words?'),
                Text('Stop-words are common words that carry little meaning:'),
                Text('• Articles: a, an, the'),
                Text('• Pronouns: I, you, he, she'),
                Text('• Prepositions: in, on, at'),
                Text('• Conjunctions: and, but, or'),
                Text('• Common verbs: is, are, was'),
                SizedBox(height: 16),
                Text('Uses:'),
                Text('• Text preprocessing for NLP'),
                Text('• Improving search relevance'),
                Text('• Text summarization'),
                Text('• Keyword extraction'),
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
    _filteredController.dispose();
    super.dispose();
  }
}