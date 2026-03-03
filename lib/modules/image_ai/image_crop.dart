import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageCrop {
  /// Classical Rectangle Cropping Algorithm
  static Uint8List cropRectangle(
      Uint8List imageBytes,
      int x,
      int y,
      int width,
      int height) {
    final original = img.decodeImage(imageBytes)!;

    // Validate crop parameters
    x = x.clamp(0, original.width - 1);
    y = y.clamp(0, original.height - 1);
    width = width.clamp(1, original.width - x);
    height = height.clamp(1, original.height - y);

    // Create cropped image
    final cropped = img.Image(width: width, height: height);

    // Copy pixels from original to cropped
    for (int cropY = 0; cropY < height; cropY++) {
      for (int cropX = 0; cropX < width; cropX++) {
        final srcX = x + cropX;
        final srcY = y + cropY;

        if (srcX < original.width && srcY < original.height) {
          final pixel = original.getPixel(srcX, srcY);
          cropped.setPixel(cropX, cropY, pixel);
        }
      }
    }

        return Uint8List.fromList(img.encodePng(cropped));
  }

  /// Circular Crop using Mathematical Circle Equation
    static Uint8List cropCircle(
      Uint8List imageBytes,
      int centerX,
      int centerY,
      int radius) {
    final original = img.decodeImage(imageBytes)!;
    final diameter = radius * 2;
    final cropped = img.Image(width: diameter, height: diameter);

    // Fill with transparent background
    for (int y = 0; y < diameter; y++) {
      for (int x = 0; x < diameter; x++) {
        cropped.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
      }
    }

    // Circle equation: (x - radius)^2 + (y - radius)^2 <= radius^2
    final radiusSquared = radius * radius;

    for (int y = 0; y < diameter; y++) {
      for (int x = 0; x < diameter; x++) {
        final dx = x - radius;
        final dy = y - radius;

        // Check if point is inside circle
        if (dx * dx + dy * dy <= radiusSquared) {
          final srcX = centerX - radius + x;
          final srcY = centerY - radius + y;

          if (srcX >= 0 &&
              srcX < original.width &&
              srcY >= 0 &&
              srcY < original.height) {
            final pixel = original.getPixel(srcX, srcY);
            cropped.setPixel(x, y, pixel);
          }
        }
      }
    }

        return Uint8List.fromList(img.encodePng(cropped));
  }

  /// Auto-crop to remove borders based on color similarity
  static Map<String, dynamic> autoCrop(
      Uint8List imageBytes, int tolerance) {
    final original = img.decodeImage(imageBytes)!;

    // Analyze borders to find crop boundaries
    final left = _findLeftBoundary(original, tolerance);
    final right = _findRightBoundary(original, tolerance);
    final top = _findTopBoundary(original, tolerance);
    final bottom = _findBottomBoundary(original, tolerance);

    // Validate crop area
    final width = right - left;
    final height = bottom - top;

    if (width <= 0 || height <= 0) {
      return {
        'success': false,
        'message': 'Could not find suitable crop area',
        'image': imageBytes,
      };
    }

    final croppedImage = cropRectangle(imageBytes, left, top, width, height);

    return {
      'success': true,
      'image': croppedImage,
      'bounds': {'left': left, 'top': top, 'right': right, 'bottom': bottom},
      'dimensions': {'width': width, 'height': height},
    };
  }

  static int _findLeftBoundary(img.Image image, int tolerance) {
    final sampleColor = image.getPixel(0, image.height ~/ 2);

    for (int x = 0; x < image.width; x++) {
      for (int y = 0; y < image.height; y++) {
        final pixel = image.getPixel(x, y);
        if (_colorDistance(pixel, sampleColor) > tolerance) {
          return x;
        }
      }
    }
    return 0;
  }

  static int _findRightBoundary(img.Image image, int tolerance) {
    final sampleColor = image.getPixel(image.width - 1, image.height ~/ 2);

    for (int x = image.width - 1; x >= 0; x--) {
      for (int y = 0; y < image.height; y++) {
        final pixel = image.getPixel(x, y);
        if (_colorDistance(pixel, sampleColor) > tolerance) {
          return x;
        }
      }
    }
    return image.width - 1;
  }

  static int _findTopBoundary(img.Image image, int tolerance) {
    final sampleColor = image.getPixel(image.width ~/ 2, 0);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (_colorDistance(pixel, sampleColor) > tolerance) {
          return y;
        }
      }
    }
    return 0;
  }

  static int _findBottomBoundary(img.Image image, int tolerance) {
    final sampleColor = image.getPixel(image.width ~/ 2, image.height - 1);

    for (int y = image.height - 1; y >= 0; y--) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (_colorDistance(pixel, sampleColor) > tolerance) {
          return y;
        }
      }
    }
    return image.height - 1;
  }

  static double _colorDistance(img.Color c1, img.Color c2) {
    final dr = (c1.r - c2.r).abs();
    final dg = (c1.g - c2.g).abs();
    final db = (c1.b - c2.b).abs();
    return (dr + dg + db) / 3.0;
  }
}
