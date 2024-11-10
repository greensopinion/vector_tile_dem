import 'dart:math';

import 'tile.dart';

class MarchingSquares {
  final ElevationTile tile;
  final int extent;
  final int buffer;
  late final double factor;

  MarchingSquares(
      {required this.tile, required this.extent, required this.buffer}) {
    factor = extent / tile.height;
  }

  Map<int, List<List<Point<double>>>> generateIsolines(int interval) {
    final numRows = tile.width;
    final numCols = tile.height;

    final contourLevels = _contourLevels(interval);

    final isolinesByContourLevel = <int, List<List<Point<double>>>>{};

    for (var contourLevel in contourLevels) {
      final endToContour = <Point<double>, List<Point<double>>>{};
      final rings = <List<Point<double>>>[];
      for (int y = 0 - buffer; y < numRows - 1 + buffer; y++) {
        for (int x = 0 - buffer; x < numCols - 1 + buffer; x++) {
          final bottomLeft = tile.elevation(x, y);
          final bottomRight = tile.elevation(x + 1, y);
          final topRight = tile.elevation(x + 1, y + 1);
          final topLeft = tile.elevation(x, y + 1);
          if (bottomLeft.isNaN ||
              bottomRight.isNaN ||
              topRight.isNaN ||
              topLeft.isNaN) {
            continue;
          }

          int caseIndex = 0;
          if (bottomLeft > contourLevel) caseIndex |= 1;
          if (bottomRight > contourLevel) caseIndex |= 2;
          if (topRight > contourLevel) caseIndex |= 4;
          if (topLeft > contourLevel) caseIndex |= 8;

          final contour = _handleCase(x, y, bottomLeft, bottomRight, topRight,
              topLeft, contourLevel.toDouble(), caseIndex);
          if (contour.isNotEmpty) {
            var firstContour = _findContour(endToContour, contour.first);
            var lastContour = _findContour(endToContour, contour.last);

            if (firstContour != null) {
              if (lastContour != null && firstContour == lastContour) {
                if (!_close(contour.first, contour.last)) {
                  // connect a ring and remove it for future joins
                  endToContour.remove(firstContour.first);
                  endToContour.remove(firstContour.last);
                  endToContour.remove(lastContour.first);
                  endToContour.remove(lastContour.last);
                  firstContour.add(firstContour.first);
                  rings.add(firstContour);
                }
              } else if (lastContour != null) {
                // join contours
                endToContour.remove(firstContour.first);
                endToContour.remove(firstContour.last);
                endToContour.remove(lastContour.first);
                endToContour.remove(lastContour.last);
                if (_close(firstContour.first, contour.first)) {
                  firstContour = firstContour.reversed.toList();
                }
                if (_close(lastContour.last, contour.last)) {
                  lastContour = lastContour.reversed.toList();
                }
                final newContour = firstContour + lastContour;
                endToContour[newContour.first] = newContour;
                endToContour[newContour.last] = newContour;
              } else {
                // extend the contour
                endToContour.remove(firstContour.first);
                endToContour.remove(firstContour.last);
                if (_close(firstContour.first, contour.first)) {
                  firstContour.insert(0, contour.last);
                } else {
                  firstContour.add(contour.last);
                }
                endToContour[firstContour.first] = firstContour;
                endToContour[firstContour.last] = firstContour;
              }
            } else if (lastContour != null) {
              // extend the contour
              endToContour.remove(lastContour.first);
              endToContour.remove(lastContour.last);
              if (_close(lastContour.first, contour.last)) {
                lastContour.insert(0, contour.first);
              } else {
                lastContour.add(contour.first);
              }
              endToContour[lastContour.first] = lastContour;
              endToContour[lastContour.last] = lastContour;
            } else {
              endToContour[contour.first] = contour;
              endToContour[contour.last] = contour;
            }
          }
        }
      }
      if (endToContour.isNotEmpty || rings.isNotEmpty) {
        isolinesByContourLevel[contourLevel] =
            endToContour.values.toSet().toList() + rings;
      }
    }

    return isolinesByContourLevel;
  }

  List<Point<double>> _handleCase(
      int x,
      int y,
      double bottomLeft,
      double bottomRight,
      double topRight,
      double topLeft,
      double contourLevel,
      int caseIndex) {
    final contour = <Point<double>>[];

    Point<double> interpolate(
        Point<double> p1, Point<double> p2, double v1, double v2) {
      Point<double> intersection;
      if (v1 == v2) {
        intersection = (p1 + p2) / 2.0;
      } else {
        double t = (contourLevel - v1) / (v2 - v1);
        intersection =
            Point(p1.x + t * (p2.x - p1.x), p1.y + t * (p2.y - p1.y));
      }
      return (intersection * factor).round();
    }

    final pointBottomLeft = Point<double>(x.toDouble(), y.toDouble());
    final pointBottomRight = Point<double>((x + 1).toDouble(), y.toDouble());
    final pointTopRight = Point<double>((x + 1).toDouble(), (y + 1).toDouble());
    final pointTopLeft = Point<double>(x.toDouble(), (y + 1).toDouble());

    switch (caseIndex) {
      case 0:
      case 15:
        break; // completely inside or outside
      case 1:
        contour.add(interpolate(
            pointBottomLeft, pointBottomRight, bottomLeft, bottomRight));
        contour.add(
            interpolate(pointBottomLeft, pointTopLeft, bottomLeft, topLeft));
        break;
      case 2:
        contour.add(interpolate(
            pointBottomLeft, pointBottomRight, bottomLeft, bottomRight));
        contour.add(interpolate(
            pointBottomRight, pointTopRight, bottomRight, topRight));
        break;
      case 3:
        contour.add(
            interpolate(pointBottomLeft, pointTopLeft, bottomLeft, topLeft));
        contour.add(interpolate(
            pointBottomRight, pointTopRight, bottomRight, topRight));
        break;
      case 4:
        contour.add(interpolate(
            pointTopRight, pointBottomRight, topRight, bottomRight));
        contour
            .add(interpolate(pointTopLeft, pointTopRight, topLeft, topRight));
        break;
      case 5:
        contour.add(interpolate(
            pointBottomLeft, pointBottomRight, bottomLeft, bottomRight));
        contour
            .add(interpolate(pointTopRight, pointTopLeft, topRight, topLeft));
        break;
      case 6:
        contour.add(interpolate(
            pointBottomLeft, pointBottomRight, bottomLeft, bottomRight));
        contour
            .add(interpolate(pointTopLeft, pointTopRight, topLeft, topRight));
        break;
      case 7:
        contour.add(
            interpolate(pointBottomLeft, pointTopLeft, bottomLeft, topLeft));
        contour
            .add(interpolate(pointTopRight, pointTopLeft, topRight, topLeft));
        break;
      case 8:
        contour.add(
            interpolate(pointBottomLeft, pointTopLeft, bottomLeft, topLeft));
        contour
            .add(interpolate(pointTopLeft, pointTopRight, topLeft, topRight));
        break;
      case 9:
        contour.add(interpolate(
            pointBottomLeft, pointBottomRight, bottomLeft, bottomRight));
        contour
            .add(interpolate(pointTopLeft, pointTopRight, topLeft, topRight));
        break;
      case 10:
        contour.add(
            interpolate(pointBottomLeft, pointTopLeft, bottomLeft, topLeft));
        contour.add(interpolate(
            pointBottomRight, pointTopRight, bottomRight, topRight));
        break;
      case 11:
        contour.add(interpolate(
            pointBottomRight, pointTopRight, bottomRight, topRight));
        contour
            .add(interpolate(pointTopLeft, pointTopRight, topLeft, topRight));
        break;
      case 12:
        contour.add(
            interpolate(pointBottomLeft, pointTopLeft, bottomLeft, topLeft));
        contour.add(interpolate(
            pointBottomRight, pointTopRight, bottomRight, topRight));
        break;
      case 13:
        contour.add(interpolate(
            pointBottomLeft, pointBottomRight, bottomLeft, bottomRight));
        contour.add(interpolate(
            pointBottomRight, pointTopRight, bottomRight, topRight));
        break;
      case 14:
        contour.add(interpolate(
            pointBottomLeft, pointBottomRight, bottomLeft, bottomRight));
        contour.add(
            interpolate(pointBottomLeft, pointTopLeft, bottomLeft, topLeft));
        break;
    }

    return contour;
  }

  List<int> _contourLevels(int interval) {
    final bounds = tile.elevationBounds;
    final lower = (bounds.min ~/ interval) * interval;
    final upper = (bounds.max ~/ interval) * interval;
    final levels = <int>[];
    for (int level = lower; level <= upper; level += interval) {
      levels.add(level);
    }
    return levels;
  }

  bool _close(Point<double> p1, Point<double> p2) {
    final delta = 0.01;
    return p1 == p2 ||
        ((p1.x - p2.x).abs() <= delta && (p1.y - p2.y).abs() <= delta);
  }

  List<Point<double>>? _findContour(
          Map<Point<double>, List<Point<double>>> endToContour,
          Point<double> end) =>
      endToContour[end] ??
      endToContour.entries.where((e) => _close(e.key, end)).firstOrNull?.value;
}

extension _PointExtension on Point<double> {
  Point<double> round() => Point(x.roundToDouble(), y.roundToDouble());
  Point<double> operator /(double denominator) =>
      Point(x / denominator, y / denominator);
}
