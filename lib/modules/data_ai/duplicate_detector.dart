import 'dart:math';

class DuplicateDetector {
  /// Detect duplicate records using multiple classical methods
  static Map<String, dynamic> detect(List<Map<String, dynamic>> records,
      {List<String>? keyFields, double similarityThreshold = 0.8}) {
    if (records.isEmpty) {
      return {
        'duplicates': [],
        'groups': [],
        'count': 0,
        'percentage': 0,
        'analysis': 'No records provided',
        'method': 'Exact Match + Similarity'
      };
    }

    // Method 1: Exact match detection (Classical)
    Map<String, dynamic> exactMatches = _detectExactMatches(records, keyFields);

    // Method 2: Similarity-based detection (Classical)
    Map<String, dynamic> similarMatches =
        _detectSimilarMatches(records, similarityThreshold);

    // Method 3: Fuzzy matching (Classical)
    Map<String, dynamic> fuzzyMatches = _detectFuzzyMatches(records);

    // Combine results
    List<List<int>> allDuplicateGroups = [];
    allDuplicateGroups.addAll(exactMatches['groups'] as List<List<int>>);
    allDuplicateGroups.addAll(similarMatches['groups'] as List<List<int>>);
    allDuplicateGroups.addAll(fuzzyMatches['groups'] as List<List<int>>);

    // Merge overlapping groups
    List<List<int>> mergedGroups = _mergeDuplicateGroups(allDuplicateGroups);

    // Get all duplicate indices
    Set<int> allDuplicateIndices = {};
    for (var group in mergedGroups) {
      allDuplicateIndices.addAll(group);
    }

    // Extract duplicate records
    List<Map<String, dynamic>> duplicateRecords = [];
    for (int index in allDuplicateIndices) {
      if (index < records.length) {
        duplicateRecords.add(records[index]);
      }
    }

    // Analyze duplicate patterns
    Map<String, dynamic> analysis =
        _analyzeDuplicates(records, mergedGroups, keyFields);

    // Get recommendations
    List<String> recommendations = _getDuplicateRecommendations(
        records, mergedGroups, analysis['patterns']);

    return {
      'duplicates': duplicateRecords,
      'groups': mergedGroups,
      'count': allDuplicateIndices.length,
      'uniqueDuplicates': mergedGroups.length,
      'percentage': (allDuplicateIndices.length / records.length * 100)
          .toStringAsFixed(1),
      'exactMatches': exactMatches,
      'similarMatches': similarMatches,
      'fuzzyMatches': fuzzyMatches,
      'analysis': analysis['text'],
      'patterns': analysis['patterns'],
      'severity': analysis['severity'],
      'recommendations': recommendations,
      'method': 'Combined Classical Methods',
      'thresholdUsed': similarityThreshold,
    };
  }

  /// Method 1: Exact match detection
  static Map<String, dynamic> _detectExactMatches(
      List<Map<String, dynamic>> records, List<String>? keyFields) {
    List<List<int>> groups = [];
    Set<int> processed = {};

    // If key fields specified, use them for comparison
    List<String> fieldsToCheck = keyFields ?? _extractAllFields(records);

    for (int i = 0; i < records.length; i++) {
      if (processed.contains(i)) continue;

      List<int> currentGroup = [i];
      Map<String, dynamic> currentRecord = records[i];

      for (int j = i + 1; j < records.length; j++) {
        if (processed.contains(j)) continue;

        Map<String, dynamic> compareRecord = records[j];
        bool isExactMatch = true;

        for (String field in fieldsToCheck) {
          dynamic val1 = currentRecord[field];
          dynamic val2 = compareRecord[field];

          // Handle different data types
          if (val1 == null && val2 == null) {
            continue;
          } else if (val1 == null || val2 == null) {
            isExactMatch = false;
            break;
          } else if (val1.runtimeType != val2.runtimeType) {
            isExactMatch = false;
            break;
          } else if (val1 != val2) {
            isExactMatch = false;
            break;
          }
        }

        if (isExactMatch) {
          currentGroup.add(j);
          processed.add(j);
        }
      }

      if (currentGroup.length > 1) {
        groups.add(currentGroup);
      }
      processed.add(i);
    }

    return {
      'groups': groups,
      'count': groups.fold(0, (sum, group) => sum + group.length),
      'method': 'Exact Match'
    };
  }

  /// Method 2: Similarity-based detection
  static Map<String, dynamic> _detectSimilarMatches(
      List<Map<String, dynamic>> records, double threshold) {
    List<List<int>> groups = [];
    Set<int> processed = {};

    List<String> textFields = _extractTextFields(records);

    for (int i = 0; i < records.length; i++) {
      if (processed.contains(i)) continue;

      List<int> currentGroup = [i];
      Map<String, dynamic> currentRecord = records[i];

      for (int j = i + 1; j < records.length; j++) {
        if (processed.contains(j)) continue;

        Map<String, dynamic> compareRecord = records[j];
        double overallSimilarity = 0;
        int fieldCount = 0;

        // Calculate similarity for each field
        for (String field in textFields) {
          dynamic val1 = currentRecord[field];
          dynamic val2 = compareRecord[field];

          if (val1 == null || val2 == null) continue;

          if (val1 is String && val2 is String) {
            double similarity = _calculateStringSimilarity(val1, val2);
            overallSimilarity += similarity;
            fieldCount++;
          } else if (val1 is num && val2 is num) {
            // For numeric fields, check if they're close
            double diff =
                (val1 - val2).abs() / (val1.abs() + val2.abs() + 0.0001);
            double similarity = 1 - diff;
            overallSimilarity += similarity;
            fieldCount++;
          }
        }

        if (fieldCount > 0) {
          double avgSimilarity = overallSimilarity / fieldCount;

          if (avgSimilarity >= threshold) {
            currentGroup.add(j);
            processed.add(j);
          }
        }
      }

      if (currentGroup.length > 1) {
        groups.add(currentGroup);
      }
      processed.add(i);
    }

    return {
      'groups': groups,
      'count': groups.fold(0, (sum, group) => sum + group.length),
      'method': 'Similarity-Based',
      'threshold': threshold
    };
  }

  /// Method 3: Fuzzy matching
  static Map<String, dynamic> _detectFuzzyMatches(
      List<Map<String, dynamic>> records) {
    List<List<int>> groups = [];
    Set<int> processed = {};

    // Extract text for fuzzy matching
    List<String> recordTexts = records.map((record) {
      return record.values
          .whereType<String>()
          .map((v) => v.toString())
          .join(' ')
          .toLowerCase();
    }).toList();

    for (int i = 0; i < recordTexts.length; i++) {
      if (processed.contains(i)) continue;

      List<int> currentGroup = [i];
      String currentText = recordTexts[i];

      for (int j = i + 1; j < recordTexts.length; j++) {
        if (processed.contains(j)) continue;

        String compareText = recordTexts[j];
        double similarity =
            _calculateJaccardSimilarity(currentText, compareText);

        if (similarity > 0.7) {
          // High threshold for fuzzy matching
          currentGroup.add(j);
          processed.add(j);
        }
      }

      if (currentGroup.length > 1) {
        groups.add(currentGroup);
      }
      processed.add(i);
    }

    return {
      'groups': groups,
      'count': groups.fold(0, (sum, group) => sum + group.length),
      'method': 'Fuzzy Matching'
    };
  }

  /// Calculate string similarity using multiple classical methods
  static double _calculateStringSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Normalize strings
    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();

    if (s1 == s2) return 1.0;

    // Method 1: Jaccard similarity
    double jaccard = _calculateJaccardSimilarity(s1, s2);

    // Method 2: Dice coefficient
    double dice = _calculateDiceCoefficient(s1, s2);

    // Method 3: Longest Common Subsequence
    double lcs = _calculateLCSSimilarity(s1, s2);

    // Method 4: Edit distance (normalized)
    double edit = _calculateEditDistanceSimilarity(s1, s2);

    // Weighted average
    return (jaccard * 0.25 + dice * 0.25 + lcs * 0.25 + edit * 0.25);
  }

  /// Jaccard similarity: |A ∩ B| / |A ∪ B|
  static double _calculateJaccardSimilarity(String s1, String s2) {
    Set<String> set1 = s1.split('').toSet();
    Set<String> set2 = s2.split('').toSet();

    Set<String> intersection = set1.intersection(set2);
    Set<String> union = set1.union(set2);

    if (union.isEmpty) return 0.0;
    return intersection.length / union.length;
  }

  /// Dice coefficient: 2 * |A ∩ B| / (|A| + |B|)
  static double _calculateDiceCoefficient(String s1, String s2) {
    Set<String> set1 = s1.split('').toSet();
    Set<String> set2 = s2.split('').toSet();

    Set<String> intersection = set1.intersection(set2);

    if (set1.isEmpty && set2.isEmpty) return 1.0;
    if (set1.isEmpty || set2.isEmpty) return 0.0;

    return (2 * intersection.length) / (set1.length + set2.length);
  }

  /// Longest Common Subsequence similarity
  static double _calculateLCSSimilarity(String s1, String s2) {
    int m = s1.length;
    int n = s2.length;

    List<List<int>> dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }

    int lcsLength = dp[m][n];
    int maxLength = max(m, n);

    return maxLength > 0 ? lcsLength / maxLength : 0.0;
  }

  /// Edit distance (Levenshtein) similarity
  static double _calculateEditDistanceSimilarity(String s1, String s2) {
    int m = s1.length;
    int n = s2.length;

    if (m == 0) return n == 0 ? 1.0 : 0.0;
    if (n == 0) return 0.0;

    List<List<int>> dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = min(
            dp[i - 1][j] + 1, // deletion
            min(
                dp[i][j - 1] + 1, // insertion
                dp[i - 1][j - 1] + cost // substitution
                ));
      }
    }

    int distance = dp[m][n];
    int maxLength = max(m, n);

    return maxLength > 0 ? 1 - (distance / maxLength) : 1.0;
  }

  /// Merge overlapping duplicate groups
  static List<List<int>> _mergeDuplicateGroups(List<List<int>> groups) {
    if (groups.isEmpty) return [];

    List<List<int>> merged = [];
    Set<int> processed = {};

    for (var group in groups) {
      if (group.any((index) => processed.contains(index))) {
        // Find overlapping groups
        for (int i = 0; i < merged.length; i++) {
          if (merged[i].any((index) => group.contains(index))) {
            merged[i] = merged[i].toSet().union(group.toSet()).toList()..sort();
            processed.addAll(group);
            break;
          }
        }
      } else {
        merged.add(List.from(group)..sort());
        processed.addAll(group);
      }
    }

    // Remove subsets
    merged = merged.where((group1) {
      return !merged.any((group2) {
        if (identical(group1, group2)) return false;
        return group1.toSet().difference(group2.toSet()).isEmpty;
      });
    }).toList();

    return merged;
  }

  /// Analyze duplicate patterns
  static Map<String, dynamic> _analyzeDuplicates(
      List<Map<String, dynamic>> records,
      List<List<int>> groups,
      List<String>? keyFields) {
    String analysis = 'Duplicate Analysis:\n';
    Map<String, dynamic> patterns = {};

    int totalDuplicates = groups.fold(0, (sum, group) => sum + group.length);
    double duplicatePercentage = (totalDuplicates / records.length) * 100;

    analysis += '• Total records: ${records.length}\n';
    analysis += '• Duplicate records: $totalDuplicates\n';
    analysis +=
        '• Duplicate percentage: ${duplicatePercentage.toStringAsFixed(1)}%\n';
    analysis += '• Duplicate groups: ${groups.length}\n';

    // Determine severity
    String severity;
    if (duplicatePercentage < 1) {
      severity = 'low';
      analysis += '• Severity: Low (minimal duplicates)\n';
    } else if (duplicatePercentage < 10) {
      severity = 'moderate';
      analysis += '• Severity: Moderate\n';
    } else if (duplicatePercentage < 30) {
      severity = 'high';
      analysis += '• Severity: High\n';
    } else {
      severity = 'critical';
      analysis += '• Severity: Critical (data quality issues)\n';
    }

    // Analyze group sizes
    if (groups.isNotEmpty) {
      List<int> groupSizes = groups.map((g) => g.length).toList();
        int maxGroupSize = groupSizes.reduce(max);
      double avgGroupSize =
          groupSizes.reduce((a, b) => a + b) / groupSizes.length;

      analysis += '• Largest group: $maxGroupSize records\n';
      analysis += '• Average group size: ${avgGroupSize.toStringAsFixed(1)}\n';

      patterns['groupSizes'] = groupSizes;
      patterns['maxGroupSize'] = maxGroupSize;
      patterns['avgGroupSize'] = avgGroupSize;
    }

    // Analyze which fields cause duplicates
    if (keyFields != null && groups.isNotEmpty) {
      Map<String, int> fieldDuplicateCount = {};

      for (String field in keyFields) {
        int count = 0;
        for (var group in groups) {
          if (group.length > 1) {
            Set<dynamic> values = {};
            for (int index in group) {
              values.add(records[index][field]);
            }
            if (values.length == 1) {
              count++;
            }
          }
        }
        fieldDuplicateCount[field] = count;
      }

      if (fieldDuplicateCount.isNotEmpty) {
        analysis += '• Duplicate-prone fields:\n';
        fieldDuplicateCount.forEach((field, count) {
          analysis += '  - $field: $count duplicate groups\n';
        });

        patterns['fieldDuplicates'] = fieldDuplicateCount;
      }
    }

    return {
      'text': analysis,
      'patterns': patterns,
      'severity': severity,
      'duplicatePercentage': duplicatePercentage
    };
  }

  /// Get recommendations for handling duplicates
  static List<String> _getDuplicateRecommendations(
      List<Map<String, dynamic>> records,
      List<List<int>> groups,
      Map<String, dynamic> patterns) {
    List<String> recommendations = [];

    double duplicatePercentage = patterns['duplicatePercentage'] ?? 0;
    String severity = patterns['severity'] ?? 'low';

    if (duplicatePercentage < 5) {
      recommendations.add(
          'Minimal duplicates detected. Consider manual review if needed.');
    } else {
      recommendations.add(
          'Implement automated duplicate detection in data entry process.');
      recommendations.add('Review data sources for duplicate generation.');
    }

    if (severity == 'high' || severity == 'critical') {
      recommendations.add('Immediate data cleaning required before analysis.');
      recommendations.add('Investigate root cause of high duplicate rate.');
    }

    // Based on patterns
    if (patterns.containsKey('fieldDuplicates')) {
      Map<String, int> fieldDuplicates = patterns['fieldDuplicates'];
      String mostProblematic = fieldDuplicates.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      recommendations.add('Add validation for field: "$mostProblematic"');
    }

    // Technical recommendations
    recommendations.add('Consider adding unique constraints in database.');
    recommendations
        .add('Implement real-time duplicate checking during data entry.');
    recommendations.add('Establish data deduplication procedures.');

    return recommendations;
  }

  /// Helper: Extract all fields from records
  static List<String> _extractAllFields(List<Map<String, dynamic>> records) {
    Set<String> fields = {};
    for (var record in records) {
      fields.addAll(record.keys);
    }
    return fields.toList();
  }

  /// Helper: Extract text fields from records
  static List<String> _extractTextFields(List<Map<String, dynamic>> records) {
    Set<String> textFields = {};

    for (var record in records) {
      for (var entry in record.entries) {
        if (entry.value is String && (entry.value as String).isNotEmpty) {
          textFields.add(entry.key);
        }
      }
    }

    return textFields.toList();
  }
}
