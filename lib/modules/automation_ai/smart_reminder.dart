/// Smart reminder generator using heuristic scheduling
class SmartReminder {
  /// Generate reminder based on input
  static String generate(dynamic input) {
    if (input is int) {
      return _generateForDays(input);
    } else if (input is Map<String, dynamic>) {
      return _generateForTask(input);
    } else if (input is List) {
      return _generateForMultiple(input);
    } else {
      return "No reminder needed at this time";
    }
  }

  /// Generate reminder for days since last activity
  static String _generateForDays(int daysInactive) {
    if (daysInactive <= 1) {
      return "No reminder needed. Recent activity detected.";
    } else if (daysInactive <= 3) {
      return "Gentle Reminder:\n"
          "• It's been $daysInactive days since last activity\n"
          "• Consider checking in\n"
          "• Priority: Low";
    } else if (daysInactive <= 7) {
      return "Regular Reminder:\n"
          "• $daysInactive days of inactivity detected\n"
          "• Time to re-engage\n"
          "• Suggested action: Send follow-up\n"
          "• Priority: Medium";
    } else if (daysInactive <= 14) {
      return "Important Reminder:\n"
          "• Significant inactivity: $daysInactive days\n"
          "• Risk of disengagement\n"
          "• Immediate action recommended\n"
          "• Priority: High";
    } else {
      return "Critical Reminder:\n"
          "• Extended inactivity: $daysInactive days\n"
          "• High risk of complete disengagement\n"
          "• Urgent intervention required\n"
          "• Priority: Critical";
    }
  }

  /// Generate reminder for specific task
  static String _generateForTask(Map<String, dynamic> task) {
    String taskName = task['name']?.toString() ?? 'Unnamed Task';
    DateTime? dueDate;
    String? priority = task['priority']?.toString();

    // Parse due date
    if (task['dueDate'] != null) {
      if (task['dueDate'] is DateTime) {
        dueDate = task['dueDate'];
      } else if (task['dueDate'] is String) {
        try {
          dueDate = DateTime.parse(task['dueDate']);
        } catch (e) {
          dueDate = null;
        }
      }
    }

    // Calculate urgency
    String urgency = _calculateUrgency(dueDate, priority);

    // Generate reminder message
    String message = "Task Reminder: $taskName\n\n";

    if (dueDate != null) {
      DateTime now = DateTime.now();
      Duration difference = dueDate.difference(now);
      int daysLeft = difference.inDays;

      message += "Due Date: ${dueDate.toLocal()}\n";
      message += "Time Remaining: ${_formatDuration(difference)}\n";

      if (daysLeft < 0) {
        message += "Status: OVERDUE by ${daysLeft.abs()} days\n";
      } else if (daysLeft == 0) {
        message += "Status: DUE TODAY\n";
      } else if (daysLeft <= 2) {
        message += "Status: DUE SOON\n";
      }
    }

    message += "\nUrgency Level: $urgency\n";
    message += _getReminderActions(urgency);

    return message;
  }

  /// Generate reminders for multiple items
  static String _generateForMultiple(List<dynamic> items) {
    if (items.isEmpty) return "No items to remind about";

    List<Map<String, dynamic>> reminders = [];
    int overdueCount = 0;
    int dueSoonCount = 0;

    for (var item in items) {
      if (item is Map<String, dynamic>) {
        String reminder = _generateForTask(item);
        reminders.add({
          'item': item['name'] ?? 'Unnamed',
          'reminder': reminder,
          'urgency': _extractUrgency(reminder)
        });

        if (reminder.contains('OVERDUE')) overdueCount++;
        if (reminder.contains('DUE SOON') || reminder.contains('DUE TODAY'))
          dueSoonCount++;
      }
    }

    // Sort by urgency
    reminders.sort((a, b) {
      var urgencyOrder = {'Critical': 4, 'High': 3, 'Medium': 2, 'Low': 1};
      int aOrder = urgencyOrder[a['urgency']] ?? 0;
      int bOrder = urgencyOrder[b['urgency']] ?? 0;
      return bOrder.compareTo(aOrder);
    });

    return "Multiple Reminders Summary:\n\n"
        "Total Items: ${items.length}\n"
        "Overdue: $overdueCount\n"
        "Due Soon: $dueSoonCount\n\n"
        "Priority Reminders:\n${reminders.take(3).map((r) => '• ${r['item']} - ${r['urgency']}').join('\n')}";
  }

  /// Calculate urgency based on due date and priority
  static String _calculateUrgency(DateTime? dueDate, String? priority) {
    if (dueDate == null) {
      return priority == 'high' ? 'Medium' : 'Low';
    }

    DateTime now = DateTime.now();
    Duration difference = dueDate.difference(now);
    int daysLeft = difference.inDays;

    // Base urgency on days left
    if (daysLeft < 0) {
      return 'Critical';
    } else if (daysLeft == 0) {
      return 'High';
    } else if (daysLeft <= 2) {
      return 'High';
    } else if (daysLeft <= 7) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  /// Format duration for display
  static String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return "${duration.inDays} days";
    } else if (duration.inHours > 0) {
      return "${duration.inHours} hours";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes} minutes";
    } else {
      return "Less than a minute";
    }
  }

  /// Get appropriate actions for urgency level
  static String _getReminderActions(String urgency) {
    switch (urgency) {
      case 'Critical':
        return "Recommended Actions:\n"
            "1. IMMEDIATE attention required\n"
            "2. Escalate to supervisor\n"
            "3. Allocate maximum resources\n"
            "4. Send urgent notifications";

      case 'High':
        return "Recommended Actions:\n"
            "1. Prioritize this task\n"
            "2. Reallocate resources if needed\n"
            "3. Set multiple reminders\n"
            "4. Regular progress checks";

      case 'Medium':
        return "Recommended Actions:\n"
            "1. Schedule time for completion\n"
            "2. Set single reminder\n"
            "3. Monitor progress\n"
            "4. Regular status updates";

      case 'Low':
        return "Recommended Actions:\n"
            "1. Add to weekly review\n"
            "2. Monitor for changes\n"
            "3. Optional follow-up\n"
            "4. Standard tracking";

      default:
        return "Monitor and adjust as needed";
    }
  }

  /// Extract urgency from reminder text
  static String _extractUrgency(String reminder) {
    if (reminder.contains('Critical')) return 'Critical';
    if (reminder.contains('High')) return 'High';
    if (reminder.contains('Medium')) return 'Medium';
    if (reminder.contains('Low')) return 'Low';
    return 'Unknown';
  }

  /// Schedule optimal reminder time
  static Map<String, dynamic> scheduleReminder(
      DateTime dueDate, String priority, Map<String, dynamic> preferences) {
    DateTime now = DateTime.now();
    Duration timeUntilDue = dueDate.difference(now);

    List<DateTime> reminderTimes = [];

    // Critical priority - multiple reminders
    if (priority == 'critical') {
      if (timeUntilDue.inDays > 1) {
        reminderTimes.add(now.add(Duration(days: 1)));
      }
      if (timeUntilDue.inHours > 6) {
        reminderTimes.add(now.add(Duration(hours: 6)));
      }
      if (timeUntilDue.inHours > 1) {
        reminderTimes.add(now.add(Duration(hours: 1)));
      }
      reminderTimes.add(dueDate.subtract(Duration(minutes: 30)));
    }
    // High priority - regular reminders
    else if (priority == 'high') {
      if (timeUntilDue.inDays > 2) {
        reminderTimes.add(now.add(Duration(days: 2)));
      }
      if (timeUntilDue.inDays > 0) {
        reminderTimes.add(now.add(Duration(days: 1)));
      }
      reminderTimes.add(dueDate.subtract(Duration(hours: 2)));
    }
    // Medium priority - fewer reminders
    else if (priority == 'medium') {
      if (timeUntilDue.inDays > 3) {
        reminderTimes.add(now.add(Duration(days: 3)));
      }
      reminderTimes.add(dueDate.subtract(Duration(days: 1)));
    }
    // Low priority - single reminder
    else {
      reminderTimes.add(dueDate.subtract(Duration(hours: 12)));
    }

    // Adjust based on preferences
    if (preferences.containsKey('preferredTime')) {
      DateTime preferred = DateTime.parse(preferences['preferredTime']);
      for (int i = 0; i < reminderTimes.length; i++) {
        reminderTimes[i] = DateTime(
          reminderTimes[i].year,
          reminderTimes[i].month,
          reminderTimes[i].day,
          preferred.hour,
          preferred.minute,
        );
      }
    }

    // Remove past times
    reminderTimes.removeWhere((time) => time.isBefore(now));

    return {
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'reminderCount': reminderTimes.length,
      'reminderTimes': reminderTimes.map((t) => t.toIso8601String()).toList(),
      'schedule': reminderTimes.asMap().map((i, time) =>
          MapEntry('Reminder ${i + 1}', time.toLocal().toString())),
    };
  }

  /// Calculate reminder effectiveness score
  static Map<String, dynamic> calculateEffectiveness(
      List<Map<String, dynamic>> reminderHistory) {
    if (reminderHistory.isEmpty) {
      return {
        'score': 0,
        'rating': 'No Data',
        'recommendations': ['Start tracking reminder responses']
      };
    }

    int totalReminders = reminderHistory.length;
    int acknowledged = 0;
    int onTimeCompletions = 0;
    int lateCompletions = 0;
    int missed = 0;

    for (var record in reminderHistory) {
      if (record['acknowledged'] == true) acknowledged++;
      if (record['completedOnTime'] == true) onTimeCompletions++;
      if (record['completedLate'] == true) lateCompletions++;
      if (record['missed'] == true) missed++;
    }

    double acknowledgmentRate = acknowledged / totalReminders * 100;
    double onTimeRate = onTimeCompletions / totalReminders * 100;
    double effectivenessScore = (acknowledgmentRate * 0.4 + onTimeRate * 0.6);

    String rating;
    List<String> recommendations = [];

    if (effectivenessScore >= 80) {
      rating = 'Excellent';
      recommendations.add('Continue current reminder strategy');
    } else if (effectivenessScore >= 60) {
      rating = 'Good';
      recommendations.add('Consider increasing reminder frequency');
    } else if (effectivenessScore >= 40) {
      rating = 'Fair';
      recommendations.add('Review reminder timing and content');
      recommendations.add('Consider different communication channels');
    } else {
      rating = 'Poor';
      recommendations.add('Complete overhaul of reminder system needed');
      recommendations.add('Analyze root causes of low effectiveness');
    }

    return {
      'score': effectivenessScore.toStringAsFixed(1),
      'rating': rating,
      'acknowledgmentRate': acknowledgmentRate.toStringAsFixed(1),
      'onTimeRate': onTimeRate.toStringAsFixed(1),
      'statistics': {
        'total': totalReminders,
        'acknowledged': acknowledged,
        'onTime': onTimeCompletions,
        'late': lateCompletions,
        'missed': missed,
      },
      'recommendations': recommendations,
    };
  }
}
