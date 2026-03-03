import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class _EdgeDetectionUtils {
  static img.Image _decodeAndGrayscale(List<int> imageBytes) {
    final image = img.decodeImage(Uint8List.fromList(imageBytes));
    if (image == null) throw Exception('Invalid image data');
    return img.grayscale(image);
  }

  static img.Image _convolve(img.Image image, List<List<int>> kernel) {
    final width = image.width;
    final height = image.height;
    final out = img.Image(width: width, height: height);

    final kSize = kernel.length;
    final kOffset = kSize ~/ 2;

    for (int y = kOffset; y < height - kOffset; y++) {
      for (int x = kOffset; x < width - kOffset; x++) {
        int sum = 0;
        for (int ky = 0; ky < kSize; ky++) {
          for (int kx = 0; kx < kSize; kx++) {
            final px = image.getPixel(x + kx - kOffset, y + ky - kOffset);
            final int gray = img.getLuminance(px).toInt();
            sum += gray * kernel[ky][kx];
          }
        }
        sum = sum.clamp(0, 255);
        out.setPixelRgba(x, y, sum, sum, sum, 255);
      }
    }
    return out;
  }

  static img.Image _threshold(img.Image image, double threshold) {
    final out = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final px = image.getPixel(x, y);
        final int gray = img.getLuminance(px).toInt();
        final value = gray > (threshold * 255) ? 255 : 0;
        out.setPixelRgba(x, y, value, value, value, 255);
      }
    }
    return out;
  }
}

class EdgeDetection {
  static List<Map<String, double>> detectEdgeCoordinates(List<int> imageBytes, double threshold) {
    final image = _EdgeDetectionUtils._decodeAndGrayscale(imageBytes);
    final edgeImage = _EdgeDetectionUtils._threshold(image, threshold);
    final coords = <Map<String, double>>[];
    for (int y = 0; y < edgeImage.height; y++) {
      for (int x = 0; x < edgeImage.width; x++) {
        final px = edgeImage.getPixel(x, y);
        if (img.getLuminance(px) == 255) {
          coords.add({'x': x.toDouble(), 'y': y.toDouble()});
        }
      }
    }
    return coords;
  }

  static Uint8List sobelEdgeDetection(List<int> imageBytes, {double threshold = 0.1}) {
    final image = _EdgeDetectionUtils._decodeAndGrayscale(imageBytes);
    final gxKernel = [
      [1, 0, -1],
      [2, 0, -2],
      [1, 0, -1],
    ];
    final gyKernel = [
      [1, 2, 1],
      [0, 0, 0],
      [-1, -2, -1],
    ];
    final gx = _EdgeDetectionUtils._convolve(image, gxKernel);
    final gy = _EdgeDetectionUtils._convolve(image, gyKernel);

    final out = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pxGx = gx.getPixel(x, y);
        final pxGy = gy.getPixel(x, y);
        final int gxLum = img.getLuminance(pxGx).toInt();
        final int gyLum = img.getLuminance(pxGy).toInt();
        int val = sqrt(pow(gxLum, 2) + pow(gyLum, 2)).toInt();
        val = val > (threshold * 255) ? 255 : 0;
        out.setPixelRgba(x, y, val, val, val, 255);
      }
    }
    return Uint8List.fromList(img.encodePng(out));
  }

  static Uint8List prewittEdgeDetection(List<int> imageBytes, {double threshold = 0.1}) {
    final image = _EdgeDetectionUtils._decodeAndGrayscale(imageBytes);
    final gxKernel = [
      [1, 0, -1],
      [1, 0, -1],
      [1, 0, -1],
    ];
    final gyKernel = [
      [1, 1, 1],
      [0, 0, 0],
      [-1, -1, -1],
    ];
    final gx = _EdgeDetectionUtils._convolve(image, gxKernel);
    final gy = _EdgeDetectionUtils._convolve(image, gyKernel);

    final out = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pxGx = gx.getPixel(x, y);
        final pxGy = gy.getPixel(x, y);
        final int gxLum = img.getLuminance(pxGx).toInt();
        final int gyLum = img.getLuminance(pxGy).toInt();
        int val = sqrt(pow(gxLum, 2) + pow(gyLum, 2)).toInt();
        val = val > (threshold * 255) ? 255 : 0;
        out.setPixelRgba(x, y, val, val, val, 255);
      }
    }
    return Uint8List.fromList(img.encodePng(out));
  }

  static Uint8List cannyEdgeDetection(List<int> imageBytes, {double lowThreshold = 0.1, double highThreshold = 0.3, int gaussianKernel = 5}) {
    final sobel = sobelEdgeDetection(imageBytes, threshold: highThreshold);
    final edgeImage = img.decodeImage(sobel)!;
    final out = img.Image(width: edgeImage.width, height: edgeImage.height);

    for (int y = 0; y < edgeImage.height; y++) {
      for (int x = 0; x < edgeImage.width; x++) {
        final px = edgeImage.getPixel(x, y);
        final int val = img.getLuminance(px).toInt();
        final edgeVal = (val > (lowThreshold * 255) && val < (highThreshold * 255)) ? 255 : 0;
        out.setPixelRgba(x, y, edgeVal, edgeVal, edgeVal, 255);
      }
    }
    return Uint8List.fromList(img.encodePng(out));
  }

  static Uint8List laplacianOfGaussian(List<int> imageBytes, {double sigma = 1.0}) {
    final image = _EdgeDetectionUtils._decodeAndGrayscale(imageBytes);
    final kernel = [
      [0, 1, 0],
      [1, -4, 1],
      [0, 1, 0],
    ];
    final out = _EdgeDetectionUtils._convolve(image, kernel);
    return Uint8List.fromList(img.encodePng(out));
  }

  static Uint8List robertsCrossDetection(List<int> imageBytes, {double threshold = 0.1}) {
    final image = _EdgeDetectionUtils._decodeAndGrayscale(imageBytes);
    final gxKernel = [
      [1, 0],
      [0, -1],
    ];
    final gyKernel = [
      [0, 1],
      [-1, 0],
    ];
    final gx = _EdgeDetectionUtils._convolve(image, gxKernel);
    final gy = _EdgeDetectionUtils._convolve(image, gyKernel);

    final out = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pxGx = gx.getPixel(x, y);
        final pxGy = gy.getPixel(x, y);
        int val = sqrt(pow(img.getLuminance(pxGx), 2) + pow(img.getLuminance(pxGy), 2)).toInt();
        val = val > (threshold * 255) ? 255 : 0;
        out.setPixelRgba(x, y, val, val, val, 255);
      }
    }
    return Uint8List.fromList(img.encodePng(out));
  }
}