import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';

class AutoTagScreen extends StatefulWidget {
  const AutoTagScreen({super.key});

  @override
  State<AutoTagScreen> createState() => _AutoTagScreenState();
}

class _AutoTagScreenState extends State<AutoTagScreen> {
  final TextEditingController _textController = TextEditingController(
      text: 'This is a technical document about AI and machine learning. '
          'It discusses important concepts and provides valuable insights '
          'for software developers and data scientists.');
  final Map<String, TextEditingController> _mapControllers = {
    'name': TextEditingController(text: 'Document'),
    'type': TextEditingController(text: 'Technical'),
    'category': TextEditingController(text: 'AI'),
    'status': TextEditingController(text: 'Active'),
  };
  final TextEditingController _listController =
      TextEditingController(text: 'Apple, Banana, Orange, Apple, Grape');

  String _result = '';
  bool _loading = false;
  String _selectedInputType = 'text';
  List<String> _suggestedTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Tag Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Automatic Tag Generator',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate intelligent tags using pattern matching and classification',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Input Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Input Type:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildInputTypeChip('Text', Icons.text_fields),
                        _buildInputTypeChip('Map', Icons.list),
                        _buildInputTypeChip('List', Icons.format_list_bulleted),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Text Input
            if (_selectedInputType == 'text') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Text Content',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Generate tags from text content analysis'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _textController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Enter text content',
                          border: OutlineInputBorder(),
                          hintText:
                              'Enter text to analyze for automatic tagging...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildExampleChip('Technical document about AI'),
                          _buildExampleChip(
                              'Business report with financial data'),
                          _buildExampleChip('Health and fitness article'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Map Input
            if (_selectedInputType == 'map') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Structured Data',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                          'Generate tags from structured key-value data'),
                      const SizedBox(height: 16),

                      // Map Input Fields
                      Column(
                        children: _mapControllers.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: entry.value,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      hintText: 'Enter ${entry.key} value',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // List Input
            if (_selectedInputType == 'list') ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'List Data',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      const Text('Generate tags from list data patterns'),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _listController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Enter list items (comma separated)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Apple, Banana, Orange, Apple, Grape',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildListExampleChip('10, 20, 30, 40, 50'),
                          _buildListExampleChip(
                              'Active, Pending, Completed, Failed'),
                          _buildListExampleChip('John, Jane, Bob, Alice, John'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Generate Tags Button
            ElevatedButton(
              onPressed: _loading ? null : _generateTags,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
              ),
              child: _loading
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer),
                        SizedBox(width: 8),
                        Text(
                          'Generate Tags',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Results
            if (_result.isNotEmpty) ...[
              const Text(
                'Generated Tags:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _result.split(', ').map((tag) {
                  return Chip(
                    label: Text(tag.trim()),
                    backgroundColor: _getTagColor(tag.trim()),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _result = _result
                            .replaceAll('$tag, ', '')
                            .replaceAll(', $tag', '')
                            .replaceAll(tag, '');
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Suggested Tags
              if (_suggestedTags.isNotEmpty) ...[
                const Text(
                  'Suggested Related Tags:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedTags.map((tag) {
                    return ActionChip(
                      label: Text(tag),
                      onPressed: () {
                        setState(() {
                          if (_result.isEmpty) {
                            _result = tag;
                          } else if (!_result.contains(tag)) {
                            _result = '$_result, $tag';
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 20),

              // Tag Analysis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tag Analysis:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total Tags: ${_result.split(', ').length}\n'
                        'Tag Categories: ${_extractCategories(_result)}\n'
                        'Primary Tag: ${_extractPrimaryTag(_result)}',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Classical AI Explanation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Classical AI Techniques Used:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Pattern Matching: Keyword and phrase detection\n'
                      '• Heuristic Classification: Content type identification\n'
                      '• Statistical Analysis: Frequency and pattern recognition\n'
                      '• Rule-Based Tagging: IF-THEN rules for tag assignment\n'
                      '• Content Analysis: Structure and format detection',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tags are generated based on content analysis without training data.',
                      style:
                          TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputTypeChip(String label, IconData icon) {
    bool selected = _selectedInputType == label.toLowerCase();
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (selected) {
        setState(() {
          _selectedInputType = label.toLowerCase();
        });
      },
    );
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(text.length > 30 ? '${text.substring(0, 30)}...' : text),
      onPressed: () {
        _textController.text = text;
      },
    );
  }

  Widget _buildListExampleChip(String list) {
    return ActionChip(
      label: Text(list),
      onPressed: () {
        _listController.text = list;
      },
    );
  }

  Color _getTagColor(String tag) {
    // Color coding based on tag type
    if (tag.contains('Technology') ||
        tag.contains('AI') ||
        tag.contains('Software')) {
      return const Color(0xFFBBDEFB);
    } else if (tag.contains('Business') ||
        tag.contains('Finance') ||
        tag.contains('Sales')) {
      return const Color(0xFFC8E6C9);
    } else if (tag.contains('Health') ||
        tag.contains('Medical') ||
        tag.contains('Fitness')) {
      return const Color(0xFFFFCDD2);
    } else if (tag.contains('Education') ||
        tag.contains('Learning') ||
        tag.contains('Research')) {
      return Colors.orange.shade100;
    } else if (tag.contains('Positive') ||
        tag.contains('Success') ||
        tag.contains('Achievement')) {
      return Colors.yellow.shade100;
    } else if (tag.contains('Negative') ||
        tag.contains('Problem') ||
        tag.contains('Issue')) {
      return Colors.purple.shade100;
    } else if (tag.contains('Urgent') ||
        tag.contains('Important') ||
        tag.contains('Critical')) {
      return Colors.pink.shade100;
    } else {
      return const Color(0xFFEEEEEE);
    }
  }

  String _extractCategories(String tags) {
    List<String> categories = [];
    for (var tag in tags.split(', ')) {
      if (tag.contains('Technology') || tag.contains('AI'))
        categories.add('Technology');
      if (tag.contains('Business') || tag.contains('Finance'))
        categories.add('Business');
      if (tag.contains('Health') || tag.contains('Medical'))
        categories.add('Health');
      if (tag.contains('Education') || tag.contains('Learning'))
        categories.add('Education');
    }
    return categories.toSet().join(', ');
  }

  String _extractPrimaryTag(String tags) {
    List<String> tagList = tags.split(', ');
    if (tagList.isEmpty) return 'None';

    // Simple heuristic: longest tag or first tag with capital letters
    String primary = tagList[0];
    for (var tag in tagList) {
      if (tag.length > primary.length && tag[0] == tag[0].toUpperCase()) {
        primary = tag;
      }
    }
    return primary;
  }

  Future<void> _generateTags() async {
    setState(() {
      _loading = true;
      _result = '';
      _suggestedTags = [];
    });

    try {
      dynamic input;

      if (_selectedInputType == 'text') {
        input = _textController.text;
      } else if (_selectedInputType == 'map') {
        Map<String, dynamic> mapData = {};
        for (var entry in _mapControllers.entries) {
          mapData[entry.key] = entry.value.text;
        }
        input = mapData;
      } else if (_selectedInputType == 'list') {
        input =
            _listController.text.split(',').map((item) => item.trim()).toList();
      }

      final result = await AIExecutor.runTool(
        toolName: 'Auto Tag Generator',
        module: 'Automation AI',
        input: input,
      );

      // Get suggested related tags
      List<String> generatedTags = result.toString().split(', ');
      if (generatedTags.isNotEmpty) {
        // For demo, generate some related tags
        _suggestedTags = _generateRelatedTags(generatedTags[0]);
      }

      setState(() {
        _result = result.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error generating tags: $e';
        _loading = false;
      });
    }
  }

  List<String> _generateRelatedTags(String baseTag) {
    // Simple related tag generation for demo
    final relatedTags = {
      'Technology': ['Software', 'Programming', 'AI', 'Data', 'System'],
      'Business': ['Finance', 'Marketing', 'Sales', 'Management', 'Strategy'],
      'Health': ['Fitness', 'Medical', 'Wellness', 'Nutrition', 'Therapy'],
      'Education': ['Learning', 'Teaching', 'Research', 'Academic', 'Training'],
      'Positive': [
        'Success',
        'Achievement',
        'Growth',
        'Improvement',
        'Optimistic'
      ],
      'Negative': ['Problem', 'Issue', 'Challenge', 'Risk', 'Critical'],
    };

    baseTag = baseTag.toLowerCase();

    for (var category in relatedTags.keys) {
      if (baseTag.contains(category.toLowerCase())) {
        return relatedTags[category]!;
      }
    }

    return ['General', 'Important', 'Review', 'Action', 'Follow-up'];
  }

  @override
  void dispose() {
    _textController.dispose();
    _listController.dispose();
    for (var controller in _mapControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
