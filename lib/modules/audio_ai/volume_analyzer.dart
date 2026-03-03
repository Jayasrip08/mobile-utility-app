import 'dart:math';
import 'dart:typed_data';

/// Classical AI Technique: Signal Energy Analysis + Statistical Metrics
class VolumeAnalyzer {
  /// Calculate volume level from audio bytes
  static double calculateVolume(dynamic input) {
    if (input is Uint8List) {
      return calculateRMS(input);
    }
    return 0.0;
  }

  // Original content continues...
  /// Calculate Root Mean Square (RMS) volume (classical signal processing)
  static double calculateRMS(List<int> audioBytes) {
    if (audioBytes.isEmpty) return 0.0;

    List<double> samples = _bytesToNormalizedSamples(audioBytes);

    // Classical RMS formula: sqrt(sum(samples²) / N)
    double sumSquares = 0.0;
    for (double sample in samples) {
      sumSquares += sample * sample;
    }

    double rms = sumSquares > 0 ? sqrt(sumSquares / samples.length) : 0.0;
    return double.parse(rms.toStringAsFixed(4));
  }

  /// Calculate peak amplitude (classical signal analysis)
  static double calculatePeakAmplitude(List<int> audioBytes) {
    if (audioBytes.isEmpty) return 0.0;

    List<double> samples = _bytesToNormalizedSamples(audioBytes);

    // Find maximum absolute value
    double peak = 0.0;
    for (double sample in samples) {
      double absSample = sample.abs();
      if (absSample > peak) peak = absSample;
    }

    return double.parse(peak.toStringAsFixed(4));
  }

  /// Calculate loudness using ITU-R BS.1770 inspired algorithm (simplified)
  static double calculateLoudness(List<int> audioBytes,
      {int sampleRate = 44100}) {
    if (audioBytes.isEmpty) return -double.infinity;

    List<double> samples = _bytesToNormalizedSamples(audioBytes);

    // Classical technique: Apply K-weighting filter (simplified)
    // Pre-filter: high-pass at 150Hz (approximation)
    List<double> filtered = _applyHighPassFilter(samples, sampleRate, 150.0);

    // Mean square calculation with sliding window
    int windowSize = (sampleRate * 0.4).round(); // 400ms window
    List<double> meanSquareValues = [];

    for (int i = 0; i < filtered.length - windowSize; i += windowSize ~/ 2) {
      double sum = 0.0;
      for (int j = 0; j < windowSize && i + j < filtered.length; j++) {
        sum += filtered[i + j] * filtered[i + j];
      }
      meanSquareValues.add(sum / windowSize);
    }

    if (meanSquareValues.isEmpty) return -double.infinity;

    // Calculate integrated loudness (simplified)
    // Sort and take 95th percentile (gate)
    meanSquareValues.sort();
    int gateIndex = (meanSquareValues.length * 0.05).floor();
    double gatedSum = 0.0;
    int gatedCount = 0;

    for (int i = gateIndex; i < meanSquareValues.length; i++) {
      gatedSum += meanSquareValues[i];
      gatedCount++;
    }

    double meanSquare = gatedCount > 0 ? gatedSum / gatedCount : 0.0;

    // Convert to LUFS: -0.691 + 10*log10(meanSquare)
    double lufs = meanSquare > 0
        ? -0.691 + 10 * log(meanSquare) / log(10)
        : -double.infinity;

    return double.parse(lufs.toStringAsFixed(1));
  }

  /// Calculate dynamic range (peak to RMS ratio)
  static double calculateDynamicRange(List<int> audioBytes) {
    double peak = calculatePeakAmplitude(audioBytes);
    double rms = calculateRMS(audioBytes);

    if (rms > 0) {
      // Convert to dB: 20 * log10(peak/rms)
      double dynamicRangeDb = 20 * log(peak / rms) / log(10);
      return double.parse(dynamicRangeDb.toStringAsFixed(2));
    }

    return 0.0;
  }

  /// Apply simple high-pass filter (difference equation)
  static List<double> _applyHighPassFilter(
      List<double> samples, int sampleRate, double cutoffFreq) {
    if (samples.isEmpty) return samples;

    double rc = 1.0 / (2 * pi * cutoffFreq);
    double dt = 1.0 / sampleRate;
    double alpha = rc / (rc + dt);

    List<double> filtered = List<double>.filled(samples.length, 0.0);

    // First-order high-pass filter
    filtered[0] = samples[0];
    for (int i = 1; i < samples.length; i++) {
      filtered[i] = alpha * (filtered[i - 1] + samples[i] - samples[i - 1]);
    }

    return filtered;
  }

  /// Convert bytes to normalized samples
  static List<double> _bytesToNormalizedSamples(List<int> bytes) {
    List<double> samples = [];

    for (int i = 0; i < bytes.length - 1; i += 2) {
      int sample = (bytes[i] & 0xFF) | ((bytes[i + 1] & 0xFF) << 8);
      if (sample >= 32768) sample -= 65536;
      samples.add(sample / 32768.0);
    }

    return samples;
  }
}
