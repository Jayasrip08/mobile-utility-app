import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/ai_executor.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/tool_scaffold.dart';

class DuplicateSentenceDetectorScreen extends StatefulWidget {
  const DuplicateSentenceDetectorScreen({super.key});

  @override
  State<DuplicateSentenceDetectorScreen> createState() =>
      _DuplicateSentenceDetectorScreenState();
}

class _DuplicateSentenceDetectorScreenState
    extends State<DuplicateSentenceDetectorScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _similarityController =
      TextEditingController(text: '0.8');

  List<String> _duplicates = [];
  Map<String, dynamic> _analysis = {};
  bool _loading = false;
  String _originalText = '';
  String _highlightedText = '';

  // Display options
  bool _showHighlighted = true;
  double _similarityThreshold = 0.8;

  @override
  void initState() {
    super.initState();
    _similarityController.addListener(_updateThreshold);
  }

  @override
  Widget build(BuildContext context) {
    final hasDuplicates = _duplicates.isNotEmpty;
    final hasAnalysis = _analysis.isNotEmpty;
    final duplicateCount = _analysis['duplicateCount'] ?? 0;
    final totalSentences = _analysis['totalSentences'] ?? 0;
    final duplicatePercentage = _analysis['duplicatePercentage'] ?? '0';

    return ToolScaffold(
      title: 'Duplicate Sentence Detector',
      actions: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: _showSettings,
          tooltip: 'Settings',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfo,
        ),
      ],
      child: Column(
        children: [
          // Analysis Summary
          if (hasAnalysis) ...[
            ThemedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duplicate Analysis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildAnalysisCard(
                        'Sentences',
                        totalSentences.toString(),
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildAnalysisCard(
                        'Duplicates',
                        duplicateCount.toString(),
                        duplicateCount > 0 ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildAnalysisCard(
                        'Duplication',
                        '$duplicatePercentage%',
                        double.parse(duplicatePercentage) > 30
                            ? Colors.red
                            : double.parse(duplicatePercentage) > 10
                                ? Colors.orange
                                : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildAnalysisCard(
                        'Similarity',
                        '${(_similarityThreshold * 100).toInt()}%',
                        Colors.purple,
                      ),
                    ],
                  ),
                  if (_analysis.containsKey('recommendations')) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: duplicateCount > 0
                            ? Colors.orange.shade50
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: duplicateCount > 0
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                      child: Text(
                        _analysis['recommendations']?.toString() ?? '',
                        style: TextStyle(
                          color: duplicateCount > 0
                              ? Colors.orange.shade800
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
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
                  // Input/Output Panel
                  SizedBox(
                    height: 400,
                    child: ThemedCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _showHighlighted
                                    ? Icons.highlight
                                    : Icons.article,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _showHighlighted
                                    ? 'Highlighted Text'
                                    : 'Original Text',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              ToggleButtons(
                                isSelected: [
                                  _showHighlighted,
                                  !_showHighlighted
                                ],
                                onPressed: (index) {
                                  setState(() {
                                    _showHighlighted = index == 0;
                                  });
                                },
                                children: const [
                                  Tooltip(
                                    message: 'Show highlighted duplicates',
                                    child: Icon(Icons.highlight, size: 18),
                                  ),
                                  Tooltip(
                                    message: 'Show original text',
                                    child: Icon(Icons.article, size: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFE0E0E0)),
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFFFAFAFA),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _showHighlighted &&
                                          _highlightedText.isNotEmpty
                                      ? _highlightedText
                                      : _originalText,
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _textController.text.isEmpty || _loading
                                ? null
                                : _detectDuplicates,
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
                                : const Text('Detect Duplicate Sentences'),
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
                            const Icon(Icons.copy_all,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Duplicate Sentences',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (hasDuplicates)
                              Chip(
                                label: Text('$duplicateCount found'),
                                backgroundColor: const Color(0xFFFFEBEE),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (hasDuplicates)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _duplicates.length,
                            itemBuilder: (context, index) {
                              final duplicate = _duplicates[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: const Color(0xFFFFEBEE),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    child: Text(
                                      (index + 1).toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    duplicate.length > 100
                                        ? '${duplicate.substring(0, 100)}...'
                                        : duplicate,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.open_in_full,
                                        size: 18),
                                    onPressed: () =>
                                        _showSentenceDetails(duplicate),
                                  ),
                                ),
                              );
                            },
                          )
                        else if (hasAnalysis && duplicateCount == 0)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Duplicates Found!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'All $totalSentences sentences are unique',
                                  style: TextStyle(
                                      color: const Color(0xFF757575)),
                                ),
                              ],
                            ),
                          )
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Analysis Yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter text and click "Detect" to find duplicates',
                                  style: TextStyle(
                                      color: const Color(0xFF9E9E9E)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        if (hasDuplicates) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _copyDuplicates,
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy List'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showSimilarityMatrix,
                                icon: const Icon(Icons.grid_on, size: 16),
                                label: const Text('Similarity Matrix'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Input Section
                  const SizedBox(height: 16),
                  ThemedCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Input Text',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Enter or paste text to check for duplicate sentences...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _textController.text.isEmpty
                                    ? null
                                    : _clearText,
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _loadSampleText,
                                child: const Text('Load Sample'),
                              ),
                            ),
                          ],
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

  Widget _buildAnalysisCard(String label, String value, Color color) {
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
                fontSize: 10,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateThreshold() {
    final text = _similarityController.text;
    final value = double.tryParse(text);
    if (value != null && value >= 0 && value <= 1) {
      setState(() {
        _similarityThreshold = value;
      });
    }
  }

  Future<void> _detectDuplicates() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _originalText = text;
    });

    try {
      // First get duplicates
      final duplicates = await AIExecutor.runTool(
        toolName: 'Duplicate Sentence Detector',
        module: 'Text AI',
        input: {
          'text': text,
          'similarityThreshold': _similarityThreshold,
        },
      );

      // Then get analysis
      final analysis = await AIExecutor.runTool(
        toolName: 'Duplicate Sentence Detector',
        module: 'Text AI',
        input: {
          'text': text,
          'similarityThreshold': _similarityThreshold,
          'mode': 'analyze',
        },
      );

      // Highlight text
      final highlighted = _highlightDuplicates(text, duplicates);

      setState(() {
        _duplicates = List<String>.from(duplicates ?? []);
        _analysis = analysis ?? {};
        _highlightedText = highlighted;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _duplicates = ['Error detecting duplicates: $e'];
        _analysis = {'error': 'Error: $e'};
        _loading = false;
      });
    }
  }

  String _highlightDuplicates(String text, List<dynamic> duplicates) {
    String highlighted = text;

    for (var duplicate in duplicates) {
      final duplicateText = duplicate.toString();
      if (duplicateText.isNotEmpty) {
        // Simple highlighting - in real app use better pattern matching
        highlighted = highlighted.replaceAll(
          duplicateText,
          '⚠️$duplicateText⚠️',
        );
      }
    }

    return highlighted;
  }

  void _showSentenceDetails(String sentence) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Duplicate Sentence Details'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sentence:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(sentence),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Statistics:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Word Count',
                    sentence
                        .split(' ')
                        .where((w) => w.isNotEmpty)
                        .length
                        .toString(),
                  ),
                  _buildDetailRow(
                    'Character Count', sentence.length.toString()),
                  _buildDetailRow('Similarity Threshold',
                      '${(_similarityThreshold * 100).toInt()}%'),
                ],
              ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _copyDuplicates() {
    if (_duplicates.isEmpty) return;

    final duplicatesText = _duplicates.map((d) => '• $d').join('\n');
    Clipboard.setData(ClipboardData(text: duplicatesText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate list copied to clipboard')),
    );
  }

  void _showSimilarityMatrix() {
    if (!_analysis.containsKey('similarityMatrix')) return;

    final matrix = _analysis['similarityMatrix'] as List<List<double>>;
    final sentences = _extractSentences(_originalText);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                const Text(
                  'Sentence Similarity Matrix',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Numbers show similarity between sentences (0-1 scale)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          const DataColumn(label: Text('Sentences')),
                          for (int i = 0; i < sentences.length && i < 10; i++)
                            DataColumn(label: Text('S${i + 1}')),
                        ],
                        rows: [
                          for (int i = 0; i < sentences.length && i < 10; i++)
                            DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      'S${i + 1}: ${sentences[i].length > 30 ? '${sentences[i].substring(0, 30)}...' : sentences[i]}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                for (int j = 0;
                                    j < sentences.length && j < 10;
                                    j++)
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            _getSimilarityColor(matrix[i][j]),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        matrix[i][j].toStringAsFixed(2),
                                        style: TextStyle(
                                          color: matrix[i][j] > 0.5
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Showing first 10 of ${sentences.length} sentences',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSimilarityColor(double similarity) {
    if (similarity > 0.8) return Colors.red;
    if (similarity > 0.6) return Colors.orange;
    if (similarity > 0.4) return Colors.yellow;
    if (similarity > 0.2) return const Color(0xFFBBDEFB);
    return const Color(0xFFF5F5F5);
  }

  List<String> _extractSentences(String text) {
    return text
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Detection Settings'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Similarity Threshold:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _similarityThreshold,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(_similarityThreshold * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      _similarityThreshold = value;
                      _similarityController.text = value.toStringAsFixed(1);
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Higher threshold = fewer but more exact duplicates',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lower threshold = more but less similar duplicates',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                if (_originalText.isNotEmpty) {
                  _detectDuplicates();
                }
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      _duplicates = [];
      _analysis = {};
      _originalText = '';
      _highlightedText = '';
    });
  }

  void _loadSampleText() {
    const sampleText = '''
This is a sample text. This text contains duplicate sentences. 
This is a sample text. Duplicate sentences can be detected.
The tool finds exact matches. The tool finds exact matches.
It also finds similar sentences. It also finds similar sentences.
Each sentence is analyzed. Duplicate detection is useful.
This is a sample text. Let's test the duplicate detector.
''';

    setState(() {
      _textController.text = sampleText;
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Duplicate Sentence Detector Info'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This tool uses Classical AI techniques:'),
                SizedBox(height: 8),
                Text('• Cosine similarity algorithm'),
                Text('• Sentence vectorization'),
                Text('• Pattern matching for exact duplicates'),
                Text('• Statistical similarity analysis'),
                SizedBox(height: 16),
                Text('Detection Modes:'),
                Text('• Exact duplicates (100% match)'),
                Text('• Similar sentences (configurable threshold)'),
                Text('• Near duplicates (70-99% similarity)'),
                SizedBox(height: 16),
                Text('Uses:'),
                Text('• Improving writing quality'),
                Text('• Reducing redundancy'),
                Text('• Content optimization'),
                Text('• Plagiarism prevention'),
                SizedBox(height: 16),
                Text('Similarity Threshold:'),
                Text('0.9 = Very strict (only near-exact matches)'),
                Text('0.7 = Moderate (similar sentences)'),
                Text('0.5 = Lenient (somewhat similar sentences)'),
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
    _similarityController.dispose();
    super.dispose();
  }
}