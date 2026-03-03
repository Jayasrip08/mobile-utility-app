/// Smart trigger system using pattern matching and heuristics
class SmartTrigger {
  /// Trigger based on usage patterns
  static bool trigger(dynamic input) {
    if (input is int) {
      return _triggerOnCount(input);
    } else if (input is Map<String, dynamic>) {
      return _triggerOnConditions(input);
    } else if (input is List) {
      return _triggerOnPattern(input);
    } else if (input is String) {
      return _triggerOnText(input);
    }
    return false;
  }

  /// Trigger based on count threshold
  static bool _triggerOnCount(int count) {
    // Adaptive threshold based on time of day (simulated)
    DateTime now = DateTime.now();
    int hour = now.hour;

    // Different thresholds for different times
    if (hour >= 8 && hour <= 17) {
      // Business hours - higher threshold
      return count > 15;
    } else if (hour >= 18 && hour <= 22) {
      // Evening - medium threshold
      return count > 10;
    } else {
      // Night - lower threshold
      return count > 5;
    }
  }

  /// Trigger based on multiple conditions
  static bool _triggerOnConditions(Map<String, dynamic> conditions) {
    int trueConditions = 0;
    int totalConditions = conditions.length;

    for (var key in conditions.keys) {
      var value = conditions[key];

      if (value is bool && value == true) {
        trueConditions++;
      } else if (value is num && value > 0) {
        trueConditions++;
      } else if (value is String && value.isNotEmpty) {
        trueConditions++;
      } else if (value is List && value.isNotEmpty) {
        trueConditions++;
      } else if (value is Map && value.isNotEmpty) {
        trueConditions++;
      }
    }

    // Trigger if more than 60% conditions are true
    return (trueConditions / totalConditions) > 0.6;
  }

  /// Trigger based on pattern recognition
  static bool _triggerOnPattern(List<dynamic> pattern) {
    if (pattern.length < 3) return false;

    // Check for increasing pattern
    if (_isIncreasingPattern(pattern)) {
      return true;
    }

    // Check for decreasing pattern
    if (_isDecreasingPattern(pattern)) {
      return true;
    }

    // Check for spike pattern
    if (_isSpikePattern(pattern)) {
      return true;
    }

    // Check for threshold crossing
    return _crossesThreshold(pattern, 50);
  }

  /// Trigger based on text analysis
  static bool _triggerOnText(String text) {
    text = text.toLowerCase();

    // Emergency keywords
    final emergencyWords = [
      'emergency',
      'urgent',
      'critical',
      'immediate',
      'help',
      'fire',
      'alert'
    ];
    for (var word in emergencyWords) {
      if (text.contains(word)) return true;
    }

    // Warning keywords
    final warningWords = [
      'warning',
      'caution',
      'attention',
      'problem',
      'issue',
      'error',
      'failed'
    ];
    int warningCount = 0;
    for (var word in warningWords) {
      if (text.contains(word)) warningCount++;
    }
    if (warningCount >= 2) return true;

    // Length-based trigger for long messages
    if (text.length > 200) {
      // Check for multiple exclamation marks
      int exclamationCount = text.split('!').length - 1;
      if (exclamationCount >= 3) return true;
    }

    return false;
  }

  /// Pattern recognition helpers
  static bool _isIncreasingPattern(List<dynamic> pattern) {
    for (int i = 1; i < pattern.length; i++) {
      if (pattern[i] is! num || pattern[i - 1] is! num) continue;
      if (pattern[i] <= pattern[i - 1]) return false;
    }
    return true;
  }

  static bool _isDecreasingPattern(List<dynamic> pattern) {
    for (int i = 1; i < pattern.length; i++) {
      if (pattern[i] is! num || pattern[i - 1] is! num) continue;
      if (pattern[i] >= pattern[i - 1]) return false;
    }
    return true;
  }

  static bool _isSpikePattern(List<dynamic> pattern) {
    if (pattern.length < 5) return false;

    // Calculate average
    double sum = 0;
    int count = 0;
    for (var value in pattern) {
      if (value is num) {
        sum += value.toDouble();
        count++;
      }
    }
    double average = sum / count;

    // Check for values significantly above average
    for (var value in pattern) {
      if (value is num && value > average * 2) {
        return true;
      }
    }

    return false;
  }

  static bool _crossesThreshold(List<dynamic> pattern, num threshold) {
    for (var value in pattern) {
      if (value is num && value > threshold) {
        return true;
      }
    }
    return false;
  }

  /// Get trigger sensitivity based on context
  static String getSensitivityLevel(Map<String, dynamic> context) {
    int sensitivity = 5; // Default medium

    if (context.containsKey('time')) {
      DateTime time = context['time'];
      if (time.hour >= 22 || time.hour <= 6) {
        sensitivity = 7; // Higher sensitivity at night
      }
    }

    if (context.containsKey('location') && context['location'] == 'critical') {
      sensitivity = 9; // Highest sensitivity for critical locations
    }

    if (context.containsKey('dayOfWeek')) {
      int day = context['dayOfWeek'];
      if (day == 6 || day == 7) {
        // Weekend
        sensitivity = 6; // Slightly higher on weekends
      }
    }

    return 'Sensitivity Level: $sensitivity/10';
  }
}
