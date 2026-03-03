/// Classical AI Technique: Signal Processing + Statistical Estimation
class AudioDuration {
  /// Estimate audio duration using file size and sampling rate
  /// Rule-based heuristic estimation
  static double estimateDuration(List<int> audioBytes,
      {int sampleRate = 44100, int channels = 2, int bitDepth = 16}) {
    if (audioBytes.isEmpty) return 0.0;

    // Rule 1: Calculate based on file size and format
    // Formula: duration = (file_size * 8) / (sample_rate * channels * bit_depth)
    double fileSizeBytes = audioBytes.length.toDouble();
    double bitsPerSample = bitDepth.toDouble();

    // Classical AI heuristic: Adjust for common audio formats
    double estimatedDuration;

    // Heuristic rules based on common audio patterns
    if (bitDepth == 16 && channels == 2) {
      // Standard WAV format
      estimatedDuration =
          fileSizeBytes / (sampleRate * channels * (bitsPerSample / 8));
    } else if (bitDepth == 8 && channels == 1) {
      // Mono 8-bit
      estimatedDuration = fileSizeBytes / (sampleRate * (bitsPerSample / 8));
    } else {
      // Generic calculation using classical formula
      estimatedDuration =
          (fileSizeBytes * 8) / (sampleRate * channels * bitsPerSample);
    }

    // Rule-based smoothing: Apply threshold limits
    if (estimatedDuration < 0.1) {
      return 0.0; // Too short to be valid
    } else if (estimatedDuration > 3600) {
      return 3600.0; // Cap at 1 hour
    }

    return double.parse(estimatedDuration.toStringAsFixed(2));
  }

  /// Alternative: Header-based detection (if available)
  static double estimateFromHeader(List<int> audioBytes) {
    if (audioBytes.length < 44) return 0.0;

    // Rule-based WAV header parsing (classical pattern recognition)
    // Check for "RIFF" header (classical byte pattern matching)
    if (audioBytes[0] == 82 &&
        audioBytes[1] == 73 &&
        audioBytes[2] == 70 &&
        audioBytes[3] == 70) {
      // WAV file detected using pattern matching
      // Extract sample rate from bytes 24-27 (little endian)
      int sampleRate = (audioBytes[24] & 0xFF) |
          ((audioBytes[25] & 0xFF) << 8) |
          ((audioBytes[26] & 0xFF) << 16) |
          ((audioBytes[27] & 0xFF) << 24);

      // Extract data size from bytes 40-43
      int dataSize = (audioBytes[40] & 0xFF) |
          ((audioBytes[41] & 0xFF) << 8) |
          ((audioBytes[42] & 0xFF) << 16) |
          ((audioBytes[43] & 0xFF) << 24);

      if (sampleRate > 0) {
        // Classical formula: duration = data_size / (sample_rate * channels * bytes_per_sample)
        // Assume standard 16-bit stereo for calculation
        return double.parse(
            (dataSize / (sampleRate * 2 * 2)).toStringAsFixed(2));
      }
    }

    // Fallback to statistical estimation
    return estimateDuration(audioBytes);
  }
}
