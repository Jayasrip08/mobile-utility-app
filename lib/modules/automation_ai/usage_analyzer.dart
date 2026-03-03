import 'dart:math';

/// Usage pattern analyzer using statistical analysis
class UsageAnalyzer {
  /// Analyze usage patterns
  static String analyze(dynamic input) {
    if (input is List<num>) {
      return _analyzeNumericPattern(input);
    } else if (input is Map<String, dynamic>) {
      return _analyzeBehaviorPattern(input);
    } else if (input is List<Map<String, dynamic>>) {
      return _analyzeComplexPattern(input);
    } else {
      return "Usage data format not recognized";
    }
  }

  /// Analyze numeric usage patterns
  static String _analyzeNumericPattern(List<num> usageData) {
    if (usageData.isEmpty) return "No usage data available";

    // Basic statistics
    double sum = 0;
    num min = usageData[0];
    num max = usageData[0];

    for (var value in usageData) {
      sum += value.toDouble();
      if (value < min) min = value;
      if (value > max) max = value;
    }

    double average = sum / usageData.length;

    // Calculate standard deviation
    double variance = 0;
    for (var value in usageData) {
      variance += (value - average) * (value - average);
    }
    variance /= usageData.length;
    double stdDev = sqrt(variance); // Fixed: use sqrt() from dart:math

    // Detect patterns
    String pattern = _detectUsagePattern(usageData);

    // Generate insights
    List<String> insights = [];

    if (average > 70) {
      insights.add("High average usage detected");
    } else if (average > 30) {
      insights.add("Moderate average usage");
    } else {
      insights.add("Low average usage");
    }

    if (stdDev > average * 0.5) {
      insights.add("High variability in usage");
    } else {
      insights.add("Consistent usage pattern");
    }

    if (max > average * 2) {
      insights.add("Peak usage significantly higher than average");
    }

    if (_detectIncreasingTrend(usageData)) {
      insights.add("Increasing trend detected");
    } else if (_detectDecreasingTrend(usageData)) {
      insights.add("Decreasing trend detected");
    }

    return "Usage Analysis:\n\n"
        "Statistics:\n"
        "• Count: ${usageData.length}\n"
        "• Average: ${average.toStringAsFixed(2)}\n"
        "• Minimum: $min\n"
        "• Maximum: $max\n"
        "• Range: ${(max - min).toStringAsFixed(2)}\n"
        "• Std Dev: ${stdDev.toStringAsFixed(2)}\n\n"
        "Pattern: $pattern\n\n"
        "Insights:\n${insights.map((i) => '• $i').join('\n')}";
  }

  /// Analyze behavior patterns from structured data
  static String _analyzeBehaviorPattern(Map<String, dynamic> behavior) {
    List<String> patterns = [];
    List<String> recommendations = [];

    // Time-based analysis
    if (behavior.containsKey('timePatterns')) {
      var timePatterns = behavior['timePatterns'];
      if (timePatterns is Map) {
        patterns.addAll(_analyzeTimePatterns(timePatterns));
      }
    }

    // Frequency analysis
    if (behavior.containsKey('frequency')) {
      int frequency = behavior['frequency'];
      if (frequency > 20) {
        patterns.add("High frequency usage");
        recommendations.add("Consider implementing usage limits");
      } else if (frequency > 10) {
        patterns.add("Moderate frequency usage");
      } else {
        patterns.add("Low frequency usage");
        recommendations.add("Consider promoting more engagement");
      }
    }

    // Duration analysis
    if (behavior.containsKey('duration')) {
      int duration = behavior['duration'];
      if (duration > 60) {
        patterns.add("Extended usage sessions");
        recommendations.add("Consider implementing breaks");
      } else if (duration > 30) {
        patterns.add("Moderate session length");
      } else {
        patterns.add("Short usage sessions");
      }
    }

    // Feature usage analysis
    if (behavior.containsKey('features')) {
      var features = behavior['features'];
      if (features is Map) {
        patterns.addAll(_analyzeFeatureUsage(features));
      }
    }

    if (patterns.isEmpty) {
      patterns.add("Standard usage pattern detected");
    }

    if (recommendations.isEmpty) {
      recommendations.add("Usage patterns appear normal");
    }

    return "Behavior Analysis:\n\n"
        "Detected Patterns:\n${patterns.map((p) => '• $p').join('\n')}\n\n"
        "Recommendations:\n${recommendations.map((r) => '• $r').join('\n')}";
  }

  /// Analyze complex multi-dimensional patterns
  static String _analyzeComplexPattern(List<Map<String, dynamic>> usageLogs) {
    if (usageLogs.isEmpty) return "No usage logs available";

    Map<String, List<num>> metrics = {};
    List<String> timeSlots = [];
    Map<String, int> actionCounts = {};

    // Aggregate data
    for (var log in usageLogs) {
      // Collect metrics
      for (var key in log.keys) {
        if (log[key] is num) {
          if (!metrics.containsKey(key)) {
            metrics[key] = [];
          }
          metrics[key]!.add(log[key] as num);
        }
      }

      // Track time slots
      if (log.containsKey('timestamp')) {
        String timeSlot = _getTimeSlot(log['timestamp']);
        timeSlots.add(timeSlot);
      }

      // Count actions
      if (log.containsKey('action')) {
        String action = log['action'].toString();
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
      }
    }

    // Generate analysis
    List<String> analysis = [];

    // Time pattern analysis
    if (timeSlots.isNotEmpty) {
      String peakTime = _findPeakTime(timeSlots);
      analysis.add("Peak usage time: $peakTime");
    }

    // Action analysis
    if (actionCounts.isNotEmpty) {
      String mostCommonAction = _findMostCommonAction(actionCounts);
      analysis.add("Most common action: $mostCommonAction");
    }

    // Metric analysis
    for (var metric in metrics.keys) {
      var data = metrics[metric]!;
      if (data.isNotEmpty) {
        double avg = data.reduce((a, b) => a + b) / data.length;
        analysis.add("Average $metric: ${avg.toStringAsFixed(2)}");
      }
    }

    return "Complex Usage Analysis:\n\n"
        "Total Logs: ${usageLogs.length}\n"
        "Metrics Tracked: ${metrics.keys.length}\n\n"
        "Key Findings:\n${analysis.map((a) => '• $a').join('\n')}";
  }

  /// Helper: Detect usage patterns
  static String _detectUsagePattern(List<num> data) {
    if (data.length < 3) return "Insufficient data for pattern detection";

    if (_isIncreasingTrend(data)) return "Increasing trend";
    if (_isDecreasingTrend(data)) return "Decreasing trend";
    if (_isCyclicalPattern(data)) return "Cyclical pattern";
    if (_hasSpikes(data)) return "Spike pattern";
    if (_isStable(data)) return "Stable pattern";

    return "Random pattern";
  }

  static bool _isIncreasingTrend(List<num> data) {
    for (int i = 1; i < data.length; i++) {
      if (data[i] <= data[i - 1]) return false;
    }
    return true;
  }

  static bool _isDecreasingTrend(List<num> data) {
    for (int i = 1; i < data.length; i++) {
      if (data[i] >= data[i - 1]) return false;
    }
    return true;
  }

  static bool _isCyclicalPattern(List<num> data) {
    if (data.length < 6) return false;

    // Simple cyclical detection
    int cycles = 0;
    for (int i = 2; i < data.length; i++) {
      if (data[i] > data[i - 1] && data[i - 1] < data[i - 2]) cycles++;
      if (data[i] < data[i - 1] && data[i - 1] > data[i - 2]) cycles++;
    }

    return cycles > data.length / 3;
  }

  static bool _hasSpikes(List<num> data) {
    if (data.length < 3) return false;

    double avg = data.reduce((a, b) => a + b) / data.length;
    for (var value in data) {
      if (value > avg * 2) return true;
    }
    return false;
  }

  static bool _isStable(List<num> data) {
    if (data.length < 2) return true;

    double avg = data.reduce((a, b) => a + b) / data.length;
    for (var value in data) {
      if ((value - avg).abs() > avg * 0.2) return false;
    }
    return true;
  }

  /// Helper: Analyze time patterns
  static List<String> _analyzeTimePatterns(Map<dynamic, dynamic> timePatterns) {
    List<String> patterns = [];

    // Find peak hours
    int maxCount = 0;
    String peakHour = '';

    for (var entry in timePatterns.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        peakHour = entry.key.toString();
      }
    }

    if (peakHour.isNotEmpty) {
      patterns.add("Peak usage at $peakHour ($maxCount occurrences)");
    }

    // Check for time distribution
    int total = timePatterns.values
        .fold(0, (sum, value) => sum + (value is int ? value : 0));
    if (total > 0) {
      double avgPerSlot = total / timePatterns.length;
      int aboveAvg = 0;

      for (var value in timePatterns.values) {
        if (value > avgPerSlot) aboveAvg++;
      }

      if (aboveAvg > timePatterns.length / 2) {
        patterns.add("Evenly distributed usage throughout day");
      } else {
        patterns.add("Concentrated usage during specific hours");
      }
    }

    return patterns;
  }

  /// Helper: Analyze feature usage
  static List<String> _analyzeFeatureUsage(Map<dynamic, dynamic> features) {
    List<String> patterns = [];

    // Find most used feature
    String mostUsed = '';
    int maxUsage = 0;
    int totalUsage = 0;

    for (var entry in features.entries) {
      int usage = entry.value is int ? entry.value : 0;
      totalUsage += usage;

      if (usage > maxUsage) {
        maxUsage = usage;
        mostUsed = entry.key.toString();
      }
    }

    if (mostUsed.isNotEmpty && totalUsage > 0) {
      patterns.add("Most used feature: $mostUsed ($maxUsage uses)");

      // Calculate feature diversity
      double diversity = features.length / totalUsage;
      if (diversity > 0.5) {
        patterns.add("Diverse feature usage");
      } else {
        patterns.add("Focused feature usage");
      }
    }

    return patterns;
  }

  /// Helper: Get time slot from timestamp
  static String _getTimeSlot(dynamic timestamp) {
    if (timestamp is DateTime) {
      int hour = timestamp.hour;
      if (hour >= 6 && hour < 12) return 'Morning';
      if (hour >= 12 && hour < 18) return 'Afternoon';
      if (hour >= 18 && hour < 22) return 'Evening';
      return 'Night';
    }
    return 'Unknown';
  }

  /// Helper: Find peak time from time slots
  static String _findPeakTime(List<String> timeSlots) {
    Map<String, int> counts = {};
    for (var slot in timeSlots) {
      counts[slot] = (counts[slot] ?? 0) + 1;
    }

    String peak = '';
    int maxCount = 0;
    for (var entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        peak = entry.key;
      }
    }

    return peak;
  }

  /// Helper: Find most common action
  static String _findMostCommonAction(Map<String, int> actionCounts) {
    String mostCommon = '';
    int maxCount = 0;

    for (var entry in actionCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommon = entry.key;
      }
    }

    return mostCommon;
  }

  /// Detect increasing trend (added missing method)
  static bool _detectIncreasingTrend(List<num> usageData) {
    if (usageData.length < 3) return false;

    // Simple linear regression to detect trend
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = usageData.length;

    for (int i = 0; i < n; i++) {
      sumX += i.toDouble();
      sumY += usageData[i].toDouble();
      sumXY += i.toDouble() * usageData[i].toDouble();
      sumX2 += i.toDouble() * i.toDouble();
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope > 0.1; // Positive slope indicates increasing trend
  }

  /// Detect decreasing trend (added missing method)
  static bool _detectDecreasingTrend(List<num> usageData) {
    if (usageData.length < 3) return false;

    // Simple linear regression to detect trend
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = usageData.length;

    for (int i = 0; i < n; i++) {
      sumX += i.toDouble();
      sumY += usageData[i].toDouble();
      sumXY += i.toDouble() * usageData[i].toDouble();
      sumX2 += i.toDouble() * i.toDouble();
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope < -0.1; // Negative slope indicates decreasing trend
  }

  /// Predict future usage
  static Map<String, dynamic> predictUsage(
      List<num> historicalData, int periods) {
    if (historicalData.length < 3) {
      return {
        'prediction': 'Insufficient historical data',
        'confidence': 0,
        'trend': 'unknown'
      };
    }

    // Simple moving average prediction
    double avg = historicalData.reduce((a, b) => a + b) / historicalData.length;

    // Trend detection
    String trend = 'stable';
    if (_isIncreasingTrend(historicalData)) {
      trend = 'increasing';
      avg *= 1.1; // 10% increase
    } else if (_isDecreasingTrend(historicalData)) {
      trend = 'decreasing';
      avg *= 0.9; // 10% decrease
    }

    // Confidence calculation
    double variance = 0;
    for (var value in historicalData) {
      variance += (value - avg) * (value - avg);
    }
    variance /= historicalData.length;

    // Fixed: use sqrt() from dart:math and ensure proper type conversion
    double confidence = (100 - sqrt(variance)).clamp(0, 100).toDouble();

    return {
      'prediction': avg.toStringAsFixed(2),
      'confidence': confidence.toStringAsFixed(1),
      'trend': trend,
      'recommendation': trend == 'increasing'
          ? 'Prepare for increased usage'
          : trend == 'decreasing'
              ? 'Monitor for further decline'
              : 'Maintain current capacity'
    };
  }
}
