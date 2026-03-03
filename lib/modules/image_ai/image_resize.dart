import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageResize {
  /// Classical Image Resizing using Nearest Neighbor Algorithm
    static Uint8List resizeNearestNeighbor(
      Uint8List imageBytes, int targetWidth, int targetHeight) {
    final original = img.decodeImage(imageBytes)!;

    // Create new image with target dimensions
    final resized = img.Image(width: targetWidth, height: targetHeight);

    // Calculate scaling factors
    final widthRatio = original.width / targetWidth;
    final heightRatio = original.height / targetHeight;

    // Apply Nearest Neighbor algorithm
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        // Find nearest pixel in original image
        final srcX = (x * widthRatio).floor();
        final srcY = (y * heightRatio).floor();

        // Clamp to image bounds
        final clampedX = srcX.clamp(0, original.width - 1);
        final clampedY = srcY.clamp(0, original.height - 1);

        // Get pixel from original image
        final pixel = original.getPixel(clampedX, clampedY);

        // Set pixel in resized image
        resized.setPixel(x, y, pixel);
      }
    }

    return Uint8List.fromList(img.encodePng(resized));
  }

  /// Bilinear Interpolation Resizing (Classical Computer Vision)
    static Uint8List resizeBilinear(
      Uint8List imageBytes, int targetWidth, int targetHeight) {
    final original = img.decodeImage(imageBytes)!;
    final resized = img.Image(width: targetWidth, height: targetHeight);

    final xRatio = (original.width - 1) / targetWidth;
    final yRatio = (original.height - 1) / targetHeight;

    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final srcX = x * xRatio;
        final srcY = y * yRatio;

        final x1 = srcX.floor();
        final x2 = (srcX + 1).floor().clamp(0, original.width - 1);
        final y1 = srcY.floor();
        final y2 = (srcY + 1).floor().clamp(0, original.height - 1);

        final dx = srcX - x1;
        final dy = srcY - y1;

        // Get four surrounding pixels
        final p1 = original.getPixel(x1, y1);
        final p2 = original.getPixel(x2, y1);
        final p3 = original.getPixel(x1, y2);
        final p4 = original.getPixel(x2, y2);

        // Bilinear interpolation
        final r = _bilinearInterpolate(
            p1.r.toInt(), p2.r.toInt(), p3.r.toInt(), p4.r.toInt(), dx, dy);
        final g = _bilinearInterpolate(
            p1.g.toInt(), p2.g.toInt(), p3.g.toInt(), p4.g.toInt(), dx, dy);
        final b = _bilinearInterpolate(
            p1.b.toInt(), p2.b.toInt(), p3.b.toInt(), p4.b.toInt(), dx, dy);

        resized.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return Uint8List.fromList(img.encodePng(resized));
  }

  static int _bilinearInterpolate(
      int q11, int q21, int q12, int q22, double dx, double dy) {
    return ((q11 * (1 - dx) * (1 - dy) +
                q21 * dx * (1 - dy) +
                q12 * (1 - dx) * dy +
                q22 * dx * dy)
            .round())
        .clamp(0, 255);
  }

  /// Get recommended dimensions while maintaining aspect ratio
  static Map<String, dynamic> calculateAspectRatio(
      int originalWidth, int originalHeight, int maxDimension) {
    double aspectRatio = originalWidth / originalHeight;
    int newWidth, newHeight;

    if (originalWidth > originalHeight) {
      newWidth = maxDimension;
      newHeight = (maxDimension / aspectRatio).round();
    } else {
      newHeight = maxDimension;
      newWidth = (maxDimension * aspectRatio).round();
    }

    return {
      'width': newWidth,
      'height': newHeight,
      'aspectRatio': aspectRatio,
    };
  }
}
