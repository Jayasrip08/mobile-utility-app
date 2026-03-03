import 'dart:typed_data';

/// Classical AI Technique: Threshold-based Signal Processing + Pattern Recognition
class SilenceDetector {
  /// Check if audio is silent
  static bool isSilent(dynamic input) {
    if (input is Uint8List) {
      return detectSilence(input)['isSilent'] ?? false;
    }
    return true;
  }

  // Original content continues...
  /// Detect silence using energy threshold (classical signal processing)
  static Map<String, dynamic> detectSilence(List<int> audioBytes,
      {int sampleRate = 44100, double threshold = 0.01}) {
    if (audioBytes.isEmpty) {
      return {
        'isSilent': true,
        'confidence': 1.0,
        'silenceSegments': [],
        'totalSilenceDuration': 0.0
      };
    }

    // Convert bytes to normalized samples (-1 to 1)
    List<double> samples = _bytesToNormalizedSamples(audioBytes);

    // Classical technique: Short-time energy calculation
    int windowSize = (sampleRate * 0.02).round(); // 20ms window
    List<double> energy = [];

    for (int i = 0; i < samples.length - windowSize; i += windowSize ~/ 2) {
      double windowEnergy = 0.0;
      for (int j = 0; j < windowSize && i + j < samples.length; j++) {
        windowEnergy += samples[i + j] * samples[i + j];
      }
      windowEnergy = windowEnergy / windowSize;
      energy.add(windowEnergy);
    }

    // Rule-based silence detection using threshold
    List<bool> isSilentWindow = energy.map((e) => e < threshold).toList();

    // Pattern recognition: Find continuous silent segments
    List<Map<String, dynamic>> silentSegments = [];
    bool inSilentSegment = false;
    int segmentStart = 0;

    for (int i = 0; i < isSilentWindow.length; i++) {
      if (isSilentWindow[i] && !inSilentSegment) {
        // Start of silent segment
        inSilentSegment = true;
        segmentStart = i;
      } else if (!isSilentWindow[i] && inSilentSegment) {
        // End of silent segment
        inSilentSegment = false;
        double startTime = segmentStart * (windowSize / 2) / sampleRate;
        double endTime = i * (windowSize / 2) / sampleRate;
        silentSegments.add({
          'start': double.parse(startTime.toStringAsFixed(2)),
          'end': double.parse(endTime.toStringAsFixed(2)),
          'duration': double.parse((endTime - startTime).toStringAsFixed(2))
        });
      }
    }

    // Calculate total silence duration
    double totalSilence =
        silentSegments.fold(0.0, (sum, segment) => sum + segment['duration']);
    double totalDuration = samples.length / sampleRate;
    double silenceRatio = totalSilence / totalDuration;

    // Classical decision rule: More than 80% silence = silent audio
    bool isSilent = silenceRatio > 0.8;

    return {
      'isSilent': isSilent,
      'confidence': silenceRatio,
      'silenceSegments': silentSegments,
      'totalSilenceDuration': double.parse(totalSilence.toStringAsFixed(2)),
      'silenceRatio': double.parse(silenceRatio.toStringAsFixed(3)),
      'energyProfile': energy,
    };
  }

  /// Zero-crossing rate analysis (classical speech/silence discrimination)
  static double calculateZeroCrossingRate(List<int> audioBytes) {
    if (audioBytes.isEmpty) return 0.0;

    List<double> samples = _bytesToNormalizedSamples(audioBytes);
    int zeroCrossings = 0;

    // Classical technique: Count sign changes
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i - 1] >= 0 && samples[i] < 0) ||
          (samples[i - 1] < 0 && samples[i] >= 0)) {
        zeroCrossings++;
      }
    }

    // Normalize by length
    return zeroCrossings / samples.length;
  }

  /// Convert bytes to normalized samples (-1 to 1)
  static List<double> _bytesToNormalizedSamples(List<int> bytes) {
    // Assume 16-bit PCM
    List<double> samples = [];

    for (int i = 0; i < bytes.length - 1; i += 2) {
      // Combine two bytes to get 16-bit sample
      int sample = (bytes[i] & 0xFF) | ((bytes[i + 1] & 0xFF) << 8);
      // Convert to signed 16-bit
      if (sample >= 32768) sample -= 65536;
      // Normalize to [-1, 1]
      samples.add(sample / 32768.0);
    }

    return samples;
  }
}
