import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/tool_scaffold.dart';

class SentenceCounterScreen extends StatefulWidget {
  const SentenceCounterScreen({super.key});

  @override
  State<SentenceCounterScreen> createState() => _SentenceCounterScreenState();
}

class _SentenceCounterScreenState extends State<SentenceCounterScreen> {
  final TextEditingController _textController = TextEditingController();
  Map<String, dynamic> _analysis = {};
  bool _loading = false;
  List<String> _sentences = [];

  @override
  Widget build(BuildContext context) {
    return ToolScaffold(
      title: 'Sentence Counter',
      actions: [
        IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: _analysis.isNotEmpty ? _showDetailedAnalysis : null,
          tooltip: 'Detailed Analysis',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfo,
        ),
      ],
      child: Column(
        children: [
          // Analysis Summary
          if (_analysis.isNotEmpty) ...[
            ThemedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sentence Analysis Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildAnalysisChip(
                        'Sentences',
                        _analysis['sentenceCount']?.toString() ?? '0',
                        Colors.blue,
                      ),
                      _buildAnalysisChip(
                        'Avg. Words/Sentence',
                        _analysis['avgWordsPerSentence']?.toString() ?? '0',
                        Colors.green,
                      ),
                      _buildAnalysisChip(
                        'Complexity',
                        _analysis['sentenceComplexity']?.toString() ?? 'N/A',
                        Colors.orange,
                      ),
                      if (_analysis.containsKey('shortestSentence'))
                        _buildAnalysisChip(
                          'Shortest',
                          '${_analysis['shortestSentence']?.toString().split(' ').length ?? 0} words',
                          Colors.purple,
                        ),
                      if (_analysis.containsKey('longestSentence'))
                        _buildAnalysisChip(
                          'Longest',
                          '${_analysis['longestSentence']?.toString().split(' ').length ?? 0} words',
                          Colors.red,
                        ),
                    ],
                  ),
                  if (_analysis.containsKey('structureAnalysis')) ...[
                    const SizedBox(height: 12),
                    Text(
                      _analysis['structureAnalysis']?.toString() ?? '',
                      style: TextStyle(
                        color: const Color(0xFF616161),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Input Section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Text Input
                  SizedBox(
                    height: 250,
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
                              if (_analysis.isNotEmpty)
                                Text(
                                  '${_analysis['sentenceCount'] ?? 0} sentences',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                hintText:
                                    'Enter text to analyze sentence structure...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.all(12),
                              ),
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
                                      : _analyzeSentences,
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
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text('Analyze Sentences'),
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

                  // Sentences List
                  ThemedCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.format_list_numbered,
                                color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Detected Sentences',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_sentences.isNotEmpty)
                              Chip(
                                label: Text('${_sentences.length}'),
                                backgroundColor: const Color(0xFFE3F2FD),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_sentences.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.short_text,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Sentences Detected',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter text to see sentence breakdown',
                                  style: TextStyle(
                                      color: const Color(0xFF9E9E9E)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _sentences.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 8),
                            itemBuilder: (context, index) {
                              final sentence = _sentences[index];
                              final wordCount = sentence
                                  .split(' ')
                                  .where((w) => w.isNotEmpty)
                                  .length;
                              final isComplex = wordCount > 20;

                              return Card(
                                margin: EdgeInsets.zero,
                                color: isComplex
                                    ? Colors.orange.shade50
                                    : const Color(0xFFE8F5E9),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isComplex
                                        ? Colors.orange
                                        : Colors.green,
                                    child: Text(
                                      (index + 1).toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    sentence.length > 100
                                        ? '${sentence.substring(0, 100)}...'
                                        : sentence,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '$wordCount words',
                                    style: TextStyle(
                                      color: isComplex
                                          ? Colors.orange.shade800
                                          : const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Icon(
                                    isComplex
                                        ? Icons.warning
                                        : Icons.check_circle,
                                    color: isComplex
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Complexity Analysis
          if (_analysis.containsKey('wordCounts') &&
              (_analysis['wordCounts'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            ThemedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sentence Length Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _buildWordCountBars(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Short sentences (<10 words): ${_countShortSentences()}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        'Long sentences (>20 words): ${_countLongSentences()}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisChip(String label, String value, Color color) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  List<Widget> _buildWordCountBars() {
    final wordCounts =
        (_analysis['wordCounts'] as List<dynamic>?)?.cast<int>() ?? [];
    if (wordCounts.isEmpty) return [];

    final maxCount = wordCounts.reduce((a, b) => a > b ? a : b);

    return wordCounts.asMap().entries.map((entry) {
      final index = entry.key;
      final count = entry.value;
      final percentage = maxCount > 0 ? count / maxCount : 0;
      final isLong = count > 20;
      final isShort = count < 10;

      Color color;
      if (isLong) {
        color = Colors.orange;
      } else if (isShort) {
        color = Colors.green;
      } else {
        color = Colors.blue;
      }

      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          children: [
            Container(
              width: 20,
              height: (40 * percentage).toDouble(),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              (index + 1).toString(),
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      );
    }).toList();
  }

  int _countShortSentences() {
    final wordCounts =
        (_analysis['wordCounts'] as List<dynamic>?)?.cast<int>() ?? [];
    return wordCounts.where((count) => count < 10).length;
  }

  int _countLongSentences() {
    final wordCounts =
        (_analysis['wordCounts'] as List<dynamic>?)?.cast<int>() ?? [];
    return wordCounts.where((count) => count > 20).length;
  }

  Future<void> _analyzeSentences() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Sentence Counter',
        module: 'Text AI',
        input: text,
      );

      // Parse the result
      setState(() {
        _analysis = result;
        _sentences = _extractSentencesFromText(text);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _analysis = {'error': 'Error analyzing sentences: $e'};
        _loading = false;
      });
    }
  }

  List<String> _extractSentencesFromText(String text) {
    // Simple sentence extraction
    return text
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
  }

  void _showDetailedAnalysis() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detailed Sentence Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_analysis.containsKey('sentenceCount')) ...[
                _buildDetailRow(
                    'Total Sentences', _analysis['sentenceCount'].toString()),
                const Divider(),
              ],
              if (_analysis.containsKey('avgWordsPerSentence')) ...[
                _buildDetailRow('Average Words per Sentence',
                    _analysis['avgWordsPerSentence'].toString()),
                const Divider(),
              ],
              if (_analysis.containsKey('avgCharsPerSentence')) ...[
                _buildDetailRow('Average Characters per Sentence',
                    _analysis['avgCharsPerSentence'].toString()),
                const Divider(),
              ],
              if (_analysis.containsKey('sentenceComplexity')) ...[
                _buildDetailRow('Overall Complexity',
                    _analysis['sentenceComplexity'].toString()),
                const Divider(),
              ],
              if (_analysis.containsKey('shortestSentence')) ...[
                _buildDetailRow(
                  'Shortest Sentence',
                  '${_analysis['shortestSentence']} (${_analysis['shortestSentence']?.toString().split(' ').where((w) => w.isNotEmpty).length ?? 0} words)',
                  isMultiLine: true,
                ),
                const Divider(),
              ],
              if (_analysis.containsKey('longestSentence')) ...[
                _buildDetailRow(
                  'Longest Sentence',
                  '${_analysis['longestSentence']} (${_analysis['longestSentence']?.toString().split(' ').where((w) => w.isNotEmpty).length ?? 0} words)',
                  isMultiLine: true,
                ),
                const Divider(),
              ],
              if (_analysis.containsKey('structureAnalysis')) ...[
                _buildDetailRow(
                  'Structure Analysis',
                  _analysis['structureAnalysis'].toString(),
                  isMultiLine: true,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMultiLine ? 14 : 16,
            ),
            maxLines: isMultiLine ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _analysis = {};
      _sentences = [];
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sentence Counter Info'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'This tool uses Classical AI techniques for sentence analysis:'),
                SizedBox(height: 8),
                Text('• Rule-based sentence boundary detection'),
                Text('• Heuristic complexity analysis'),
                Text('• Pattern recognition for abbreviations'),
                Text('• Statistical sentence length analysis'),
                SizedBox(height: 16),
                Text('What it analyzes:'),
                Text('• Total sentence count'),
                Text('• Average words per sentence'),
                Text('• Sentence complexity (Low/Medium/High)'),
                Text('• Sentence structure variety'),
                Text('• Shortest and longest sentences'),
                SizedBox(height: 16),
                Text('Complexity is determined by:'),
                Text('• Sentence length (>25 words = complex)'),
                Text('• Multiple clauses'),
                Text('• Parentheses and semicolons'),
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