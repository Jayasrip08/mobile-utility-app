
/// Rule-based decision engine using classical AI techniques
class RuleEngine {
  /// Evaluate conditions against a set of rules
  static String evaluate(dynamic input) {
    if (input is Map<String, dynamic>) {
      return _evaluateMap(input);
    } else if (input is int) {
      return _evaluateNumber(input);
    } else if (input is String) {
      return _evaluateString(input);
    } else {
      return "Input format not supported";
    }
  }

  /// Evaluate map-based rules (expert system)
  static String _evaluateMap(Map<String, dynamic> rules) {
    int score = 0;
    List<String> factors = [];

    // Temperature rule
    if (rules.containsKey('temperature')) {
      double temp = rules['temperature'];
      if (temp > 30) {
        score += 30;
        factors.add("High temperature detected");
      } else if (temp > 20) {
        score += 20;
        factors.add("Moderate temperature");
      } else {
        score += 10;
        factors.add("Low temperature");
      }
    }

    // Humidity rule
    if (rules.containsKey('humidity')) {
      double humidity = rules['humidity'];
      if (humidity > 80) {
        score += 25;
        factors.add("High humidity detected");
      } else if (humidity > 50) {
        score += 15;
        factors.add("Moderate humidity");
      } else {
        score += 5;
        factors.add("Low humidity");
      }
    }

    // Pressure rule
    if (rules.containsKey('pressure')) {
      double pressure = rules['pressure'];
      if (pressure > 1015) {
        score += 20;
        factors.add("High pressure system");
      } else if (pressure > 1000) {
        score += 10;
        factors.add("Normal pressure");
      } else {
        score += 5;
        factors.add("Low pressure system");
      }
    }

    // Wind speed rule
    if (rules.containsKey('windSpeed')) {
      double windSpeed = rules['windSpeed'];
      if (windSpeed > 20) {
        score += 25;
        factors.add("Strong winds detected");
      } else if (windSpeed > 10) {
        score += 15;
        factors.add("Moderate winds");
      } else {
        score += 5;
        factors.add("Calm winds");
      }
    }

    // Decision logic based on score
    String decision;
    String recommendation;

    if (score >= 70) {
      decision = "HIGH ALERT";
      recommendation =
          "Take immediate action. Multiple critical factors detected.";
    } else if (score >= 50) {
      decision = "MEDIUM ALERT";
      recommendation = "Monitor closely. Several factors require attention.";
    } else if (score >= 30) {
      decision = "LOW ALERT";
      recommendation = "Normal conditions with minor concerns.";
    } else {
      decision = "NORMAL";
      recommendation = "All parameters within acceptable ranges.";
    }

    return "Decision: $decision\nScore: $score/100\nFactors: ${factors.join(', ')}\nRecommendation: $recommendation";
  }

  /// Evaluate numeric input
  static String _evaluateNumber(int value) {
    if (value >= 90) {
      return "CRITICAL - Immediate action required. Value: $value";
    } else if (value >= 70) {
      return "HIGH - Significant attention needed. Value: $value";
    } else if (value >= 50) {
      return "MEDIUM - Monitor situation. Value: $value";
    } else if (value >= 30) {
      return "LOW - Normal operation. Value: $value";
    } else {
      return "NORMAL - Within safe parameters. Value: $value";
    }
  }

  /// Evaluate string-based rules
  static String _evaluateString(String condition) {
    condition = condition.toLowerCase();

    // Medical emergency rules
    if (condition.contains('emergency') || condition.contains('critical')) {
      return "IMMEDIATE ACTION REQUIRED\nAlert level: CRITICAL\nResponse: Activate emergency protocols";
    }

    // Warning rules
    if (condition.contains('warning') || condition.contains('alert')) {
      return "HIGH PRIORITY\nAlert level: HIGH\nResponse: Investigate and take necessary actions";
    }

    // Information rules
    if (condition.contains('info') || condition.contains('update')) {
      return "INFORMATIONAL\nAlert level: LOW\nResponse: Log information for review";
    }

    // Status rules
    if (condition.contains('status') || condition.contains('check')) {
      return "STATUS CHECK\nAlert level: NORMAL\nResponse: Verify system status";
    }

    // Default rule
    return "UNKNOWN CONDITION\nAlert level: UNKNOWN\nResponse: Review condition statement";
  }

  /// Validate rules against constraints
  static Map<String, dynamic> validateRules(
      Map<String, dynamic> rules, Map<String, dynamic> constraints) {
    Map<String, dynamic> validation = {
      'valid': true,
      'violations': [],
      'suggestions': []
    };

    for (var key in constraints.keys) {
      if (rules.containsKey(key)) {
        if (rules[key] is num && constraints[key] is Map) {
          // Numeric constraint check
          var constraint = constraints[key] as Map<String, dynamic>;
          num value = rules[key] as num;

          if (constraint.containsKey('min') && value < constraint['min']) {
            validation['valid'] = false;
            validation['violations']
                .add('$key: Value $value below minimum ${constraint['min']}');
            validation['suggestions']
                .add('Increase $key to at least ${constraint['min']}');
          }

          if (constraint.containsKey('max') && value > constraint['max']) {
            validation['valid'] = false;
            validation['violations']
                .add('$key: Value $value above maximum ${constraint['max']}');
            validation['suggestions']
                .add('Decrease $key to at most ${constraint['max']}');
          }
        }
      }
    }

    return validation;
  }
}
