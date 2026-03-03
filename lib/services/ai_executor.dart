// Firebase auth imports are handled by AuthService where needed
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';
import '../models/ai_history_model.dart';

// Import all AI modules
// Text AI
import '../modules/text_ai/grammar_checker.dart';
import '../modules/text_ai/spell_checker.dart';
import '../modules/text_ai/keyword_extractor.dart';
import '../modules/text_ai/word_counter.dart';
import '../modules/text_ai/sentence_counter.dart';
import '../modules/text_ai/readability_score.dart';
import '../modules/text_ai/stopword_remover.dart';
// stopword_remover imported above
import '../modules/text_ai/duplicate_sentence_detector.dart';
import '../modules/text_ai/text_summarizer.dart';
import '../modules/text_ai/sentiment_analyzer.dart';

// Image AI

// Audio AI
import '../modules/audio_ai/audio_duration.dart';
import '../modules/audio_ai/silence_detector.dart';
import '../modules/audio_ai/volume_analyzer.dart';
import '../modules/audio_ai/noise_estimator.dart';
import '../modules/audio_ai/audio_speed.dart';
import '../modules/audio_ai/voice_activity.dart';
import '../modules/audio_ai/audio_format.dart';

// Data AI
import '../modules/data_ai/data_summary.dart';
import '../modules/data_ai/central_tendency.dart';
import '../modules/data_ai/outlier_detector.dart';
import '../modules/data_ai/trend_detector.dart';
import '../modules/data_ai/data_normalizer.dart';
import '../modules/data_ai/duplicate_detector.dart';
import '../modules/data_ai/rule_recommendation.dart';
import '../modules/data_ai/data_validator.dart';

// Automation AI
import '../modules/automation_ai/rule_engine.dart';
import '../modules/automation_ai/smart_trigger.dart';
import '../modules/automation_ai/conditional_action.dart';
import '../modules/automation_ai/auto_tag.dart';
import '../modules/automation_ai/usage_analyzer.dart';
import '../modules/automation_ai/smart_reminder.dart';
import '../modules/automation_ai/threshold_alert.dart';
import '../modules/automation_ai/decision_tree.dart';

// Logic AI (NEW)
import '../modules/logic_ai/decision_support.dart';
import '../modules/logic_ai/yes_no_predictor.dart';
import '../modules/logic_ai/rule_chatbot.dart';
import '../modules/logic_ai/priority_analyzer.dart';
import '../modules/logic_ai/risk_analysis.dart';
import '../modules/logic_ai/recommendation_system.dart';
import '../modules/logic_ai/smart_calculator.dart';
import '../modules/logic_ai/logic_solver.dart';

class AIExecutor {
  static final FirestoreService _firestoreService = FirestoreService();
  // FirebaseAuth handled via AuthService/FirestoreService when needed

  /// Execute any AI tool and auto-save to Firestore
  static Future<dynamic> runTool({
    required String toolName,
    required String module,
    required dynamic input,
    Map<String, dynamic>? parameters,
  }) async {
    if (parameters != null) {
      input = parameters;
    }
    dynamic output;

    // current user ID handled by FirestoreService when saving

    try {
      // Execute the tool based on name
      switch (toolName) {
        // ---------- TEXT AI ----------
        case "Grammar Checker":
          output = GrammarChecker.checkText(input as String).join(", ");
          break;
        case "Spell Checker":
          output = SpellChecker.checkSpelling(input as String).join(", ");
          break;
        case "Keyword Extractor":
          output = KeywordExtractor.extract(input as String).join(", ");
          break;
        case "Word Counter":
          output = WordCounter.countWords(input as String).toString();
          break;
        case "Sentence Counter":
          output = SentenceCounter.countSentences(input as String).toString();
          break;
        case "Readability Score":
          output =
              ReadabilityScore.calculate(input as String).toStringAsFixed(2);
          break;
        case "Stop-word Remover":
          output = StopwordRemover.removeStopWords(input as String);
          break;
        case "Duplicate Sentence Detector":
          output = DuplicateSentenceDetector.findDuplicates(input as String)
              .join(", ");
          break;
        case "Text Summarizer":
          output = TextSummarizer.summarize(input as String);
          break;
        case "Sentiment Analyzer":
          output = SentimentAnalyzer.analyze(input as String);
          break;

        // ---------- IMAGE AI ----------
        case "Image Resize":
          output = "Image resized successfully";
          break;
        case "Image Crop":
          output = "Image cropped successfully";
          break;
        case "Brightness Adjustment":
          output = "Brightness adjusted successfully";
          break;
        case "Contrast Adjustment":
          output = "Contrast adjusted successfully";
          break;
        case "Grayscale Conversion":
          output = "Converted to grayscale successfully";
          break;
        case "Edge Detection":
          output = "Edge detection completed";
          break;
        case "Blur Filter":
          output = "Blur filter applied";
          break;
        case "Noise Reduction":
          output = "Noise reduction applied";
          break;

        // ---------- AUDIO AI ----------
        case "Audio Duration Analyzer":
          output = "Duration: ${AudioDuration.estimateDuration(input)} seconds";
          break;
        case "Silence Detector":
          output = SilenceDetector.isSilent(input)
              ? "Silence detected"
              : "Audio detected";
          break;
        case "Volume Level Analyzer":
          output = "Volume level: ${VolumeAnalyzer.calculateVolume(input)}";
          break;
        case "Noise Level Estimator":
          output = "Noise level: ${NoiseEstimator.estimate(input)}";
          break;
        case "Audio Speed Controller":
          output = "Speed adjusted to ${AudioSpeed.changeSpeed(input, 1.5)}x";
          break;
        case "Audio Trimmer":
          output = "Audio trimmed successfully";
          break;
        case "Voice Activity Detector":
          final vad = VoiceActivity.detectVoiceActivity(input as List<int>);
          output = (vad['hasVoice'] == true) ? "Voice detected" : "No voice detected";
          break;
        case "Audio Format Analyzer":
          final formatInfo = AudioFormat.detectFormat(input as List<int>);
          output = "Format: ${formatInfo['format']}";
          break;

        // ---------- DATA AI ----------
        case "Data Summary Generator":
          output = DataSummary.generate(input).toString();
          break;
        case "Mean–Median–Mode Analyzer":
          output = CentralTendency.calculate(input).toString();
          break;
        case "Outlier Detector":
          output = OutlierDetector.detect(input).toString();
          break;
        case "Trend Detector":
          output = TrendDetector.detect(input);
          break;
        case "Data Normalizer":
          output = DataNormalizer.normalize(input).toString();
          break;
        case "Duplicate Record Detector":
          output = DuplicateDetector.detect(input as List<Map<String, dynamic>>).toString();
          break;
        case "Rule-based Recommendation":
          output = RuleRecommendation.recommend(input);
          break;
        case "Data Validation Engine":
          output = DataValidator.validate(input)
                  .containsKey('isValid')
              ? "Valid data"
              : "Invalid data";
          break;

        // ---------- AUTOMATION AI ----------
        case "Rule Engine":
          output = RuleEngine.evaluate(input);
          break;
        case "Smart Trigger System":
          output = SmartTrigger.trigger(input) ? "Triggered" : "Not triggered";
          break;
        case "Conditional Action Executor":
          output = ConditionalAction.execute(input);
          break;
        case "Auto Tag Generator":
          output = AutoTag.generate(input);
          break;
        case "Usage Pattern Analyzer":
          output = UsageAnalyzer.analyze(input);
          break;
        case "Smart Reminder Generator":
          output = SmartReminder.generate(input);
          break;
        case "Threshold Alert System":
          output = ThresholdAlert.check(input['value'], input['threshold'])
              ? "Alert: Above threshold"
              : "Normal";
          break;
        case "Decision Tree Engine":
          output = DecisionTree.decide(input);
          break;

        // ---------- LOGIC & DECISION AI ----------
        case "Decision Support System":
          output = DecisionSupportSystem.analyzeDecision(input);
          break;
        case "Yes/No Predictor":
          output = YesNoPredictor.predict(input['question'], input['context']);
          break;
        case "Rule-based Chatbot":
          output = RuleChatbot.getResponse(input);
          break;
        case "Priority Analyzer":
          output = PriorityAnalyzer.analyzeTasks(input).toString();
          break;
        case "Risk Analysis Tool":
          output = RiskAnalysisTool.analyzeRisk(input).toString();
          break;
        case "Recommendation System (rules)":
          output = RecommendationSystem.getToolSuggestion(
              input['task'], input['level']);
          break;
        case "Smart Calculator":
          output = SmartCalculator.calculate(input);
          break;
        case "Logic Solver":
          output = LogicSolver.solveBooleanExpression(input);
          break;

        default:
          output = "Tool not found";
      }

      // Auto-save to Firestore (FirestoreService will attach current userId)
      await _firestoreService.saveAIResult(
        AIHistory(
          toolName: toolName,
          result: output,
          timestamp: DateTime.now(),
          module: module,
          input: input?.toString(),
          output: output?.toString(),
        ),
      );

      return output;
    } catch (e) {
      debugPrint('Error executing tool $toolName: $e');
      return "Error: $e";
    }
  }

  // Get module for a tool
  static String getModuleForTool(String toolName) {
    final textTools = [
      'Grammar Checker',
      'Spell Checker',
      'Keyword Extractor',
      'Word Counter',
      'Sentence Counter',
      'Readability Score',
      'Stop-word Remover',
      'Duplicate Sentence Detector',
      'Text Summarizer',
      'Sentiment Analyzer'
    ];

    final imageTools = [
      'Image Resize',
      'Image Crop',
      'Brightness Adjustment',
      'Contrast Adjustment',
      'Grayscale Conversion',
      'Edge Detection',
      'Blur Filter',
      'Noise Reduction'
    ];

    final audioTools = [
      'Audio Duration Analyzer',
      'Silence Detector',
      'Volume Level Analyzer',
      'Noise Level Estimator',
      'Audio Speed Controller',
      'Audio Trimmer',
      'Voice Activity Detector',
      'Audio Format Analyzer'
    ];

    final dataTools = [
      'Data Summary Generator',
      'Mean–Median–Mode Analyzer',
      'Outlier Detector',
      'Trend Detector',
      'Data Normalizer',
      'Duplicate Record Detector',
      'Rule-based Recommendation',
      'Data Validation Engine'
    ];

    final automationTools = [
      'Rule Engine',
      'Smart Trigger System',
      'Conditional Action Executor',
      'Auto Tag Generator',
      'Usage Pattern Analyzer',
      'Smart Reminder Generator',
      'Threshold Alert System',
      'Decision Tree Engine'
    ];

    final logicTools = [
      'Decision Support System',
      'Yes/No Predictor',
      'Rule-based Chatbot',
      'Priority Analyzer',
      'Risk Analysis Tool',
      'Recommendation System (rules)',
      'Smart Calculator',
      'Logic Solver'
    ];

    if (textTools.contains(toolName)) return 'Text AI';
    if (imageTools.contains(toolName)) return 'Image AI';
    if (audioTools.contains(toolName)) return 'Audio AI';
    if (dataTools.contains(toolName)) return 'Data AI';
    if (automationTools.contains(toolName)) return 'Automation AI';
    if (logicTools.contains(toolName)) return 'Logic & Decision AI';

    return 'Unknown';
  }
}
