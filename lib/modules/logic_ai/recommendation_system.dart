class RecommendationSystem {
  static final Map<String, Map<String, int>> userPreferences = {
    'beginner': {'simplicity': 9, 'guidance': 8, 'speed': 6, 'accuracy': 7},
    'intermediate': {'simplicity': 7, 'guidance': 6, 'speed': 7, 'accuracy': 8},
    'advanced': {'simplicity': 5, 'guidance': 4, 'speed': 8, 'accuracy': 9},
    'expert': {'simplicity': 3, 'guidance': 2, 'speed': 9, 'accuracy': 9},
  };

  static final Map<String, Map<String, int>> toolProfiles = {
    'Grammar Checker': {
      'simplicity': 8,
      'guidance': 7,
      'speed': 9,
      'accuracy': 8
    },
    'Sentiment Analyzer': {
      'simplicity': 7,
      'guidance': 6,
      'speed': 8,
      'accuracy': 7
    },
    'Image Resize': {'simplicity': 9, 'guidance': 8, 'speed': 9, 'accuracy': 9},
    'Edge Detection': {
      'simplicity': 5,
      'guidance': 4,
      'speed': 7,
      'accuracy': 8
    },
    'Data Summary': {'simplicity': 7, 'guidance': 6, 'speed': 8, 'accuracy': 9},
    'Outlier Detector': {
      'simplicity': 4,
      'guidance': 3,
      'speed': 6,
      'accuracy': 8
    },
    'Decision Support': {
      'simplicity': 6,
      'guidance': 8,
      'speed': 7,
      'accuracy': 8
    },
    'Rule Engine': {'simplicity': 5, 'guidance': 7, 'speed': 8, 'accuracy': 9},
  };

  static List<String> getRecommendations(
      String userLevel, List<String> availableTools) {
    if (!userPreferences.containsKey(userLevel)) {
      return ['Grammar Checker', 'Image Resize', 'Data Summary'];
    }

    final preferences = userPreferences[userLevel]!;
    final Map<String, double> scores = {};

    for (var tool in availableTools) {
      if (toolProfiles.containsKey(tool)) {
        final profile = toolProfiles[tool]!;
        double score = 0;

        for (var criterion in preferences.keys) {
          score += profile[criterion]! * preferences[criterion]!;
        }

        scores[tool] = score;
      }
    }

    // Sort by score and get top 3
    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(3).map((e) => e.key).toList();
  }

  static String getToolSuggestion(String taskDescription, String userLevel) {
    taskDescription = taskDescription.toLowerCase();

    if (taskDescription.contains('text') || taskDescription.contains('write')) {
      if (userLevel == 'beginner') return 'Grammar Checker';
      if (userLevel == 'intermediate') return 'Sentiment Analyzer';
      return 'Text Summarizer';
    }

    if (taskDescription.contains('image') ||
        taskDescription.contains('photo')) {
      if (userLevel == 'beginner') return 'Image Resize';
      if (userLevel == 'intermediate') return 'Brightness Adjustment';
      return 'Edge Detection';
    }

    if (taskDescription.contains('data') ||
        taskDescription.contains('analyze')) {
      if (userLevel == 'beginner') return 'Data Summary Generator';
      if (userLevel == 'intermediate') return 'Trend Detector';
      return 'Outlier Detector';
    }

    if (taskDescription.contains('decide') ||
        taskDescription.contains('choose')) {
      return 'Decision Support System';
    }

    if (taskDescription.contains('calculate') ||
        taskDescription.contains('math')) {
      return 'Smart Calculator';
    }

    return 'Grammar Checker'; // Default recommendation
  }
}
