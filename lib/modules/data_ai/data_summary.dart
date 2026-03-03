import 'dart:math';

class DataSummary {
  /// Generates comprehensive statistical summary for numerical data
  static Map<String, dynamic> generate(List<double> data) {
    if (data.isEmpty) {
      return {'error': 'No data provided'};
    }

    // Sort data for calculations
    List<double> sortedData = List.from(data)..sort();

    // Basic statistics
    int count = data.length;
    double sum = _calculateSum(data);
    double mean = _calculateMean(data);
    double median = _calculateMedian(sortedData);
    double mode = _calculateMode(sortedData);
    double min = sortedData.first;
    double max = sortedData.last;
    double range = max - min;

    // Dispersion measures
    double variance = _calculateVariance(data, mean);
    double stdDev = sqrt(variance);
    double q1 = _calculateQuartile(sortedData, 0.25);
    double q3 = _calculateQuartile(sortedData, 0.75);
    double iqr = q3 - q1;

    // Shape measures
    double skewness = _calculateSkewness(data, mean, stdDev);
    double kurtosis = _calculateKurtosis(data, mean, stdDev);

    // Additional statistics
    double coefficientOfVariation = stdDev / mean.abs() * 100;
    double meanAbsoluteDeviation = _calculateMAD(data, mean);
    double standardError = stdDev / sqrt(count);

    // Generate summary text
    String summary = _generateSummaryText(
      count: count,
      mean: mean,
      median: median,
      stdDev: stdDev,
      skewness: skewness,
      kurtosis: kurtosis,
    );

    return {
      // Basic Info
      'count': count,
      'sum': sum,

      // Central Tendency
      'mean': mean,
      'median': median,
      'mode': mode,

      // Dispersion
      'min': min,
      'max': max,
      'range': range,
      'variance': variance,
      'stdDev': stdDev,
      'q1': q1,
      'q3': q3,
      'iqr': iqr,

      // Shape
      'skewness': skewness,
      'kurtosis': kurtosis,

      // Advanced
      'coefficientOfVariation': coefficientOfVariation,
      'meanAbsoluteDeviation': meanAbsoluteDeviation,
      'standardError': standardError,

      // Text Summary
      'summary': summary,
    };
  }

  // Helper Methods

  static double _calculateSum(List<double> data) {
    return data.reduce((a, b) => a + b);
  }

  static double _calculateMean(List<double> data) {
    return _calculateSum(data) / data.length;
  }

  static double _calculateMedian(List<double> sortedData) {
    int n = sortedData.length;
    if (n % 2 == 1) {
      return sortedData[n ~/ 2];
    } else {
      return (sortedData[n ~/ 2 - 1] + sortedData[n ~/ 2]) / 2;
    }
  }

  static double _calculateMode(List<double> sortedData) {
    if (sortedData.isEmpty) return 0;

    double mode = sortedData[0];
    int maxCount = 1;
    int currentCount = 1;
    double currentNumber = sortedData[0];

    for (int i = 1; i < sortedData.length; i++) {
      if (sortedData[i] == currentNumber) {
        currentCount++;
      } else {
        if (currentCount > maxCount) {
          maxCount = currentCount;
          mode = currentNumber;
        }
        currentNumber = sortedData[i];
        currentCount = 1;
      }
    }

    // Check last sequence
    if (currentCount > maxCount) {
      mode = currentNumber;
    }

    return mode;
  }

  static double _calculateVariance(List<double> data, double mean) {
    double sumOfSquares = 0;
    for (double value in data) {
      sumOfSquares += pow(value - mean, 2);
    }
    return sumOfSquares / data.length;
  }

  static double _calculateQuartile(List<double> sortedData, double percentile) {
    int n = sortedData.length;
    double index = (n - 1) * percentile;
    int lower = index.floor();
    int upper = index.ceil();

    if (lower == upper) {
      return sortedData[lower];
    }

    double weight = index - lower;
    return sortedData[lower] * (1 - weight) + sortedData[upper] * weight;
  }

  static double _calculateSkewness(
      List<double> data, double mean, double stdDev) {
    if (stdDev == 0) return 0;

    double n = data.length.toDouble();
    double sumCubes = 0;

    for (double value in data) {
      sumCubes += pow(value - mean, 3);
    }

    return (sumCubes / n) / pow(stdDev, 3);
  }

  static double _calculateKurtosis(
      List<double> data, double mean, double stdDev) {
    if (stdDev == 0) return 0;

    double n = data.length.toDouble();
    double sumQuads = 0;

    for (double value in data) {
      sumQuads += pow(value - mean, 4);
    }

    return (sumQuads / n) / pow(stdDev, 4) - 3; // Excess kurtosis
  }

  static double _calculateMAD(List<double> data, double mean) {
    double sumAbsDev = 0;
    for (double value in data) {
      sumAbsDev += (value - mean).abs();
    }
    return sumAbsDev / data.length;
  }

  static String _generateSummaryText({
    required int count,
    required double mean,
    required double median,
    required double stdDev,
    required double skewness,
    required double kurtosis,
  }) {
    StringBuffer summary = StringBuffer();

    summary.writeln('📊 Statistical Summary\n');
    summary.writeln('• Sample Size: $count observations');
    summary.writeln('• Mean (Average): ${mean.toStringAsFixed(4)}');
    summary.writeln('• Median (Center): ${median.toStringAsFixed(4)}');
    summary.writeln('• Standard Deviation: ${stdDev.toStringAsFixed(4)}');
    summary.writeln('');

    // Interpret skewness
    String skewnessInterpretation;
    if (skewness.abs() < 0.5) {
      skewnessInterpretation = 'The distribution is approximately symmetric.';
    } else if (skewness > 0.5) {
      skewnessInterpretation =
          'The distribution is right-skewed (tail extends to the right).';
    } else {
      skewnessInterpretation =
          'The distribution is left-skewed (tail extends to the left).';
    }

    summary.writeln('• Skewness: ${skewness.toStringAsFixed(4)}');
    summary.writeln('  $skewnessInterpretation');
    summary.writeln('');

    // Interpret kurtosis
    String kurtosisInterpretation;
    if (kurtosis.abs() < 0.5) {
      kurtosisInterpretation = 'The distribution has normal peak (mesokurtic).';
    } else if (kurtosis > 0.5) {
      kurtosisInterpretation = 'The distribution has sharp peak (leptokurtic).';
    } else {
      kurtosisInterpretation = 'The distribution has flat peak (platykurtic).';
    }

    summary.writeln('• Kurtosis: ${kurtosis.toStringAsFixed(4)}');
    summary.writeln('  $kurtosisInterpretation');
    summary.writeln('');

    // Variability interpretation
    double cv = (stdDev / mean.abs()) * 100;
    String variabilityInterpretation;
    if (cv < 15) {
      variabilityInterpretation =
          'Low variability - Data points are close to the mean.';
    } else if (cv < 30) {
      variabilityInterpretation =
          'Moderate variability - Typical spread observed.';
    } else {
      variabilityInterpretation =
          'High variability - Data points are widely dispersed.';
    }

    summary.writeln('• Coefficient of Variation: ${cv.toStringAsFixed(1)}%');
    summary.writeln('  $variabilityInterpretation');

    return summary.toString();
  }

  /// Advanced statistical calculations

  static double calculateGeometricMean(List<double> data) {
    if (data.isEmpty) return 0;
    if (data.any((x) => x <= 0)) {
      throw ArgumentError('Geometric mean requires all positive values');
    }

    double product = data.reduce((a, b) => a * b);
    return pow(product, 1 / data.length).toDouble();
  }

  static double calculateHarmonicMean(List<double> data) {
    if (data.isEmpty) return 0;
    if (data.any((x) => x == 0)) {
      throw ArgumentError('Harmonic mean cannot have zero values');
    }

    double sumReciprocals = data.map((x) => 1 / x).reduce((a, b) => a + b);
    return data.length / sumReciprocals;
  }

  static double calculateTrimmedMean(List<double> data, double trimPercentage) {
    if (data.isEmpty) return 0;
    if (trimPercentage < 0 || trimPercentage > 0.5) {
      throw ArgumentError('Trim percentage must be between 0 and 0.5');
    }

    List<double> sorted = List.from(data)..sort();
    int n = sorted.length;
    int trimCount = (n * trimPercentage).floor();

    if (trimCount * 2 >= n) {
      // If trimming too much, return median
      return _calculateMedian(sorted);
    }

    List<double> trimmed = sorted.sublist(trimCount, n - trimCount);
    return _calculateMean(trimmed);
  }

  static Map<String, double> calculatePercentiles(
      List<double> data, List<double> percentiles) {
    if (data.isEmpty) {
      return {for (var p in percentiles) 'p${(p * 100).round()}': 0};
    }

    List<double> sorted = List.from(data)..sort();
    Map<String, double> result = {};

    for (double p in percentiles) {
      if (p < 0 || p > 1) continue;
      double value = _calculateQuartile(sorted, p);
      result['p${(p * 100).round()}'] = value;
    }

    return result;
  }

  static Map<String, dynamic> detectOutliers(List<double> data) {
    if (data.isEmpty) {
      return {
        'outliers': [],
        'method': 'IQR',
        'threshold': 1.5,
      };
    }

    List<double> sorted = List.from(data)..sort();
    double q1 = _calculateQuartile(sorted, 0.25);
    double q3 = _calculateQuartile(sorted, 0.75);
    double iqr = q3 - q1;

    double lowerBound = q1 - 1.5 * iqr;
    double upperBound = q3 + 1.5 * iqr;

    List<double> outliers = [];
    List<double> extremeOutliers = [];

    for (double value in data) {
      if (value < lowerBound || value > upperBound) {
        outliers.add(value);
      }
      if (value < q1 - 3 * iqr || value > q3 + 3 * iqr) {
        extremeOutliers.add(value);
      }
    }

    return {
      'outliers': outliers,
      'extremeOutliers': extremeOutliers,
      'lowerBound': lowerBound,
      'upperBound': upperBound,
      'method': 'IQR',
      'threshold': 1.5,
    };
  }

  static String getDistributionType(List<double> data) {
    if (data.isEmpty) return 'Unknown';

    Map<String, dynamic> summary = generate(data);
    double skewness = summary['skewness'];
    double kurtosis = summary['kurtosis'];

    if (skewness.abs() < 0.5 && kurtosis.abs() < 1.0) {
      return 'Approximately Normal';
    } else if (skewness > 1.0) {
      return 'Right-Skewed';
    } else if (skewness < -1.0) {
      return 'Left-Skewed';
    } else if (kurtosis > 2.0) {
      return 'Heavy-Tailed (Leptokurtic)';
    } else if (kurtosis < -1.0) {
      return 'Light-Tailed (Platykurtic)';
    } else {
      return 'Irregular';
    }
  }
}
