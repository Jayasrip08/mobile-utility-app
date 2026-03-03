import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class NoiseReduction {
  /// Mean Filter (Simple noise reduction)
    static Uint8List meanFilter(
      Uint8List imageBytes, int kernelSize) {
    final image = img.decodeImage(imageBytes)!;
    final filtered = img.Image(width: image.width, height: image.height);

    final halfSize = kernelSize ~/ 2;
    final kernelArea = kernelSize * kernelSize;

    for (int y = halfSize; y < image.height - halfSize; y++) {
      for (int x = halfSize; x < image.width - halfSize; x++) {
        int rSum = 0, gSum = 0, bSum = 0;

        for (int j = -halfSize; j <= halfSize; j++) {
          for (int i = -halfSize; i <= halfSize; i++) {
            final pixel = image.getPixel(x + i, y + j);
            rSum += pixel.r.toInt().toInt();
            gSum += pixel.g.toInt().toInt();
            bSum += pixel.b.toInt().toInt();
          }
        }

        final r = (rSum ~/ kernelArea).clamp(0, 255);
        final g = (gSum ~/ kernelArea).clamp(0, 255);
        final b = (bSum ~/ kernelArea).clamp(0, 255);

        filtered.setPixelRgba(x, y, r, g, b, image.getPixel(x, y).a);
      }
    }

    _copyBorders(image, filtered, halfSize);

    return Uint8List.fromList(img.encodePng(filtered));
  }

  /// Adaptive Median Filter (Better for salt-and-pepper noise)
    static Uint8List adaptiveMedianFilter(
      Uint8List imageBytes, int maxWindowSize) {
    final image = img.decodeImage(imageBytes)!;
    final filtered = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = _adaptiveMedianPixel(image, x, y, maxWindowSize);
        filtered.setPixel(x, y, pixel);
      }
    }

    return Uint8List.fromList(img.encodePng(filtered));
  }

  /// Wiener Filter (Classical frequency-domain approach)
    static Uint8List wienerFilter(
      Uint8List imageBytes,
      int kernelSize,
      double noiseVariance) {
    final image = img.decodeImage(imageBytes)!;

    // Apply Wiener filter in spatial domain (simplified)
    final blurredImage = img.gaussianBlur(image, radius: 3);

    final result = img.Image(width: image.width, height: image.height);
    final halfSize = kernelSize ~/ 2;

    for (int y = halfSize; y < image.height - halfSize; y++) {
      for (int x = halfSize; x < image.width - halfSize; x++) {
        // Calculate local variance
        double localMean = 0;
        double localVariance = 0;

        for (int j = -halfSize; j <= halfSize; j++) {
          for (int i = -halfSize; i <= halfSize; i++) {
            final pixel = image.getPixel(x + i, y + j);
            final luminance = (0.299 * pixel.r.toInt().toInt() +
                0.587 * pixel.g.toInt().toInt() +
                0.114 * pixel.b.toInt().toInt());
            localMean += luminance;
          }
        }

        localMean /= (kernelSize * kernelSize);

        for (int j = -halfSize; j <= halfSize; j++) {
          for (int i = -halfSize; i <= halfSize; i++) {
            final pixel = image.getPixel(x + i, y + j);
            final luminance = (0.299 * pixel.r.toInt().toInt() +
                0.587 * pixel.g.toInt().toInt() +
                0.114 * pixel.b.toInt().toInt());
            localVariance += pow(luminance - localMean, 2);
          }
        }

        localVariance /= (kernelSize * kernelSize);

        // Wiener filter formula
        final wienerFactor =
            max(0, localVariance - noiseVariance) / localVariance;

        final originalPixel = image.getPixel(x, y);
        final blurredPixel = blurredImage.getPixel(x, y);

        final r = (wienerFactor * originalPixel.r.toInt().toInt() +
                (1 - wienerFactor) * blurredPixel.r.toInt().toInt())
            .round();
        final g = (wienerFactor * originalPixel.g.toInt().toInt() +
                (1 - wienerFactor) * blurredPixel.g.toInt().toInt())
            .round();
        final b = (wienerFactor * originalPixel.b.toInt().toInt() +
                (1 - wienerFactor) * blurredPixel.b.toInt().toInt())
            .round();

        result.setPixelRgba(x, y, r.clamp(0, 255), g.clamp(0, 255),
            b.clamp(0, 255), originalPixel.a);
      }
    }

    _copyBorders(image, result, halfSize);

    return Uint8List.fromList(img.encodePng(result));
  }

  /// Non-local Means Denoising (Advanced classical algorithm)
    static Uint8List nonLocalMeans(
      Uint8List imageBytes,
      int searchWindow,
      int patchSize,
      double h) {
    final image = img.decodeImage(imageBytes)!;
    final denoised = img.Image(width: image.width, height: image.height);

    final halfSearch = searchWindow ~/ 2;
    final halfPatch = patchSize ~/ 2;

    for (int y = halfSearch; y < image.height - halfSearch; y++) {
      for (int x = halfSearch; x < image.width - halfSearch; x++) {
        double weightSum = 0;
        double rSum = 0, gSum = 0, bSum = 0;

        // Reference patch
        final referencePatch = _extractPatch(image, x, y, patchSize);

        for (int j = -halfSearch; j <= halfSearch; j++) {
          for (int i = -halfSearch; i <= halfSearch; i++) {
            final nx = x + i;
            final ny = y + j;

            // Skip center pixel (it will have maximum weight)
            if (i == 0 && j == 0) continue;

            // Check bounds
            if (nx < halfPatch ||
                nx >= image.width - halfPatch ||
                ny < halfPatch ||
                ny >= image.height - halfPatch) {
              continue;
            }

            // Compare patch
            final comparePatch = _extractPatch(image, nx, ny, patchSize);
            final distance = _patchDistance(referencePatch, comparePatch);

            // Calculate weight using Gaussian function
            final weight = exp(-distance / (h * h));

            final pixel = image.getPixel(nx, ny);
            rSum += pixel.r.toInt().toInt() * weight;
            gSum += pixel.g.toInt().toInt() * weight;
            bSum += pixel.b.toInt().toInt() * weight;
            weightSum += weight;
          }
        }

        // Add center pixel with maximum weight
        final centerPixel = image.getPixel(x, y);
        final centerWeight = 1.0; // exp(0) = 1
        rSum += centerPixel.r.toInt().toInt() * centerWeight;
        gSum += centerPixel.g.toInt().toInt() * centerWeight;
        bSum += centerPixel.b.toInt().toInt() * centerWeight;
        weightSum += centerWeight;

        final r = (rSum / weightSum).round().clamp(0, 255);
        final g = (gSum / weightSum).round().clamp(0, 255);
        final b = (bSum / weightSum).round().clamp(0, 255);

        denoised.setPixelRgba(x, y, r, g, b, centerPixel.a);
      }
    }

    _copyBorders(image, denoised, halfSearch);

    return Uint8List.fromList(img.encodePng(denoised));
  }

  /// Wavelet Denoising (Multi-resolution analysis)
    static Uint8List waveletDenoising(
      Uint8List imageBytes, double threshold) {
    final image = img.decodeImage(imageBytes)!;
    final grayImage = img.grayscale(image);

    // Simple Haar wavelet transform (1 level)
    final width = image.width;
    final height = image.height;

    // Apply Haar transform to rows
    final rowTransform = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final left = grayImage.getPixel(2 * x, y).r;
        final right = grayImage.getPixel(2 * x + 1, y).r;

        // Average (approximation)
        final avg = ((left + right) ~/ 2).clamp(0, 255);
        // Difference (detail)
        final diff = ((left - right) ~/ 2).clamp(-128, 127) + 128;

        rowTransform.setPixelRgba(x, y, avg, avg, avg, 255);
        rowTransform.setPixelRgba(x + width ~/ 2, y, diff, diff, diff, 255);
      }
    }

    // Apply Haar transform to columns
    final colTransform = img.Image(width: width, height: height);
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height ~/ 2; y++) {
        final top = rowTransform.getPixel(x, 2 * y).r;
        final bottom = rowTransform.getPixel(x, 2 * y + 1).r;

        final avg = ((top + bottom) ~/ 2).clamp(0, 255);
        final diff = ((top - bottom) ~/ 2).clamp(-128, 127) + 128;

        colTransform.setPixelRgba(x, y, avg, avg, avg, 255);
        colTransform.setPixelRgba(x, y + height ~/ 2, diff, diff, diff, 255);
      }
    }

    // Threshold detail coefficients
    final thresholded = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final value = colTransform.getPixel(x, y).r;
        final newValue = value.abs() < (threshold * 255) ? 128 : value;
        thresholded.setPixelRgba(x, y, newValue, newValue, newValue, 255);
      }
    }

    // Inverse transform (simplified - just return approximation)
    final result = img.Image(width: width, height: height);
    for (int y = 0; y < height ~/ 2; y++) {
      for (int x = 0; x < width ~/ 2; x++) {
        final value = colTransform.getPixel(x, y).r;
        result.setPixelRgba(x * 2, y * 2, value, value, value, 255);
        result.setPixelRgba(x * 2 + 1, y * 2, value, value, value, 255);
        result.setPixelRgba(x * 2, y * 2 + 1, value, value, value, 255);
        result.setPixelRgba(x * 2 + 1, y * 2 + 1, value, value, value, 255);
      }
    }

    return Uint8List.fromList(img.encodePng(result));
  }

  /// Salt and Pepper Noise Removal
    static Uint8List removeSaltAndPepper(
      Uint8List imageBytes, double noiseProbability) {
    final image = img.decodeImage(imageBytes)!;
    final cleaned = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        // Check if pixel is likely noise (extremely dark or light)
        final isBlack = pixel.r.toInt().toInt().toInt() < 10 &&
            pixel.g.toInt().toInt() < 10 &&
            pixel.b.toInt().toInt() < 10;
        final isWhite = pixel.r.toInt().toInt().toInt() > 245 &&
            pixel.g.toInt().toInt() > 245 &&
            pixel.b.toInt().toInt() > 245;

        if ((isBlack || isWhite) && Random().nextDouble() < noiseProbability) {
          // Replace with median of 3x3 neighborhood
          cleaned.setPixel(x, y, _median3x3(image, x, y));
        } else {
          cleaned.setPixel(x, y, pixel);
        }
      }
    }

    return Uint8List.fromList(img.encodePng(cleaned));
  }

  /// Estimate noise level in image
  static Map<String, double> estimateNoise(
      Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;

    // Calculate local variance in small patches
    final patchSize = 7;
    final halfSize = patchSize ~/ 2;
    final variances = <double>[];

    for (int y = halfSize; y < image.height - halfSize; y += patchSize) {
      for (int x = halfSize; x < image.width - halfSize; x += patchSize) {
        variances.add(_calculateLocalVariance(image, x, y, patchSize));
      }
    }

    // Sort and take median
    variances.sort();
    final medianVariance = variances[variances.length ~/ 2];
    final noiseStdDev = sqrt(medianVariance);

    return {
      'variance': medianVariance,
      'stdDev': noiseStdDev,
      'estimatedNoiseLevel': noiseStdDev / 255, // Normalized to [0,1]
    };
  }

  // Helper Methods

  static img.Color _adaptiveMedianPixel(
      img.Image image, int x, int y, int maxWindowSize) {
    int windowSize = 3;

    while (windowSize <= maxWindowSize) {
      final halfSize = windowSize ~/ 2;

      // Check if window is within image bounds
      if (x < halfSize ||
          x >= image.width - halfSize ||
          y < halfSize ||
          y >= image.height - halfSize) {
        return image.getPixel(x, y);
      }

      // Collect pixel values
      final rValues = <int>[];
      final gValues = <int>[];
      final bValues = <int>[];

      for (int j = -halfSize; j <= halfSize; j++) {
        for (int i = -halfSize; i <= halfSize; i++) {
          final pixel = image.getPixel(x + i, y + j);
          rValues.add(pixel.r.toInt().toInt());
          gValues.add(pixel.g.toInt().toInt());
          bValues.add(pixel.b.toInt().toInt());
        }
      }

      rValues.sort();
      gValues.sort();
      bValues.sort();

      final zMin = img.ColorRgb8(rValues.first, gValues.first, bValues.first);
      final zMax = img.ColorRgb8(rValues.last, gValues.last, bValues.last);
      final zMed = img.ColorRgb8(
        rValues[rValues.length ~/ 2],
        gValues[gValues.length ~/ 2],
        bValues[bValues.length ~/ 2],
      );
      final zXY = image.getPixel(x, y);

      // Adaptive median filter algorithm
      final a1 = zMed.r - zMin.r;
      final a2 = zMed.r - zMax.r;
      final b1 = zMed.g - zMin.g;
      final b2 = zMed.g - zMax.g;
      final c1 = zMed.b - zMin.b;
      final c2 = zMed.b - zMax.b;

      if (a1 > 0 && a2 < 0 && b1 > 0 && b2 < 0 && c1 > 0 && c2 < 0) {
        // Level B
        final d1 = zXY.r - zMin.r;
        final d2 = zXY.r - zMax.r;
        final e1 = zXY.g - zMin.g;
        final e2 = zXY.g - zMax.g;
        final f1 = zXY.b - zMin.b;
        final f2 = zXY.b - zMax.b;

        if (d1 > 0 && d2 < 0 && e1 > 0 && e2 < 0 && f1 > 0 && f2 < 0) {
          return zXY;
        } else {
          return zMed;
        }
      } else {
        windowSize += 2;
        if (windowSize > maxWindowSize) {
          return zMed;
        }
      }
    }

    return image.getPixel(x, y);
  }

  static List<List<img.Color>> _extractPatch(
      img.Image image, int centerX, int centerY, int patchSize) {
    final halfSize = patchSize ~/ 2;
    final patch = List.generate(patchSize,
        (_) => List<img.Color>.filled(patchSize, img.ColorRgb8(0, 0, 0)));

    for (int j = -halfSize; j <= halfSize; j++) {
      for (int i = -halfSize; i <= halfSize; i++) {
        final x = centerX + i;
        final y = centerY + j;

        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          patch[j + halfSize][i + halfSize] = image.getPixel(x, y);
        }
      }
    }

    return patch;
  }

  static double _patchDistance(
      List<List<img.Color>> patch1, List<List<img.Color>> patch2) {
    double distance = 0;
    final size = patch1.length;

    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final p1 = patch1[y][x];
        final p2 = patch2[y][x];

        final dr = (p1.r - p2.r).abs();
        final dg = (p1.g - p2.g).abs();
        final db = (p1.b - p2.b).abs();

        distance += (dr + dg + db) / 3;
      }
    }

    return distance / (size * size);
  }

  static img.Color _median3x3(img.Image image, int x, int y) {
    final rValues = <int>[];
    final gValues = <int>[];
    final bValues = <int>[];

    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        final nx = x + i;
        final ny = y + j;

        if (nx >= 0 && nx < image.width && ny >= 0 && ny < image.height) {
          final pixel = image.getPixel(nx, ny);
          rValues.add(pixel.r.toInt().toInt());
          gValues.add(pixel.g.toInt().toInt());
          bValues.add(pixel.b.toInt().toInt());
        }
      }
    }

    rValues.sort();
    gValues.sort();
    bValues.sort();

    final medianIndex = rValues.length ~/ 2;

    return img.ColorRgb8(
      rValues[medianIndex],
      gValues[medianIndex],
      bValues[medianIndex],
    );
  }

  static double _calculateLocalVariance(
      img.Image image, int centerX, int centerY, int patchSize) {
    final halfSize = patchSize ~/ 2;

    // Calculate mean
    double sum = 0;
    int count = 0;

    for (int j = -halfSize; j <= halfSize; j++) {
      for (int i = -halfSize; i <= halfSize; i++) {
        final x = centerX + i;
        final y = centerY + j;

        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          final pixel = image.getPixel(x, y);
          final luminance = 0.299 * pixel.r.toInt().toInt() +
              0.587 * pixel.g.toInt().toInt() +
              0.114 * pixel.b.toInt().toInt();
          sum += luminance;
          count++;
        }
      }
    }

    final mean = sum / count;

    // Calculate variance
    double variance = 0;
    for (int j = -halfSize; j <= halfSize; j++) {
      for (int i = -halfSize; i <= halfSize; i++) {
        final x = centerX + i;
        final y = centerY + j;

        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          final pixel = image.getPixel(x, y);
          final luminance = 0.299 * pixel.r.toInt().toInt() +
              0.587 * pixel.g.toInt().toInt() +
              0.114 * pixel.b.toInt().toInt();
          variance += pow(luminance - mean, 2);
        }
      }
    }

    return variance / count;
  }

  static void _copyBorders(img.Image source, img.Image target, int borderSize) {
    // Copy top border
    for (int y = 0; y < borderSize; y++) {
      for (int x = 0; x < source.width; x++) {
        target.setPixel(x, y, source.getPixel(x, y));
      }
    }

    // Copy bottom border
    for (int y = source.height - borderSize; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        target.setPixel(x, y, source.getPixel(x, y));
      }
    }

    // Copy left border
    for (int y = borderSize; y < source.height - borderSize; y++) {
      for (int x = 0; x < borderSize; x++) {
        target.setPixel(x, y, source.getPixel(x, y));
      }
    }

    // Copy right border
    for (int y = borderSize; y < source.height - borderSize; y++) {
      for (int x = source.width - borderSize; x < source.width; x++) {
        target.setPixel(x, y, source.getPixel(x, y));
      }
    }
  }

  /// Auto-detect noise type and apply appropriate filter
    static Map<String, dynamic> autoNoiseReduction(
      Uint8List imageBytes) {
    final noiseEstimate = estimateNoise(imageBytes);
    final noiseLevel = noiseEstimate['estimatedNoiseLevel']!;

    Uint8List result;
    String method;

    if (noiseLevel < 0.05) {
      // Low noise - use mild filter
      result = meanFilter(imageBytes, 3);
      method = 'Mean Filter (3x3)';
    } else if (noiseLevel < 0.1) {
      // Moderate noise - use median filter
      result = medianFilter(imageBytes, 3);
      method = 'Median Filter (3x3)';
    } else if (noiseLevel < 0.2) {
      // High noise - use adaptive median
      result = adaptiveMedianFilter(imageBytes, 7);
      method = 'Adaptive Median Filter';
    } else {
      // Very high noise - use bilateral filter
      result = bilateralFilter(imageBytes, 5, 75, 75);
      method = 'Bilateral Filter';
    }

    return {
      'filteredImage': result,
      'method': method,
      'noiseLevel': noiseLevel,
      'originalSize': imageBytes.length,
      'filteredSize': result.length,
    };
  }

  /// Apply median filter (inline implementation for NoiseReduction class)
  static Uint8List medianFilter(
      Uint8List imageBytes, int kernelSize) {
    final image = img.decodeImage(imageBytes)!;
    final filtered = img.Image(width: image.width, height: image.height);

    final halfSize = kernelSize ~/ 2;

    for (int y = halfSize; y < image.height - halfSize; y++) {
      for (int x = halfSize; x < image.width - halfSize; x++) {
        final rValues = <int>[];
        final gValues = <int>[];
        final bValues = <int>[];

        for (int j = -halfSize; j <= halfSize; j++) {
          for (int i = -halfSize; i <= halfSize; i++) {
            final pixel = image.getPixel(x + i, y + j);
            rValues.add(pixel.r.toInt());
            gValues.add(pixel.g.toInt());
            bValues.add(pixel.b.toInt());
          }
        }

        rValues.sort();
        gValues.sort();
        bValues.sort();

        final r = rValues[rValues.length ~/ 2].clamp(0, 255);
        final g = gValues[gValues.length ~/ 2].clamp(0, 255);
        final b = bValues[bValues.length ~/ 2].clamp(0, 255);

        filtered.setPixelRgba(x, y, r, g, b, image.getPixel(x, y).a);
      }
    }

    _copyBorders(image, filtered, halfSize);
    return Uint8List.fromList(img.encodePng(filtered));
  }

  /// Apply bilateral filter (inline implementation for NoiseReduction class)
  static Uint8List bilateralFilter(
      Uint8List imageBytes,
      int diameter,
      double sigmaColor,
      double sigmaSpace) {
    final image = img.decodeImage(imageBytes)!;
    final filtered = img.Image(width: image.width, height: image.height);

    final radius = diameter ~/ 2;

    for (int y = radius; y < image.height - radius; y++) {
      for (int x = radius; x < image.width - radius; x++) {
        double r = 0, g = 0, b = 0, weight = 0;

        for (int j = -radius; j <= radius; j++) {
          for (int i = -radius; i <= radius; i++) {
            final pixel = image.getPixel(x + i, y + j);
            final dx = i.toDouble();
            final dy = j.toDouble();
            final spatial = exp(-(dx * dx + dy * dy) / (2 * sigmaSpace * sigmaSpace));

            final centerPixel = image.getPixel(x, y);
            final dr = (pixel.r - centerPixel.r).toDouble();
            final dg = (pixel.g - centerPixel.g).toDouble();
            final db = (pixel.b - centerPixel.b).toDouble();
            final range = exp(-(dr * dr + dg * dg + db * db) / (2 * sigmaColor * sigmaColor));

            final w = spatial * range;
            r += pixel.r * w;
            g += pixel.g * w;
            b += pixel.b * w;
            weight += w;
          }
        }

        filtered.setPixelRgba(
          x,
          y,
          (r / weight).toInt().clamp(0, 255),
          (g / weight).toInt().clamp(0, 255),
          (b / weight).toInt().clamp(0, 255),
          image.getPixel(x, y).a,
        );
      }
    }

    _copyBorders(image, filtered, radius);
    return Uint8List.fromList(img.encodePng(filtered));
  }
}
