import 'dart:math';

class DataValidator {
  /// Validate data against multiple classical rules
  static Map<String, dynamic> validate(List<double> data,
      {String? dataType, Map<String, dynamic>? constraints}) {
    if (data.isEmpty) {
      return {
        'valid': false,
        'score': 0,
        'issues': ['No data provided'],
        'passedTests': [],
        'failedTests': [],
        'analysis': 'Cannot validate empty data',
        'recommendations': ['Provide data for validation']
      };
    }

    List<String> issues = [];
    List<String> passedTests = [];
    List<String> failedTests = [];
    Map<String, dynamic> detailedResults = {};
    int passedCount = 0;
    int totalTests = 0;

    // Test 1: Basic Completeness
    totalTests++;
    String completenessResult = _testCompleteness(data);
    if (completenessResult.isEmpty) {
      passedTests.add('Completeness');
      passedCount++;
    } else {
      failedTests.add('Completeness');
      issues.add(completenessResult);
    }
    detailedResults['completeness'] =
        completenessResult.isEmpty ? 'PASS' : completenessResult;

    // Test 2: Data Type Consistency
    totalTests++;
    String typeResult = _testDataTypeConsistency(data, dataType);
    if (typeResult.isEmpty) {
      passedTests.add('Type Consistency');
      passedCount++;
    } else {
      failedTests.add('Type Consistency');
      issues.add(typeResult);
    }
    detailedResults['typeConsistency'] =
        typeResult.isEmpty ? 'PASS' : typeResult;

    // Test 3: Range Validation
    totalTests++;
    String rangeResult = _testValueRange(data, constraints);
    if (rangeResult.isEmpty) {
      passedTests.add('Value Range');
      passedCount++;
    } else {
      failedTests.add('Value Range');
      issues.add(rangeResult);
    }
    detailedResults['valueRange'] = rangeResult.isEmpty ? 'PASS' : rangeResult;

    // Test 4: Statistical Validity
    totalTests++;
    String statsResult = _testStatisticalValidity(data);
    if (statsResult.isEmpty) {
      passedTests.add('Statistical Validity');
      passedCount++;
    } else {
      failedTests.add('Statistical Validity');
      issues.add(statsResult);
    }
    detailedResults['statisticalValidity'] =
        statsResult.isEmpty ? 'PASS' : statsResult;

    // Test 5: Pattern Consistency
    totalTests++;
    String patternResult = _testPatternConsistency(data);
    if (patternResult.isEmpty) {
      passedTests.add('Pattern Consistency');
      passedCount++;
    } else {
      failedTests.add('Pattern Consistency');
      issues.add(patternResult);
    }
    detailedResults['patternConsistency'] =
        patternResult.isEmpty ? 'PASS' : patternResult;

    // Test 6: Outlier Detection
    totalTests++;
    String outlierResult = _testOutliers(data);
    if (outlierResult.isEmpty) {
      passedTests.add('Outlier Check');
      passedCount++;
    } else {
      failedTests.add('Outlier Check');
      issues.add(outlierResult);
    }
    detailedResults['outliers'] =
        outlierResult.isEmpty ? 'PASS' : outlierResult;

    // Test 7: Data Distribution
    totalTests++;
    String distributionResult = _testDistribution(data);
    if (distributionResult.isEmpty) {
      passedTests.add('Distribution Check');
      passedCount++;
    } else {
      failedTests.add('Distribution Check');
      issues.add(distributionResult);
    }
    detailedResults['distribution'] =
        distributionResult.isEmpty ? 'PASS' : distributionResult;

    // Test 8: Custom Constraints (if provided)
    if (constraints != null) {
      totalTests++;
      String customResult = _testCustomConstraints(data, constraints);
      if (customResult.isEmpty) {
        passedTests.add('Custom Constraints');
        passedCount++;
      } else {
        failedTests.add('Custom Constraints');
        issues.add(customResult);
      }
      detailedResults['customConstraints'] =
          customResult.isEmpty ? 'PASS' : customResult;
    }

    // Calculate validation score
    double score = totalTests > 0 ? (passedCount / totalTests) * 100 : 0;
    bool overallValid = score >= 70; // At least 70% pass rate

    // Generate analysis
    String analysis = _generateValidationAnalysis(
        data, score, issues, passedTests, failedTests);

    // Generate recommendations
    List<String> recommendations =
        _generateRecommendations(issues, score, data.length);

    // Data quality rating
    String qualityRating = _getQualityRating(score);

    return {
      'valid': overallValid,
      'score': score,
      'qualityRating': qualityRating,
      'passedCount': passedCount,
      'totalTests': totalTests,
      'issues': issues,
      'passedTests': passedTests,
      'failedTests': failedTests,
      'detailedResults': detailedResults,
      'analysis': analysis,
      'recommendations': recommendations,
      'statistics': _calculateValidationStatistics(data),
      'severity': _getSeverityLevel(issues.length, score),
    };
  }

  /// Test 1: Check for completeness (no missing values)
  static String _testCompleteness(List<double> data) {
    // For numerical data in List<double>, completeness means no NaN or Infinite values
    int nanCount = data.where((x) => x.isNaN).length;
    int infiniteCount = data.where((x) => x.isInfinite).length;

    if (nanCount > 0 || infiniteCount > 0) {
      String message = 'Data completeness issues: ';
      if (nanCount > 0) message += '$nanCount NaN values. ';
      if (infiniteCount > 0) message += '$infiniteCount infinite values. ';
      return message.trim();
    }

    return '';
  }

  /// Test 2: Check data type consistency
  static String _testDataTypeConsistency(
      List<double> data, String? expectedType) {
    // All values should be finite numbers (already covered by completeness)
    // Check for extreme values that might indicate wrong data type
    int suspiciousCount = 0;
    List<double> suspiciousValues = [];

    for (var value in data) {
      // Check for values that might be categorical codes mistaken as numeric
      if (value == value.round() && value.abs() < 100) {
        // Could be categorical, but not necessarily wrong
      }

      // Check for extremely large values
      if (value.abs() > 1e15) {
        suspiciousCount++;
        if (suspiciousValues.length < 5) {
          suspiciousValues.add(value);
        }
      }
    }

    if (suspiciousCount > 0) {
      return 'Potential data type issues: $suspiciousCount extremely large values found.';
    }

    return '';
  }

  /// Test 3: Check value ranges
  static String _testValueRange(
      List<double> data, Map<String, dynamic>? constraints) {
    if (data.isEmpty) return '';

    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);

    // Apply constraints if provided
    if (constraints != null) {
      if (constraints.containsKey('min') && minVal < constraints['min']) {
        return 'Value below minimum constraint: $minVal < ${constraints['min']}';
      }
      if (constraints.containsKey('max') && maxVal > constraints['max']) {
        return 'Value above maximum constraint: $maxVal > ${constraints['max']}';
      }
      if (constraints.containsKey('allowedValues')) {
        List<dynamic> allowed = constraints['allowedValues'];
        for (var value in data) {
          if (!allowed.contains(value)) {
            return 'Value $value not in allowed values list';
          }
        }
      }
    }

    // Generic range checks based on data characteristics
    double mean = data.reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            data.length);

    // Check for values too far from mean (potential errors)
    int extremeCount = data.where((x) => (x - mean).abs() > 5 * stdDev).length;
    if (extremeCount > 0 && data.length > 10) {
      return '$extremeCount extreme values (beyond 5 standard deviations from mean)';
    }

    return '';
  }

  /// Test 4: Statistical validity checks
  static String _testStatisticalValidity(List<double> data) {
    if (data.length < 3) return 'Insufficient data for statistical tests';

    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;

    // Check for zero variance (all values identical)
    if (variance == 0) {
      return 'Zero variance - all values are identical';
    }

    // Check for reasonable coefficient of variation
    double cv = (sqrt(variance) / mean.abs()) * 100;
    if (cv.isInfinite || cv.isNaN) {
      return 'Unstable statistical measures (mean near zero)';
    }

    return '';
  }

  /// Test 5: Pattern consistency
  static String _testPatternConsistency(List<double> data) {
    if (data.length < 4) return '';

    // Check for sudden jumps or drops
    List<double> differences = [];
    for (int i = 1; i < data.length; i++) {
      differences.add((data[i] - data[i - 1]).abs());
    }

    double meanDiff = differences.reduce((a, b) => a + b) / differences.length;
    double diffStdDev = sqrt(
        differences.map((d) => pow(d - meanDiff, 2)).reduce((a, b) => a + b) /
            differences.length);

    // Count large jumps
    int largeJumps =
        differences.where((d) => d > meanDiff + 3 * diffStdDev).length;

    if (largeJumps > data.length * 0.1) {
      // More than 10% are large jumps
      return 'Inconsistent pattern: $largeJumps large jumps detected';
    }

    return '';
  }

  /// Test 6: Outlier detection
  static String _testOutliers(List<double> data) {
    if (data.length < 4) return 'Insufficient data for outlier detection';

    List<double> sortedData = List.from(data)..sort();
    int n = sortedData.length;

    double q1 = sortedData[n ~/ 4];
    double q3 = sortedData[(3 * n) ~/ 4];
    double iqr = q3 - q1;

    double lowerBound = q1 - 1.5 * iqr;
    double upperBound = q3 + 1.5 * iqr;

    int outlierCount =
        data.where((x) => x < lowerBound || x > upperBound).length;
    double outlierPercentage = (outlierCount / data.length) * 100;

    if (outlierPercentage > 20) {
      return 'High outlier count: $outlierCount outliers (${outlierPercentage.toStringAsFixed(1)}%)';
    } else if (outlierCount > 0) {
      return '$outlierCount potential outliers detected';
    }

    return '';
  }

  /// Test 7: Distribution check
  static String _testDistribution(List<double> data) {
    if (data.length < 10) return 'Insufficient data for distribution analysis';

    double mean = data.reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            data.length);

    // Check for normality using simplified rule
    int within1Sigma = data.where((x) => (x - mean).abs() <= stdDev).length;

    double pct1Sigma = within1Sigma / data.length;

    // Check for extreme deviation from normal
    if (pct1Sigma < 0.50 || pct1Sigma > 0.80) {
      return 'Distribution may not be normal (${(pct1Sigma * 100).toStringAsFixed(1)}% within 1σ)';
    }

    return '';
  }

  /// Test 8: Custom constraints
  static String _testCustomConstraints(
      List<double> data, Map<String, dynamic> constraints) {
    // Check for required sum
    if (constraints.containsKey('requiredSum')) {
      double actualSum = data.reduce((a, b) => a + b);
      double requiredSum = constraints['requiredSum'];
      double tolerance = constraints['sumTolerance'] ?? 0.01;

      if ((actualSum - requiredSum).abs() > tolerance * requiredSum) {
        return 'Sum mismatch: $actualSum vs required $requiredSum';
      }
    }

    // Check for monotonicity
    if (constraints.containsKey('monotonic')) {
      String direction = constraints['monotonic'];
      bool isIncreasing = true;
      bool isDecreasing = true;

      for (int i = 1; i < data.length; i++) {
        if (data[i] < data[i - 1]) isIncreasing = false;
        if (data[i] > data[i - 1]) isDecreasing = false;
      }

      if (direction == 'increasing' && !isIncreasing) {
        return 'Data not monotonically increasing';
      } else if (direction == 'decreasing' && !isDecreasing) {
        return 'Data not monotonically decreasing';
      }
    }

    return '';
  }

  /// Calculate validation statistics
  static Map<String, dynamic> _calculateValidationStatistics(
      List<double> data) {
    if (data.isEmpty) {
      return {
        'count': 0,
        'mean': 0,
        'stdDev': 0,
        'min': 0,
        'max': 0,
        'range': 0,
        'median': 0
      };
    }

    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(variance);
    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    double range = maxVal - minVal;

    List<double> sortedData = List.from(data)..sort();
    double median = sortedData[sortedData.length ~/ 2];

    return {
      'count': data.length,
      'mean': mean,
      'stdDev': stdDev,
      'min': minVal,
      'max': maxVal,
      'range': range,
      'median': median,
      'variance': variance,
      'cv': (stdDev / mean.abs()) * 100,
    };
  }

  /// Generate validation analysis
  static String _generateValidationAnalysis(List<double> data, double score,
      List<String> issues, List<String> passedTests, List<String> failedTests) {
    String analysis = 'DATA VALIDATION REPORT\n';
    analysis += '=' * 50 + '\n\n';

    analysis += 'SUMMARY\n';
    analysis += '• Validation Score: ${score.toStringAsFixed(1)}%\n';
    analysis += '• Tests Passed: ${passedTests.length}\n';
    analysis += '• Tests Failed: ${failedTests.length}\n';
    analysis += '• Data Points: ${data.length}\n\n';

    if (issues.isEmpty) {
      analysis += '✅ ALL TESTS PASSED\n';
      analysis += 'Data appears valid and ready for analysis.\n';
    } else {
      analysis += '⚠️ VALIDATION ISSUES DETECTED\n\n';
      analysis += 'ISSUES FOUND:\n';
      for (int i = 0; i < issues.length; i++) {
        analysis += '${i + 1}. ${issues[i]}\n';
      }
      analysis += '\n';
    }

    analysis += 'DETAILED RESULTS:\n';
    analysis += '• Passed Tests: ${passedTests.join(', ')}\n';
    if (failedTests.isNotEmpty) {
      analysis += '• Failed Tests: ${failedTests.join(', ')}\n';
    }

    // Add statistical summary
    Map<String, dynamic> stats = _calculateValidationStatistics(data);
    analysis += '\nSTATISTICAL SUMMARY:\n';
    analysis += '• Mean: ${stats['mean'].toStringAsFixed(4)}\n';
    analysis += '• Standard Deviation: ${stats['stdDev'].toStringAsFixed(4)}\n';
    analysis +=
        '• Range: ${stats['min'].toStringAsFixed(4)} to ${stats['max'].toStringAsFixed(4)}\n';
    analysis +=
        '• Coefficient of Variation: ${stats['cv'].toStringAsFixed(1)}%\n';

    return analysis;
  }

  /// Generate recommendations based on validation results
  static List<String> _generateRecommendations(
      List<String> issues, double score, int dataSize) {
    List<String> recommendations = [];

    if (score >= 90) {
      recommendations.add('Data quality is excellent. Proceed with analysis.');
    } else if (score >= 70) {
      recommendations.add(
          'Data quality is acceptable. Review minor issues before analysis.');
    } else if (score >= 50) {
      recommendations.add(
          'Data quality needs improvement. Address issues before analysis.');
    } else {
      recommendations
          .add('Data quality is poor. Significant cleanup required.');
    }

    // Specific recommendations based on issues
    for (var issue in issues) {
      if (issue.contains('NaN') || issue.contains('infinite')) {
        recommendations.add('Remove or impute missing/invalid values');
      }
      if (issue.contains('outlier')) {
        recommendations.add('Investigate outliers for validity');
      }
      if (issue.contains('variance') || issue.contains('identical')) {
        recommendations.add('Check if constant data is expected');
      }
      if (issue.contains('range') || issue.contains('constraint')) {
        recommendations.add('Review data collection boundaries');
      }
    }

    // General recommendations
    if (dataSize < 30) {
      recommendations
          .add('Consider collecting more data for reliable analysis');
    }

    if (issues.isNotEmpty) {
      recommendations.add('Document all data quality issues for reporting');
    }

    return recommendations;
  }

  /// Get quality rating based on score
  static String _getQualityRating(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Acceptable';
    if (score >= 60) return 'Needs Improvement';
    if (score >= 50) return 'Poor';
    return 'Unacceptable';
  }

  /// Get severity level
  static String _getSeverityLevel(int issueCount, double score) {
    if (score >= 90) return 'Low';
    if (score >= 70) return 'Moderate';
    if (score >= 50) return 'High';
    return 'Critical';
  }
}
