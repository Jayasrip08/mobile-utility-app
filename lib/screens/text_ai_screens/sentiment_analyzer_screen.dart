import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../services/ai_executor.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/tool_scaffold.dart';

class SentimentAnalyzerScreen extends StatefulWidget {
  const SentimentAnalyzerScreen({super.key});

  @override
  State<SentimentAnalyzerScreen> createState() =>
      _SentimentAnalyzerScreenState();
}

class _SentimentAnalyzerScreenState extends State<SentimentAnalyzerScreen> {
  final TextEditingController _textController = TextEditingController();
  Map<String, dynamic> _sentiment = {};
  Map<String, dynamic> _advancedAnalysis = {};
  bool _loading = false;
  bool _advancedMode = false;
  String _originalText = '';

  // Chart data
  List<SentimentData> _sentimentData = [];
  List<EmotionData> _emotionData = [];

  @override
  Widget build(BuildContext context) {
    final hasSentiment = _sentiment.isNotEmpty;
    final hasAdvanced = _advancedAnalysis.isNotEmpty && _advancedMode;
    final sentiment = _sentiment['sentiment']?.toString() ?? 'neutral';
    final score = double.tryParse(_sentiment['score']?.toString() ?? '0') ?? 0;
    final confidence =
        double.tryParse(_sentiment['confidence']?.toString() ?? '0') ?? 0;

    return ToolScaffold(
      title: 'Sentiment Analyzer',
      actions: [
        IconButton(
          icon: Icon(_advancedMode ? Icons.analytics : Icons.analytics_outlined),
          onPressed: _toggleAdvancedMode,
          tooltip: 'Toggle Advanced Mode',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfo,
        ),
      ],
      child: Column(
        children: [
          // Sentiment Result Card
          if (hasSentiment) ...[
            ThemedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildSentimentIcon(sentiment),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getSentimentTitle(sentiment),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _sentiment['analysis']?.toString() ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildScoreCard('Score', score.toStringAsFixed(3),
                          _getScoreColor(score)),
                      const SizedBox(width: 8),
                      _buildScoreCard(
                        'Confidence',
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        _getConfidenceColor(confidence),
                      ),
                      const SizedBox(width: 8),
                      _buildScoreCard(
                        'Magnitude',
                        _sentiment['magnitude']?.toString() ?? '0',
                        _getMagnitudeColor(double.tryParse(
                                _sentiment['magnitude']?.toString() ?? '0') ??
                            0),
                      ),
                      const SizedBox(width: 8),
                      _buildScoreCard(
                        'Words',
                        _sentiment['wordCount']?.toString() ?? '0',
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Charts (if advanced mode)
          if (hasAdvanced) ...[
            ThemedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sentiment Analysis Charts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        // Sentiment Distribution
                        Expanded(
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            series: <CartesianSeries<dynamic, String>>[
                              ColumnSeries<SentimentData, String>(
                                dataSource: _sentimentData,
                                xValueMapper: (SentimentData data, _) =>
                                    data.category,
                                yValueMapper: (SentimentData data, _) =>
                                    data.value,
                                color: Colors.blue,
                                dataLabelSettings:
                                    const DataLabelSettings(isVisible: true),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Emotion Distribution
                        Expanded(
                          child: SfCircularChart(
                            series: <CircularSeries<dynamic, String>>[
                              PieSeries<EmotionData, String>(
                                dataSource: _emotionData,
                                xValueMapper: (EmotionData data, _) =>
                                    data.emotion,
                                yValueMapper: (EmotionData data, _) =>
                                    data.value,
                                dataLabelSettings:
                                    const DataLabelSettings(isVisible: true),
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
            const SizedBox(height: 16),
          ],

          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Input Panel
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
                                'Text to Analyze',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (hasSentiment)
                                Chip(
                                  label: Text(sentiment.toUpperCase()),
                                  backgroundColor: _getSentimentColor(sentiment),
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
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
                                hintText: 'Enter text to analyze sentiment...',
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
                                      : _analyzeSentiment,
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
                                      : const Text('Analyze Sentiment'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _textController.text.isEmpty
                                    ? null
                                    : _clearText,
                                child: const Text('Clear'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _loadSampleText,
                                icon: const Icon(Icons.text_snippet),
                                tooltip: 'Load Sample',
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
                            const Icon(Icons.psychology,
                                color: Colors.purple, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _advancedMode
                                  ? 'Advanced Analysis'
                                  : 'Sentiment Results',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (hasSentiment)
                              IconButton(
                                onPressed: _showDetailedAnalysis,
                                icon: const Icon(Icons.open_in_full),
                                tooltip: 'Detailed Analysis',
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (hasAdvanced && _advancedMode)
                          _buildAdvancedResults()
                        else if (hasSentiment)
                          _buildBasicResults()
                        else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sentiment_neutral,
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
                                  'Enter text and click "Analyze" to see sentiment',
                                  style: TextStyle(
                                      color: const Color(0xFF9E9E9E)),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        if (hasSentiment) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _copyAnalysis,
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy Analysis'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _showWordAnalysis,
                                icon: const Icon(Icons.list, size: 16),
                                label: const Text('Word Analysis'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Word Lists (if available)
                  if (hasSentiment &&
                      ((_sentiment['positiveWords'] as List?)?.isNotEmpty ==
                              true ||
                          (_sentiment['negativeWords'] as List?)?.isNotEmpty ==
                              true)) ...[
                    const SizedBox(height: 16),
                    ThemedCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sentiment Words',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Positive Words
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.add_circle,
                                            color: Colors.green, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Positive Words (${(_sentiment['positiveWords'] as List?)?.length ?? 0})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: ((_sentiment['positiveWords']
                                                  as List?) ??
                                              [])
                                          .map<Widget>((word) => Chip(
                                                label: Text(word.toString()),
                                                backgroundColor:
                                                    const Color(0xFFE8F5E9),
                                                side: const BorderSide(
                                                    color: Color(0xFFC8E6C9)),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Negative Words
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.remove_circle,
                                            color: Colors.red, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Negative Words (${(_sentiment['negativeWords'] as List?)?.length ?? 0})',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: ((_sentiment['negativeWords']
                                                  as List?) ??
                                              [])
                                          .map<Widget>((word) => Chip(
                                                label: Text(word.toString()),
                                                backgroundColor:
                                                    const Color(0xFFFFEBEE),
                                                side: const BorderSide(
                                                    color: Color(0xFFFFCDD2)),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildSentimentIcon(String sentiment) {
    IconData icon;
    Color color;

    if (sentiment.contains('positive')) {
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (sentiment.contains('negative')) {
      icon = Icons.sentiment_very_dissatisfied;
      color = Colors.red;
    } else {
      icon = Icons.sentiment_neutral;
      color = Colors.blue;
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color, size: 32),
    );
  }

  String _getSentimentTitle(String sentiment) {
    if (sentiment.contains('strongly positive')) return 'Strongly Positive';
    if (sentiment.contains('positive')) return 'Positive';
    if (sentiment.contains('strongly negative')) return 'Strongly Negative';
    if (sentiment.contains('negative')) return 'Negative';
    return 'Neutral';
  }

  Color _getSentimentColor(String sentiment) {
    if (sentiment.contains('strongly positive')) return Colors.green;
    if (sentiment.contains('positive')) return Colors.lightGreen;
    if (sentiment.contains('neutral')) return Colors.blue;
    if (sentiment.contains('negative')) return Colors.orange;
    return Colors.red;
  }

  Widget _buildScoreCard(String label, String value, Color color) {
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

  Color _getScoreColor(double score) {
    if (score > 0.1) return Colors.green;
    if (score < -0.1) return Colors.red;
    return Colors.blue;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getMagnitudeColor(double magnitude) {
    if (magnitude > 0.3) return Colors.red;
    if (magnitude > 0.1) return Colors.orange;
    return Colors.green;
  }

  Widget _buildBasicResults() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sentiment Analysis:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(_sentiment['analysis']?.toString() ?? ''),
          const SizedBox(height: 16),
          const Text(
            'Statistics:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildResultRow(
              'Sentiment Score', _sentiment['score']?.toString() ?? '0'),
          _buildResultRow('Confidence', '${_sentiment['confidence']}'),
          _buildResultRow(
              'Magnitude', _sentiment['magnitude']?.toString() ?? '0'),
          _buildResultRow(
              'Word Count', _sentiment['wordCount']?.toString() ?? '0'),
          _buildResultRow(
              'Positive Words', _sentiment['positiveCount']?.toString() ?? '0'),
          _buildResultRow(
              'Negative Words', _sentiment['negativeCount']?.toString() ?? '0'),
          _buildResultRow(
              'Neutral Words', _sentiment['neutralCount']?.toString() ?? '0'),
          _buildResultRow(
              'Positive Ratio', _sentiment['positiveRatio']?.toString() ?? '0'),
          _buildResultRow(
              'Negative Ratio', _sentiment['negativeRatio']?.toString() ?? '0'),
        ],
      ),
    );
  }

  Widget _buildAdvancedResults() {
    if (_advancedAnalysis.isEmpty) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Sentiment
          const Text(
            'Overall Sentiment:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '${_advancedAnalysis['overallSentiment']} (Score: ${_advancedAnalysis['overallScore']})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Sentence Analysis
          const Text(
            'Sentence-by-Sentence Analysis:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...((_advancedAnalysis['sentences'] as List?) ?? []).map((sentence) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  (sentence['sentence']?.toString().length ?? 0) > 100
                      ? '${sentence['sentence']?.toString().substring(0, 100)}...'
                      : sentence['sentence']?.toString() ?? '',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  'Sentiment: ${sentence['sentiment']} (Score: ${sentence['score']})',
                  style: TextStyle(
                    color: _getSentimentColor(
                        sentence['sentiment']?.toString() ?? 'neutral'),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: _getSentimentColor(
                      sentence['sentiment']?.toString() ?? 'neutral'),
                  child: Text(
                    (sentence['index'] ?? 0).toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Additional Stats
          if (_advancedAnalysis.containsKey('sentimentTrend')) ...[
            const Text(
              'Sentiment Trend:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                  _advancedAnalysis['sentimentTrend']?.toString() ?? 'stable'),
              backgroundColor:
                  _advancedAnalysis['sentimentTrend'] == 'improving'
                      ? const Color(0xFFE8F5E9)
                      : _advancedAnalysis['sentimentTrend'] == 'declining'
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE3F2FD),
            ),
          ],

          if (_advancedAnalysis.containsKey('keyPhrases')) ...[
            const SizedBox(height: 16),
            const Text(
              'Key Phrases:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ((_advancedAnalysis['keyPhrases'] as List?) ?? [])
                  .map<Widget>((phrase) => Chip(
                        label: Text(phrase.toString()),
                        backgroundColor: Colors.purple.shade50,
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
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

  Future<void> _analyzeSentiment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _originalText = text;
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Sentiment Analyzer',
        module: 'Text AI',
        input: text,
      );

      // If in advanced mode, get advanced analysis too
      if (_advancedMode) {
        final advancedResult = await AIExecutor.runTool(
          toolName: 'Sentiment Analyzer',
          module: 'Text AI',
          input: {
            'text': text,
            'mode': 'advanced',
          },
        );

        setState(() {
          _advancedAnalysis = advancedResult;

          // Prepare chart data
          if (advancedResult.containsKey('emotionDistribution')) {
            final distribution =
                advancedResult['emotionDistribution'] as Map<String, dynamic>;
            _sentimentData = distribution.entries
                .map((e) => SentimentData(e.key, e.value.toDouble()))
                .toList();
          }

          // Prepare emotion data (simplified)
          _emotionData = [
            EmotionData('Positive', 35),
            EmotionData('Negative', 25),
            EmotionData('Neutral', 40),
          ];
        });
      }

      setState(() {
        _sentiment = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _sentiment = {'error': 'Error analyzing sentiment: $e'};
        _loading = false;
      });
    }
  }

  void _toggleAdvancedMode() {
    setState(() {
      _advancedMode = !_advancedMode;
      if (_advancedMode && _originalText.isNotEmpty) {
        _analyzeSentiment(); // Re-analyze with advanced mode
      }
    });
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
                'Detailed Sentiment Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_sentiment.isNotEmpty) ...[
                _buildDetailRow('Overall Sentiment',
                    _sentiment['sentiment']?.toString() ?? 'neutral'),
                _buildDetailRow(
                    'Sentiment Score', _sentiment['score']?.toString() ?? '0'),
                _buildDetailRow(
                    'Analysis Confidence', '${_sentiment['confidence']}'),
                _buildDetailRow('Sentiment Magnitude',
                    _sentiment['magnitude']?.toString() ?? '0'),
                const Divider(),
                _buildDetailRow(
                    'Total Words', _sentiment['wordCount']?.toString() ?? '0'),
                _buildDetailRow('Positive Words',
                    _sentiment['positiveCount']?.toString() ?? '0'),
                _buildDetailRow('Negative Words',
                    _sentiment['negativeCount']?.toString() ?? '0'),
                _buildDetailRow('Neutral Words',
                    _sentiment['neutralCount']?.toString() ?? '0'),
                _buildDetailRow(
                    'Positive Ratio', '${_sentiment['positiveRatio']}%'),
                _buildDetailRow(
                    'Negative Ratio', '${_sentiment['negativeRatio']}%'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _copyAnalysis() {
    if (_sentiment.isEmpty) return;

    final analysisText = '''
Sentiment Analysis:
Overall: ${_sentiment['sentiment']}
Score: ${_sentiment['score']}
Confidence: ${_sentiment['confidence']}
Analysis: ${_sentiment['analysis']}

Statistics:
Total Words: ${_sentiment['wordCount']}
Positive Words: ${_sentiment['positiveCount']}
Negative Words: ${_sentiment['negativeCount']}
Positive Ratio: ${_sentiment['positiveRatio']}%
Negative Ratio: ${_sentiment['negativeRatio']}%
''';

    Clipboard.setData(ClipboardData(text: analysisText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analysis copied to clipboard')),
    );
  }

  void _showWordAnalysis() {
    if (_sentiment.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Word-Level Analysis'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((_sentiment['positiveWords'] as List?)?.isNotEmpty ==
                    true) ...[
                  const Text(
                    'Positive Words Found:',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: ((_sentiment['positiveWords'] as List?) ?? [])
                        .map<Widget>((word) => Chip(
                              label: Text(word.toString()),
                              backgroundColor: const Color(0xFFE8F5E9),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if ((_sentiment['negativeWords'] as List?)?.isNotEmpty ==
                    true) ...[
                  const Text(
                    'Negative Words Found:',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: ((_sentiment['negativeWords'] as List?) ?? [])
                        .map<Widget>((word) => Chip(
                              label: Text(word.toString()),
                              backgroundColor: const Color(0xFFFFEBEE),
                            ))
                        .toList(),
                  ),
                ],
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

  void _clearText() {
    setState(() {
      _textController.clear();
      _sentiment = {};
      _advancedAnalysis = {};
      _sentimentData = [];
      _emotionData = [];
      _originalText = '';
    });
  }

  void _loadSampleText() {
    const sampleText = '''
I absolutely love this product! It's amazing and works perfectly. 
The quality is excellent and I'm very satisfied with my purchase.
The customer service was also fantastic and very helpful.
However, the delivery took a bit longer than expected.
Overall, I'm extremely happy and would highly recommend it!
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
          title: const Text('Sentiment Analyzer Info'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'This sentiment analyzer uses Classical AI techniques:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInfoItem('• Lexicon-based analysis with weighted words'),
                _buildInfoItem('• Rule-based context and negation handling'),
                _buildInfoItem('• Intensifier and diminisher modifiers'),
                _buildInfoItem('• Sentence-level sentiment tracking'),
                const SizedBox(height: 16),
                const Text(
                  'Sentiment Categories:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSentimentIndicator(
                        'Strongly Positive', const Color(0xFF1B5E20)),
                    _buildSentimentIndicator('Positive', Colors.green),
                    _buildSentimentIndicator('Neutral', Colors.blue),
                    _buildSentimentIndicator('Negative', Colors.orange),
                    _buildSentimentIndicator(
                        'Strongly Negative', const Color(0xFFB71C1C)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Advanced Mode Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInfoItem('• Emotion distribution charts'),
                _buildInfoItem('• Sentiment trend analysis'),
                _buildInfoItem('• Key phrase extraction'),
                _buildInfoItem('• Sentence-by-sentence breakdown'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tip:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For best results, use complete sentences and avoid ambiguous phrases.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
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

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildSentimentIndicator(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.split(' ')[0],
            style: TextStyle(
              fontSize: 8,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

// Chart Data Classes
class SentimentData {
  final String category;
  final double value;

  SentimentData(this.category, this.value);
}

class EmotionData {
  final String emotion;
  final double value;

  EmotionData(this.emotion, this.value);
}