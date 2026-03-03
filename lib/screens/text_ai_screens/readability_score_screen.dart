import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../services/ai_executor.dart';
import '../../widgets/themed_card.dart';
import '../../widgets/tool_scaffold.dart';

class ReadabilityScoreScreen extends StatefulWidget {
  const ReadabilityScoreScreen({super.key});

  @override
  State<ReadabilityScoreScreen> createState() => _ReadabilityScoreScreenState();
}

class _ReadabilityScoreScreenState extends State<ReadabilityScoreScreen> {
  final TextEditingController _textController = TextEditingController();
  Map<String, dynamic> _scores = {};
  bool _loading = false;

  // Selected score for gauge display
  String _selectedScore = 'fleschReadingEase';

  @override
  Widget build(BuildContext context) {
    final hasScores = _scores.isNotEmpty && !_scores.containsKey('error');

    return ToolScaffold(
      title: 'Readability Score',
      actions: [
        IconButton(
          icon: const Icon(Icons.compare),
          onPressed: hasScores ? _compareScores : null,
          tooltip: 'Compare Scores',
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: _showInfo,
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Score Gauge
            if (hasScores) ...[
              ThemedCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Readability Score',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: _selectedScore,
                          items: [
                            _buildDropdownItem(
                                'Flesch Reading Ease', 'fleschReadingEase'),
                            _buildDropdownItem(
                                'Flesch-Kincaid Grade', 'fleschKincaidGrade'),
                            _buildDropdownItem(
                                'Gunning Fog Index', 'gunningFog'),
                            _buildDropdownItem('SMOG Index', 'smogIndex'),
                            _buildDropdownItem(
                                'Coleman-Liau Index', 'colemanLiau'),
                            _buildDropdownItem('Automated Readability',
                                'automatedReadability'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedScore = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildReadabilityGauge(),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _getScoreDescription(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _getScoreColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Score Grid
            if (hasScores) ...[
              ThemedCard(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildScoreCard(
                      'Flesch Reading Ease',
                      _scores['fleschReadingEase']?.toString() ?? 'N/A',
                      _getFleschColor(double.tryParse(
                              _scores['fleschReadingEase']?.toString() ??
                                  '0') ??
                          0),
                    ),
                    _buildScoreCard(
                      'Flesch-Kincaid Grade',
                      _scores['fleschKincaidGrade']?.toString() ?? 'N/A',
                      _getGradeColor(double.tryParse(
                              _scores['fleschKincaidGrade']?.toString() ??
                                  '0') ??
                          0),
                    ),
                    _buildScoreCard(
                      'Gunning Fog',
                      _scores['gunningFog']?.toString() ?? 'N/A',
                      _getFogColor(double.tryParse(
                              _scores['gunningFog']?.toString() ?? '0') ??
                          0),
                    ),
                    _buildScoreCard(
                      'SMOG Index',
                      _scores['smogIndex']?.toString() ?? 'N/A',
                      _getSmogColor(double.tryParse(
                              _scores['smogIndex']?.toString() ?? '0') ??
                          0),
                    ),
                    _buildScoreCard(
                      'Coleman-Liau',
                      _scores['colemanLiau']?.toString() ?? 'N/A',
                      _getColemanColor(double.tryParse(
                              _scores['colemanLiau']?.toString() ?? '0') ??
                          0),
                    ),
                    _buildScoreCard(
                      'Automated Readability',
                      _scores['automatedReadability']?.toString() ?? 'N/A',
                      _getARIColor(double.tryParse(
                              _scores['automatedReadability']?.toString() ??
                                  '0') ??
                          0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Input Section
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
                          'Text to Analyze',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_scores.isNotEmpty)
                          Chip(
                            label: Text(
                              _scores['overallReadability']?.toString() ??
                                  'N/A',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: _getOverallColor(),
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
                          hintText: 'Enter text to analyze readability...',
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
                            onPressed:
                                _textController.text.isEmpty || _loading
                                    ? null
                                    : _calculateReadability,
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
                                : const Text('Calculate Readability'),
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
                          onPressed: hasScores ? _showDetailedStats : null,
                          icon: const Icon(Icons.insights),
                          tooltip: 'Detailed Statistics',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Text Statistics
            if (hasScores && _scores.containsKey('wordCount')) ...[
              const SizedBox(height: 16),
              ThemedCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Text Statistics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _buildStatChip('Words: ${_scores['wordCount']}'),
                        _buildStatChip(
                            'Sentences: ${_scores['sentenceCount']}'),
                        _buildStatChip(
                            'Avg Words/Sentence: ${_scores['avgWordsPerSentence']}'),
                        _buildStatChip(
                            'Avg Syllables/Word: ${_scores['avgSyllablesPerWord']}'),
                        _buildStatChip(
                            'Complex Words: ${_scores['complexWordPercentage']}%'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String text, String value) {
    return DropdownMenuItem(
      value: value,
      child: Text(text),
    );
  }

  Widget _buildReadabilityGauge() {
    final score =
        double.tryParse(_scores[_selectedScore]?.toString() ?? '0') ?? 0;
    final minMax = _getScoreRange(_selectedScore);
    final min = minMax['min'] ?? 0;
    final max = minMax['max'] ?? 100;
    final ranges = _getGaugeRanges(_selectedScore);

    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: min,
          maximum: max,
          ranges: ranges,
          pointers: <GaugePointer>[
            NeedlePointer(
              value: score,
              enableAnimation: true,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getScoreLabel(_selectedScore),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    );
  }

  List<GaugeRange> _getGaugeRanges(String scoreType) {
    switch (scoreType) {
      case 'fleschReadingEase':
        return [
          GaugeRange(startValue: 0, endValue: 30, color: Colors.red),
          GaugeRange(startValue: 30, endValue: 50, color: Colors.orange),
          GaugeRange(startValue: 50, endValue: 60, color: Colors.yellow),
          GaugeRange(startValue: 60, endValue: 70, color: Colors.lightGreen),
          GaugeRange(startValue: 70, endValue: 80, color: Colors.green),
          GaugeRange(startValue: 80, endValue: 90, color: Colors.lightGreen),
          GaugeRange(startValue: 90, endValue: 100, color: Colors.blue),
        ];
      case 'fleschKincaidGrade':
      case 'gunningFog':
      case 'smogIndex':
      case 'colemanLiau':
      case 'automatedReadability':
        return [
          GaugeRange(startValue: 0, endValue: 6, color: Colors.green),
          GaugeRange(startValue: 6, endValue: 9, color: Colors.lightGreen),
          GaugeRange(startValue: 9, endValue: 12, color: Colors.yellow),
          GaugeRange(startValue: 12, endValue: 16, color: Colors.orange),
          GaugeRange(startValue: 16, endValue: 20, color: Colors.red),
        ];
      default:
        return [
          GaugeRange(startValue: 0, endValue: 50, color: Colors.red),
          GaugeRange(startValue: 50, endValue: 100, color: Colors.green),
        ];
    }
  }

  Map<String, double> _getScoreRange(String scoreType) {
    switch (scoreType) {
      case 'fleschReadingEase':
        return {'min': 0, 'max': 100};
      case 'fleschKincaidGrade':
        return {'min': 0, 'max': 20};
      case 'gunningFog':
        return {'min': 0, 'max': 20};
      case 'smogIndex':
        return {'min': 0, 'max': 20};
      case 'colemanLiau':
        return {'min': 0, 'max': 20};
      case 'automatedReadability':
        return {'min': 0, 'max': 20};
      default:
        return {'min': 0, 'max': 100};
    }
  }

  String _getScoreLabel(String scoreType) {
    switch (scoreType) {
      case 'fleschReadingEase':
        return 'Reading Ease';
      case 'fleschKincaidGrade':
        return 'Grade Level';
      case 'gunningFog':
        return 'Fog Index';
      case 'smogIndex':
        return 'SMOG Index';
      case 'colemanLiau':
        return 'Coleman-Liau';
      case 'automatedReadability':
        return 'ARI';
      default:
        return 'Score';
    }
  }

  String _getScoreDescription() {
    if (_selectedScore == 'fleschReadingEase') {
      final score =
          double.tryParse(_scores[_selectedScore]?.toString() ?? '0') ?? 0;
      if (score >= 90) return 'Very Easy (5th grade)';
      if (score >= 80) return 'Easy (6th grade)';
      if (score >= 70) return 'Fairly Easy (7th grade)';
      if (score >= 60) return 'Standard (8th-9th grade)';
      if (score >= 50) return 'Fairly Difficult (10th-12th grade)';
      if (score >= 30) return 'Difficult (College)';
      return 'Very Difficult (College graduate)';
    } else {
      final score =
          double.tryParse(_scores[_selectedScore]?.toString() ?? '0') ?? 0;
      if (score <= 6) return 'Easy (Elementary School)';
      if (score <= 9) return 'Standard (Middle School)';
      if (score <= 12) return 'Difficult (High School)';
      if (score <= 16) return 'Very Difficult (College)';
      return 'Extremely Difficult (Graduate Level)';
    }
  }

  Color _getScoreColor() {
    final score =
        double.tryParse(_scores[_selectedScore]?.toString() ?? '0') ?? 0;

    if (_selectedScore == 'fleschReadingEase') {
      return _getFleschColor(score);
    } else {
      return _getGradeColor(score);
    }
  }

  Color _getFleschColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 50) return Colors.yellow;
    if (score >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getGradeColor(double score) {
    if (score <= 6) return Colors.green;
    if (score <= 9) return Colors.lightGreen;
    if (score <= 12) return Colors.yellow;
    if (score <= 16) return Colors.orange;
    return Colors.red;
  }

  Color _getFogColor(double score) => _getGradeColor(score);
  Color _getSmogColor(double score) => _getGradeColor(score);
  Color _getColemanColor(double score) => _getGradeColor(score);
  Color _getARIColor(double score) => _getGradeColor(score);

  Color _getOverallColor() {
    final readability = _scores['overallReadability']?.toString() ?? '';
    if (readability.contains('Very Easy') || readability.contains('Easy')) {
      return Colors.green;
    } else if (readability.contains('Standard') ||
        readability.contains('Fairly')) {
      return Colors.blue;
    } else if (readability.contains('Difficult')) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Widget _buildScoreCard(String title, String score, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
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

  Future<void> _calculateReadability() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Readability Score',
        module: 'Text AI',
        input: text,
      );

      setState(() {
        _scores = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _scores = {'error': 'Error calculating readability: $e'};
        _loading = false;
      });
    }
  }

  void _compareScores() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Readability Scores Comparison'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildComparisonRow('Flesch Reading Ease',
                      _scores['fleschReadingEase'], 'Higher = easier'),
                  _buildComparisonRow('Flesch-Kincaid Grade',
                      _scores['fleschKincaidGrade'], 'Years of education'),
                  _buildComparisonRow('Gunning Fog Index',
                      _scores['gunningFog'], 'Years of education'),
                  _buildComparisonRow(
                      'SMOG Index', _scores['smogIndex'], 'Years of education'),
                  _buildComparisonRow('Coleman-Liau Index',
                      _scores['colemanLiau'], 'US grade level'),
                  _buildComparisonRow('Automated Readability',
                      _scores['automatedReadability'], 'US grade level'),
                  const Divider(),
                  _buildComparisonRow('Overall Readability',
                      _scores['overallReadability'], 'Based on Flesch'),
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

  Widget _buildComparisonRow(String metric, dynamic value, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedStats() {
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
                'Detailed Text Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_scores.containsKey('wordCount')) ...[
                _buildStatDetail('Word Count', _scores['wordCount'].toString()),
                _buildStatDetail(
                    'Sentence Count', _scores['sentenceCount'].toString()),
                _buildStatDetail('Average Words per Sentence',
                    _scores['avgWordsPerSentence'].toString()),
                _buildStatDetail('Average Syllables per Word',
                    _scores['avgSyllablesPerWord'].toString()),
                _buildStatDetail('Complex Word Percentage',
                    '${_scores['complexWordPercentage']}%'),
                const Divider(),
              ],
              const Text(
                'Algorithm Formulas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Flesch Reading Ease: 206.835 - 1.015*(words/sentences) - 84.6*(syllables/words)',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              const Text(
                'Flesch-Kincaid: 0.39*(words/sentences) + 11.8*(syllables/words) - 15.59',
                style: TextStyle(fontSize: 12),
              ),
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

  Widget _buildStatDetail(String label, String value) {
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

  void _clearText() {
    setState(() {
      _textController.clear();
      _scores = {};
      _selectedScore = 'fleschReadingEase';
    });
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Readability Score Info'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This tool uses Classical AI readability formulas:'),
                SizedBox(height: 8),
                Text('• Flesch Reading Ease (0-100 scale)'),
                Text('• Flesch-Kincaid Grade Level (US grades)'),
                Text('• Gunning Fog Index (years of education)'),
                Text('• SMOG Index (years of education)'),
                Text('• Coleman-Liau Index (US grade level)'),
                Text('• Automated Readability Index (US grade level)'),
                SizedBox(height: 16),
                Text('What the scores mean:'),
                Text('• 90-100: Very Easy (5th grade)'),
                Text('• 80-89: Easy (6th grade)'),
                Text('• 70-79: Fairly Easy (7th grade)'),
                Text('• 60-69: Standard (8th-9th grade)'),
                Text('• 50-59: Fairly Difficult (10th-12th grade)'),
                Text('• 30-49: Difficult (College)'),
                Text('• 0-29: Very Difficult (College graduate)'),
                SizedBox(height: 16),
                Text('Grade level scores indicate years of education needed'),
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