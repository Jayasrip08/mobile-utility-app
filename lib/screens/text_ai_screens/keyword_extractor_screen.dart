import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_executor.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/tool_scaffold.dart';

class KeywordExtractorScreen extends StatefulWidget {
  const KeywordExtractorScreen({super.key});

  @override
  State<KeywordExtractorScreen> createState() => _KeywordExtractorScreenState();
}

class _KeywordExtractorScreenState extends State<KeywordExtractorScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _keywordCountController =
      TextEditingController(text: '10');

  List<String> _keywords = [];
  bool _loading = false;
  String _originalText = '';

  // Statistics
  int _wordCount = 0;
  int _uniqueWords = 0;
  double _keywordDensity = 0.0;

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Keyword Extractor',
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          onPressed: _keywords.isNotEmpty ? _exportKeywords : null,
          tooltip: 'Export Keywords',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfo,
        ),
      ],
      child: Column(
        children: [
          // Control Panel
          ThemedCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keyword Extraction Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _keywordCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Keywords',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune),
                            onPressed: () {},
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty &&
                              int.tryParse(value) != null) {
                            _extractKeywords();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed:
                            _textController.text.isEmpty || _loading ? null : _extractKeywords,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Extract'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Main Content Area
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
                          Row(
                            children: [
                              const Text(
                                'Input Text',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _textController.text.isEmpty
                                    ? null
                                    : _clearText,
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                hintText: 'Paste or type your text here...',
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
                          if (_wordCount > 0)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildStatChip('Words: $_wordCount'),
                                _buildStatChip('Unique: $_uniqueWords'),
                                _buildStatChip(
                                    'Density: ${_keywordDensity.toStringAsFixed(1)}%'),
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
                            const Icon(Icons.key, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Extracted Keywords',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_keywords.isNotEmpty)
                              Text(
                                '${_keywords.length} keywords',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_keywords.isEmpty && _originalText.isNotEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Keywords Found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Text may be too short or contain only common words',
                                  style: TextStyle(
                                      color: const Color(0xFF9E9E9E)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else if (_keywords.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 3,
                            ),
                            itemCount: _keywords.length,
                            itemBuilder: (context, index) {
                              final keyword = _keywords[index];
                              final rank = index + 1;
                              final color = _getKeywordColor(rank);

                              return Card(
                                color: color.withValues(alpha: 0.1),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: color,
                                    child: Text(
                                      rank.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    keyword,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: color,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () => _copyKeyword(keyword),
                                  ),
                                ),
                              );
                            },
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.key,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'Enter Text to Extract Keywords',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Keywords will appear here once extracted',
                                  style: TextStyle(
                                      color: const Color(0xFF9E9E9E)),
                                ),
                              ],
                            ),
                          ),
                        if (_keywords.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _copyAllKeywords,
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy All'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _shareKeywords,
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildStatChip(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: const Color(0xFFE3F2FD),
      labelStyle: const TextStyle(fontSize: 12),
    );
  }

  Color _getKeywordColor(int rank) {
    if (rank == 1) return Colors.red;
    if (rank == 2) return Colors.orange;
    if (rank == 3) return Colors.amber;
    if (rank <= 5) return Colors.green;
    if (rank <= 10) return Colors.blue;
    return Colors.purple;
  }

  void _calculateStats(String text) {
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final uniqueWords = words.toSet().length;

    setState(() {
      _wordCount = words.length;
      _uniqueWords = uniqueWords;
      _keywordDensity =
          words.isNotEmpty ? (uniqueWords / words.length * 100) : 0;
    });
  }

  Future<void> _extractKeywords() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final maxKeywords = int.tryParse(_keywordCountController.text) ?? 10;
    if (maxKeywords <= 0) return;

    setState(() {
      _loading = true;
      _originalText = text;
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Keyword Extractor',
        module: 'Text AI',
        input: text,
      );

      final keywords =
          result.toString().split(', ').where((k) => k.isNotEmpty).toList();

      // Limit to maxKeywords
      final limitedKeywords = keywords.take(maxKeywords).toList();

      setState(() {
        _keywords = limitedKeywords;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _keywords = ['Error extracting keywords: $e'];
        _loading = false;
      });
    }
  }

  void _copyKeyword(String keyword) {
    Clipboard.setData(ClipboardData(text: keyword));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $keyword')),
    );
  }

  void _copyAllKeywords() {
    if (_keywords.isEmpty) return;

    final allKeywords = _keywords.join(', ');
    Clipboard.setData(ClipboardData(text: allKeywords));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All keywords copied to clipboard')),
    );
  }

  void _shareKeywords() {
    if (_keywords.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Share Keywords'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Export format:'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _exportAsCSV(),
                      child: const Text('CSV'),
                    ),
                    ElevatedButton(
                      onPressed: () => _exportAsJSON(),
                      child: const Text('JSON'),
                    ),
                    ElevatedButton(
                      onPressed: () => _exportAsText(),
                      child: const Text('Text'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _exportKeywords() {
    // Export implementation would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _exportAsCSV() {
    // CSV export implementation
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV export coming soon')),
    );
  }

  void _exportAsJSON() {
    // JSON export implementation
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON export coming soon')),
    );
  }

  void _exportAsText() {
    // Text export implementation
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text export coming soon')),
    );
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _keywords = [];
      _originalText = '';
      _wordCount = 0;
      _uniqueWords = 0;
      _keywordDensity = 0;
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keyword Extractor Info'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This tool uses Classical AI techniques:'),
                SizedBox(height: 8),
                Text('• TF-IDF inspired algorithm'),
                Text('• Frequency analysis'),
                Text('• Stop word filtering'),
                Text('• Statistical ranking'),
                SizedBox(height: 16),
                Text('Extraction Process:'),
                Text('1. Tokenize text into words'),
                Text('2. Remove common stop words'),
                Text('3. Calculate word frequencies'),
                Text('4. Score based on frequency and length'),
                Text('5. Rank and extract top keywords'),
                SizedBox(height: 16),
                Text(
                    'Best for: SEO analysis, content summarization, topic identification'),
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
    _keywordCountController.dispose();
    super.dispose();
  }
}