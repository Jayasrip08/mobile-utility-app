/// Decision tree engine using rule-based branching
class DecisionTree {
  /// Make decision based on input
  static String decide(dynamic input) {
    if (input is int) {
      return _decideOnScore(input);
    } else if (input is Map<String, dynamic>) {
      return _decideOnCriteria(input);
    } else if (input is String) {
      return _decideOnCategory(input);
    } else {
      return "Decision: Unable to process input";
    }
  }

  /// Decide based on score
  static String _decideOnScore(int score) {
    // Decision tree for score-based evaluation
    if (score >= 90) {
      return "Decision: APPROVE WITH HIGHEST PRIORITY\n"
          "Path: Score > 90 → Category A → Immediate Processing\n"
          "Reason: Exceptional score indicates high confidence\n"
          "Next Steps: Expedite processing, notify stakeholders";
    } else if (score >= 75) {
      return "Decision: APPROVE WITH STANDARD PROCESSING\n"
          "Path: 75 ≤ Score < 90 → Category B → Standard Review\n"
          "Reason: Good score meets all requirements\n"
          "Next Steps: Process through standard workflow";
    } else if (score >= 60) {
      return "Decision: REVIEW WITH ADDITIONAL CHECKS\n"
          "Path: 60 ≤ Score < 75 → Category C → Enhanced Review\n"
          "Reason: Marginal score requires verification\n"
          "Next Steps: Additional documentation, supervisor review";
    } else if (score >= 40) {
      return "Decision: REJECT WITH OPTION TO APPEAL\n"
          "Path: 40 ≤ Score < 60 → Category D → Rejection with Appeal\n"
          "Reason: Below minimum threshold\n"
          "Next Steps: Send rejection notice, provide appeal process";
    } else {
      return "Decision: REJECT IMMEDIATELY\n"
          "Path: Score < 40 → Category E → Automatic Rejection\n"
          "Reason: Far below acceptable standards\n"
          "Next Steps: Automated rejection, no further action";
    }
  }

  /// Decide based on multiple criteria
  static String _decideOnCriteria(Map<String, dynamic> criteria) {
    int approvalPoints = 0;
    List<String> factors = [];
    List<String> warnings = [];

    // Financial criteria
    if (criteria.containsKey('creditScore')) {
      int creditScore = criteria['creditScore'];
      if (creditScore >= 750) {
        approvalPoints += 3;
        factors.add("Excellent credit score");
      } else if (creditScore >= 650) {
        approvalPoints += 2;
        factors.add("Good credit score");
      } else if (creditScore >= 550) {
        approvalPoints += 1;
        factors.add("Fair credit score");
      } else {
        approvalPoints -= 2;
        warnings.add("Poor credit score");
      }
    }

    if (criteria.containsKey('income')) {
      double income = criteria['income'];
      if (income >= 100000) {
        approvalPoints += 3;
        factors.add("High income level");
      } else if (income >= 50000) {
        approvalPoints += 2;
        factors.add("Moderate income level");
      } else {
        approvalPoints += 1;
        factors.add("Low income level");
      }
    }

    // Risk criteria
    if (criteria.containsKey('employmentStatus')) {
      String status = criteria['employmentStatus'].toString().toLowerCase();
      if (status.contains('full')) {
        approvalPoints += 2;
        factors.add("Full-time employment");
      } else if (status.contains('part')) {
        approvalPoints += 1;
        factors.add("Part-time employment");
      } else {
        warnings.add("Unstable employment status");
      }
    }

    if (criteria.containsKey('debtRatio')) {
      double debtRatio = criteria['debtRatio'];
      if (debtRatio < 0.3) {
        approvalPoints += 3;
        factors.add("Low debt ratio");
      } else if (debtRatio < 0.5) {
        approvalPoints += 1;
        factors.add("Moderate debt ratio");
      } else {
        approvalPoints -= 2;
        warnings.add("High debt ratio");
      }
    }

    // Additional factors
    if (criteria.containsKey('experience')) {
      int experience = criteria['experience'];
      if (experience > 5) {
        approvalPoints += 2;
        factors.add("Substantial experience");
      } else if (experience > 2) {
        approvalPoints += 1;
        factors.add("Some experience");
      }
    }

    if (criteria.containsKey('collateral') && criteria['collateral'] == true) {
      approvalPoints += 2;
      factors.add("Collateral available");
    }

    // Make decision based on points
    String decision;
    String path;

    if (approvalPoints >= 8) {
      decision = "APPROVE IMMEDIATELY";
      path = "Strong positive indicators across all categories";
    } else if (approvalPoints >= 5) {
      decision = "APPROVE WITH CONDITIONS";
      path = "Generally positive with minor concerns";
    } else if (approvalPoints >= 2) {
      decision = "REVIEW BY COMMITTEE";
      path = "Mixed indicators require human review";
    } else if (approvalPoints >= 0) {
      decision = "REJECT WITH APPEAL OPTION";
      path = "Below threshold but salvageable";
    } else {
      decision = "REJECT IMMEDIATELY";
      path = "Multiple negative factors";
    }

    return "Decision: $decision\n\n"
        "Approval Points: $approvalPoints\n"
        "Decision Path: $path\n\n"
        "Positive Factors:\n${factors.map((f) => '• $f').join('\n')}\n\n"
        "${warnings.isNotEmpty ? 'Warnings:\n${warnings.map((w) => '⚠️ $w').join('\n')}\n\n' : ''}"
        "Next Steps: ${_getNextSteps(decision)}";
  }

  /// Decide based on category
  static String _decideOnCategory(String category) {
    category = category.toLowerCase();

    Map<String, Map<String, dynamic>> decisionTree = {
      'urgent': {
        'decision': 'IMMEDIATE ACTION',
        'path': 'Urgent → High Priority → Immediate Processing',
        'actions': [
          'Notify emergency contacts',
          'Activate response team',
          'Log incident details'
        ],
        'timeframe': 'Immediate'
      },
      'high': {
        'decision': 'PRIORITY PROCESSING',
        'path': 'High → Priority Queue → Expedited Review',
        'actions': [
          'Assign to senior staff',
          'Set 24-hour deadline',
          'Daily progress updates'
        ],
        'timeframe': '24 hours'
      },
      'medium': {
        'decision': 'STANDARD PROCESSING',
        'path': 'Medium → Standard Queue → Regular Review',
        'actions': [
          'Process in order',
          'Weekly status updates',
          'Standard documentation'
        ],
        'timeframe': '3-5 days'
      },
      'low': {
        'decision': 'BACKGROUND PROCESSING',
        'path': 'Low → Background Queue → Batch Processing',
        'actions': [
          'Process during low periods',
          'Monthly review',
          'Minimal documentation'
        ],
        'timeframe': '1-2 weeks'
      },
      'informational': {
        'decision': 'DOCUMENT AND ARCHIVE',
        'path': 'Informational → Documentation → Archival',
        'actions': [
          'File in appropriate category',
          'Update records',
          'No action required'
        ],
        'timeframe': 'When convenient'
      }
    };

    // Find matching category
    String matchedCategory = 'medium'; // Default
    for (var key in decisionTree.keys) {
      if (category.contains(key)) {
        matchedCategory = key;
        break;
      }
    }

    var decision = decisionTree[matchedCategory]!;

    return "Decision: ${decision['decision']}\n\n"
        "Category: ${matchedCategory.toUpperCase()}\n"
        "Decision Path: ${decision['path']}\n"
        "Timeframe: ${decision['timeframe']}\n\n"
        "Required Actions:\n${(decision['actions'] as List).map((a) => '• $a').join('\n')}\n\n"
        "Decision Logic: ${_getDecisionLogic(matchedCategory)}";
  }

  /// Get next steps based on decision
  static String _getNextSteps(String decision) {
    if (decision.contains('APPROVE')) {
      return "1. Generate approval documentation\n"
          "2. Notify applicant\n"
          "3. Update records\n"
          "4. Schedule follow-up";
    } else if (decision.contains('REVIEW')) {
      return "1. Escalate to review committee\n"
          "2. Gather additional information\n"
          "3. Schedule review meeting\n"
          "4. Prepare comprehensive report";
    } else if (decision.contains('REJECT')) {
      return "1. Prepare rejection notice\n"
          "2. Document reasons for rejection\n"
          "3. Update applicant status\n"
          "4. Archive application";
    } else {
      return "1. Log decision\n"
          "2. Continue monitoring\n"
          "3. Standard follow-up procedures";
    }
  }

  /// Get decision logic explanation
  static String _getDecisionLogic(String category) {
    switch (category) {
      case 'urgent':
        return "Urgent items trigger immediate response protocols to prevent escalation";
      case 'high':
        return "High priority items receive expedited processing to meet critical deadlines";
      case 'medium':
        return "Medium priority follows standard workflow with regular monitoring";
      case 'low':
        return "Low priority items are processed during available capacity periods";
      case 'informational':
        return "Informational items are documented for reference without immediate action";
      default:
        return "Standard decision-making process applied";
    }
  }

  /// Build custom decision tree
  static Map<String, dynamic> buildDecisionTree(
      List<Map<String, dynamic>> rules) {
    Map<String, dynamic> tree = {'nodes': [], 'edges': [], 'decisions': []};

    // Process each rule
    for (var rule in rules) {
      String nodeId = rule['id'] ?? 'node_${tree['nodes'].length}';
      String condition = rule['condition']?.toString() ?? '';
      String action = rule['action']?.toString() ?? '';
      List<String> children = List<String>.from(rule['children'] ?? []);

      // Add node
      tree['nodes'].add({
        'id': nodeId,
        'condition': condition,
        'action': action,
        'type': children.isEmpty ? 'leaf' : 'decision'
      });

      // Add edges to children
      for (var childId in children) {
        tree['edges'].add({
          'from': nodeId,
          'to': childId,
          'label': 'Yes' // Default label
        });
      }

      // Add decision if leaf node
      if (children.isEmpty && action.isNotEmpty) {
        tree['decisions'].add({
          'node': nodeId,
          'decision': action,
          'path': _buildPathToNode(tree, nodeId)
        });
      }
    }

    return tree;
  }

  /// Build path to node
  static String _buildPathToNode(
      Map<String, dynamic> tree, String targetNodeId) {
    List<String> path = [];
    String currentNode = targetNodeId;

    while (true) {
      // Find edge leading to this node
      var edge = tree['edges']
          .firstWhere((e) => e['to'] == currentNode, orElse: () => null);

      if (edge == null) break;

      path.insert(0, edge['from']);
      currentNode = edge['from'];
    }

    return path.join(' → ') +
        (path.isNotEmpty ? ' → $targetNodeId' : targetNodeId);
  }

  /// Evaluate decision tree with data
  static Map<String, dynamic> evaluateTree(
      Map<String, dynamic> tree, Map<String, dynamic> data) {
    List<String> path = [];
    List<String> decisions = [];
    String currentNode = 'root';

    // Find root node (node with no incoming edges)
    var rootEdge =
        tree['edges'].firstWhere((e) => false, // This will trigger orElse
            orElse: () {
      for (var node in tree['nodes']) {
        bool hasIncoming = tree['edges'].any((e) => e['to'] == node['id']);
        if (!hasIncoming) {
          return {'from': null, 'to': node['id']};
        }
      }
      return {'from': null, 'to': tree['nodes'][0]['id']};
    });

    currentNode = rootEdge['to'];
    path.add(currentNode);

    // Traverse tree
    while (true) {
      var node = tree['nodes'].firstWhere((n) => n['id'] == currentNode,
          orElse: () => {'type': 'leaf'});

      // If leaf node, record decision
      if (node['type'] == 'leaf') {
        decisions.add(node['action']?.toString() ?? 'No action defined');
        break;
      }

      // Evaluate condition
      String condition = node['condition']?.toString() ?? '';
      bool conditionResult = _evaluateCondition(condition, data);

      // Find next node
      var outgoingEdges =
          tree['edges'].where((e) => e['from'] == currentNode).toList();

      if (outgoingEdges.isEmpty) {
        decisions.add('No outgoing edges from node $currentNode');
        break;
      }

      // For simplicity, assume first edge is 'Yes', second is 'No'
      String nextNode;
      if (outgoingEdges.length >= 2) {
        nextNode =
            conditionResult ? outgoingEdges[0]['to'] : outgoingEdges[1]['to'];
      } else {
        nextNode = conditionResult ? outgoingEdges[0]['to'] : currentNode;
      }

      if (nextNode == currentNode) {
        decisions.add('Stuck at node $currentNode');
        break;
      }

      currentNode = nextNode;
      path.add(currentNode);

      // Prevent infinite loops
      if (path.length > tree['nodes'].length * 2) {
        decisions.add('Possible infinite loop detected');
        break;
      }
    }

    return {
      'path': path,
      'decisions': decisions,
      'finalDecision':
          decisions.isNotEmpty ? decisions.last : 'No decision reached',
      'steps': path.length,
      'dataUsed': data.keys.toList()
    };
  }

  /// Evaluate condition string against data
  static bool _evaluateCondition(String condition, Map<String, dynamic> data) {
    if (condition.isEmpty) return true;

    condition = condition.toLowerCase();

    // Simple condition evaluation
    for (var key in data.keys) {
      if (condition.contains(key.toLowerCase())) {
        var value = data[key];

        // Check for comparison operators
        if (condition.contains('>')) {
          List<String> parts = condition.split('>');
          if (parts.length == 2 && value is num) {
            num threshold = num.tryParse(parts[1].trim()) ?? 0;
            return value > threshold;
          }
        } else if (condition.contains('<')) {
          List<String> parts = condition.split('<');
          if (parts.length == 2 && value is num) {
            num threshold = num.tryParse(parts[1].trim()) ?? 0;
            return value < threshold;
          }
        } else if (condition.contains('=')) {
          List<String> parts = condition.split('=');
          if (parts.length == 2) {
            String expected = parts[1].trim();
            return value.toString().toLowerCase() == expected.toLowerCase();
          }
        } else if (condition.contains('contains')) {
          return value
              .toString()
              .toLowerCase()
              .contains(condition.replaceAll('contains', '').trim());
        }
      }
    }

    return false;
  }
}
