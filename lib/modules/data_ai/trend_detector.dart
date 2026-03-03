import 'dart:math';

class TrendDetector {
  /// Detect trends in time series data using classical methods
  static Map<String, dynamic> detect(List<double> data,
      {List<String>? timestamps}) {
    if (data.isEmpty) {
      return {
        'trend': 'No data',
        'direction': 'none',
        'strength': 0,
        'confidence': 0,
        'slope': 0,
        'intercept': 0,
        'rSquared': 0,
        'analysis': 'No data provided',
        'forecast': [],
        'seasonality': false,
        'breakpoints': [],
        'method': 'Linear Regression'
      };
    }

    // Method 1: Linear Regression (Classical)
    Map<String, dynamic> linearResult = _linearRegressionAnalysis(data);

    // Method 2: Moving Average (Classical)
    Map<String, dynamic> maResult = _movingAverageAnalysis(data);

    // Method 3: Mann-Kendall Test (Classical non-parametric)
    Map<String, dynamic> mkResult = _mannKendallTest(data);

    // Method 4: Simple Slope Analysis (Classical)
    Map<String, dynamic> slopeResult = _slopeAnalysis(data);

    // Combine results
    String trend =
        _combineTrendResults([linearResult, maResult, mkResult, slopeResult]);
    double confidence =
        _calculateConfidence([linearResult, maResult, mkResult, slopeResult]);

    // Detect seasonality (Classical approach)
    bool hasSeasonality = _detectSeasonality(data);

    // Detect structural breaks (Classical Chow test approximation)
    List<int> breakpoints = _detectBreakpoints(data);

    // Generate forecast (Classical linear extrapolation)
    List<double> forecast = _generateForecast(
        data, linearResult['slope'], linearResult['intercept']);

    // Detailed analysis
    String analysis = _generateTrendAnalysis(
        data, trend, confidence, hasSeasonality, breakpoints);

    return {
      'trend': trend,
      'direction': _getDirection(trend),
      'strength': linearResult['rSquared'],
      'confidence': confidence,
      'slope': linearResult['slope'],
      'intercept': linearResult['intercept'],
      'rSquared': linearResult['rSquared'],
      'pValue': mkResult['pValue'],
      'tau': mkResult['tau'],
      'movingAverage': maResult['trend'],
      'analysis': analysis,
      'forecast': forecast,
      'seasonality': hasSeasonality,
      'breakpoints': breakpoints,
      'method': 'Combined Classical Methods',
      'recommendations':
          _getTrendRecommendations(trend, confidence, hasSeasonality),
    };
  }

  /// Method 1: Linear Regression (Classical OLS)
  static Map<String, dynamic> _linearRegressionAnalysis(List<double> data) {
    int n = data.length;
    List<double> x = List.generate(n, (i) => i.toDouble());

    // Calculate means
    double xMean = x.reduce((a, b) => a + b) / n;
    double yMean = data.reduce((a, b) => a + b) / n;

    // Calculate slope (β1)
    double numerator = 0;
    double denominator = 0;

    for (int i = 0; i < n; i++) {
      numerator += (x[i] - xMean) * (data[i] - yMean);
      denominator += pow(x[i] - xMean, 2);
    }

    double slope = denominator != 0 ? numerator / denominator : 0;
    double intercept = yMean - slope * xMean;

    // Calculate R-squared
    double ssTotal = 0;
    double ssResidual = 0;

    for (int i = 0; i < n; i++) {
      double predicted = intercept + slope * x[i];
      ssTotal += pow(data[i] - yMean, 2);
      ssResidual += pow(data[i] - predicted, 2);
    }

    double rSquared = ssTotal != 0 ? 1 - (ssResidual / ssTotal) : 0;

    // Determine trend
    String trend;
    if (slope > 0.01) {
      trend = 'increasing';
    } else if (slope < -0.01) {
      trend = 'decreasing';
    } else {
      trend = 'stable';
    }

    return {
      'slope': slope,
      'intercept': intercept,
      'rSquared': rSquared,
      'trend': trend,
      'method': 'Linear Regression'
    };
  }

  /// Method 2: Moving Average Analysis (Classical smoothing)
  static Map<String, dynamic> _movingAverageAnalysis(List<double> data) {
    if (data.length < 3) {
      return {'trend': 'insufficient data', 'method': 'Moving Average'};
    }

    // Simple Moving Average (window = 3)
    int window = data.length >= 7 ? 3 : 2;
    List<double> ma = [];

    for (int i = 0; i <= data.length - window; i++) {
      double sum = 0;
      for (int j = 0; j < window; j++) {
        sum += data[i + j];
      }
      ma.add(sum / window);
    }

    // Analyze MA trend
    if (ma.length < 2) {
      return {'trend': 'stable', 'method': 'Moving Average'};
    }

    double firstThird =
        ma.take(ma.length ~/ 3).reduce((a, b) => a + b) / (ma.length ~/ 3);
    double lastThird =
        ma.skip(ma.length - (ma.length ~/ 3)).reduce((a, b) => a + b) /
            (ma.length ~/ 3);
    double change = lastThird - firstThird;

    String trend;
    if (change > 0.05 * firstThird) {
      trend = 'increasing';
    } else if (change < -0.05 * firstThird) {
      trend = 'decreasing';
    } else {
      trend = 'stable';
    }

    return {
      'trend': trend,
      'movingAverages': ma,
      'change': change,
      'method': 'Moving Average'
    };
  }

  /// Method 3: Mann-Kendall Test (Classical non-parametric)
  static Map<String, dynamic> _mannKendallTest(List<double> data) {
    if (data.length < 3) {
      return {
        'trend': 'insufficient data',
        'tau': 0,
        'pValue': 1,
        'method': 'Mann-Kendall'
      };
    }

    int n = data.length;
    int s = 0;

    // Calculate S statistic
    for (int i = 0; i < n - 1; i++) {
      for (int j = i + 1; j < n; j++) {
        s += (data[j] > data[i])
            ? 1
            : (data[j] < data[i])
                ? -1
                : 0;
      }
    }

    // Calculate Kendall's Tau
    double tau = (2.0 * s) / (n * (n - 1));

    // Calculate variance (no ties simplified)
    double varS = (n * (n - 1) * (2 * n + 5)) / 18.0;

    // Calculate Z-score
    double z = (s > 0)
        ? (s - 1) / sqrt(varS)
        : (s < 0)
            ? (s + 1) / sqrt(varS)
            : 0;

    // Approximate p-value (two-tailed)
    double pValue = 2 * (1 - _normalCDF(z.abs()));

    String trend;
    if (pValue < 0.05) {
      trend = tau > 0 ? 'increasing' : 'decreasing';
    } else {
      trend = 'stable';
    }

    return {
      'trend': trend,
      'tau': tau,
      's': s,
      'pValue': pValue,
      'method': 'Mann-Kendall'
    };
  }

  /// Method 4: Simple Slope Analysis
  static Map<String, dynamic> _slopeAnalysis(List<double> data) {
    if (data.length < 2) {
      return {'trend': 'insufficient data', 'method': 'Slope Analysis'};
    }

    // Split data into thirds
    int third = data.length ~/ 3;
    if (third < 1) third = 1;

    double firstThirdAvg = data.take(third).reduce((a, b) => a + b) / third;
    double middleThirdAvg =
        data.skip(third).take(third).reduce((a, b) => a + b) / third;
    double lastThirdAvg =
        data.skip(2 * third).take(third).reduce((a, b) => a + b) / third;

    // Calculate slopes
    double slope1 = (middleThirdAvg - firstThirdAvg) / third;
    double slope2 = (lastThirdAvg - middleThirdAvg) / third;
    double overallSlope = (lastThirdAvg - firstThirdAvg) / (2 * third);

    // Determine trend
    String trend;
    if (overallSlope > 0 && slope1 > 0 && slope2 > 0) {
      trend = 'increasing';
    } else if (overallSlope < 0 && slope1 < 0 && slope2 < 0) {
      trend = 'decreasing';
    } else if (slope1 > 0 && slope2 < 0) {
      trend = 'peaking';
    } else if (slope1 < 0 && slope2 > 0) {
      trend = 'bottoming';
    } else {
      trend = 'stable';
    }

    return {
      'trend': trend,
      'slopes': [slope1, slope2, overallSlope],
      'averages': [firstThirdAvg, middleThirdAvg, lastThirdAvg],
      'method': 'Slope Analysis'
    };
  }

  /// Combine results from multiple methods
  static String _combineTrendResults(List<Map<String, dynamic>> results) {
    Map<String, int> voteCount = {
      'increasing': 0,
      'decreasing': 0,
      'stable': 0
    };

    for (var result in results) {
      String trend = result['trend'];
      if (voteCount.containsKey(trend)) {
        voteCount[trend] = voteCount[trend]! + 1;
      }
    }

    // Find majority
    String majorityTrend = 'stable';
    int maxVotes = 0;

    voteCount.forEach((trend, count) {
      if (count > maxVotes) {
        maxVotes = count;
        majorityTrend = trend;
      }
    });

    return majorityTrend;
  }

  /// Calculate confidence based on agreement
  static double _calculateConfidence(List<Map<String, dynamic>> results) {
    if (results.isEmpty) return 0;

    String majorityTrend = _combineTrendResults(results);
    int agreementCount =
        results.where((r) => r['trend'] == majorityTrend).length;

    return (agreementCount / results.length) * 100;
  }

  /// Detect seasonality using classical differencing
  static bool _detectSeasonality(List<double> data) {
    if (data.length < 8) return false;

    // Simple seasonality test: check if pattern repeats
    int testSeason = data.length >= 12 ? 3 : 2;

    for (int lag = 1; lag <= testSeason; lag++) {
      double correlation = 0;
      int count = 0;

      for (int i = 0; i < data.length - lag; i++) {
        correlation += data[i] * data[i + lag];
        count++;
      }

      if (count > 0) {
        correlation /= count;
        // If correlation is high at certain lag, might indicate seasonality
        if (correlation.abs() > 0.7) {
          return true;
        }
      }
    }

    return false;
  }

  /// Detect structural breakpoints
  static List<int> _detectBreakpoints(List<double> data) {
    if (data.length < 10) return [];

    List<int> breakpoints = [];

    // Simple breakpoint detection: significant change in slope
    for (int i = 5; i < data.length - 5; i++) {
      List<double> before = data.sublist(0, i);
      List<double> after = data.sublist(i);

      double slopeBefore = _linearRegressionAnalysis(before)['slope'];
      double slopeAfter = _linearRegressionAnalysis(after)['slope'];

      if ((slopeAfter - slopeBefore).abs() > 0.5) {
        breakpoints.add(i);
      }
    }

    return breakpoints;
  }

  /// Generate forecast using classical linear extrapolation
  static List<double> _generateForecast(
      List<double> data, double slope, double intercept) {
    List<double> forecast = [];
    int forecastPeriod = 3; // Forecast next 3 periods

    for (int i = 1; i <= forecastPeriod; i++) {
      double predicted = intercept + slope * (data.length + i - 1);
      forecast.add(predicted);
    }

    return forecast;
  }

  /// Generate detailed trend analysis
  static String _generateTrendAnalysis(List<double> data, String trend,
      double confidence, bool hasSeasonality, List<int> breakpoints) {
    String analysis = 'Trend Analysis:\n';
    analysis += '• Primary Trend: $trend\n';
    analysis += '• Confidence: ${confidence.toStringAsFixed(1)}%\n';

    if (hasSeasonality) {
      analysis += '• Seasonality: Detected (consider seasonal adjustment)\n';
    } else {
      analysis += '• Seasonality: No significant pattern detected\n';
    }

    if (breakpoints.isNotEmpty) {
      analysis += '• Structural Breaks: ${breakpoints.length} detected\n';
    }

    // Add data characteristics
    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    double stdDev = sqrt(variance);
    double cv = (stdDev / mean) * 100; // Coefficient of variation

    analysis += '• Volatility: ${cv.toStringAsFixed(1)}% CV\n';

    if (confidence > 80) {
      analysis += '• Reliability: High confidence in trend direction\n';
    } else if (confidence > 60) {
      analysis += '• Reliability: Moderate confidence\n';
    } else {
      analysis += '• Reliability: Low confidence, consider more data\n';
    }

    return analysis;
  }

  /// Get recommendations based on trend analysis
  static List<String> _getTrendRecommendations(
      String trend, double confidence, bool hasSeasonality) {
    List<String> recommendations = [];

    if (trend == 'increasing') {
      recommendations.add('Consider scaling operations to match growth');
      recommendations.add('Monitor for sustainability of growth trend');
    } else if (trend == 'decreasing') {
      recommendations.add('Investigate causes of decline');
      recommendations.add('Consider intervention strategies');
    } else {
      recommendations.add('Maintain current operations');
      recommendations.add('Monitor for trend changes');
    }

    if (hasSeasonality) {
      recommendations.add('Apply seasonal adjustment for better analysis');
      recommendations.add('Plan for seasonal variations');
    }

    if (confidence < 70) {
      recommendations.add('Collect more data for reliable trend detection');
      recommendations.add('Use caution when making decisions based on trend');
    }

    return recommendations;
  }

  /// Helper: Normal CDF approximation
  static double _normalCDF(double x) {
    // Abramowitz and Stegun approximation
    double t = 1 / (1 + 0.2316419 * x.abs());
    double d = 0.3989423 * exp(-x * x / 2);
    double probability = d *
        t *
        (0.3193815 +
            t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));

    if (x > 0) {
      return 1 - probability;
    } else {
      return probability;
    }
  }

  /// Get direction from trend
  static String _getDirection(String trend) {
    switch (trend) {
      case 'increasing':
        return 'up';
      case 'decreasing':
        return 'down';
      case 'peaking':
        return 'up then down';
      case 'bottoming':
        return 'down then up';
      default:
        return 'flat';
    }
  }
}
