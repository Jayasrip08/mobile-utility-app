class PriorityAnalyzer {
  static Map<String, dynamic> analyzeTasks(List<Map<String, dynamic>> tasks) {
    // Calculate priority score for each task
    List<Map<String, dynamic>> scoredTasks = [];

    for (var task in tasks) {
      int score = 0;

      // Urgency (1-10)
      score += task['urgency'] as int;

      // Importance (1-10)
      score += task['importance'] as int;

      // Effort (inverse - less effort = higher priority)
      int effort = task['effort'] as int;
      score += (10 - effort.clamp(1, 10));

      // Deadline proximity (days left)
      int daysLeft = task['daysLeft'] as int;
      if (daysLeft <= 1)
        score += 10;
      else if (daysLeft <= 3)
        score += 7;
      else if (daysLeft <= 7)
        score += 5;
      else if (daysLeft <= 14) score += 3;

      // Dependencies
      if (task['dependencies'] == true) score += 3;

      scoredTasks.add({
        ...task,
        'priorityScore': score,
        'priorityLevel': _getPriorityLevel(score),
      });
    }

    // Sort by priority score (descending)
    scoredTasks
        .sort((a, b) => b['priorityScore'].compareTo(a['priorityScore']));

    return {
      'tasks': scoredTasks,
      'highestPriority':
          scoredTasks.isNotEmpty ? scoredTasks.first['name'] : 'None',
      'recommendedOrder': scoredTasks.map((t) => t['name']).toList(),
    };
  }

  static String _getPriorityLevel(int score) {
    if (score >= 35) return 'CRITICAL';
    if (score >= 25) return 'HIGH';
    if (score >= 15) return 'MEDIUM';
    return 'LOW';
  }
}
