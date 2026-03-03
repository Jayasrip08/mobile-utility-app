import 'package:flutter/material.dart';
import '../utils/constants.dart';

// Import all screens
// Text AI Screens
import 'text_ai_screens/grammar_checker_screen.dart';
import 'text_ai_screens/spell_checker_screen.dart';
import 'text_ai_screens/keyword_extractor_screen.dart';
import 'text_ai_screens/word_counter_screen.dart';
import 'text_ai_screens/sentence_counter_screen.dart';
import 'text_ai_screens/readability_score_screen.dart';
import 'text_ai_screens/stopword_remover_screen.dart';
import 'text_ai_screens/duplicate_sentence_detector_screen.dart';
import 'text_ai_screens/text_summarizer_screen.dart';
import 'text_ai_screens/sentiment_analyzer_screen.dart';

// Image AI Screens
import 'image_ai_screens/image_resize_screen.dart';
import 'image_ai_screens/image_crop_screen.dart';
import 'image_ai_screens/brightness_adjust_screen.dart';
import 'image_ai_screens/contrast_adjust_screen.dart';
import 'image_ai_screens/grayscale_screen.dart';
import 'image_ai_screens/edge_detection_screen.dart';
import 'image_ai_screens/blur_filter_screen.dart';
import 'image_ai_screens/noise_reduction_screen.dart';

// Audio AI Screens
import 'audio_ai_screens/audio_duration_screen.dart';
import 'audio_ai_screens/silence_detector_screen.dart';
import 'audio_ai_screens/volume_analyzer_screen.dart';
import 'audio_ai_screens/noise_estimator_screen.dart';
import 'audio_ai_screens/audio_speed_screen.dart';
import 'audio_ai_screens/audio_trimmer_screen.dart';
import 'audio_ai_screens/voice_activity_screen.dart';
import 'audio_ai_screens/audio_format_screen.dart';

// Data AI Screens
import 'data_ai_screens/data_summary_screen.dart';
import 'data_ai_screens/central_tendency_screen.dart';
import 'data_ai_screens/outlier_detector_screen.dart';
import 'data_ai_screens/trend_detector_screen.dart';
import 'data_ai_screens/data_normalizer_screen.dart';
import 'data_ai_screens/duplicate_detector_screen.dart';
import 'data_ai_screens/rule_recommendation_screen.dart';
import 'data_ai_screens/data_validator_screen.dart';

// Automation AI Screens
import 'automation_ai_screens/rule_engine_screen.dart';
import 'automation_ai_screens/smart_trigger_screen.dart';
import 'automation_ai_screens/conditional_action_screen.dart';
import 'automation_ai_screens/auto_tag_screen.dart';
import 'automation_ai_screens/usage_analyzer_screen.dart';
import 'automation_ai_screens/smart_reminder_screen.dart';
import 'automation_ai_screens/threshold_alert_screen.dart';
import 'automation_ai_screens/decision_tree_screen.dart';

// Logic AI Screens
import 'logic_ai_screens/decision_support_screen.dart';
import 'logic_ai_screens/yes_no_predictor_screen.dart';
import 'logic_ai_screens/rule_chatbot_screen.dart';
import 'logic_ai_screens/priority_analyzer_screen.dart';
import 'logic_ai_screens/risk_analysis_screen.dart';
import 'logic_ai_screens/recommendation_system_screen.dart';
import 'logic_ai_screens/smart_calculator_screen.dart';
import 'logic_ai_screens/logic_solver_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  List<String> _availableTools = [];

  // Map tool names to their screens
  final Map<String, Widget> _toolScreens = {
    // Text AI
    'Grammar Checker': const GrammarCheckerScreen(),
    'Spell Checker': const SpellCheckerScreen(),
    'Keyword Extractor': const KeywordExtractorScreen(),
    'Word Counter': const WordCounterScreen(),
    'Sentence Counter': const SentenceCounterScreen(),
    'Readability Score': const ReadabilityScoreScreen(),
    'Stop-word Remover': const StopwordRemoverScreen(),
    'Duplicate Sentence Detector': const DuplicateSentenceDetectorScreen(),
    'Text Summarizer': const TextSummarizerScreen(),
    'Sentiment Analyzer': const SentimentAnalyzerScreen(),

    // Image AI
    'Image Resize': const ImageResizeScreen(),
    'Image Crop': const ImageCropScreen(),
    'Brightness Adjustment': const BrightnessAdjustScreen(),
    'Contrast Adjustment': const ContrastAdjustScreen(),
    'Grayscale Conversion': const GrayscaleScreen(),
    'Edge Detection': const EdgeDetectionScreen(),
    'Blur Filter': const BlurFilterScreen(),
    'Noise Reduction': const NoiseReductionScreen(),

    // Audio AI
    'Audio Duration Analyzer': const AudioDurationScreen(),
    'Silence Detector': const SilenceDetectorScreen(),
    'Volume Level Analyzer': const VolumeAnalyzerScreen(),
    'Noise Level Estimator': const NoiseEstimationScreen(),
    'Audio Speed Controller': const AudioSpeedScreen(),
    'Audio Trimmer': const AudioTrimmerScreen(),
    'Voice Activity Detector': const VoiceActivityScreen(),
    'Audio Format Analyzer': const AudioFormatScreen(),

    // Data AI
    'Data Summary Generator': const DataSummaryScreen(),
    'Mean–Median–Mode Analyzer': const CentralTendencyScreen(),
    'Outlier Detector': const OutlierDetectorScreen(),
    'Trend Detector': const TrendDetectorScreen(),
    'Data Normalizer': const DataNormalizerScreen(),
    'Duplicate Record Detector': const DuplicateDetectorScreen(),
    'Rule-based Recommendation': const RuleRecommendationScreen(),
    'Data Validation Engine': const DataValidatorScreen(),

    // Automation AI
    'Rule Engine': const RuleEngineScreen(),
    'Smart Trigger System': const SmartTriggerScreen(),
    'Conditional Action Executor': const ConditionalActionScreen(),
    'Auto Tag Generator': const AutoTagScreen(),
    'Usage Pattern Analyzer': const UsageAnalyzerScreen(),
    'Smart Reminder Generator': const SmartReminderScreen(),
    'Threshold Alert System': const ThresholdAlertScreen(),
    'Decision Tree Engine': const DecisionTreeScreen(),

    // Logic AI
    'Decision Support System': const DecisionSupportScreen(),
    'Yes/No Predictor': const YesNoPredictorScreen(),
    'Rule-based Chatbot': const RuleChatbotScreen(),
    'Priority Analyzer': const PriorityAnalyzerScreen(),
    'Risk Analysis Tool': const RiskAnalysisScreen(),
    'Recommendation System (rules)': const RecommendationSystemScreen(),
    'Smart Calculator': const SmartCalculatorScreen(),
    'Logic Solver': const LogicSolverScreen(),
  };

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = 'All'; // Default to All
    _updateAvailableTools();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateAvailableTools() {
    setState(() {
      if (_selectedCategory == 'All') {
        _availableTools = [];
        for (var cat in AppConstants.categories) {
          _availableTools.addAll(List<String>.from(cat['tools'] ?? []));
        }
      } else {
        final category = AppConstants.categories.firstWhere(
          (cat) => cat['name'] == _selectedCategory,
          orElse: () => AppConstants.categories[0],
        );
        _availableTools = List<String>.from(category['tools'] ?? []);
      }
    });
  }

  List<String> get _filteredTools {
    if (_searchQuery.isEmpty) return _availableTools;
    return _availableTools
        .where((tool) => tool.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0, // Hide default AppBar toolbar, use custom header
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade900.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome Back,',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI Tools Hub',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.person, color: Colors.white),
                        onPressed: () => Navigator.pushNamed(context, '/profile'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search for a tool...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // Categories List
          Container(
            height: 60,
            margin: const EdgeInsets.only(top: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All', Colors.grey.shade800),
                ...AppConstants.categories.map((cat) => _buildCategoryChip(
                      cat['name'],
                      cat['color'] as Color,
                    )),
              ],
            ),
          ),

          // Tools Grid
          Expanded(
            child: _filteredTools.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No tools found',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3, // Slightly taller for better layout
                    ),
                    itemCount: _filteredTools.length,
                    itemBuilder: (context, index) {
                      final toolName = _filteredTools[index];
                      // Find category for this tool to get color/icon
                      var category = AppConstants.categories.firstWhere(
                        (cat) => (cat['tools'] as List).contains(toolName),
                        orElse: () => AppConstants.categories[0],
                      );
                      
                      return ToolCard(
                        toolName: toolName,
                        color: category['color'] as Color,
                        icon: category['icon'] as IconData,
                        onTap: () {
                          if (_toolScreens.containsKey(toolName)) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _toolScreens[toolName]!,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    bool isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = label;
            _updateAvailableTools();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: color.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: color,
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class ToolCard extends StatelessWidget {
  final String toolName;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.toolName,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 10,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                Text(
                  toolName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

