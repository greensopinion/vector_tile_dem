import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../vector_tile_dem.dart';

final double invalidElevation = double.nan;
final double minValidElevation = -12000.0;
final double maxValidElevation = 9000.0;

typedef Bounds = ({double min, double max});

class ElevationTile {
  final int width;
  final int height;
  final double Function(int x, int y) elevation;
  Bounds? _bounds;
  Bounds get elevationBounds {
    var bounds = _bounds;
    if (bounds == null) {
      bounds = _elevationBounds();
      _bounds = bounds;
    }
    return bounds;
  }

  ElevationTile(
      {required this.width, required this.height, required this.elevation});

  Bounds _elevationBounds() {
    var bounds = (min: double.nan, max: double.nan);
    for (int x = 0; x < width; ++x) {
      for (int y = 0; y < height; ++y) {
        final v = elevation(x, y);
        if (bounds.min.isNaN || bounds.min > v) {
          bounds = (min: v, max: bounds.max);
        }
        if (bounds.max.isNaN || bounds.max < v) {
          bounds = (min: bounds.min, max: v);
        }
      }
    }
    return bounds;
  }

  ElevationTile materialize(int buffer) {
    final padding = 2 * buffer;
    final lineWidth = width + padding;
    final columnWidth = height + padding;
    final elevations = Float32List(lineWidth * columnWidth);
    var index = 0;
    for (var y = 0 - buffer; y < height + buffer; ++y) {
      for (var x = 0 - buffer; x < width + buffer; ++x) {
        elevations[index++] = elevation(x, y);
      }
    }
    return ElevationTile(
        width: width,
        height: height,
        elevation: (x, y) {
          final index = (y + buffer) * lineWidth + x + buffer;
          if (index < 0 || index >= elevations.length) {
            return invalidElevation;
          }
          return elevations[index];
        });
  }

  /// scales elevations by the given multiplier
  ElevationTile scale(double multiplier) {
    if (multiplier == 1.0) {
      return this;
    }
    final original = this;
    return ElevationTile(
      width: width,
      height: height,
      elevation: (x, y) => original.elevation(x, y) * multiplier,
    );
  }
}

class ElevationTileArea {
  final ElevationTile center;
  final ElevationTile? leftCenter;
  final ElevationTile? rightCenter;
  final ElevationTile? topLeft;
  final ElevationTile? topCenter;
  final ElevationTile? topRight;
  final ElevationTile? bottomLeft;
  final ElevationTile? bottomCenter;
  final ElevationTile? bottomRight;

  ElevationTileArea(
      {required this.center,
      required this.leftCenter,
      required this.rightCenter,
      required this.topLeft,
      required this.topCenter,
      required this.topRight,
      required this.bottomLeft,
      required this.bottomCenter,
      required this.bottomRight});

  ElevationTile combine() {
    final width = center.width;
    final height = center.height;
    return ElevationTile(
        width: width,
        height: height,
        elevation: (x, y) {
          final List<ElevationTile?> column;
          if (x < 0) {
            x += width;
            column = [topLeft, leftCenter, bottomLeft];
          } else if (x >= width) {
            x -= width;
            column = [topRight, rightCenter, bottomRight];
          } else {
            column = [topCenter, center, bottomCenter];
          }
          ElevationTile? tile;
          if (y < 0) {
            y += height;
            tile = column[0];
          } else if (y >= height) {
            y -= height;
            tile = column[2];
          } else {
            tile = column[1];
          }
          return tile?.elevation(x, y) ?? invalidElevation;
        });
  }
}

class DemTile extends ElevationTile {
  final Float32List data;

  DemTile({required super.width, required super.height, required this.data})
      : super(elevation: (x, y) {
          final v = data[y * width + x];
          if (_isValidElevation(v)) {
            return v;
          }
          return invalidElevation;
        });

  factory DemTile.fromImage(img.Image image, DemEncoding encoding) {
    final width = image.width;
    final height = image.height;
    double decodeMapbox(num r, num g, num b) =>
        -10000 + (r * 256 * 256 + g * 256 + b) * 0.1;
    double decode(num r, num g, num b) => r * 256 + g + b / 256 - 32768;
    final decoder = (encoding == DemEncoding.mapbox) ? decodeMapbox : decode;
    Float32List data = Float32List(width * height);
    for (int y = 0; y < height; ++y) {
      for (int x = 0; x < width; ++x) {
        final pixel = image.getPixelSafe(x, y);
        if (pixel != img.Pixel.undefined) {
          data[(y * width) + x] = decoder(pixel.r, pixel.g, pixel.b);
        }
      }
    }
    return DemTile(width: width, height: height, data: data);
  }
}

bool _isValidElevation(double v) =>
    v >= minValidElevation && v <= maxValidElevation;
