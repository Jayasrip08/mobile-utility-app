import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class BrightnessAdjust {
  /// Classical Brightness Adjustment using Pixel-wise Addition
    static Uint8List adjustBrightness(
      Uint8List imageBytes, int brightness) {
    final image = img.decodeImage(imageBytes)!;
    final adjusted = img.Image(width: image.width, height: image.height);

    // Clamp brightness to reasonable range
    brightness = brightness.clamp(-100, 100);

    // Apply brightness adjustment to each pixel
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final r = (pixel.r.toInt() + brightness).clamp(0, 255);
        final g = (pixel.g.toInt() + brightness).clamp(0, 255);
        final b = (pixel.b.toInt() + brightness).clamp(0, 255);

        adjusted.setPixelRgba(x, y, r, g, b, pixel.a);
      }
    }

    return Uint8List.fromList(img.encodePng(adjusted));
  }

  /// Gamma Correction (Classical Computer Vision Technique)
    static Uint8List adjustGamma(
      Uint8List imageBytes, double gamma) {
    final image = img.decodeImage(imageBytes)!;
    final adjusted = img.Image(width: image.width, height: image.height);

    // Clamp gamma value
    gamma = gamma.clamp(0.1, 5.0);

    // Pre-calculate gamma correction table for performance
    final gammaTable = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      gammaTable[i] = (255 * pow(i / 255, 1 / gamma)).round().clamp(0, 255);
    }

    // Apply gamma correction using lookup table
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final r = gammaTable[pixel.r.toInt()];
        final g = gammaTable[pixel.g.toInt()];
        final b = gammaTable[pixel.b.toInt()];

        adjusted.setPixelRgba(x, y, r, g, b, pixel.a);
      }
    }

    return Uint8List.fromList(img.encodePng(adjusted));
  }

  /// Auto Brightness using Histogram Analysis
    static Uint8List autoBrightness(
      Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;

    // Calculate image histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = (0.299 * pixel.r.toInt() +
                0.587 * pixel.g.toInt() +
                0.114 * pixel.b.toInt())
            .round();
        histogram[luminance]++;
      }
    }

    // Find 5th and 95th percentiles (ignore extremes)
    final totalPixels = image.width * image.height;
    int cumulative = 0;
    int lowPercentile = 0;
    int highPercentile = 255;

    for (int i = 0; i < 256; i++) {
      cumulative += histogram[i];
      if (cumulative >= totalPixels * 0.05 && lowPercentile == 0) {
        lowPercentile = i;
      }
      if (cumulative >= totalPixels * 0.95) {
        highPercentile = i;
        break;
      }
    }

    // Calculate brightness adjustment needed
    final targetLow = 25; // Target for dark pixels
    final targetHigh = 230; // Target for bright pixels

    final scale = (targetHigh - targetLow) /
        (highPercentile - lowPercentile).clamp(1, 254);
    final offset = targetLow - lowPercentile * scale;

    // Apply calculated adjustment
    return adjustBrightnessContrast(imageBytes, offset.round(), scale);
  }

  /// Combined Brightness and Contrast Adjustment
  static Uint8List adjustBrightnessContrast(
      Uint8List imageBytes, int brightness, double contrast) {
    final image = img.decodeImage(imageBytes)!;
    final adjusted = img.Image(width: image.width, height: image.height);

    // Apply brightness and contrast formula
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        // Brightness and contrast formula
        final r = ((pixel.r.toInt() - 128) * contrast + 128 + brightness)
            .clamp(0, 255);
        final g = ((pixel.g.toInt() - 128) * contrast + 128 + brightness)
            .clamp(0, 255);
        final b = ((pixel.b.toInt() - 128) * contrast + 128 + brightness)
            .clamp(0, 255);

        adjusted.setPixelRgba(x, y, r, g, b, pixel.a);
      }
    }

    return Uint8List.fromList(img.encodePng(adjusted));
  }

  /// Get recommended brightness based on image analysis
  static int analyzeOptimalBrightness(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;

    int totalLuminance = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        totalLuminance += (0.299 * pixel.r.toInt() +
                0.587 * pixel.g.toInt() +
                0.114 * pixel.b.toInt())
            .round();
      }
    }

    final averageLuminance = totalLuminance ~/ (image.width * image.height);

    // Target middle gray (128)
    return 128 - averageLuminance;
  }
}
