import 'dart:math';

/// Classical AI Technique: Voice Activity Detection using Multiple Features
class VoiceActivity {
  /// Detect voice activity using multiple classical features
  static Map<String, dynamic> detectVoiceActivity(List<int> audioBytes,
      {int sampleRate = 44100}) {
    if (audioBytes.isEmpty) {
      return {
        'hasVoice': false,
        'confidence': 0.0,
        'voiceSegments': [],
        'voiceDuration': 0.0,
        'features': {},
        'classification': 'silence'
      };
    }

    List<double> samples = _bytesToNormalizedSamples(audioBytes);

    // Extract multiple classical features
    Map<String, double> features = _extractFeatures(samples, sampleRate);

    // Rule-based VAD using feature thresholds
    bool hasVoice = _classifyVoiceActivity(features);
    double confidence = _calculateConfidence(features);

    // Detect voice segments
    List<Map<String, dynamic>> voiceSegments =
        _detectVoiceSegments(samples, sampleRate, features);
    double voiceDuration =
        voiceSegments.fold(0.0, (sum, segment) => sum + segment['duration']);
    double totalDuration = samples.length / sampleRate;
    double voiceRatio = totalDuration > 0 ? voiceDuration / totalDuration : 0.0;

    // Classify audio type
    String classification = _classifyAudioType(features, voiceRatio);

    return {
      'hasVoice': hasVoice,
      'confidence': double.parse(confidence.toStringAsFixed(3)),
      'voiceSegments': voiceSegments,
      'voiceDuration': double.parse(voiceDuration.toStringAsFixed(2)),
      'voiceRatio': double.parse(voiceRatio.toStringAsFixed(3)),
      'features': features.map((key, value) =>
          MapEntry(key, double.parse(value.toStringAsFixed(4)))),
      'classification': classification,
      'recommendation': _getVADRecommendation(classification, voiceRatio)
    };
  }

  /// Extract multiple classical audio features
  static Map<String, double> _extractFeatures(
      List<double> samples, int sampleRate) {
    Map<String, double> features = {};

    // 1. Zero Crossing Rate (ZCR)
    features['zcr'] = _calculateZeroCrossingRate(samples);

    // 2. Short-term Energy
    features['energy'] = _calculateShortTermEnergy(samples);

    // 3. Spectral Centroid
    features['spectralCentroid'] =
        _calculateSpectralCentroid(samples, sampleRate);

    // 4. Spectral Rolloff (85%)
    features['spectralRolloff'] =
        _calculateSpectralRolloff(samples, sampleRate, 0.85);

    // 5. Spectral Flux
    features['spectralFlux'] = _calculateSpectralFlux(samples, sampleRate);

    // 6. RMS
    features['rms'] = _calculateRMS(samples);

    // 7. Peak to RMS ratio
    double peak =
        samples.fold(0.0, (max, val) => val.abs() > max ? val.abs() : max);
    var rmsValue = features['rms'];
    features['peakToRMS'] =
        (rmsValue != null && rmsValue > 0) ? peak / rmsValue : 0.0;

    return features;
  }

  /// Rule-based voice activity classification
  static bool _classifyVoiceActivity(Map<String, double> features) {
    // Classical VAD decision rules based on thresholds

    // Rule 1: Check energy level
    bool hasEnergy = features['energy']! > 0.001;

    // Rule 2: Check ZCR range (typical for speech: 0.1 to 0.4)
    bool hasSpeechZCR = features['zcr']! > 0.1 && features['zcr']! < 0.4;

    // Rule 3: Check spectral centroid (speech typically 100-1000 Hz)
    bool hasSpeechSpectral = features['spectralCentroid']! > 100 &&
        features['spectralCentroid']! < 2000;

    // Rule 4: Check spectral flux (speech has moderate flux)
    bool hasModerateFlux =
        features['spectralFlux']! > 0.01 && features['spectralFlux']! < 0.5;

    // Decision: Voice if at least 3 out of 4 rules are satisfied
    int rulesSatisfied = 0;
    if (hasEnergy) rulesSatisfied++;
    if (hasSpeechZCR) rulesSatisfied++;
    if (hasSpeechSpectral) rulesSatisfied++;
    if (hasModerateFlux) rulesSatisfied++;

    return rulesSatisfied >= 3;
  }

  /// Calculate confidence score
  static double _calculateConfidence(Map<String, double> features) {
    double confidence = 0.0;

    // Energy confidence (normalized)
    confidence += (features['energy']!.clamp(0, 0.01) / 0.01) * 0.3;

    // ZCR confidence (Gaussian around 0.25)
    double zcrDiff = (features['zcr']! - 0.25).abs();
    confidence += exp(-zcrDiff * zcrDiff / 0.02) * 0.3;

    // Spectral centroid confidence (prefer 500 Hz)
    double centroidDiff = (features['spectralCentroid']! - 500).abs();
    confidence += exp(-centroidDiff * centroidDiff / 250000) * 0.2;

    // Spectral flux confidence (prefer 0.1)
    double fluxDiff = (features['spectralFlux']! - 0.1).abs();
    confidence += exp(-fluxDiff * fluxDiff / 0.02) * 0.2;

    return confidence.clamp(0, 1);
  }

  /// Detect voice segments using feature analysis
  static List<Map<String, dynamic>> _detectVoiceSegments(List<double> samples,
      int sampleRate, Map<String, double> globalFeatures) {
    List<Map<String, dynamic>> segments = [];

    int windowSize = (sampleRate * 0.05).round(); // 50ms window
    int hopSize = windowSize ~/ 2;

    bool inVoiceSegment = false;
    int segmentStart = 0;

    for (int start = 0; start < samples.length - windowSize; start += hopSize) {
      // Extract window
      List<double> window = [];
      for (int i = 0; i < windowSize && start + i < samples.length; i++) {
        window.add(samples[start + i]);
      }

      // Calculate window features
      Map<String, double> windowFeatures = _extractFeatures(window, sampleRate);

      // Classify this window
      bool isVoice = _classifyVoiceActivity(windowFeatures);

      if (isVoice && !inVoiceSegment) {
        // Start of voice segment
        inVoiceSegment = true;
        segmentStart = start;
      } else if (!isVoice && inVoiceSegment) {
        // End of voice segment
        inVoiceSegment = false;
        double startTime = segmentStart / sampleRate;
        double endTime = start / sampleRate;

        // Only add if duration > 100ms
        if (endTime - startTime > 0.1) {
          segments.add({
            'start': double.parse(startTime.toStringAsFixed(3)),
            'end': double.parse(endTime.toStringAsFixed(3)),
            'duration': double.parse((endTime - startTime).toStringAsFixed(3))
          });
        }
      }
    }

    // Handle final segment
    if (inVoiceSegment) {
      double startTime = segmentStart / sampleRate;
      double endTime = samples.length / sampleRate;

      if (endTime - startTime > 0.1) {
        segments.add({
          'start': double.parse(startTime.toStringAsFixed(3)),
          'end': double.parse(endTime.toStringAsFixed(3)),
          'duration': double.parse((endTime - startTime).toStringAsFixed(3))
        });
      }
    }

    return segments;
  }

  /// Classify audio type based on features
  static String _classifyAudioType(
      Map<String, double> features, double voiceRatio) {
    if (voiceRatio < 0.1) {
      return 'silence';
    } else if (voiceRatio > 0.9) {
      return 'continuous_speech';
    } else if (features['zcr']! > 0.3) {
      return 'music';
    } else if (features['spectralCentroid']! > 1000) {
      return 'noise';
    } else {
      return 'speech_with_pauses';
    }
  }

  /// Get VAD recommendation
  static String _getVADRecommendation(
      String classification, double voiceRatio) {
    switch (classification) {
      case 'silence':
        return "No voice detected. Audio is mostly silent.";
      case 'continuous_speech':
        return "Continuous speech detected. Good for transcription.";
      case 'music':
        return "Music detected. Not suitable for speech processing.";
      case 'noise':
        return "Noise detected. Consider noise reduction first.";
      case 'speech_with_pauses':
        return "Speech with natural pauses detected. ${(voiceRatio * 100).toStringAsFixed(0)}% voice activity.";
      default:
        return "Audio classification completed.";
    }
  }

  /// Feature calculation methods
  static double _calculateZeroCrossingRate(List<double> samples) {
    if (samples.isEmpty) return 0.0;

    int crossings = 0;
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i - 1] >= 0 && samples[i] < 0) ||
          (samples[i - 1] < 0 && samples[i] >= 0)) {
        crossings++;
      }
    }

    return crossings / samples.length;
  }

  static double _calculateShortTermEnergy(List<double> samples) {
    if (samples.isEmpty) return 0.0;

    double energy = 0.0;
    for (double sample in samples) {
      energy += sample * sample;
    }

    return energy / samples.length;
  }

  static double _calculateSpectralCentroid(
      List<double> samples, int sampleRate) {
    if (samples.length < 256) return 0.0;

    // Simplified FFT magnitude calculation
    int n = 256;
    List<double> magnitudes = List<double>.filled(n ~/ 2, 0.0);

    for (int k = 0; k < n ~/ 2; k++) {
      double real = 0.0;
      double imag = 0.0;

      for (int i = 0; i < n && i < samples.length; i++) {
        double angle = 2 * pi * k * i / n;
        real += samples[i] * cos(angle);
        imag += samples[i] * sin(angle);
      }

      magnitudes[k] = sqrt(real * real + imag * imag);
    }

    // Calculate spectral centroid
    double weightedSum = 0.0;
    double sum = 0.0;

    for (int k = 0; k < magnitudes.length; k++) {
      double freq = k * sampleRate / n;
      weightedSum += magnitudes[k] * freq;
      sum += magnitudes[k];
    }

    return sum > 0 ? weightedSum / sum : 0.0;
  }

  static double _calculateSpectralRolloff(
      List<double> samples, int sampleRate, double percentile) {
    if (samples.length < 256) return 0.0;

    int n = 256;
    List<double> magnitudes = List<double>.filled(n ~/ 2, 0.0);

    for (int k = 0; k < n ~/ 2; k++) {
      double real = 0.0;
      double imag = 0.0;

      for (int i = 0; i < n && i < samples.length; i++) {
        double angle = 2 * pi * k * i / n;
        real += samples[i] * cos(angle);
        imag += samples[i] * sin(angle);
      }

      magnitudes[k] = sqrt(real * real + imag * imag);
    }

    // Calculate total spectral energy
    double totalEnergy = magnitudes.fold(0.0, (sum, mag) => sum + mag);
    double targetEnergy = totalEnergy * percentile;

    // Find rolloff frequency
    double cumulativeEnergy = 0.0;
    for (int k = 0; k < magnitudes.length; k++) {
      cumulativeEnergy += magnitudes[k];
      if (cumulativeEnergy >= targetEnergy) {
        return k * sampleRate / n;
      }
    }

    return (magnitudes.length - 1) * sampleRate / n;
  }

  static double _calculateSpectralFlux(List<double> samples, int sampleRate) {
    if (samples.length < 512) return 0.0;

    int n = 256;
    int hop = n ~/ 2;

    List<double> previousMagnitudes = List<double>.filled(n ~/ 2, 0.0);
    double totalFlux = 0.0;
    int frameCount = 0;

    for (int start = 0; start <= samples.length - n; start += hop) {
      // Current frame magnitudes
      List<double> currentMagnitudes = List<double>.filled(n ~/ 2, 0.0);

      for (int k = 0; k < n ~/ 2; k++) {
        double real = 0.0;
        double imag = 0.0;

        for (int i = 0; i < n && start + i < samples.length; i++) {
          double angle = 2 * pi * k * i / n;
          real += samples[start + i] * cos(angle);
          imag += samples[start + i] * sin(angle);
        }

        currentMagnitudes[k] = sqrt(real * real + imag * imag);
      }

      // Calculate flux with previous frame
      if (frameCount > 0) {
        double flux = 0.0;
        for (int k = 0; k < n ~/ 2; k++) {
          double diff = currentMagnitudes[k] - previousMagnitudes[k];
          flux += diff * diff;
        }
        totalFlux += sqrt(flux);
      }

      previousMagnitudes = currentMagnitudes;
      frameCount++;
    }

    return frameCount > 1 ? totalFlux / (frameCount - 1) : 0.0;
  }

  static double _calculateRMS(List<double> samples) {
    if (samples.isEmpty) return 0.0;

    double sumSquares = 0.0;
    for (double sample in samples) {
      sumSquares += sample * sample;
    }

    return sqrt(sumSquares / samples.length);
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
