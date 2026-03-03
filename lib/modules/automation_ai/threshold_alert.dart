import 'dart:math';

/// Threshold alert system using rule-based monitoring
class ThresholdAlert {
  /// Check if value exceeds threshold
  static bool check(dynamic value, dynamic threshold) {
    if (value is num && threshold is num) {
      return _checkNumeric(value, threshold);
    } else if (value is String && threshold is String) {
      return _checkString(value, threshold);
    } else if (value is List && threshold is num) {
      return _checkList(value, threshold);
    } else if (value is Map && threshold is Map) {
      return _checkMap(value, threshold);
    }
    return false;
  }

  /// Check numeric value against threshold
  static bool _checkNumeric(num value, num threshold) {
    return value > threshold;
  }

  /// Check string against condition
  static bool _checkString(String value, String condition) {
    value = value.toLowerCase();
    condition = condition.toLowerCase();

    if (condition.startsWith('contains:')) {
      String target = condition.substring(9);
      return value.contains(target);
    } else if (condition.startsWith('equals:')) {
      String target = condition.substring(7);
      return value == target;
    } else if (condition.startsWith('length>')) {
      int length = int.tryParse(condition.substring(7)) ?? 0;
      return value.length > length;
    }

    return false;
  }

  /// Check list against threshold
  static bool _checkList(List<dynamic> list, num threshold) {
    if (list.isEmpty) return false;

    // Check list length
    if (list.length > threshold) return true;

    // Check if any element exceeds threshold
    for (var item in list) {
      if (item is num && item > threshold) return true;
    }

    return false;
  }

  /// Check map against thresholds
  static bool _checkMap(
      Map<dynamic, dynamic> data, Map<dynamic, dynamic> thresholds) {
    for (var key in thresholds.keys) {
      if (data.containsKey(key)) {
        var value = data[key];
        var threshold = thresholds[key];

        if (value is num && threshold is num && value > threshold) {
          return true;
        }
      }
    }
    return false;
  }

  /// Generate alert message based on threshold breach
  static String generateAlert(dynamic value, dynamic threshold,
      [String? context]) {
    String alertType = _determineAlertType(value, threshold);
    String severity = _determineSeverity(value, threshold);

    String message = "🚨 THRESHOLD ALERT\n\n";
    message += "Alert Type: $alertType\n";
    message += "Severity: $severity\n\n";

    if (context != null) {
      message += "Context: $context\n";
    }

    message += "Current Value: $value\n";
    message += "Threshold: $threshold\n\n";

    message += _getAlertActions(severity);
    message += _getPreventiveMeasures(alertType);

    return message;
  }

  /// Determine alert type
  static String _determineAlertType(dynamic value, dynamic threshold) {
    if (value is num && threshold is num) {
      double percentage = (value / threshold * 100);

      if (percentage > 200) return "Critical Exceedance";
      if (percentage > 150) return "Major Exceedance";
      if (percentage > 120) return "Moderate Exceedance";
      return "Minor Exceedance";
    }

    return "Threshold Breach";
  }

  /// Determine severity level
  static String _determineSeverity(dynamic value, dynamic threshold) {
    if (value is num && threshold is num) {
      double ratio = value / threshold;

      if (ratio > 2.0) return "CRITICAL";
      if (ratio > 1.5) return "HIGH";
      if (ratio > 1.2) return "MEDIUM";
      return "LOW";
    }

    return "MEDIUM";
  }

  /// Get alert actions based on severity
  static String _getAlertActions(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return "IMMEDIATE ACTIONS REQUIRED:\n"
            "1. Trigger emergency protocols\n"
            "2. Notify all stakeholders immediately\n"
            "3. Initiate system shutdown if necessary\n"
            "4. Deploy emergency response team\n\n";

      case 'HIGH':
        return "URGENT ACTIONS:\n"
            "1. Escalate to management\n"
            "2. Increase monitoring frequency\n"
            "3. Prepare contingency plans\n"
            "4. Schedule immediate review\n\n";

      case 'MEDIUM':
        return "RECOMMENDED ACTIONS:\n"
            "1. Investigate root cause\n"
            "2. Adjust system parameters\n"
            "3. Schedule maintenance\n"
            "4. Monitor trend\n\n";

      case 'LOW':
        return "STANDARD ACTIONS:\n"
            "1. Log incident\n"
            "2. Regular monitoring\n"
            "3. Review during next check\n"
            "4. No immediate action required\n\n";

      default:
        return "Monitor situation and adjust as needed\n\n";
    }
  }

  /// Get preventive measures based on alert type
  static String _getPreventiveMeasures(String alertType) {
    switch (alertType) {
      case 'Critical Exceedance':
        return "PREVENTIVE MEASURES:\n"
            "• Implement automatic shutdown at 180%\n"
            "• Increase safety margins\n"
            "• Regular system audits\n"
            "• Redundant monitoring systems";

      case 'Major Exceedance':
        return "PREVENTIVE MEASURES:\n"
            "• Set warning at 120%\n"
            "• Regular maintenance schedule\n"
            "• Staff training on early detection\n"
            "• Performance trend analysis";

      case 'Moderate Exceedance':
        return "PREVENTIVE MEASURES:\n"
            "• Adjust thresholds based on usage patterns\n"
            "• Implement gradual alerts\n"
            "• Regular system calibration\n"
            "• Historical data analysis";

      default:
        return "PREVENTIVE MEASURES:\n"
            "• Regular threshold review\n"
            "• System performance monitoring\n"
            "• Documentation of all breaches\n"
            "• Continuous improvement";
    }
  }

  /// Calculate trend and predict future breaches
  static Map<String, dynamic> analyzeTrend(
      List<num> historicalData, num threshold) {
    if (historicalData.length < 3) {
      return {
        'trend': 'Insufficient data',
        'prediction': 'Cannot predict',
        'confidence': 0,
        'recommendation': 'Collect more data'
      };
    }

    // Calculate trend
    double slope = _calculateSlope(historicalData);
    String trend = slope > 0.1
        ? 'Increasing'
        : slope < -0.1
            ? 'Decreasing'
            : 'Stable';

    // Predict next value
    double lastValue = historicalData.last.toDouble();
    double predictedValue = lastValue + slope;

    // Calculate time to threshold breach
    double timeToBreach = double.infinity;
    if (slope > 0 && predictedValue < threshold) {
      timeToBreach = (threshold - lastValue) / slope;
    }

    // Confidence calculation
    double mean =
        historicalData.reduce((a, b) => a + b) / historicalData.length;
    double variance = historicalData
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        historicalData.length;
    double confidence = (100 - sqrt(variance))
        .clamp(0, 100); // Fixed: use sqrt() from dart:math

    // Generate recommendation
    String recommendation;
    if (trend == 'Increasing' && timeToBreach < 10) {
      recommendation = 'Immediate action required to prevent breach';
    } else if (trend == 'Increasing') {
      recommendation =
          'Monitor closely, breach predicted in ${timeToBreach.toStringAsFixed(1)} periods';
    } else if (trend == 'Decreasing') {
      recommendation = 'Trend is favorable, continue current practices';
    } else {
      recommendation = 'Stable trend, maintain current monitoring levels';
    }

    return {
      'trend': trend,
      'slope': slope.toStringAsFixed(3),
      'currentValue': lastValue.toStringAsFixed(2),
      'predictedNext': predictedValue.toStringAsFixed(2),
      'timeToBreach':
          timeToBreach.isFinite ? timeToBreach.toStringAsFixed(1) : 'Never',
      'confidence': confidence.toStringAsFixed(1),
      'recommendation': recommendation,
    };
  }

  /// Calculate slope of historical data
  static double _calculateSlope(List<num> data) {
    if (data.length < 2) return 0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = data.length;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += data[i].toDouble();
      sumXY += i * data[i].toDouble();
      sumX2 += i * i;
    }

    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  }

  /// Optimize threshold based on historical data
  static Map<String, dynamic> optimizeThreshold(
      List<num> historicalData, double targetCoverage) {
    if (historicalData.isEmpty) {
      return {
        'optimalThreshold': 0,
        'coverage': 0,
        'recommendation': 'No data available'
      };
    }

    // Sort data
    List<num> sortedData = List.from(historicalData)..sort();

    // Calculate percentiles
    int index = (sortedData.length * targetCoverage).floor();
    num optimalThreshold = sortedData[index.clamp(0, sortedData.length - 1)];

    // Calculate current coverage with optimal threshold
    int belowThreshold = sortedData.where((v) => v <= optimalThreshold).length;
    double coverage = belowThreshold / sortedData.length * 100;

    // Calculate false positives/negatives (placeholders removed)

    // For simplicity, assume normal distribution
    double mean = sortedData.reduce((a, b) => a + b) / sortedData.length;
    double stdDev = _calculateStdDev(sortedData, mean);

    // Generate recommendation
    String recommendation;
    if (coverage >= targetCoverage * 100) {
      recommendation = 'Threshold optimal for target coverage';
    } else if (stdDev > mean * 0.5) {
      recommendation = 'High variability detected. Consider dynamic thresholds';
    } else {
      recommendation = 'Adjust threshold based on operational requirements';
    }

    return {
      'optimalThreshold': optimalThreshold,
      'currentCoverage': coverage.toStringAsFixed(1),
      'targetCoverage': (targetCoverage * 100).toStringAsFixed(1),
      'mean': mean.toStringAsFixed(2),
      'stdDev': stdDev.toStringAsFixed(2),
      'dataPoints': sortedData.length,
      'recommendation': recommendation,
      'suggestedRange':
          '${(optimalThreshold * 0.9).toStringAsFixed(2)} - ${(optimalThreshold * 1.1).toStringAsFixed(2)}'
    };
  }

  /// Calculate standard deviation
  static double _calculateStdDev(List<num> data, double mean) {
    double variance = 0;
    for (var value in data) {
      variance += (value - mean) * (value - mean);
    }
    variance /= data.length;
    return sqrt(variance); // Fixed: use sqrt() from dart:math
  }
}
