import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'AI Tools App';
  static const String appVersion = '1.0.0';

  // Firestore Collections
  static const String historyCollection = 'ai_history';
  static const String usersCollection = 'users';

  // Module Names
  static const String textAI = 'Text AI';
  static const String imageAI = 'Image AI';
  static const String audioAI = 'Audio AI';
  static const String dataAI = 'Data AI';
  static const String automationAI = 'Automation AI';
  static const String logicAI = 'Logic & Decision AI';

  // Tool Categories
  static final List<Map<String, dynamic>> categories = [
    {
      'name': 'Text AI',
      'icon': Icons.text_fields,
      'color': Colors.blue,
      'tools': [
        'Grammar Checker',
        'Spell Checker',
        'Keyword Extractor',
        'Word Counter',
        'Sentence Counter',
        'Readability Score',
        'Stop-word Remover',
        'Duplicate Sentence Detector',
        'Text Summarizer',
        'Sentiment Analyzer',
      ]
    },
    {
      'name': 'Image AI',
      'icon': Icons.image,
      'color': Colors.green,
      'tools': [
        'Image Resize',
        'Image Crop',
        'Brightness Adjustment',
        'Contrast Adjustment',
        'Grayscale Conversion',
        'Edge Detection',
        'Blur Filter',
        'Noise Reduction',
      ]
    },
    {
      'name': 'Audio AI',
      'icon': Icons.audiotrack,
      'color': Colors.orange,
      'tools': [
        'Audio Duration Analyzer',
        'Silence Detector',
        'Volume Level Analyzer',
        'Noise Level Estimator',
        'Audio Speed Controller',
        'Audio Trimmer',
        'Voice Activity Detector',
        'Audio Format Analyzer',
      ]
    },
    {
      'name': 'Data AI',
      'icon': Icons.analytics,
      'color': Colors.purple,
      'tools': [
        'Data Summary Generator',
        'Mean–Median–Mode Analyzer',
        'Outlier Detector',
        'Trend Detector',
        'Data Normalizer',
        'Duplicate Record Detector',
        'Rule-based Recommendation',
        'Data Validation Engine',
      ]
    },
    {
      'name': 'Automation AI',
      'icon': Icons.autorenew,
      'color': Colors.red,
      'tools': [
        'Rule Engine',
        'Smart Trigger System',
        'Conditional Action Executor',
        'Auto Tag Generator',
        'Usage Pattern Analyzer',
        'Smart Reminder Generator',
        'Threshold Alert System',
        'Decision Tree Engine',
      ]
    },
    {
      'name': 'Logic & Decision AI',
      'icon': Icons.psychology,
      'color': Colors.teal,
      'tools': [
        'Decision Support System',
        'Yes/No Predictor',
        'Rule-based Chatbot',
        'Priority Analyzer',
        'Risk Analysis Tool',
        'Recommendation System (rules)',
        'Smart Calculator',
        'Logic Solver',
      ]
    },
  ];
}
