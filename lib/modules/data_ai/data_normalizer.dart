import 'dart:math';

class DataNormalizer {
  /// Normalize data using multiple classical normalization techniques
  static Map<String, dynamic> normalize(List<double> data,
      {String method = 'auto'}) {
    if (data.isEmpty) {
      return {
        'normalized': [],
        'method': 'none',
        'parameters': {},
        'original': [],
        'analysis': 'No data provided',
        'recommendation': 'none'
      };
    }

    // Determine best method if auto
    if (method == 'auto') {
      method = _determineBestMethod(data);
    }

    Map<String, dynamic> result;
    List<double> normalizedData;
    Map<String, dynamic> parameters;

    switch (method.toLowerCase()) {
      case 'minmax':
        result = _minMaxNormalization(data);
        break;
      case 'zscore':
        result = _zScoreNormalization(data);
        break;
      case 'decimal':
        result = _decimalScalingNormalization(data);
        break;
      case 'log':
        result = _logNormalization(data);
        break;
      case 'robust':
        result = _robustNormalization(data);
        break;
      case 'unit':
        result = _unitVectorNormalization(data);
        break;
      default:
        result = _zScoreNormalization(data);
    }

    normalizedData = result['normalized'];
    parameters = result['parameters'];

    // Analysis of normalization
    String analysis = _analyzeNormalization(data, normalizedData, method);
    String recommendation = _getNormalizationRecommendation(data, method);

    // Check if normalization was successful
    bool successful = _checkNormalizationSuccess(normalizedData);

    return {
      'normalized': normalizedData,
      'original': data,
      'method': method,
      'parameters': parameters,
      'successful': successful,
      'analysis': analysis,
      'recommendation': recommendation,
      'statistics': {
        'originalMean': _calculateMean(data),
        'originalStdDev': _calculateStdDev(data),
        'normalizedMean': _calculateMean(normalizedData),
        'normalizedStdDev': _calculateStdDev(normalizedData),
        'rangeBefore': _calculateRange(data),
        'rangeAfter': _calculateRange(normalizedData),
      }
    };
  }

  /// Method 1: Min-Max Normalization (Classical)
  static Map<String, dynamic> _minMaxNormalization(List<double> data) {
    if (data.isEmpty) return {'normalized': [], 'parameters': {}};

    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);

    // Handle case where all values are equal
    if (maxVal == minVal) {
      return {
        'normalized': List.filled(data.length, 0.5),
        'parameters': {'min': minVal, 'max': maxVal, 'range': 0}
      };
    }

    double range = maxVal - minVal;
    List<double> normalized = data.map((x) => (x - minVal) / range).toList();

    return {
      'normalized': normalized,
      'parameters': {'min': minVal, 'max': maxVal, 'range': range}
    };
  }

  /// Method 2: Z-Score Normalization (Standardization)
  static Map<String, dynamic> _zScoreNormalization(List<double> data) {
    if (data.isEmpty) return {'normalized': [], 'parameters': {}};

    double mean = _calculateMean(data);
    double stdDev = _calculateStdDev(data);

    // Handle zero standard deviation
    if (stdDev == 0) {
      return {
        'normalized': List.filled(data.length, 0.0),
        'parameters': {'mean': mean, 'stdDev': stdDev}
      };
    }

    List<double> normalized = data.map((x) => (x - mean) / stdDev).toList();

    return {
      'normalized': normalized,
      'parameters': {'mean': mean, 'stdDev': stdDev}
    };
  }

  /// Method 3: Decimal Scaling Normalization (Classical)
  static Map<String, dynamic> _decimalScalingNormalization(List<double> data) {
    if (data.isEmpty) return {'normalized': [], 'parameters': {}};

    // Find maximum absolute value
    double maxAbs = data.map((x) => x.abs()).reduce((a, b) => a > b ? a : b);

    // Calculate scaling factor
    int j = 0;
    while (maxAbs >= 1) {
      maxAbs /= 10;
      j++;
    }

    double scalingFactor = pow(10, j).toDouble();
    List<double> normalized = data.map((x) => x / scalingFactor).toList();

    return {
      'normalized': normalized,
      'parameters': {'scalingFactor': scalingFactor, 'j': j}
    };
  }

  /// Method 4: Log Transformation (Classical for skewed data)
  static Map<String, dynamic> _logNormalization(List<double> data) {
    if (data.isEmpty) return {'normalized': [], 'parameters': {}};

    // Handle non-positive values by adding constant
    double minVal = data.reduce((a, b) => a < b ? a : b);
    double shift = minVal <= 0 ? (1 - minVal) : 1;

    List<double> normalized = data.map((x) => log(x + shift)).toList();

    // Scale to [0,1] range for consistency
    double normMin = normalized.reduce((a, b) => a < b ? a : b);
    double normMax = normalized.reduce((a, b) => a > b ? a : b);
    double normRange = normMax - normMin;

    if (normRange > 0) {
      normalized = normalized.map((x) => (x - normMin) / normRange).toList();
    }

    return {
      'normalized': normalized,
      'parameters': {'shift': shift, 'originalMin': minVal}
    };
  }

  /// Method 5: Robust Normalization (using median and IQR)
  static Map<String, dynamic> _robustNormalization(List<double> data) {
    if (data.length < 4) return {'normalized': [], 'parameters': {}};

    List<double> sortedData = List.from(data)..sort();

    // Calculate median
    double median = _calculateMedian(sortedData);

    // Calculate IQR
    int n = sortedData.length;
    double q1 = sortedData[n ~/ 4];
    double q3 = sortedData[(3 * n) ~/ 4];
    double iqr = q3 - q1;

    // Handle zero IQR
    if (iqr == 0) {
      // Use MAD instead
      List<double> absDeviations =
          sortedData.map((x) => (x - median).abs()).toList();
      absDeviations.sort();
      double mad = _calculateMedian(absDeviations);

      if (mad == 0) {
        return {
          'normalized': List.filled(data.length, 0.0),
          'parameters': {'median': median, 'iqr': iqr, 'mad': mad}
        };
      }

      List<double> normalized = data.map((x) => (x - median) / mad).toList();

      return {
        'normalized': normalized,
        'parameters': {
          'median': median,
          'iqr': iqr,
          'mad': mad,
          'method': 'MAD'
        }
      };
    }

    List<double> normalized = data.map((x) => (x - median) / iqr).toList();

    return {
      'normalized': normalized,
      'parameters': {'median': median, 'q1': q1, 'q3': q3, 'iqr': iqr}
    };
  }

  /// Method 6: Unit Vector Normalization (L2 norm)
  static Map<String, dynamic> _unitVectorNormalization(List<double> data) {
    if (data.isEmpty) return {'normalized': [], 'parameters': {}};

    // Calculate L2 norm
    double sumSquares = data.map((x) => x * x).reduce((a, b) => a + b);
    double norm = sqrt(sumSquares);

    // Handle zero norm
    if (norm == 0) {
      return {
        'normalized': List.filled(data.length, 0.0),
        'parameters': {'norm': norm}
      };
    }

    List<double> normalized = data.map((x) => x / norm).toList();

    return {
      'normalized': normalized,
      'parameters': {'norm': norm, 'sumSquares': sumSquares}
    };
  }

  /// Determine best normalization method based on data characteristics
  static String _determineBestMethod(List<double> data) {
    if (data.isEmpty) return 'zscore';

    // Check for outliers
    List<double> sortedData = List.from(data)..sort();
    double q1 = sortedData[data.length ~/ 4];
    double q3 = sortedData[(3 * data.length) ~/ 4];
    double iqr = q3 - q1;
    double lowerBound = q1 - 1.5 * iqr;
    double upperBound = q3 + 1.5 * iqr;

    int outlierCount =
        data.where((x) => x < lowerBound || x > upperBound).length;
    double outlierPercentage = (outlierCount / data.length) * 100;

    // Check for skewness
    double mean = _calculateMean(data);
    double median = _calculateMedian(sortedData);
    double skewness = (mean - median).abs() / _calculateStdDev(data);

    // Check range
    double minVal = sortedData.first;
    double maxVal = sortedData.last;
    double range = maxVal - minVal;
    double cv =
        (_calculateStdDev(data) / mean.abs()) * 100; // Coefficient of variation

    if (outlierPercentage > 10) {
      return 'robust'; // Use robust methods with outliers
    } else if (skewness > 1) {
      return 'log'; // Use log transform for skewed data
    } else if (range > 1000 || cv > 100) {
      return 'decimal'; // Use decimal scaling for large ranges
    } else if (data.every((x) => x >= 0) && maxVal <= 1) {
      return 'minmax'; // Already in good range for minmax
    } else {
      return 'zscore'; // Default to z-score
    }
  }

  /// Analyze the normalization results
  static String _analyzeNormalization(
      List<double> original, List<double> normalized, String method) {
    if (original.isEmpty || normalized.isEmpty) {
      return 'No data to analyze';
    }

    String analysis = 'Normalization Analysis ($method):\n';

    double originalMean = _calculateMean(original);
    double normalizedMean = _calculateMean(normalized);
    double originalStdDev = _calculateStdDev(original);
    double normalizedStdDev = _calculateStdDev(normalized);

    analysis +=
        '• Mean: ${originalMean.toStringAsFixed(2)} → ${normalizedMean.toStringAsFixed(2)}\n';
    analysis +=
        '• Std Dev: ${originalStdDev.toStringAsFixed(2)} → ${normalizedStdDev.toStringAsFixed(2)}\n';

    // Check if standardization worked (for z-score)
    if (method == 'zscore' && normalizedStdDev.abs() - 1 < 0.1) {
      analysis += '• Standardization successful (σ ≈ 1)\n';
    }

    // Check if in [0,1] range (for minmax)
    if (method == 'minmax') {
      double normMin = normalized.reduce((a, b) => a < b ? a : b);
      double normMax = normalized.reduce((a, b) => a > b ? a : b);

      if (normMin >= 0 && normMax <= 1) {
        analysis += '• Successfully scaled to [0,1] range\n';
      }
    }

    // Information loss analysis
    double originalVariance = pow(originalStdDev, 2).toDouble();
    double normalizedVariance = pow(normalizedStdDev, 2).toDouble();
    double varianceRatio = normalizedVariance / originalVariance;

    if (varianceRatio < 0.1) {
      analysis += '• Warning: Significant variance reduction\n';
    } else if (varianceRatio > 10) {
      analysis += '• Warning: Variance increased significantly\n';
    }

    return analysis;
  }

  /// Get recommendation for normalization usage
  static String _getNormalizationRecommendation(
      List<double> data, String method) {
    switch (method) {
      case 'minmax':
        return 'Use for: Neural networks, algorithms requiring [0,1] range, image processing';
      case 'zscore':
        return 'Use for: Statistical analysis, algorithms assuming normal distribution, PCA';
      case 'robust':
        return 'Use for: Data with outliers, non-normal distributions, robust statistics';
      case 'log':
        return 'Use for: Highly skewed data, multiplicative relationships, growth rates';
      case 'decimal':
        return 'Use for: Very large numbers, maintaining decimal relationships';
      case 'unit':
        return 'Use for: Vector similarity, cosine distance, text mining';
      default:
        return 'Use for general data preprocessing';
    }
  }

  /// Check if normalization was successful
  static bool _checkNormalizationSuccess(List<double> normalizedData) {
    if (normalizedData.isEmpty) return false;

    // Check for NaN or infinite values
    if (normalizedData.any((x) => x.isNaN || x.isInfinite)) {
      return false;
    }

    // Check if all values are the same (possible failure)
    double first = normalizedData.first;
    if (normalizedData.every((x) => x == first)) {
      return false;
    }

    return true;
  }

  /// Helper methods
  static double _calculateMean(List<double> data) {
    if (data.isEmpty) return 0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  static double _calculateStdDev(List<double> data) {
    if (data.length < 2) return 0;
    double mean = _calculateMean(data);
    double variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    return sqrt(variance);
  }

  static double _calculateRange(List<double> data) {
    if (data.isEmpty) return 0;
    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    return maxVal - minVal;
  }

  static double _calculateMedian(List<double> sortedData) {
    if (sortedData.isEmpty) return 0;
    int n = sortedData.length;
    if (n % 2 == 1) {
      return sortedData[n ~/ 2];
    } else {
      return (sortedData[n ~/ 2 - 1] + sortedData[n ~/ 2]) / 2;
    }
  }
}
