/// Conditional action executor using rule-based logic
class ConditionalAction {
  /// Execute action based on condition
  static String execute(dynamic input) {
    if (input is bool) {
      return _executeBoolean(input);
    } else if (input is Map<String, dynamic>) {
      return _executeComplex(input);
    } else if (input is String) {
      return _executeText(input);
    } else {
      return "No action defined for input type";
    }
  }

  /// Execute based on boolean condition
  static String _executeBoolean(bool condition) {
    if (condition) {
      return "✅ Condition TRUE - Executing action sequence:\n"
          "1. Log event to system\n"
          "2. Send notification to users\n"
          "3. Update status dashboard\n"
          "4. Trigger automated response";
    } else {
      return "⏸️ Condition FALSE - Action paused:\n"
          "1. Monitoring condition\n"
          "2. Waiting for trigger\n"
          "3. System in standby mode";
    }
  }

  /// Execute complex conditional logic
  static String _executeComplex(Map<String, dynamic> conditions) {
    List<String> actions = [];
    List<String> logs = [];

    // Check temperature condition
    if (conditions.containsKey('temperature')) {
      double temp = conditions['temperature'];
      if (temp > 30) {
        actions.add("Activate cooling system");
        logs.add("High temperature detected: ${temp.toStringAsFixed(1)}°C");
      } else if (temp < 15) {
        actions.add("Activate heating system");
        logs.add("Low temperature detected: ${temp.toStringAsFixed(1)}°C");
      }
    }

    // Check humidity condition
    if (conditions.containsKey('humidity')) {
      double humidity = conditions['humidity'];
      if (humidity > 80) {
        actions.add("Activate dehumidifier");
        logs.add("High humidity: ${humidity.toStringAsFixed(1)}%");
      } else if (humidity < 30) {
        actions.add("Activate humidifier");
        logs.add("Low humidity: ${humidity.toStringAsFixed(1)}%");
      }
    }

    // Check time-based conditions
    if (conditions.containsKey('time')) {
      DateTime time = conditions['time'];
      if (time.hour >= 18 && time.hour <= 22) {
        actions.add("Switch to evening mode");
        logs.add("Evening hours detected");
      } else if (time.hour >= 22 || time.hour <= 6) {
        actions.add("Switch to night mode");
        logs.add("Night hours detected");
      }
    }

    // Check presence condition
    if (conditions.containsKey('presence') && conditions['presence'] == true) {
      actions.add("Adjust settings for occupancy");
      logs.add("Presence detected");
    }

    // Check light level
    if (conditions.containsKey('lightLevel')) {
      double light = conditions['lightLevel'];
      if (light < 300) {
        actions.add("Adjust lighting to optimal level");
        logs.add("Low light level: ${light.toStringAsFixed(0)} lux");
      }
    }

    // Generate response
    if (actions.isEmpty) {
      return "No actions required. All conditions within normal parameters.";
    } else {
      return "Executing ${actions.length} actions:\n\n"
          "Actions:\n${actions.map((a) => '• $a').join('\n')}\n\n"
          "Logs:\n${logs.map((l) => '📝 $l').join('\n')}";
    }
  }

  /// Execute based on text command
  static String _executeText(String command) {
    command = command.toLowerCase();

    // Emergency commands
    if (command.contains('emergency') || command.contains('shutdown')) {
      return "🚨 EMERGENCY PROTOCOL ACTIVATED\n"
          "1. Immediate system shutdown initiated\n"
          "2. Backup systems engaged\n"
          "3. Notifications sent to all personnel\n"
          "4. Safety protocols activated";
    }

    // Maintenance commands
    if (command.contains('maintenance') || command.contains('service')) {
      return "🔧 MAINTENANCE MODE ACTIVATED\n"
          "1. System entering maintenance mode\n"
          "2. Automatic backups completed\n"
          "3. User notifications sent\n"
          "4. Service personnel alerted";
    }

    // Optimization commands
    if (command.contains('optimize') || command.contains('tune')) {
      return "⚙️ OPTIMIZATION PROTOCOL\n"
          "1. Analyzing system performance\n"
          "2. Adjusting parameters for efficiency\n"
          "3. Monitoring resource utilization\n"
          "4. Applying optimal settings";
    }

    // Monitoring commands
    if (command.contains('monitor') || command.contains('watch')) {
      return "👁️ MONITORING MODE ACTIVATED\n"
          "1. Enhanced monitoring enabled\n"
          "2. Real-time alerts configured\n"
          "3. Data logging intensified\n"
          "4. Dashboard updates increased";
    }

    // Default action
    return "Standard action sequence:\n"
        "1. Processing command: $command\n"
        "2. Validating permissions\n"
        "3. Checking system status\n"
        "4. Executing standard procedures";
  }

  /// Validate action sequence
  static Map<String, dynamic> validateActionSequence(
      List<String> actions, List<String> dependencies) {
    Map<String, dynamic> validation = {
      'valid': true,
      'sequence': [],
      'warnings': [],
      'estimatedTime': 0
    };

    int timeEstimate = 0;

    for (var action in actions) {
      action = action.toLowerCase();

      // Estimate time based on action type
      if (action.contains('start') || action.contains('begin')) {
        timeEstimate += 5;
      } else if (action.contains('stop') || action.contains('end')) {
        timeEstimate += 3;
      } else if (action.contains('check') || action.contains('verify')) {
        timeEstimate += 2;
      } else if (action.contains('send') || action.contains('notify')) {
        timeEstimate += 1;
      } else if (action.contains('process') || action.contains('analyze')) {
        timeEstimate += 10;
      } else {
        timeEstimate += 5;
      }

      // Check for dependencies
      for (var dep in dependencies) {
        if (action.contains(dep.toLowerCase()) && !actions.contains(dep)) {
          validation['warnings'].add(
              "Action '$action' depends on '$dep' which is not in sequence");
        }
      }

      validation['sequence'].add({
        'action': action,
        'timeEstimate': timeEstimate,
        'status': 'pending'
      });
    }

    validation['estimatedTime'] = timeEstimate;

    if (validation['warnings'].isNotEmpty) {
      validation['valid'] = false;
    }

    return validation;
  }

  /// Schedule actions based on priority
  static List<Map<String, dynamic>> scheduleActions(
      List<Map<String, dynamic>> actions) {
    // Sort by priority (higher priority first)
    actions.sort((a, b) {
      int priorityA = a['priority'] ?? 5;
      int priorityB = b['priority'] ?? 5;
      return priorityB.compareTo(priorityA);
    });

    // Assign time slots
    DateTime startTime = DateTime.now();
    List<Map<String, dynamic>> schedule = [];

    for (var action in actions) {
      int duration = action['duration'] ?? 5; // Default 5 minutes

      schedule.add({
        'action': action['name'],
        'startTime': startTime.toString(),
        'duration': duration,
        'priority': action['priority'] ?? 5,
        'status': 'scheduled'
      });

      startTime = startTime.add(Duration(minutes: duration));
    }

    return schedule;
  }
}
