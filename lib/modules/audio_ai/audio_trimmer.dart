import 'package:ai_tools_app/modules/audio_ai/silence_detector.dart';
import 'package:ai_tools_app/modules/audio_ai/volume_analyzer.dart';

/// Classical AI Technique: Energy-based Segmentation + Threshold Detection
class AudioTrimmer {
  /// Trim audio based on start and end times (manual)
  static List<int> trimManual(
      List<int> audioBytes, double startTime, double endTime,
      {int sampleRate = 44100}) {
    if (audioBytes.isEmpty || startTime < 0 || endTime <= startTime) {
      return audioBytes;
    }

    // Convert times to sample indices
    int startSample =
        (startTime * sampleRate).round() * 2; // *2 for 16-bit stereo
    int endSample = (endTime * sampleRate).round() * 2;

    // Ensure indices are within bounds
    startSample = startSample.clamp(0, audioBytes.length - 1);
    endSample = endSample.clamp(startSample, audioBytes.length);

    // Extract the trimmed portion
    return audioBytes.sublist(startSample, endSample);
  }

  /// Auto-trim silence from beginning and end (classical energy-based)
  static Map<String, dynamic> trimSilence(List<int> audioBytes,
      {int sampleRate = 44100, double threshold = 0.01, double padding = 0.1}) {
    if (audioBytes.isEmpty) {
      return {
        'trimmedAudio': audioBytes,
        'startTime': 0.0,
        'endTime': 0.0,
        'originalDuration': 0.0,
        'trimmedDuration': 0.0,
        'removedDuration': 0.0
      };
    }

    List<double> samples = _bytesToNormalizedSamples(audioBytes);

    // Calculate energy profile
    int windowSize = (sampleRate * 0.05).round(); // 50ms window
    List<double> energyProfile = [];

    for (int i = 0; i < samples.length - windowSize; i += windowSize) {
      double windowEnergy = 0.0;
      for (int j = 0; j < windowSize && i + j < samples.length; j++) {
        windowEnergy += samples[i + j] * samples[i + j];
      }
      energyProfile.add(windowEnergy / windowSize);
    }

    // Find start of audio (first window above threshold)
    int startWindow = 0;
    for (int i = 0; i < energyProfile.length; i++) {
      if (energyProfile[i] > threshold) {
        startWindow = i;
        break;
      }
    }

    // Find end of audio (last window above threshold)
    int endWindow = energyProfile.length - 1;
    for (int i = energyProfile.length - 1; i >= 0; i--) {
      if (energyProfile[i] > threshold) {
        endWindow = i;
        break;
      }
    }

    // Add padding
    int paddingWindows = (padding * sampleRate / windowSize).round();
    startWindow =
        (startWindow - paddingWindows).clamp(0, energyProfile.length - 1);
    endWindow = (endWindow + paddingWindows)
        .clamp(startWindow, energyProfile.length - 1);

    // Convert window indices to sample indices
    int startSample = startWindow * windowSize;
    int endSample = (endWindow * windowSize + windowSize)
        .clamp(startSample, samples.length);

    // Convert back to byte indices (*2 for 16-bit)
    int startByte = startSample * 2;
    int endByte = endSample * 2;

    // Ensure byte alignment (must be even for 16-bit)
    if (startByte % 2 != 0) startByte--;
    if (endByte % 2 != 0) endByte++;
    endByte = endByte.clamp(startByte, audioBytes.length);

    // Extract trimmed audio
    List<int> trimmedAudio = audioBytes.sublist(startByte, endByte);

    // Calculate times
    double originalDuration = samples.length / sampleRate;
    double startTime = startSample / sampleRate;
    double endTime = endSample / sampleRate;
    double trimmedDuration = trimmedAudio.length / 2 / sampleRate;

    return {
      'trimmedAudio': trimmedAudio,
      'startTime': double.parse(startTime.toStringAsFixed(3)),
      'endTime': double.parse(endTime.toStringAsFixed(3)),
      'originalDuration': double.parse(originalDuration.toStringAsFixed(3)),
      'trimmedDuration': double.parse(trimmedDuration.toStringAsFixed(3)),
      'removedDuration':
          double.parse((originalDuration - trimmedDuration).toStringAsFixed(3)),
      'trimmedPercentage': double.parse(
          ((trimmedDuration / originalDuration) * 100).toStringAsFixed(1)),
      'startSample': startSample,
      'endSample': endSample
    };
  }

  /// Trim to loudest segment (useful for extracting highlights)
  static Map<String, dynamic> trimToLoudestSegment(List<int> audioBytes,
      {int sampleRate = 44100, double segmentDuration = 10.0}) {
    if (audioBytes.isEmpty) {
      return {
        'trimmedAudio': audioBytes,
        'startTime': 0.0,
        'endTime': 0.0,
        'segmentEnergy': 0.0
      };
    }

    List<double> samples = _bytesToNormalizedSamples(audioBytes);
    int segmentSamples = (segmentDuration * sampleRate).round();

    if (segmentSamples >= samples.length) {
      return {
        'trimmedAudio': audioBytes,
        'startTime': 0.0,
        'endTime': samples.length / sampleRate,
        'segmentEnergy': VolumeAnalyzer.calculateRMS(audioBytes)
      };
    }

    // Slide window to find loudest segment
    double maxEnergy = 0.0;
    int bestStart = 0;

    for (int start = 0;
        start <= samples.length - segmentSamples;
        start += (segmentSamples ~/ 4)) {
      double segmentEnergy = 0.0;

      // Calculate energy for this segment
      for (int i = 0; i < segmentSamples && start + i < samples.length; i++) {
        segmentEnergy += samples[start + i] * samples[start + i];
      }
      segmentEnergy /= segmentSamples;

      if (segmentEnergy > maxEnergy) {
        maxEnergy = segmentEnergy;
        bestStart = start;
      }
    }

    // Extract the loudest segment
    int end = (bestStart + segmentSamples).clamp(0, samples.length);
    int startByte = bestStart * 2;
    int endByte = end * 2;

    // Ensure byte alignment
    if (startByte % 2 != 0) startByte--;
    if (endByte % 2 != 0) endByte++;
    endByte = endByte.clamp(startByte, audioBytes.length);

    List<int> trimmedAudio = audioBytes.sublist(startByte, endByte);

    return {
      'trimmedAudio': trimmedAudio,
      'startTime': double.parse((bestStart / sampleRate).toStringAsFixed(3)),
      'endTime': double.parse((end / sampleRate).toStringAsFixed(3)),
      'segmentEnergy': double.parse(maxEnergy.toStringAsFixed(4)),
      'segmentDuration':
          double.parse(((end - bestStart) / sampleRate).toStringAsFixed(2))
    };
  }

  /// Detect and trim multiple segments (useful for removing commercials or pauses)
  static Map<String, dynamic> trimMultipleSegments(List<int> audioBytes,
      {int sampleRate = 44100,
      double minSegmentLength = 1.0,
      double maxSilenceLength = 2.0}) {
    if (audioBytes.isEmpty) {
      return {'trimmedAudio': audioBytes, 'segments': [], 'totalDuration': 0.0};
    }

    Map<String, dynamic> silenceInfo =
        SilenceDetector.detectSilence(audioBytes, sampleRate: sampleRate);
    List<Map<String, dynamic>> silentSegments =
        silenceInfo['silenceSegments'] as List<Map<String, dynamic>>;

    // Filter out short silent segments (likely natural pauses)
    List<Map<String, dynamic>> longSilences = silentSegments
        .where((segment) => segment['duration'] > maxSilenceLength)
        .toList();

    if (longSilences.isEmpty) {
      return {
        'trimmedAudio': audioBytes,
        'segments': [
          {
            'start': 0.0,
            'end': audioBytes.length / 2 / sampleRate,
            'duration': audioBytes.length / 2 / sampleRate
          }
        ],
        'totalDuration': audioBytes.length / 2 / sampleRate,
        'removedSegments': []
      };
    }

    // Extract non-silent segments
    List<Map<String, dynamic>> audioSegments = [];
    double lastEnd = 0.0;

    for (var silence in longSilences) {
      double segmentStart = lastEnd;
      double segmentEnd = silence['start'] as double;

      if (segmentEnd - segmentStart >= minSegmentLength) {
        audioSegments.add({
          'start': double.parse(segmentStart.toStringAsFixed(3)),
          'end': double.parse(segmentEnd.toStringAsFixed(3)),
          'duration':
              double.parse((segmentEnd - segmentStart).toStringAsFixed(3))
        });
      }

      lastEnd = silence['end'] as double;
    }

    // Add final segment
    double totalDuration = audioBytes.length / 2 / sampleRate;
    if (totalDuration - lastEnd >= minSegmentLength) {
      audioSegments.add({
        'start': double.parse(lastEnd.toStringAsFixed(3)),
        'end': double.parse(totalDuration.toStringAsFixed(3)),
        'duration': double.parse((totalDuration - lastEnd).toStringAsFixed(3))
      });
    }

    // Concatenate all segments
    List<int> trimmedAudio = [];
    for (var segment in audioSegments) {
      int startByte = ((segment['start'] as double) * sampleRate).round() * 2;
      int endByte = ((segment['end'] as double) * sampleRate).round() * 2;

      startByte = startByte.clamp(0, audioBytes.length - 1);
      endByte = endByte.clamp(startByte, audioBytes.length);

      trimmedAudio.addAll(audioBytes.sublist(startByte, endByte));
    }

    return {
      'trimmedAudio': trimmedAudio,
      'segments': audioSegments,
      'totalDuration': double.parse(
          (trimmedAudio.length / 2 / sampleRate).toStringAsFixed(3)),
      'removedSegments': longSilences,
      'originalDuration': double.parse(totalDuration.toStringAsFixed(3))
    };
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
