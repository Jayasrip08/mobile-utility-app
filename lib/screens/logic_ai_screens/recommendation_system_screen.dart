import 'package:flutter/material.dart';
import '../../services/ai_executor.dart';
import '../../utils/constants.dart';

class RecommendationSystemScreen extends StatefulWidget {
  const RecommendationSystemScreen({super.key});

  @override
  State<RecommendationSystemScreen> createState() =>
      _RecommendationSystemScreenState();
}

class _RecommendationSystemScreenState
    extends State<RecommendationSystemScreen> {
  String _userLevel = 'beginner';
  String _taskDescription = '';
  final TextEditingController _taskController = TextEditingController();

  List<String> _recommendations = [];
  String _toolSuggestion = '';
  bool _loading = false;

  final List<String> _userLevels = [
    'beginner',
    'intermediate',
    'advanced',
    'expert'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommendation System')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'AI Tool Recommendation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
                'Get personalized tool recommendations based on your needs:'),
            const SizedBox(height: 20),

            // User Level Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Your Skill Level:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _userLevels.map((level) {
                        return ChoiceChip(
                          label:
                              Text(level[0].toUpperCase() + level.substring(1)),
                          selected: _userLevel == level,
                          onSelected: (selected) {
                            setState(() {
                              _userLevel = level;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Task Description
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Describe Your Task:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _taskController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'e.g., I need to analyze some text data...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _taskDescription = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Examples: "edit an image", "analyze data", "make a decision", "process audio"',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _getRecommendations,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Get Recommendations'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _taskDescription.isEmpty || _loading
                        ? null
                        : _getToolSuggestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Suggest Best Tool'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recommendations Display
            if (_recommendations.isNotEmpty) ...[
              const Text(
                'Recommended Tools for You:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._recommendations.asMap().entries.map((entry) {
                final index = entry.key;
                final tool = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getToolColor(tool),
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(tool),
                    subtitle: Text(_getToolDescription(tool)),
                    trailing: const Icon(Icons.arrow_forward),
                  ),
                );
              }).toList(),
            ],

            if (_toolSuggestion.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Best Tool for Your Task:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _toolSuggestion,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getToolDescription(_toolSuggestion),
                      style: const TextStyle(color: Colors.grey),
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

  Color _getToolColor(String tool) {
    for (var category in AppConstants.categories) {
      final tools = List<String>.from(category['tools'] ?? []);
      if (tools.contains(tool)) {
        return category['color'] as Color;
      }
    }
    return Colors.blue;
  }

  String _getToolDescription(String tool) {
    final descriptions = {
      'Grammar Checker': 'Check and correct grammar errors in text',
      'Sentiment Analyzer': 'Analyze emotional tone of text',
      'Image Resize': 'Resize images to desired dimensions',
      'Data Summary Generator': 'Generate statistical summaries of data',
      'Decision Support System': 'Get guidance for complex decisions',
      'Smart Calculator': 'Advanced mathematical calculations',
    };
    return descriptions[tool] ?? 'AI tool for various tasks';
  }

  Future<void> _getRecommendations() async {
    setState(() {
      _loading = true;
      _recommendations = [];
      _toolSuggestion = '';
    });

    try {
      // Get all available tools
      List<String> allTools = [];
      for (var category in AppConstants.categories) {
        allTools.addAll(List<String>.from(category['tools'] ?? []));
      }

      // In a real app, this would come from the AI module
      // For now, we'll simulate recommendations
      await Future.delayed(const Duration(milliseconds: 500));

      // Simple recommendation logic
      List<String> recommendations = [];
      if (_userLevel == 'beginner') {
        recommendations = [
          'Grammar Checker',
          'Image Resize',
          'Data Summary Generator'
        ];
      } else if (_userLevel == 'intermediate') {
        recommendations = [
          'Sentiment Analyzer',
          'Brightness Adjustment',
          'Trend Detector'
        ];
      } else if (_userLevel == 'advanced') {
        recommendations = [
          'Edge Detection',
          'Outlier Detector',
          'Decision Support System'
        ];
      } else {
        recommendations = ['Rule Engine', 'Logic Solver', 'Risk Analysis Tool'];
      }

      setState(() {
        _recommendations = recommendations;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _recommendations = [
          'Grammar Checker',
          'Image Resize',
          'Data Summary Generator'
        ];
        _loading = false;
      });
    }
  }

  Future<void> _getToolSuggestion() async {
    setState(() {
      _loading = true;
      _toolSuggestion = '';
    });

    try {
      final result = await AIExecutor.runTool(
        toolName: 'Recommendation System (rules)',
        module: 'Logic & Decision AI',
        input: {
          'task': _taskDescription,
          'level': _userLevel,
        },
      );

      setState(() {
        _toolSuggestion = result.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _toolSuggestion = 'Grammar Checker';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
