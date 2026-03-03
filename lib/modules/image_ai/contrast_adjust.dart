import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ContrastAdjust {
  /// Classical Contrast Adjustment using Linear Stretching
    static Uint8List adjustContrast(
      Uint8List imageBytes, double contrastFactor) {
    final image = img.decodeImage(imageBytes)!;
    final adjusted = img.Image(width: image.width, height: image.height);

    // Clamp contrast factor
    contrastFactor = contrastFactor.clamp(0.0, 3.0);

    // Contrast adjustment formula
    final intercept = 128 * (1 - contrastFactor);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final r = (pixel.r.toInt() * contrastFactor + intercept).clamp(0, 255);
        final g = (pixel.g.toInt() * contrastFactor + intercept).clamp(0, 255);
        final b = (pixel.b.toInt() * contrastFactor + intercept).clamp(0, 255);

        adjusted.setPixelRgba(x, y, r, g, b, pixel.a);
      }
    }

    return Uint8List.fromList(img.encodePng(adjusted));
  }

  /// Histogram Equalization (Classical Computer Vision)
    static Uint8List histogramEqualization(
      Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;
    final adjusted = img.Image(width: image.width, height: image.height);

    // Calculate luminance histogram
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

    // Calculate cumulative distribution function (CDF)
    final cdf = List<int>.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Normalize CDF to 0-255 range
    final cdfMin = cdf.firstWhere((value) => value > 0);
    final totalPixels = image.width * image.height;
    final equalizationTable = List<int>.filled(256, 0);

    for (int i = 0; i < 256; i++) {
      if (histogram[i] > 0) {
        equalizationTable[i] =
            ((cdf[i] - cdfMin) * 255 / (totalPixels - cdfMin))
                .round()
                .clamp(0, 255);
      }
    }

    // Apply histogram equalization
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final luminance = (0.299 * pixel.r.toInt() +
                0.587 * pixel.g.toInt() +
                0.114 * pixel.b.toInt())
            .round();
        final newLuminance = equalizationTable[luminance];

        // Scale RGB channels proportionally
        final scale = newLuminance / luminance.clamp(1, 255);

        final r = (pixel.r.toInt() * scale).clamp(0, 255);
        final g = (pixel.g.toInt() * scale).clamp(0, 255);
        final b = (pixel.b.toInt() * scale).clamp(0, 255);

        adjusted.setPixelRgba(x, y, r.round(), g.round(), b.round(), pixel.a);
      }
    }

    return Uint8List.fromList(img.encodePng(adjusted));
  }

  /// Adaptive Histogram Equalization (CLAHE - Classical Algorithm)
    static Uint8List adaptiveHistogramEqualization(
      Uint8List imageBytes, int tileSize, double clipLimit) {
    final image = img.decodeImage(imageBytes)!;
    final adjusted = img.Image(width: image.width, height: image.height);

    // Calculate number of tiles
    final tilesX = (image.width / tileSize).ceil();
    final tilesY = (image.height / tileSize).ceil();

    // Process each tile
    for (int tileY = 0; tileY < tilesY; tileY++) {
      for (int tileX = 0; tileX < tilesX; tileX++) {
        final startX = tileX * tileSize;
        final startY = tileY * tileSize;
        final endX = min(startX + tileSize, image.width);
        final endY = min(startY + tileSize, image.height);

        // Process tile
        _processTile(image, adjusted, startX, startY, endX, endY, clipLimit);
      }
    }

    return Uint8List.fromList(img.encodePng(adjusted));
  }

  static void _processTile(img.Image image, img.Image adjusted, int startX,
      int startY, int endX, int endY, double clipLimit) {
    final tileWidth = endX - startX;
    final tileHeight = endY - startY;

    // Calculate histogram for tile
    final histogram = List<int>.filled(256, 0);
    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = (0.299 * pixel.r.toInt() +
                0.587 * pixel.g.toInt() +
                0.114 * pixel.b.toInt())
            .round();
        histogram[luminance]++;
      }
    }

    // Clip histogram (CLAHE)
    final clipThreshold = (tileWidth * tileHeight * clipLimit).round();
    int excess = 0;

    for (int i = 0; i < 256; i++) {
      if (histogram[i] > clipThreshold) {
        excess += histogram[i] - clipThreshold;
        histogram[i] = clipThreshold;
      }
    }

    // Redistribute excess
    final redistribution = excess ~/ 256;
    for (int i = 0; i < 256; i++) {
      histogram[i] += redistribution;
    }

    // Calculate CDF
    final cdf = List<int>.filled(256, 0);
    cdf[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cdf[i] = cdf[i - 1] + histogram[i];
    }

    // Apply to tile
    final cdfMin = cdf.firstWhere((value) => value > 0);
    final tilePixels = tileWidth * tileHeight;

    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = (0.299 * pixel.r.toInt() +
                0.587 * pixel.g.toInt() +
                0.114 * pixel.b.toInt())
            .round();

        final newLuminance =
            ((cdf[luminance] - cdfMin) * 255 / (tilePixels - cdfMin))
                .round()
                .clamp(0, 255);
        final scale = newLuminance / luminance.clamp(1, 255);

        final r = (pixel.r.toInt() * scale).clamp(0, 255);
        final g = (pixel.g.toInt() * scale).clamp(0, 255);
        final b = (pixel.b.toInt() * scale).clamp(0, 255);

        adjusted.setPixelRgba(x, y, r.round(), g.round(), b.round(), pixel.a);
      }
    }
  }

  /// Calculate image contrast ratio
  static double calculateContrastRatio(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;

    int minLuminance = 255;
    int maxLuminance = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = (0.299 * pixel.r.toInt() +
                0.587 * pixel.g.toInt() +
                0.114 * pixel.b.toInt())
            .round();

        minLuminance = min(minLuminance, luminance);
        maxLuminance = max(maxLuminance, luminance);
      }
    }

    if (minLuminance == 0) minLuminance = 1;
    return maxLuminance / minLuminance;
  }

  /// Auto-contrast using histogram stretching
    static Uint8List autoContrast(
      Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;

    // Find min and max luminance
    int minLuminance = 255;
    int maxLuminance = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = (0.299 * pixel.r.toInt() +
                0.587 * pixel.g.toInt() +
                0.114 * pixel.b.toInt())
            .round();

        minLuminance = min(minLuminance, luminance);
        maxLuminance = max(maxLuminance, luminance);
      }
    }

    // If already full range, return original
    if (minLuminance == 0 && maxLuminance == 255) {
      return imageBytes;
    }

    // Calculate stretch factor
    final range = maxLuminance - minLuminance;
    if (range == 0) return imageBytes;

    final stretchFactor = 255.0 / range;

    // Apply contrast stretch
    return adjustContrast(imageBytes, stretchFactor);
  }
}
