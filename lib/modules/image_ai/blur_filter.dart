import 'edge_detection.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class BlurFilter {
  /// Gaussian Blur (Classical Computer Vision)
    static Uint8List gaussianBlur(
      Uint8List imageBytes, int kernelSize,
      {double sigma = 0.0}) {
    final image = img.decodeImage(imageBytes)!;

    // Auto-calculate sigma if not provided
    if (sigma == 0.0) {
      sigma = kernelSize / 6.0;
    }

    // Create Gaussian kernel
    final kernel = _createGaussianKernel(kernelSize, sigma);

    // Apply convolution
    final blurred = _convolve(image, kernel);

    return Uint8List.fromList(img.encodePng(blurred));
  }

  /// Box Blur (Simple Average)
    static Uint8List boxBlur(
      Uint8List imageBytes, int kernelSize) {
    final image = img.decodeImage(imageBytes)!;

    // Create box kernel (all values equal)
    final kernelValue = 1.0 / (kernelSize * kernelSize);
    final kernel = List.generate(
        kernelSize, (_) => List<double>.filled(kernelSize, kernelValue));

    final blurred = _convolve(image, kernel);

    return Uint8List.fromList(img.encodePng(blurred));
  }

  /// Median Filter (Non-linear, removes noise while preserving edges)
    static Uint8List medianFilter(
      Uint8List imageBytes, int kernelSize) {
    final image = img.decodeImage(imageBytes)!;
    final filtered = img.Image(width: image.width, height: image.height);

    final halfSize = kernelSize ~/ 2;
    final neighbors = kernelSize * kernelSize;

    for (int y = halfSize; y < image.height - halfSize; y++) {
      for (int x = halfSize; x < image.width - halfSize; x++) {
        // Collect pixel values from neighborhood
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

        // Sort and take median
        rValues.sort();
        gValues.sort();
        bValues.sort();

        final medianIndex = neighbors ~/ 2;
        final r = rValues[medianIndex];
        final g = gValues[medianIndex];
        final b = bValues[medianIndex];

        filtered.setPixelRgba(x, y, r, g, b, image.getPixel(x, y).a);
      }
    }

    // Handle borders (copy original)
    _copyBorders(image, filtered, halfSize);

    return Uint8List.fromList(img.encodePng(filtered));
  }

  /// Motion Blur (Simulates camera or object motion)
    static Uint8List motionBlur(
      Uint8List imageBytes, int length, double angle) {
    final image = img.decodeImage(imageBytes)!;

    // Convert angle to radians
    final angleRad = angle * pi / 180;

    // Calculate motion vector
    final dx = (length * cos(angleRad)).round();
    final dy = (length * sin(angleRad)).round();

    // Create motion blur kernel
    final kernelSize = max(dx.abs(), dy.abs()) * 2 + 1;
    final kernel =
        List.generate(kernelSize, (_) => List<double>.filled(kernelSize, 0));

    // Draw line in kernel
    final center = kernelSize ~/ 2;
    final steps = max(dx.abs(), dy.abs());

    if (steps > 0) {
      for (int i = 0; i <= steps; i++) {
        final x = center + (dx * i ~/ steps);
        final y = center + (dy * i ~/ steps);

        if (x >= 0 && x < kernelSize && y >= 0 && y < kernelSize) {
          kernel[y][x] = 1.0 / (steps + 1);
        }
      }
    } else {
      kernel[center][center] = 1.0;
    }

    final result = _convolve(image, kernel);
    return Uint8List.fromList(img.encodePng(result));
  }

  /// Bilateral Filter (Edge-preserving smoothing)
    static Uint8List bilateralFilter(
      Uint8List imageBytes,
      int diameter,
      double sigmaColor,
      double sigmaSpace) {
    final image = img.decodeImage(imageBytes)!;
    final filtered = img.Image(width: image.width, height: image.height);

    final radius = diameter ~/ 2;
    final colorWeightTable = _createWeightTable(sigmaColor);
    final spaceWeightTable = _createWeightTable(sigmaSpace);

    for (int y = radius; y < image.height - radius; y++) {
      for (int x = radius; x < image.width - radius; x++) {
        final centerPixel = image.getPixel(x, y);

        double weightSum = 0;
        double rSum = 0, gSum = 0, bSum = 0;

        for (int j = -radius; j <= radius; j++) {
          for (int i = -radius; i <= radius; i++) {
            final neighborPixel = image.getPixel(x + i, y + j);

            // Spatial distance weight
            final spatialDist = sqrt(i * i + j * j);
            final spatialWeight = spaceWeightTable[spatialDist.round()];

            // Color difference weight
            final colorDist = _colorDistance(centerPixel, neighborPixel);
            final colorWeight = colorWeightTable[colorDist];

            // Combined weight
            final weight = spatialWeight * colorWeight;

            rSum += neighborPixel.r.toInt() * weight;
            gSum += neighborPixel.g.toInt() * weight;
            bSum += neighborPixel.b.toInt() * weight;
            weightSum += weight;
          }
        }

        final r = (rSum / weightSum).round().clamp(0, 255);
        final g = (gSum / weightSum).round().clamp(0, 255);
        final b = (bSum / weightSum).round().clamp(0, 255);

        filtered.setPixelRgba(x, y, r, g, b, centerPixel.a);
      }
    }

    _copyBorders(image, filtered, radius);

    return Uint8List.fromList(img.encodePng(filtered));
  }

  /// Stack Blur (Fast approximation of Gaussian blur)
    static Uint8List stackBlur(
      Uint8List imageBytes, int radius) {
    final image = img.decodeImage(imageBytes)!;
    final blurred = img.Image(width: image.width, height: image.height);

    // Horizontal pass
    for (int y = 0; y < image.height; y++) {
      final row = _blurRow(image, y, radius);
      for (int x = 0; x < image.width; x++) {
        blurred.setPixel(x, y, row[x]);
      }
    }

    // Vertical pass
    for (int x = 0; x < image.width; x++) {
      final column = _blurColumn(blurred, x, radius);
      for (int y = 0; y < image.height; y++) {
        blurred.setPixel(x, y, column[y]);
      }
    }

    return Uint8List.fromList(img.encodePng(blurred));
  }

  // Helper Methods

  static List<List<double>> _createGaussianKernel(int size, double sigma) {
    final kernel = List.generate(size, (_) => List<double>.filled(size, 0));
    final halfSize = size ~/ 2;
    double sum = 0;

    for (int y = -halfSize; y <= halfSize; y++) {
      for (int x = -halfSize; x <= halfSize; x++) {
        final exponent = -(x * x + y * y) / (2 * sigma * sigma);
        final value = exp(exponent) / (2 * pi * sigma * sigma);
        kernel[y + halfSize][x + halfSize] = value;
        sum += value;
      }
    }

    // Normalize kernel
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        kernel[y][x] /= sum;
      }
    }

    return kernel;
  }

  static img.Image _convolve(img.Image image, List<List<double>> kernel) {
    final size = kernel.length;
    final halfSize = size ~/ 2;
    final result = img.Image(width: image.width, height: image.height);

    for (int y = halfSize; y < image.height - halfSize; y++) {
      for (int x = halfSize; x < image.width - halfSize; x++) {
        double r = 0, g = 0, b = 0;

        for (int j = -halfSize; j <= halfSize; j++) {
          for (int i = -halfSize; i <= halfSize; i++) {
            final pixel = image.getPixel(x + i, y + j);
            final weight = kernel[j + halfSize][i + halfSize];

            r += pixel.r.toInt() * weight;
            g += pixel.g.toInt() * weight;
            b += pixel.b.toInt() * weight;
          }
        }

        result.setPixelRgba(
            x,
            y,
            r.clamp(0, 255).round(),
            g.clamp(0, 255).round(),
            b.clamp(0, 255).round(),
            image.getPixel(x, y).a);
      }
    }

    _copyBorders(image, result, halfSize);

    return result;
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

  static List<double> _createWeightTable(double sigma) {
    final table = List<double>.filled(256, 0);
    final sigma2 = sigma * sigma * 2;

    for (int i = 0; i < 256; i++) {
      table[i] = exp(-(i * i) / sigma2);
    }

    return table;
  }

  static int _colorDistance(img.Color c1, img.Color c2) {
    final dr = (c1.r - c2.r).abs();
    final dg = (c1.g - c2.g).abs();
    final db = (c1.b - c2.b).abs();
    return ((dr + dg + db) / 3).round();
  }

  static List<img.Color> _blurRow(img.Image image, int y, int radius) {
    final width = image.width;
    final row = List<img.Color>.filled(width, img.ColorRgb8(0, 0, 0));

    for (int x = 0; x < width; x++) {
      int r = 0, g = 0, b = 0;
      int count = 0;

      final start = max(0, x - radius);
      final end = min(width - 1, x + radius);

      for (int i = start; i <= end; i++) {
        final pixel = image.getPixel(i, y);
        r += pixel.r.toInt();
        g += pixel.g.toInt();
        b += pixel.b.toInt();
        count++;
      }

      row[x] = img.ColorRgb8(
        (r ~/ count).clamp(0, 255),
        (g ~/ count).clamp(0, 255),
        (b ~/ count).clamp(0, 255),
      );
    }

    return row;
  }

  static List<img.Color> _blurColumn(img.Image image, int x, int radius) {
    final height = image.height;
    final column = List<img.Color>.filled(height, img.ColorRgb8(0, 0, 0));

    for (int y = 0; y < height; y++) {
      int r = 0, g = 0, b = 0;
      int count = 0;

      final start = max(0, y - radius);
      final end = min(height - 1, y + radius);

      for (int i = start; i <= end; i++) {
        final pixel = image.getPixel(x, i);
        r += pixel.r.toInt();
        g += pixel.g.toInt();
        b += pixel.b.toInt();
        count++;
      }

      column[y] = img.ColorRgb8(
        (r ~/ count).clamp(0, 255),
        (g ~/ count).clamp(0, 255),
        (b ~/ count).clamp(0, 255),
      );
    }

    return column;
  }

  /// Calculate optimal blur radius based on image size
  static int calculateOptimalRadius(int width, int height) {
    final minDimension = min(width, height);
    return (minDimension * 0.02).round().clamp(1, 20);
  }

  /// Detect if image needs blurring (based on high frequency content)
  static bool needsBlurring(
      Uint8List imageBytes, double threshold) {
    final edges = EdgeDetection.sobelEdgeDetection(imageBytes, threshold: 0.1);
    final edgeImage = img.decodeImage(edges)!;

    int edgePixels = 0;
    for (int y = 0; y < edgeImage.height; y++) {
      for (int x = 0; x < edgeImage.width; x++) {
        if (edgeImage.getPixel(x, y).r > 128) {
          edgePixels++;
        }
      }
    }

    final edgeRatio = edgePixels / (edgeImage.width * edgeImage.height);
    return edgeRatio > threshold;
  }
}
