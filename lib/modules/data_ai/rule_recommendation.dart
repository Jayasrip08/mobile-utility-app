import 'dart:math';

class RuleRecommendation {
  /// Generate rule-based recommendations for data
  static Map<String, dynamic> recommend(List<double> data, {String? context}) {
    if (data.isEmpty) {
      return {
        'recommendations': ['No data provided'],
        'analysis': 'No analysis possible',
        'rulesTriggered': [],
        'confidence': 0,
        'severity': 'none',
        'actionItems': [],
        'patterns': {}
      };
    }

    List<String> recommendations = [];
    List<String> rulesTriggered = [];
    List<String> actionItems = [];
    Map<String, dynamic> patterns = {};
    double confidence = 0;
    String severity = 'low';

    // Calculate basic statistics
    double mean = data.reduce((a, b) => a + b) / data.length;
    List<double> sortedData = List.from(data)..sort();
    double median = sortedData[sortedData.length ~/ 2];
    double minVal = sortedData.first;
    double maxVal = sortedData.last;
    double range = maxVal - minVal;

    // Calculate variance and standard deviation
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(variance);
    double cv = (stdDev / mean.abs()) * 100; // Coefficient of variation

    // Rule 1: Check for outliers
    List<double> outliers = _detectOutliersIQR(sortedData);
    if (outliers.isNotEmpty) {
      rulesTriggered.add('OutlierDetection');
      double outlierPercentage = (outliers.length / data.length) * 100;

      if (outlierPercentage > 20) {
        recommendations.add(
            'High outlier count (${outlierPercentage.toStringAsFixed(1)}%). Data quality issues likely.');
        actionItems.add('Investigate data collection process');
        actionItems.add('Consider robust statistical methods');
        severity = 'high';
      } else if (outlierPercentage > 5) {
        recommendations
            .add('Moderate outliers detected. Consider outlier treatment.');
        actionItems.add('Review outlier values for validity');
        actionItems.add('Use median instead of mean for analysis');
        severity = 'moderate';
      }

      patterns['outlierCount'] = outliers.length;
      patterns['outlierPercentage'] = outlierPercentage;
    }

    // Rule 2: Check data spread
    if (cv > 100) {
      rulesTriggered.add('HighVariability');
      recommendations.add(
          'High variability detected (CV = ${cv.toStringAsFixed(1)}%). Data is highly dispersed.');
      actionItems.add('Consider data segmentation');
      actionItems.add('Use non-parametric methods');
      List<String> severityLevels = ['low', 'moderate', 'high'];
      int currentIndex = severityLevels.indexOf(severity);
      int moderateIndex = severityLevels.indexOf('moderate');
      if (currentIndex < moderateIndex) {
        severity = 'moderate';
      }
    } else if (cv < 10) {
      rulesTriggered.add('LowVariability');
      recommendations.add(
          'Low variability (CV = ${cv.toStringAsFixed(1)}%). Data is very consistent.');
      patterns['consistent'] = true;
    }

    // Rule 3: Check for skewness
    double skewness = _calculateSkewness(data, mean, stdDev);
    if (skewness.abs() > 1) {
      rulesTriggered.add('HighSkewness');
      String direction = skewness > 0 ? 'right' : 'left';
      recommendations.add(
          'Highly ${direction}-skewed data (skewness = ${skewness.toStringAsFixed(2)}).');

      if (skewness > 1.5) {
        actionItems.add('Consider log transformation');
        actionItems.add('Use median-based analysis');
        // Custom severity comparison
        List<String> severityLevels = ['low', 'moderate', 'high', 'critical'];
        int currentIndex = severityLevels.indexOf(severity);
        int moderateIndex = severityLevels.indexOf('moderate');
        if (currentIndex < moderateIndex) {
          severity = 'moderate';
        }
      }

      patterns['skewness'] = skewness;
      patterns['skewDirection'] = direction;
    }

    // Rule 4: Check sample size
    if (data.length < 30) {
      rulesTriggered.add('SmallSample');
      recommendations.add(
          'Small sample size (n = ${data.length}). Results may not be representative.');
      actionItems.add('Collect more data if possible');
      actionItems.add('Use caution with statistical inference');
      confidence = 0.6; // Lower confidence for small samples
    } else if (data.length >= 100) {
      rulesTriggered.add('LargeSample');
      recommendations.add('Adequate sample size (n = ${data.length}).');
      confidence = 0.9;
    } else {
      confidence = 0.8;
    }

    // Rule 5: Check for normality (simplified)
    bool appearsNormal = _checkNormality(data, mean, stdDev);
    if (!appearsNormal && data.length >= 20) {
      rulesTriggered.add('NonNormal');
      recommendations.add('Data may not follow normal distribution.');
      actionItems.add('Consider non-parametric tests');
      actionItems.add('Check transformation options');
    }

    // Rule 6: Check for trends (if time series context)
    if (context == 'timeseries' && data.length >= 10) {
      Map<String, dynamic> trendResult = _checkTrend(data);
      if (trendResult['hasTrend']) {
        rulesTriggered.add('TrendDetected');
        String trendDirection = trendResult['direction'];
        recommendations
            .add('${trendDirection} trend detected in time series data.');
        actionItems.add('Consider trend adjustment');
        actionItems.add('Use time series analysis methods');

        patterns['trend'] = trendResult;
      }
    }

    // Rule 7: Check for clusters
    if (data.length >= 20) {
      bool hasClusters = _checkClusters(data);
      if (hasClusters) {
        rulesTriggered.add('ClusteredData');
        recommendations
            .add('Data appears clustered. May represent multiple groups.');
        actionItems.add('Consider cluster analysis');
        actionItems.add('Segment data by clusters');

        patterns['clustered'] = true;
      }
    }

    // Rule 8: Check value range appropriateness
    String rangeAnalysis = _analyzeValueRange(data, context);
    if (rangeAnalysis.isNotEmpty) {
      rulesTriggered.add('RangeAnalysis');
      recommendations.add(rangeAnalysis);
    }

    // Generate summary analysis
    String analysis =
        _generateAnalysis(data, recommendations, rulesTriggered, severity);

    // If no specific recommendations, provide general ones
    if (recommendations.isEmpty) {
      recommendations.add(
          'Data appears normal and well-behaved. Standard statistical methods appropriate.');
    }

    // Calculate overall confidence
    if (confidence == 0) {
      confidence = 0.7 + (rulesTriggered.contains('LargeSample') ? 0.2 : 0.0);
    }

    return {
      'recommendations': recommendations,
      'analysis': analysis,
      'rulesTriggered': rulesTriggered,
      'confidence': confidence,
      'severity': severity,
      'actionItems': actionItems,
      'patterns': patterns,
      'statistics': {
        'mean': mean,
        'median': median,
        'stdDev': stdDev,
        'cv': cv,
        'range': range,
        'min': minVal,
        'max': maxVal,
        'n': data.length
      }
    };
  }

  /// Detect outliers using IQR method
  static List<double> _detectOutliersIQR(List<double> sortedData) {
    if (sortedData.length < 4) return [];

    int n = sortedData.length;
    double q1 = sortedData[n ~/ 4];
    double q3 = sortedData[(3 * n) ~/ 4];
    double iqr = q3 - q1;

    double lowerFence = q1 - 1.5 * iqr;
    double upperFence = q3 + 1.5 * iqr;

    return sortedData.where((x) => x < lowerFence || x > upperFence).toList();
  }

  /// Calculate skewness
  static double _calculateSkewness(
      List<double> data, double mean, double stdDev) {
    if (stdDev == 0) return 0;

    double sumCubed = 0;
    for (var value in data) {
      sumCubed += pow(value - mean, 3);
    }

    double n = data.length.toDouble();
    double moment3 = sumCubed / n;

    return moment3 / pow(stdDev, 3);
  }

  /// Simplified normality check
  static bool _checkNormality(List<double> data, double mean, double stdDev) {
    if (data.length < 8) return true; // Too small to check

    // Check if 68-95-99.7 rule approximately holds
    int within1Sigma = data.where((x) => (x - mean).abs() <= stdDev).length;
    int within2Sigma = data.where((x) => (x - mean).abs() <= 2 * stdDev).length;

    double pct1Sigma = within1Sigma / data.length;
    double pct2Sigma = within2Sigma / data.length;

    // Approximate checks
    return (pct1Sigma >= 0.60 && pct1Sigma <= 0.75) &&
        (pct2Sigma >= 0.90 && pct2Sigma <= 0.98);
  }

  /// Check for trend in data
  static Map<String, dynamic> _checkTrend(List<double> data) {
    if (data.length < 3) return {'hasTrend': false, 'direction': 'none'};

    // Simple trend detection: compare first and last thirds
    int third = data.length ~/ 3;
    if (third < 1) third = 1;

    double firstThirdAvg = data.take(third).reduce((a, b) => a + b) / third;
    double lastThirdAvg =
        data.skip(data.length - third).reduce((a, b) => a + b) / third;

    double change = lastThirdAvg - firstThirdAvg;
    double relativeChange = (change / firstThirdAvg.abs()) * 100;

    bool hasTrend = relativeChange.abs() > 10; // More than 10% change
    String direction = change > 0 ? 'increasing' : 'decreasing';

    return {
      'hasTrend': hasTrend,
      'direction': direction,
      'change': change,
      'relativeChange': relativeChange
    };
  }

  /// Check for clusters using simple rule
  static bool _checkClusters(List<double> data) {
    if (data.length < 20) return false;

    // Sort and look for gaps
    List<double> sortedData = List.from(data)..sort();

    // Calculate gaps between consecutive values
    List<double> gaps = [];
    for (int i = 1; i < sortedData.length; i++) {
      gaps.add(sortedData[i] - sortedData[i - 1]);
    }

    // Find large gaps (potential cluster boundaries)
    double meanGap = gaps.reduce((a, b) => a + b) / gaps.length;
    double gapStdDev = sqrt(
        gaps.map((g) => pow(g - meanGap, 2)).reduce((a, b) => a + b) /
            gaps.length);

    int largeGaps = gaps.where((g) => g > meanGap + 2 * gapStdDev).length;

    return largeGaps >= 2; // At least 2 large gaps suggests clusters
  }

  /// Analyze if values are in appropriate ranges
  static String _analyzeValueRange(List<double> data, String? context) {
    if (data.isEmpty) return '';

    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);

    // Context-specific range checks
    if (context == 'percentages') {
      if (minVal < 0 || maxVal > 100) {
        return 'Values outside 0-100% range. Check data validity.';
      }
    } else if (context == 'probabilities') {
      if (minVal < 0 || maxVal > 1) {
        return 'Values outside 0-1 probability range.';
      }
    } else if (context == 'ratings' || context == 'scores') {
      if (minVal < 1 || maxVal > 10) {
        return 'Check rating scale (values outside typical 1-10 range).';
      }
    }

    // General negative value check
    if (minVal < 0 &&
        context != null &&
        !['returns', 'changes', 'differences'].contains(context)) {
      return 'Negative values present. Confirm if appropriate for context.';
    }

    return '';
  }

  /// Generate comprehensive analysis
  static String _generateAnalysis(
      List<double> data,
      List<String> recommendations,
      List<String> rulesTriggered,
      String severity) {
    String analysis = 'Data Analysis Summary:\n';
    analysis += '• Sample size: ${data.length}\n';
    analysis += '• Rules triggered: ${rulesTriggered.length}\n';
    analysis += '• Severity level: ${severity.toUpperCase()}\n';
    analysis += '\nKey Findings:\n';

    for (int i = 0; i < recommendations.length; i++) {
      analysis += '${i + 1}. ${recommendations[i]}\n';
    }

    // Add statistical summary
    double mean = data.reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            data.length);

    analysis += '\nStatistical Summary:\n';
    analysis += '• Mean: ${mean.toStringAsFixed(2)}\n';
    analysis += '• Standard Deviation: ${stdDev.toStringAsFixed(2)}\n';
    analysis +=
        '• Range: ${data.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} to ${data.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}\n';

    // Data quality assessment
    analysis += '\nData Quality Assessment:\n';
    if (severity == 'low') {
      analysis += '• GOOD: Data appears clean and well-behaved\n';
    } else if (severity == 'moderate') {
      analysis += '• MODERATE: Some issues detected, review recommended\n';
    } else {
      analysis += '• NEEDS ATTENTION: Significant data quality issues\n';
    }

    return analysis;
  }
}
