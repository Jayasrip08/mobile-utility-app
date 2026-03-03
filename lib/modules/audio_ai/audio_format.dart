import 'dart:math';

/// Classical AI Technique: File Header Analysis + Statistical Pattern Recognition
class AudioFormat {
  /// Detect audio format using header analysis and statistical patterns
  static Map<String, dynamic> detectFormat(List<int> audioBytes) {
    if (audioBytes.isEmpty) {
      return {
        'format': 'unknown',
        'confidence': 0.0,
        'sampleRate': 0,
        'channels': 0,
        'bitDepth': 0,
        'duration': 0.0,
        'fileSize': 0,
        'isValid': false,
        'details': {}
      };
    }

    // Try to detect format using classical pattern matching
    Map<String, dynamic>? detected = _detectByHeader(audioBytes);

    if (detected != null && detected['confidence'] > 0.7) {
      return detected;
    }

    // Fallback to statistical analysis
    return _analyzeStatistically(audioBytes);
  }

  /// Detect format by analyzing file headers (classical pattern matching)
  static Map<String, dynamic>? _detectByHeader(List<int> bytes) {
    // Check for WAV format (RIFF header)
    if (bytes.length >= 44) {
      // Check for "RIFF" signature
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return _parseWAVHeader(bytes);
      }
    }

    // Check for MP3 (simplified - look for frame sync)
    if (bytes.length >= 10) {
      for (int i = 0; i < bytes.length - 10; i++) {
        // MP3 frame sync: 11111111 111
        if (bytes[i] == 0xFF && (bytes[i + 1] & 0xE0) == 0xE0) {
          return _parseMP3Header(bytes, i);
        }
      }
    }

    return null;
  }

  /// Parse WAV header (classical binary pattern recognition)
  static Map<String, dynamic> _parseWAVHeader(List<int> bytes) {
    Map<String, dynamic> info = {
      'format': 'WAV',
      'confidence': 0.95,
      'isValid': true,
      'details': {}
    };

    try {
      // Extract sample rate (bytes 24-27, little endian)
      int sampleRate =
          bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);

      // Extract bits per sample (bytes 34-35)
      int bitsPerSample = bytes[34] | (bytes[35] << 8);

      // Extract number of channels (bytes 22-23)
      int channels = bytes[22] | (bytes[23] << 8);

      // Calculate data size (bytes 40-43)
      int dataSize =
          bytes[40] | (bytes[41] << 8) | (bytes[42] << 16) | (bytes[43] << 24);

      // Calculate duration
      double duration =
          dataSize / (sampleRate * channels * (bitsPerSample / 8));

      info['sampleRate'] = sampleRate;
      info['bitDepth'] = bitsPerSample;
      info['channels'] = channels;
      info['duration'] = double.parse(duration.toStringAsFixed(2));
      info['fileSize'] = bytes.length;
      info['dataSize'] = dataSize;

      // Additional WAV details
      info['details'] = {
        'audioFormat': bytes[20] | (bytes[21] << 8), // 1 = PCM
        'byteRate': bytes[28] |
            (bytes[29] << 8) |
            (bytes[30] << 16) |
            (bytes[31] << 24),
        'blockAlign': bytes[32] | (bytes[33] << 8),
        'subchunk2ID': String.fromCharCodes(bytes.sublist(36, 40))
      };
    } catch (e) {
      info['confidence'] = 0.5;
      info['isValid'] = false;
    }

    return info;
  }

  /// Parse MP3 header (simplified)
  static Map<String, dynamic> _parseMP3Header(List<int> bytes, int start) {
    Map<String, dynamic> info = {
      'format': 'MP3',
      'confidence': 0.85,
      'isValid': true,
      'details': {}
    };

    try {
      // Extract MPEG version and layer
      int header = (bytes[start + 1] << 8) | bytes[start + 2];

      // MPEG version (bits 11-12)
      int mpegVersion = (header >> 11) & 0x03;
      List<String> versions = ['2.5', 'reserved', '2', '1'];

      // Layer (bits 9-10)
      int layer = (header >> 9) & 0x03;
      List<String> layers = ['reserved', 'III', 'II', 'I'];

      // Bitrate (bits 4-7)
      int bitrateIndex = (header >> 4) & 0x0F;
      Map<int, List<int>> bitrateTable = {
        1: [
          32,
          32,
          32,
          32,
          64,
          48,
          40,
          48,
          56,
          56,
          64,
          80,
          96,
          112,
          128,
          144
        ], // MPEG1 Layer1
        2: [
          32,
          48,
          56,
          64,
          80,
          96,
          112,
          128,
          160,
          192,
          224,
          256,
          320,
          384,
          448,
          512
        ], // MPEG1 Layer2/3
        3: [
          32,
          40,
          48,
          56,
          64,
          80,
          96,
          112,
          128,
          160,
          192,
          224,
          256,
          320,
          384,
          448
        ], // MPEG2/2.5 Layer1
        4: [
          8,
          16,
          24,
          32,
          40,
          48,
          56,
          64,
          80,
          96,
          112,
          128,
          144,
          160,
          176,
          192
        ] // MPEG2/2.5 Layer2/3
      };

      int bitrate = 0;
      if (mpegVersion == 3) {
        // MPEG1
        bitrate = bitrateTable[layer == 3 ? 1 : 2]![bitrateIndex];
      } else {
        // MPEG2/2.5
        bitrate = bitrateTable[layer == 3 ? 3 : 4]![bitrateIndex];
      }

      // Sample rate (bits 2-3)
      int sampleRateIndex = (header >> 2) & 0x03;
      Map<int, List<int>> sampleRateTable = {
        0: [11025, 12000, 8000], // MPEG2.5
        2: [22050, 24000, 16000], // MPEG2
        3: [44100, 48000, 32000] // MPEG1
      };

      int sampleRate = sampleRateTable[mpegVersion]![sampleRateIndex];

      // Calculate frame size
      int frameSize;
      if (layer == 3) {
        // Layer I
        frameSize =
            ((12 * bitrate * 1000 ~/ sampleRate) + ((header >> 1) & 0x01)) * 4;
      } else {
        // Layer II/III
        frameSize =
            (144 * bitrate * 1000 ~/ sampleRate) + ((header >> 1) & 0x01);
      }

      // Estimate duration
      int totalFrames = bytes.length ~/ frameSize;
      double duration = totalFrames * (layer == 3 ? 384 : 1152) / sampleRate;

      info['sampleRate'] = sampleRate;
      info['bitDepth'] = 16; // MP3 is typically 16-bit
      info['channels'] = ((header >> 6) & 0x03) == 3 ? 1 : 2;
      info['duration'] = double.parse(duration.toStringAsFixed(2));
      info['fileSize'] = bytes.length;
      info['bitrate'] = bitrate;

      info['details'] = {
        'mpegVersion': versions[mpegVersion],
        'layer': layers[layer],
        'protection': (header >> 8) & 0x01 == 0,
        'padding': (header >> 1) & 0x01 == 1,
        'private': (header >> 7) & 0x01 == 1,
        'mode': [
          'stereo',
          'joint_stereo',
          'dual_channel',
          'mono'
        ][(header >> 6) & 0x03]
      };
    } catch (e) {
      info['confidence'] = 0.6;
      info['isValid'] = false;
    }

    return info;
  }

  /// Analyze audio statistically when header is not available
  static Map<String, dynamic> _analyzeStatistically(List<int> bytes) {
    Map<String, dynamic> info = {
      'format': 'unknown',
      'confidence': 0.5,
      'isValid': false,
      'details': {}
    };

    // Statistical analysis of byte patterns
    if (bytes.isEmpty) return info;

    // Check if data looks like PCM audio (statistical properties)
    bool isLikelyPCM = _isLikelyPCMAudio(bytes);

    if (isLikelyPCM) {
      info['format'] = 'PCM (raw)';
      info['confidence'] = 0.7;
      info['isValid'] = true;

      // Try to guess parameters
      info['sampleRate'] = _estimateSampleRate(bytes);
      info['channels'] = _estimateChannels(bytes);
      info['bitDepth'] = _estimateBitDepth(bytes);

      // Calculate duration
      if (info['sampleRate'] > 0 &&
          info['channels'] > 0 &&
          info['bitDepth'] > 0) {
        double duration = bytes.length /
            (info['sampleRate'] * info['channels'] * (info['bitDepth'] / 8));
        info['duration'] = double.parse(duration.toStringAsFixed(2));
      }
    } else {
      // Check for common patterns
      double compressionRatio = _calculateCompressionRatio(bytes);

      if (compressionRatio < 0.5) {
        info['format'] = 'compressed (likely MP3/AAC)';
        info['confidence'] = 0.65;
        info['details']['compressionRatio'] =
            double.parse(compressionRatio.toStringAsFixed(3));
      }
    }

    info['fileSize'] = bytes.length;
    info['details']['bytePatternAnalysis'] = _analyzeBytePatterns(bytes);

    return info;
  }

  /// Check if data looks like PCM audio using statistical tests
  static bool _isLikelyPCMAudio(List<int> bytes) {
    if (bytes.length < 1000) return false;

    // Test 1: Check for alternating high/low bytes (16-bit pattern)
    int patternMatches = 0;
    for (int i = 0; i < bytes.length - 100; i += 2) {
      // In 16-bit PCM, consecutive bytes often have correlation
      if ((bytes[i] & 0x80) != (bytes[i + 1] & 0x80)) {
        patternMatches++;
      }
    }

    double patternScore = patternMatches / (bytes.length / 2);

    // Test 2: Check amplitude distribution (should be centered)
    int zeroCrossings = 0;
    List<int> samples16 = [];

    for (int i = 0; i < bytes.length - 1; i += 2) {
      int sample = (bytes[i] & 0xFF) | ((bytes[i + 1] & 0xFF) << 8);
      if (sample >= 32768) sample -= 65536;
      samples16.add(sample);
    }

    // Count zero crossings
    for (int i = 1; i < samples16.length; i++) {
      if ((samples16[i - 1] >= 0 && samples16[i] < 0) ||
          (samples16[i - 1] < 0 && samples16[i] >= 0)) {
        zeroCrossings++;
      }
    }

    double zcr = zeroCrossings / samples16.length;

    // Test 3: Check for typical audio amplitude range
    int maxAmplitude =
        samples16.fold(0, (max, val) => val.abs() > max ? val.abs() : max);
    double amplitudeRatio = maxAmplitude / 32767.0;

    // Decision rules
    bool hasGoodPattern = patternScore > 0.3 && patternScore < 0.7;
    bool hasTypicalZCR = zcr > 0.05 && zcr < 0.4;
    bool hasGoodAmplitude = amplitudeRatio > 0.1 && amplitudeRatio < 0.9;

    return hasGoodPattern && hasTypicalZCR && hasGoodAmplitude;
  }

  /// Estimate sample rate statistically
  static int _estimateSampleRate(List<int> bytes) {
    if (bytes.length < 1000) return 44100; // Default guess

    // Look for repeating patterns that might indicate common sample rates
    List<int> commonRates = [8000, 11025, 16000, 22050, 44100, 48000];

    // Try autocorrelation to find periodicity
    int bestRate = 44100;
    double bestScore = 0.0;

    for (int rate in commonRates) {
      int period = (rate / 100).round() * 2; // Convert to bytes

      if (period < 20 || period > bytes.length ~/ 2) continue;

      double correlation = 0.0;
      int comparisons = 0;

      for (int i = 0; i < bytes.length - period; i += period) {
        for (int j = 0; j < period && i + j + period < bytes.length; j++) {
          int diff = (bytes[i + j] - bytes[i + j + period]).abs();
          correlation += 255 - diff;
          comparisons++;
        }
      }

      if (comparisons > 0) {
        double score = correlation / (comparisons * 255);
        if (score > bestScore) {
          bestScore = score;
          bestRate = rate;
        }
      }
    }

    return bestRate;
  }

  /// Estimate number of channels
  static int _estimateChannels(List<int> bytes) {
    if (bytes.length < 100) return 1;

    // Try to detect stereo by comparing left/right channel correlation
    // Assuming interleaved stereo: L R L R ...

    int testSize = min(1000, bytes.length ~/ 4);
    double leftRightCorrelation = 0.0;

    for (int i = 0; i < testSize - 4; i += 4) {
      // Compare left and right channel samples
      int left1 = (bytes[i] & 0xFF) | ((bytes[i + 1] & 0xFF) << 8);
      int right1 = (bytes[i + 2] & 0xFF) | ((bytes[i + 3] & 0xFF) << 8);

      if (left1 >= 32768) left1 -= 65536;
      if (right1 >= 32768) right1 -= 65536;

      leftRightCorrelation += (left1 - right1).abs().toDouble();
    }

    double avgDiff = leftRightCorrelation / (testSize ~/ 4);

    // If average difference is small, might be mono duplicated
    // If difference is significant, likely stereo
    return avgDiff > 1000 ? 2 : 1;
  }

  /// Estimate bit depth
  static int _estimateBitDepth(List<int> bytes) {
    if (bytes.length < 100) return 16;

    // Check byte alignment patterns

    // Test 8-bit (look for common 8-bit marker values)
    bool couldBe8Bit = bytes
        .take(min(1000, bytes.length))
        .any((b) => b == 0 || b == 255);

    // Test 16-bit (more common)
    bool couldBe16Bit = true;
    for (int i = 0; i < min(1000, bytes.length - 1); i += 2) {
      int sample = (bytes[i] & 0xFF) | ((bytes[i + 1] & 0xFF) << 8);
      if (sample < -32768 || sample > 32767) {
        couldBe16Bit = false;
        break;
      }
    }

    // Test 24-bit (less common)
    bool couldBe24Bit = bytes.length % 3 == 0;

    if (couldBe16Bit) return 16;
    if (couldBe8Bit) return 8;
    if (couldBe24Bit) return 24;

    return 16; // Default
  }

  /// Calculate compression ratio (simplified)
  static double _calculateCompressionRatio(List<int> bytes) {
    if (bytes.length < 1000) return 1.0;

    // Calculate entropy to estimate compression
    Map<int, int> frequency = {};
    for (int i = 0; i < min(10000, bytes.length); i++) {
      frequency[bytes[i]] = (frequency[bytes[i]] ?? 0) + 1;
    }

    double entropy = 0.0;
    int total = min(10000, bytes.length);

    for (int count in frequency.values) {
      double probability = count / total;
      entropy -= probability * log(probability);
    }

    // Normalize entropy (0-1)
    double normalizedEntropy = entropy / log(256);

    // Low entropy suggests compression
    return normalizedEntropy;
  }

  /// Analyze byte patterns
  static Map<String, dynamic> _analyzeBytePatterns(List<int> bytes) {
    if (bytes.isEmpty) return {};

    Map<String, dynamic> analysis = {};

    // Calculate basic statistics
    int sum = bytes.reduce((a, b) => a + b);
    double mean = sum / bytes.length;

    double variance = 0.0;
    for (int byte in bytes) {
      variance += (byte - mean) * (byte - mean);
    }
    variance /= bytes.length;
    double stdDev = sqrt(variance);

    // Count zero bytes (common in some formats)
    int zeroBytes = bytes.where((b) => b == 0).length;

    // Check for repeating patterns
    int patternRepeats = 0;
    int patternLength = 4;

    for (int i = 0; i < bytes.length - patternLength * 2; i++) {
      bool matches = true;
      for (int j = 0; j < patternLength; j++) {
        if (bytes[i + j] != bytes[i + j + patternLength]) {
          matches = false;
          break;
        }
      }
      if (matches) patternRepeats++;
    }

    analysis['mean'] = double.parse(mean.toStringAsFixed(2));
    analysis['stdDev'] = double.parse(stdDev.toStringAsFixed(2));
    analysis['zeroByteRatio'] =
        double.parse((zeroBytes / bytes.length).toStringAsFixed(3));
    analysis['patternRepeats'] = patternRepeats;
    analysis['size'] = bytes.length;

    return analysis;
  }

  // _bytesToNormalizedSamples removed (duplicate implementation exists in other modules)
}
