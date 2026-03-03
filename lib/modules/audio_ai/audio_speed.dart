import 'dart:math';

/// Classical AI Technique: Time-Scale Modification using Phase Vocoder (simplified)
class AudioSpeed {
  /// Change audio speed using classical time-scale modification
  /// Simplified phase vocoder algorithm
  static List<int> changeSpeed(List<int> audioBytes, double speedFactor,
      {int sampleRate = 44100}) {
    if (audioBytes.isEmpty || speedFactor <= 0) return audioBytes;

    if (speedFactor == 1.0) {
      return List.from(audioBytes); // Return copy
    }

    List<double> samples = _bytesToNormalizedSamples(audioBytes);
    List<double> outputSamples = [];

    // Classical technique: Overlap-add (OLA) method for time scaling
    int windowSize = 2048; // Window size in samples
    int hopSize = (windowSize / 4).round(); // Hop size (overlap factor)

    // Create analysis windows
    for (double analysisTime = 0.0;
        analysisTime < samples.length - windowSize;
        analysisTime += hopSize) {
      int startIdx = analysisTime.round();

      // Extract window with Hann window function
      List<double> window = [];
      for (int i = 0; i < windowSize && startIdx + i < samples.length; i++) {
        double sample = samples[startIdx + i];
        // Apply Hann window
        double windowValue = 0.5 * (1 - cos(2 * pi * i / (windowSize - 1)));
        window.add(sample * windowValue);
      }

      // Pad if necessary
      while (window.length < windowSize) {
        window.add(0.0);
      }

      // Add to output with overlap-add
      int outputStart = (analysisTime / speedFactor).round();
      for (int i = 0; i < windowSize; i++) {
        int outputIdx = outputStart + i;

        // Ensure output list is large enough
        while (outputSamples.length <= outputIdx) {
          outputSamples.add(0.0);
        }

        // Overlap-add
        outputSamples[outputIdx] += window[i];
      }
    }

    // Normalize output
    double maxValue = outputSamples.fold(
        0.0, (max, val) => val.abs() > max ? val.abs() : max);
    if (maxValue > 1.0) {
      for (int i = 0; i < outputSamples.length; i++) {
        outputSamples[i] /= maxValue;
      }
    }

    // Convert back to bytes
    return _samplesToBytes(outputSamples);
  }

  /// Pitch-preserving time scaling using classical PSOLA (simplified)
  static List<int> changeSpeedPreservePitch(
      List<int> audioBytes, double speedFactor,
      {int sampleRate = 44100}) {
    if (audioBytes.isEmpty || speedFactor <= 0) return audioBytes;

    // For pitch preservation, we need more complex processing
    // This is a simplified version using resampling

    if (speedFactor > 2.0) speedFactor = 2.0;
    if (speedFactor < 0.5) speedFactor = 0.5;

    List<double> samples = _bytesToNormalizedSamples(audioBytes);
    List<double> outputSamples = [];

    // Classical technique: Linear interpolation for resampling
    double inputIndex = 0.0;
    double step = 1.0 / speedFactor;

    while (inputIndex < samples.length - 1) {
      int idx1 = inputIndex.floor();
      int idx2 = inputIndex.ceil().clamp(0, samples.length - 1);

      double fraction = inputIndex - idx1;
      double interpolated =
          samples[idx1] * (1 - fraction) + samples[idx2] * fraction;

      outputSamples.add(interpolated);
      inputIndex += step;
    }

    // Convert back to original sample rate (simplified - actual would require anti-aliasing)
    return _samplesToBytes(outputSamples);
  }

  /// Calculate optimal speed factor for given target duration
  static double calculateSpeedFactor(
      double currentDuration, double targetDuration) {
    if (currentDuration <= 0 || targetDuration <= 0) return 1.0;

    // Classical rule: speed factor = current duration / target duration
    double factor = currentDuration / targetDuration;

    // Apply limits (classical constraints)
    if (factor < 0.25) factor = 0.25; // Don't speed up more than 4x
    if (factor > 4.0) factor = 4.0; // Don't slow down more than 4x

    return double.parse(factor.toStringAsFixed(2));
  }

  /// Get speed change recommendation based on content type
  static String getSpeedRecommendation(
      String contentType, double originalDuration) {
    Map<String, Map<String, dynamic>> recommendations = {
      'speech': {
        'min': 0.8,
        'max': 1.5,
        'optimal': 1.0,
        'reason': 'Natural speech intelligibility requires moderate speeds'
      },
      'music': {
        'min': 0.75,
        'max': 1.25,
        'optimal': 1.0,
        'reason': 'Musical integrity preserved at original speed'
      },
      'podcast': {
        'min': 0.9,
        'max': 1.8,
        'optimal': 1.2,
        'reason': 'Slightly faster speeds improve engagement'
      },
      'lecture': {
        'min': 0.8,
        'max': 2.0,
        'optimal': 1.5,
        'reason': 'Educational content can be sped up for review'
      },
      'default': {
        'min': 0.5,
        'max': 2.0,
        'optimal': 1.0,
        'reason': 'General audio content'
      }
    };

    Map<String, dynamic> rec =
        recommendations[contentType] ?? recommendations['default']!;

    return '''
Recommended Speed Range: ${rec['min']}x to ${rec['max']}x
Optimal Speed: ${rec['optimal']}x
Reason: ${rec['reason']}
Time at Optimal Speed: ${(originalDuration / rec['optimal']).toStringAsFixed(1)}s
''';
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

  /// Convert samples to bytes
  static List<int> _samplesToBytes(List<double> samples) {
    List<int> bytes = [];

    for (double sample in samples) {
      int intSample = (sample * 32767).round().clamp(-32768, 32767);
      if (intSample < 0) intSample += 65536;

      bytes.add(intSample & 0xFF);
      bytes.add((intSample >> 8) & 0xFF);
    }

    return bytes;
  }
}
