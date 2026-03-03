import 'dart:math';

class OutlierDetector {
  /// Detect outliers using multiple classical methods
  static Map<String, dynamic> detect(List<double> data) {
    if (data.isEmpty) {
      return {
        'outliers': [],
        'method': 'None',
        'count': 0,
        'analysis': 'No data provided',
        'suggestions': []
      };
    }

    List<double> sortedData = List.from(data)..sort();

    // Method 1: Z-Score method (Classical)
    List<double> zScoreOutliers = _detectZScoreOutliers(data);

    // Method 2: IQR method (Classical - Tukey's fences)
    List<double> iqrOutliers = _detectIQROutliers(sortedData);

    // Method 3: Modified Z-Score (Classical robust)
    List<double> modifiedZScoreOutliers = _detectModifiedZScoreOutliers(data);

    // Method 4: Standard Deviation method (Classical)
    List<double> stdDevOutliers = _detectStdDevOutliers(data);

    // Method 5: Percentile method (Classical)
    List<double> percentileOutliers = _detectPercentileOutliers(sortedData);

    // Combine all detected outliers
    Set<double> allOutliers = {};
    allOutliers.addAll(zScoreOutliers);
    allOutliers.addAll(iqrOutliers);
    allOutliers.addAll(modifiedZScoreOutliers);
    allOutliers.addAll(stdDevOutliers);
    allOutliers.addAll(percentileOutliers);

    // Determine consensus
    List<double> consensusOutliers = _getConsensusOutliers([
      zScoreOutliers,
      iqrOutliers,
      modifiedZScoreOutliers,
      stdDevOutliers,
      percentileOutliers
    ]);

    // Analyze data characteristics
    Map<String, dynamic> analysis = _analyzeOutliers(data, consensusOutliers);

    // Get suggestions for handling
    List<String> suggestions =
        _getOutlierHandlingSuggestions(data, consensusOutliers);

    // Determine best method
    String bestMethod = _determineBestMethod(data, consensusOutliers);

    return {
      'allOutliers': allOutliers.toList(),
      'consensusOutliers': consensusOutliers,
      'zScoreOutliers': zScoreOutliers,
      'iqrOutliers': iqrOutliers,
      'modifiedZScoreOutliers': modifiedZScoreOutliers,
      'stdDevOutliers': stdDevOutliers,
      'percentileOutliers': percentileOutliers,
      'bestMethod': bestMethod,
      'count': consensusOutliers.length,
      'percentage':
          (consensusOutliers.length / data.length * 100).toStringAsFixed(1),
      'analysis': analysis['analysis'],
      'severity': analysis['severity'],
      'suggestions': suggestions,
      'statistics': {
        'mean': analysis['mean'],
        'stdDev': analysis['stdDev'],
        'median': analysis['median'],
        'q1': analysis['q1'],
        'q3': analysis['q3'],
        'iqr': analysis['iqr'],
      }
    };
  }

  /// Method 1: Z-Score (Classical parametric)
  static List<double> _detectZScoreOutliers(List<double> data) {
    if (data.length < 3) return [];

    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(variance);

    if (stdDev == 0) return [];

    List<double> outliers = [];
    for (var value in data) {
      double zScore = (value - mean) / stdDev;
      if (zScore.abs() > 3) {
        // Classic 3-sigma rule
        outliers.add(value);
      }
    }

    return outliers;
  }

  /// Method 2: IQR method (Tukey's fences - Classical non-parametric)
  static List<double> _detectIQROutliers(List<double> sortedData) {
    if (sortedData.length < 4) return [];

    int n = sortedData.length;
    double q1 = sortedData[n ~/ 4];
    double q3 = sortedData[(3 * n) ~/ 4];
    double iqr = q3 - q1;

    double lowerFence = q1 - 1.5 * iqr;
    double upperFence = q3 + 1.5 * iqr;

    // Extreme outliers (optional)
    // double extremeLowerFence = q1 - 3 * iqr;
    // double extremeUpperFence = q3 + 3 * iqr;

    List<double> outliers = [];
    for (var value in sortedData) {
      if (value < lowerFence || value > upperFence) {
        outliers.add(value);
      }
    }

    return outliers;
  }

  /// Method 3: Modified Z-Score (Classical robust to outliers)
  static List<double> _detectModifiedZScoreOutliers(List<double> data) {
    if (data.length < 3) return [];

    // Calculate median
    List<double> sortedData = List.from(data)..sort();
    double median = _calculateMedian(sortedData);

    // Calculate Median Absolute Deviation (MAD)
    List<double> absoluteDeviations = [];
    for (var value in data) {
      absoluteDeviations.add((value - median).abs());
    }
    absoluteDeviations.sort();
    double mad = _calculateMedian(absoluteDeviations);

    // Modified Z-Score = 0.6745 * (x - median) / MAD
    List<double> outliers = [];
    for (var value in data) {
      if (mad == 0) continue;
      double modifiedZScore = 0.6745 * (value - median).abs() / mad;
      if (modifiedZScore > 3.5) {
        // Classic threshold
        outliers.add(value);
      }
    }

    return outliers;
  }

  /// Method 4: Standard Deviation method (Classical)
  static List<double> _detectStdDevOutliers(List<double> data) {
    if (data.length < 3) return [];

    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(variance);

    List<double> outliers = [];
    for (var value in data) {
      if ((value - mean).abs() > 2 * stdDev) {
        // 2-sigma rule
        outliers.add(value);
      }
    }

    return outliers;
  }

  /// Method 5: Percentile method (Classical)
  static List<double> _detectPercentileOutliers(List<double> sortedData) {
    if (sortedData.length < 10) return [];

    int n = sortedData.length;
    double lowerPercentile = sortedData[(n * 0.01).floor()]; // 1st percentile
    double upperPercentile = sortedData[(n * 0.99).floor()]; // 99th percentile

    List<double> outliers = [];
    for (var value in sortedData) {
      if (value < lowerPercentile || value > upperPercentile) {
        outliers.add(value);
      }
    }

    return outliers;
  }

  /// Get consensus outliers (appear in majority of methods)
  static List<double> _getConsensusOutliers(
      List<List<double>> allOutlierLists) {
    if (allOutlierLists.isEmpty) return [];

    Map<double, int> frequency = {};
    for (var outlierList in allOutlierLists) {
      for (var outlier in outlierList) {
        frequency[outlier] = (frequency[outlier] ?? 0) + 1;
      }
    }

    int majorityThreshold = (allOutlierLists.length / 2).ceil();
    List<double> consensusOutliers = [];

    frequency.forEach((outlier, count) {
      if (count >= majorityThreshold) {
        consensusOutliers.add(outlier);
      }
    });

    return consensusOutliers;
  }

  /// Analyze outlier characteristics
  static Map<String, dynamic> _analyzeOutliers(
      List<double> data, List<double> outliers) {
    if (data.isEmpty) {
      return {
        'analysis': 'No data',
        'severity': 'none',
        'mean': 0,
        'stdDev': 0,
        'median': 0,
        'q1': 0,
        'q3': 0,
        'iqr': 0,
      };
    }

    List<double> sortedData = List.from(data)..sort();
    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(variance);
    double median = _calculateMedian(sortedData);

    int n = sortedData.length;
    double q1 = sortedData[n ~/ 4];
    double q3 = sortedData[(3 * n) ~/ 4];
    double iqr = q3 - q1;

    double outlierPercentage = (outliers.length / data.length * 100);

    String severity;
    String analysis;

    if (outlierPercentage == 0) {
      severity = 'none';
      analysis = 'No outliers detected. Data appears clean.';
    } else if (outlierPercentage < 5) {
      severity = 'low';
      analysis =
          'Minimal outliers ($outlierPercentage%). Likely natural variation.';
    } else if (outlierPercentage < 15) {
      severity = 'moderate';
      analysis = 'Moderate outliers ($outlierPercentage%). Check data quality.';
    } else {
      severity = 'high';
      analysis =
          'High outlier count ($outlierPercentage%). Possible data issues.';
    }

    // Check for pattern
    int lowOutliers = outliers.where((x) => x < median).length;
    int highOutliers = outliers.where((x) => x > median).length;

    if (lowOutliers > highOutliers * 2) {
      analysis += ' Mostly low-side outliers (skew left).';
    } else if (highOutliers > lowOutliers * 2) {
      analysis += ' Mostly high-side outliers (skew right).';
    }

    // Check for clusters
    if (outliers.length >= 3) {
      outliers.sort();
      double range = outliers.last - outliers.first;
      double density = outliers.length / range;
      if (density > 0.5) {
        analysis += ' Outliers appear clustered.';
      }
    }

    return {
      'analysis': analysis,
      'severity': severity,
      'mean': mean,
      'stdDev': stdDev,
      'median': median,
      'q1': q1,
      'q3': q3,
      'iqr': iqr,
    };
  }

  /// Get suggestions for handling outliers
  static List<String> _getOutlierHandlingSuggestions(
      List<double> data, List<double> outliers) {
    List<String> suggestions = [];

    if (outliers.isEmpty) {
      suggestions.add('No outliers detected. Proceed with analysis.');
      return suggestions;
    }

    double outlierPercentage = (outliers.length / data.length * 100);

    if (outlierPercentage < 2) {
      suggestions.add('Ignore outliers (less than 2% of data)');
      suggestions.add('Use robust statistical methods');
    } else if (outlierPercentage < 10) {
      suggestions.add('Investigate source of outliers');
      suggestions.add('Consider winsorizing or trimming');
      suggestions.add('Use median instead of mean');
    } else {
      suggestions.add('Review data collection process');
      suggestions.add('Consider data transformation');
      suggestions.add('Use non-parametric methods');
      suggestions.add('Segment analysis by outlier status');
    }

    // Check data characteristics
    double mean = data.reduce((a, b) => a + b) / data.length;
    List<double> sortedData = List.from(data)..sort();
    double median = _calculateMedian(sortedData);

    if (mean > median * 1.5 || mean < median * 0.67) {
      suggestions.add('Significant skew - use median-based analysis');
    }

    return suggestions;
  }

  /// Determine best detection method for this dataset
  static String _determineBestMethod(
      List<double> data, List<double> consensusOutliers) {
    if (data.length < 10) return 'IQR Method (works well with small samples)';

    // Check normality assumption
    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    // Simple normality check (kurtosis)
    double kurtosis =
        data.map((x) => pow(x - mean, 4)).reduce((a, b) => a + b) / data.length;
    kurtosis = kurtosis / pow(variance, 2) - 3;

    if (kurtosis.abs() < 1) {
      return 'Z-Score Method (data appears normal)';
    } else {
      return 'Modified Z-Score Method (robust to non-normality)';
    }
  }

  /// Helper: Calculate median
  static double _calculateMedian(List<double> sortedData) {
    int n = sortedData.length;
    if (n % 2 == 1) {
      return sortedData[n ~/ 2];
    } else {
      return (sortedData[n ~/ 2 - 1] + sortedData[n ~/ 2]) / 2;
    }
  }
}
