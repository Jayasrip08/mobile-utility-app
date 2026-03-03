import 'dart:math';

class CentralTendency {
  /// Calculate all central tendency measures (Classical Statistics)
  static Map<String, dynamic> calculate(List<double> data) {
    if (data.isEmpty) {
      return {
        'mean': 0,
        'median': 0,
        'mode': [],
        'geometricMean': 0,
        'harmonicMean': 0,
        'trimmedMean': 0,
        'winsorizedMean': 0,
        'analysis': 'No data provided'
      };
    }

    // Sort data
    List<double> sortedData = List.from(data)..sort();

    // 1. Arithmetic Mean (Classical)
    double mean = data.reduce((a, b) => a + b) / data.length;

    // 2. Median (Classical)
    double median = _calculateMedian(sortedData);

    // 3. Mode (Classical)
    List<double> mode = _calculateAllModes(data);

    // 4. Geometric Mean (Classical for multiplicative data)
    double geometricMean = _calculateGeometricMean(data);

    // 5. Harmonic Mean (Classical for rates)
    double harmonicMean = _calculateHarmonicMean(data);

    // 6. Trimmed Mean (10% trimmed - Classical robust estimator)
    double trimmedMean = _calculateTrimmedMean(sortedData, 0.1);

    // 7. Winsorized Mean (10% winsorized - Classical robust estimator)
    double winsorizedMean = _calculateWinsorizedMean(sortedData, 0.1);

    // 8. Midrange (Classical simple measure)
    double midrange = (sortedData.first + sortedData.last) / 2;

    // Analyze which measure is most appropriate
    String analysis =
        _analyzeCentralTendency(data, mean, median, mode, geometricMean);

    return {
      'mean': mean,
      'median': median,
      'mode': mode,
      'geometricMean': geometricMean,
      'harmonicMean': harmonicMean,
      'trimmedMean': trimmedMean,
      'winsorizedMean': winsorizedMean,
      'midrange': midrange,
      'analysis': analysis,
      'recommendation': _getRecommendation(data, mean, median, mode),
    };
  }

  /// Classical median calculation
  static double _calculateMedian(List<double> sortedData) {
    int n = sortedData.length;
    if (n % 2 == 1) {
      return sortedData[n ~/ 2];
    } else {
      return (sortedData[n ~/ 2 - 1] + sortedData[n ~/ 2]) / 2;
    }
  }

  /// Calculate all modes (data can be multimodal)
  static List<double> _calculateAllModes(List<double> data) {
    if (data.isEmpty) return [];

    Map<double, int> frequency = {};
    for (var value in data) {
      frequency[value] = (frequency[value] ?? 0) + 1;
    }

    int maxFrequency = frequency.values.reduce((a, b) => a > b ? a : b);

    // Find all values with max frequency
    List<double> modes = [];
    frequency.forEach((value, count) {
      if (count == maxFrequency) {
        modes.add(value);
      }
    });

    return modes;
  }

  /// Geometric Mean: ∏(x_i)^(1/n)
  static double _calculateGeometricMean(List<double> data) {
    // Handle non-positive values
    bool hasNonPositive = data.any((x) => x <= 0);
    if (hasNonPositive) {
      // Add constant to make all values positive for calculation
      double minValue = data.reduce((a, b) => a < b ? a : b);
      double shift = minValue <= 0 ? (1 - minValue) : 0;

      double product = 1.0;
      for (var value in data) {
        product *= (value + shift);
      }
      double geometricMean = pow(product, 1 / data.length) - shift;
      return geometricMean;
    }

    double product = 1.0;
    for (var value in data) {
      product *= value;
    }
    return pow(product, 1 / data.length).toDouble();
  }

  /// Harmonic Mean: n / Σ(1/x_i)
  static double _calculateHarmonicMean(List<double> data) {
    // Handle zero values
    if (data.any((x) => x == 0)) {
      return 0;
    }

    double sumReciprocals = 0;
    for (var value in data) {
      sumReciprocals += 1 / value;
    }

    return data.length / sumReciprocals;
  }

  /// Trimmed Mean - Classical robust estimator
  static double _calculateTrimmedMean(
      List<double> sortedData, double proportion) {
    if (sortedData.isEmpty) return 0;

    int n = sortedData.length;
    int trimCount = (n * proportion).floor();

    if (2 * trimCount >= n) {
      return sortedData.reduce((a, b) => a + b) / n;
    }

    List<double> trimmedData = sortedData.sublist(trimCount, n - trimCount);
    return trimmedData.reduce((a, b) => a + b) / trimmedData.length;
  }

  /// Winsorized Mean - Classical robust estimator
  static double _calculateWinsorizedMean(
      List<double> sortedData, double proportion) {
    if (sortedData.isEmpty) return 0;

    int n = sortedData.length;
    int winsorizeCount = (n * proportion).floor();

    if (2 * winsorizeCount >= n) {
      return sortedData.reduce((a, b) => a + b) / n;
    }

    double lowerBound = sortedData[winsorizeCount];
    double upperBound = sortedData[n - winsorizeCount - 1];

    double sum = 0;
    for (int i = 0; i < n; i++) {
      double value = sortedData[i];
      if (i < winsorizeCount) {
        value = lowerBound;
      } else if (i >= n - winsorizeCount) {
        value = upperBound;
      }
      sum += value;
    }

    return sum / n;
  }

  /// Analyze which central tendency measure is most appropriate
  static String _analyzeCentralTendency(List<double> data, double mean,
      double median, List<double> mode, double geometricMean) {
    // Check for outliers using IQR method
    List<double> sortedData = List.from(data)..sort();
    double q1 = sortedData[data.length ~/ 4];
    double q3 = sortedData[(3 * data.length) ~/ 4];
    double iqr = q3 - q1;
    double lowerBound = q1 - 1.5 * iqr;
    double upperBound = q3 + 1.5 * iqr;

    int outlierCount =
        data.where((x) => x < lowerBound || x > upperBound).length;

    // Calculate skewness
    double stdDev = sqrt(
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            data.length);
    double skewness = stdDev == 0
        ? 0
        : data.map((x) => pow(x - mean, 3)).reduce((a, b) => a + b) /
            data.length /
            pow(stdDev, 3);

    String analysis = 'Analysis: ';

    if (outlierCount > 0) {
      analysis += 'Data has $outlierCount potential outliers. ';
      analysis += 'Use MEDIAN or TRIMMED MEAN. ';
    } else {
      analysis += 'No significant outliers detected. ';
    }

    if (skewness.abs() > 0.5) {
      analysis +=
          'Data is ${skewness > 0 ? "right" : "left"}-skewed (skewness: ${skewness.toStringAsFixed(2)}). ';
      analysis += 'MEDIAN is preferred over MEAN. ';
    } else {
      analysis += 'Data is approximately symmetric. ';
      analysis += 'MEAN is appropriate. ';
    }

    if (mode.length == 1) {
      analysis += 'Unimodal distribution. ';
    } else if (mode.length > 1) {
      analysis += 'Multimodal distribution with ${mode.length} modes. ';
    }

    // Check if geometric mean is appropriate (multiplicative data)
    if (data.every((x) => x > 0)) {
      double ratioMean = geometricMean / mean;
      if (ratioMean.abs() > 0.1) {
        analysis += 'Consider GEOMETRIC MEAN for multiplicative data. ';
      }
    }

    return analysis;
  }

  /// Get recommendation based on data characteristics
  static String _getRecommendation(
      List<double> data, double mean, double median, List<double> mode) {
    double skewness =
        data.map((x) => pow(x - mean, 3)).reduce((a, b) => a + b) / data.length;
    skewness /= pow(
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length,
        1.5);

    if (skewness.abs() > 1) {
      return 'RECOMMENDATION: Use MEDIAN (data is highly skewed)';
    } else if (mode.length == 1 &&
        data.where((x) => x == mode[0]).length > data.length / 3) {
      return 'RECOMMENDATION: Use MODE (clear central peak)';
    } else if (data.any((x) => x <= 0)) {
      return 'RECOMMENDATION: Use ARITHMETIC MEAN (contains non-positive values)';
    } else {
      return 'RECOMMENDATION: Use ARITHMETIC MEAN (balanced distribution)';
    }
  }
}
