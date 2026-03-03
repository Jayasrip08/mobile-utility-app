import 'package:ai_tools_app/modules/audio_ai/silence_detector.dart';
import 'package:ai_tools_app/modules/audio_ai/volume_analyzer.dart';
import 'dart:math';
import 'dart:typed_data';

/// Classical AI Technique: Statistical Noise Estimation + Spectral Analysis
class NoiseEstimator {
  static double calculateNoiseLevel(dynamic input, int sampleRate) {
    // Stub implementation
    return 0.0;
  }

  /// Estimate noise level
  static double estimate(dynamic input) {
    if (input is Uint8List) {
      return calculateNoiseLevel(input, 44100);
    }
    return 0.0;
  }

  // Original content continues...
  /// Estimate noise floor using statistical methods
  static Map<String, dynamic> estimateNoise(List<int> audioBytes,
      {int sampleRate = 44100}) {
    if (audioBytes.isEmpty) {
      return {
        'noiseLevel': 0.0,
        'snrDb': 0.0,
        'isNoisy': false,
        'noiseType': 'silent',
        'confidence': 0.0
      };
    }

    List<double> samples = _bytesToNormalizedSamples(audioBytes);

    // Classical technique: Estimate noise from silent segments
    Map<String, dynamic> silenceInfo =
        SilenceDetector.detectSilence(audioBytes);
    List<Map<String, dynamic>> silentSegments =
        silenceInfo['silenceSegments'] as List<Map<String, dynamic>>;

    // Extract noise samples from silent segments
    List<double> noiseSamples = [];
    for (var segment in silentSegments) {
      int startIdx = (segment['start'] * sampleRate).round();
      int endIdx = (segment['end'] * sampleRate).round();
      startIdx = startIdx.clamp(0, samples.length - 1);
      endIdx = endIdx.clamp(0, samples.length - 1);

      for (int i = startIdx; i < endIdx && i < samples.length; i++) {
        noiseSamples.add(samples[i]);
      }
    }

    // If no silent segments, use statistical estimation
    double noiseLevel;
    if (noiseSamples.isEmpty) {
      // Classical statistical estimation: assume noise is in low-energy regions
      List<double> energies = [];
      int windowSize = (sampleRate * 0.05).round(); // 50ms

      for (int i = 0; i < samples.length - windowSize; i += windowSize) {
        double energy = 0.0;
        for (int j = 0; j < windowSize && i + j < samples.length; j++) {
          energy += samples[i + j] * samples[i + j];
        }
        energies.add(energy / windowSize);
      }

      // Sort and take lower quartile as noise estimate
      energies.sort();
      int noiseIndex = (energies.length * 0.25).floor();
      noiseLevel = energies[noiseIndex];
    } else {
      // Calculate RMS of noise samples
      noiseLevel = VolumeAnalyzer.calculateRMS(_samplesToBytes(noiseSamples));
    }

    // Calculate signal power
    double signalPower = VolumeAnalyzer.calculateRMS(audioBytes);

    // Calculate SNR in dB
    double snrDb =
        noiseLevel > 0 ? 20 * log(signalPower / noiseLevel) / log(10) : 100.0;

    // Rule-based noise classification
    String noiseType;
    bool isNoisy;

    if (snrDb < 10) {
      noiseType = 'high_noise';
      isNoisy = true;
    } else if (snrDb < 20) {
      noiseType = 'moderate_noise';
      isNoisy = true;
    } else if (snrDb < 30) {
      noiseType = 'low_noise';
      isNoisy = false;
    } else {
      noiseType = 'clean';
      isNoisy = false;
    }

    // Spectral flatness measure (indicator of noise vs tone)
    double spectralFlatness = _calculateSpectralFlatness(samples, sampleRate);

    return {
      'noiseLevel': double.parse(noiseLevel.toStringAsFixed(4)),
      'snrDb': double.parse(snrDb.toStringAsFixed(2)),
      'isNoisy': isNoisy,
      'noiseType': noiseType,
      'confidence':
          double.parse((1.0 - (snrDb.clamp(0, 50) / 50)).toStringAsFixed(3)),
      'spectralFlatness': double.parse(spectralFlatness.toStringAsFixed(3)),
      'recommendation':
          _getNoiseReductionRecommendation(snrDb, spectralFlatness)
    };
  }

  /// Calculate spectral flatness (classical audio feature)
  static double _calculateSpectralFlatness(
      List<double> samples, int sampleRate) {
    if (samples.length < 1024) return 0.5;

    // Use FFT or simpler spectral estimation
    int n = 1024;
    List<double> magnitudes = List<double>.filled(n ~/ 2, 0.0);

    // Simplified spectral estimation using FFT (classical technique)
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

    // Avoid zeros
    for (int i = 0; i < magnitudes.length; i++) {
      if (magnitudes[i] <= 0) magnitudes[i] = 0.0001;
    }

    // Geometric mean
    double logSum = 0.0;
    for (double mag in magnitudes) {
      logSum += log(mag);
    }
    double geometricMean = exp(logSum / magnitudes.length);

    // Arithmetic mean
    double arithmeticMean =
        magnitudes.reduce((a, b) => a + b) / magnitudes.length;

    // Spectral flatness = geometric mean / arithmetic mean
    return geometricMean / arithmeticMean;
  }

  /// Get noise reduction recommendation based on analysis
  static String _getNoiseReductionRecommendation(
      double snrDb, double spectralFlatness) {
    if (snrDb < 10) {
      return "Strong noise reduction needed. Consider multiple pass filtering.";
    } else if (snrDb < 20) {
      return "Moderate noise reduction recommended. Use band-pass filtering.";
    } else if (snrDb < 30) {
      return "Light noise reduction may help. Consider gentle high-pass filter.";
    } else if (spectralFlatness > 0.8) {
      return "Noise-like spectrum detected. Spectral subtraction may help.";
    } else {
      return "Signal is clean. No noise reduction needed.";
    }
  }

  /// Convert samples to bytes (for compatibility with other functions)
  static List<int> _samplesToBytes(List<double> samples) {
    List<int> bytes = [];

    for (double sample in samples) {
      // Convert back to 16-bit
      int intSample = (sample * 32767).round().clamp(-32768, 32767);
      if (intSample < 0) intSample += 65536;

      // Split into two bytes
      bytes.add(intSample & 0xFF);
      bytes.add((intSample >> 8) & 0xFF);
    }

    return bytes;
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
