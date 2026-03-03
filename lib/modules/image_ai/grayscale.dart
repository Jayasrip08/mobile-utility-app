import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class Grayscale {
  /// Helper to set pixel RGBA in an image.
  static void setPixelRgba(
      img.Image image, int x, int y, int r, int g, int b, int a) {
    image.setPixelRgba(x, y, r, g, b, a);
  }

  /// Method 1: Luminosity Method (Weighted Average)
    static Uint8List convertLuminosity(
      Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;
    final grayscale = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
        setPixelRgba(grayscale, x, y, gray, gray, gray, pixel.a.toInt());
      }
    }

    return Uint8List.fromList(img.encodePng(grayscale));
  }

  /// Method 2: Average Method (Simple Average)
    static Uint8List convertAverage(
      Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;
    final grayscale = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = ((pixel.r + pixel.g + pixel.b) ~/ 3);
        setPixelRgba(grayscale, x, y, gray, gray, gray, pixel.a.toInt());
      }
    }

    return Uint8List.fromList(img.encodePng(grayscale));
  }

  /// Method 3: Lightness Method (Min/Max Average)
    static Uint8List convertLightness(
      Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;
    final grayscale = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final maxVal = [pixel.r, pixel.g, pixel.b].reduce(max);
        final minVal = [pixel.r, pixel.g, pixel.b].reduce(min);
        final gray = ((maxVal + minVal) ~/ 2);
        setPixelRgba(grayscale, x, y, gray, gray, gray, pixel.a.toInt());
      }
    }

    return Uint8List.fromList(img.encodePng(grayscale));
  }

  /// Method 4: Desaturation Method (Color to Grayscale)
    static Uint8List convertDesaturation(
      Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;
    final grayscale = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;
        final maxVal = [r, g, b].reduce(max);
        final minVal = [r, g, b].reduce(min);
        final lightness = (maxVal + minVal) / 2;
        final gray = (lightness * 255).round();
        setPixelRgba(grayscale, x, y, gray, gray, gray, pixel.a.toInt());
      }
    }

    return Uint8List.fromList(img.encodePng(grayscale));
  }

  /// Method 5: Custom Weighted Grayscale
    static Uint8List convertCustomWeights(
      Uint8List imageBytes,
      double redWeight,
      double greenWeight,
      double blueWeight) {
    final image = img.decodeImage(imageBytes)!;
    final grayscale = img.Image(width: image.width, height: image.height);

    final totalWeight = redWeight + greenWeight + blueWeight;
    final normalizedRed = redWeight / totalWeight;
    final normalizedGreen = greenWeight / totalWeight;
    final normalizedBlue = blueWeight / totalWeight;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray = (normalizedRed * pixel.r +
                normalizedGreen * pixel.g +
                normalizedBlue * pixel.b)
            .round();
        setPixelRgba(grayscale, x, y, gray, gray, gray, pixel.a.toInt());
      }
    }

    return Uint8List.fromList(img.encodePng(grayscale));
  }

  /// Method 6: Channel Extraction (Red, Green, or Blue only)
    static Uint8List extractChannel(
      Uint8List imageBytes, String channel) {
    final image = img.decodeImage(imageBytes)!;
    final grayscale = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        int gray;
        switch (channel.toLowerCase()) {
          case 'red':
            gray = pixel.r.toInt();
            break;
          case 'green':
            gray = pixel.g.toInt();
            break;
          case 'blue':
            gray = pixel.b.toInt();
            break;
          default:
            gray = pixel.r.toInt();
        }
        setPixelRgba(grayscale, x, y, gray, gray, gray, pixel.a.toInt());
      }
    }

    return Uint8List.fromList(img.encodePng(grayscale));
  }

  /// Method 7: Binary (Black & White) Thresholding
    static Uint8List convertBinary(
      Uint8List imageBytes, int threshold) {
    final image = img.decodeImage(imageBytes)!;
    final binary = img.Image(width: image.width, height: image.height);

    // First convert to grayscale using luminosity method
    final grayscaleImage = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
        grayscaleImage.setPixelRgba(x, y, gray, gray, gray, pixel.a.toInt());
      }
    }

    // Apply threshold
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = grayscaleImage.getPixel(x, y);
        final value = pixel.r > threshold ? 255 : 0;
        binary.setPixelRgba(x, y, value, value, value, pixel.a.toInt());
      }
    }

    return Uint8List.fromList(img.encodePng(binary));
  }

  /// Calculate optimal threshold using Otsu's Method (Classical)
  static int calculateOtsuThreshold(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes)!;

    // Calculate histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final gray =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).round();
        histogram[gray]++;
      }
    }

    final total = image.width * image.height;

    // Otsu's algorithm
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;

    double maxVariance = 0;
    int threshold = 0;

    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];

      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      // Calculate between-class variance
      final variance = wB * wF * (mB - mF) * (mB - mF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = i;
      }
    }

    return threshold;
  }
}
