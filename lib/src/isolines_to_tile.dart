import 'dart:math';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:vector_tile/raw/raw_vector_tile.dart';

import 'contour_options.dart';

Uint8List isolinesToTile(
    Map<int, List<List<Point<double>>>> isolines, ContourOptions options) {
  final keys = <String>['ele', 'level'];
  final values = <VectorTile_Value>[];
  final eleKeyIndex = keys.indexOf('ele');
  final levelKeyIndex = keys.indexOf('level');
  final features = <VectorTile_Feature>[];
  for (var isoline in isolines.entries) {
    final elevation = isoline.key;
    final level = elevation % options.majorLevel == 0 ? 1 : 0;
    final levelIndex = _valueIndex(values, level);
    final eleValueIndex = _valueIndex(values, elevation);
    for (final geometry in isoline.value) {
      features.add(createVectorTileFeature(
          type: VectorTile_GeomType.LINESTRING,
          geometry: _toVectorLine(geometry),
          tags: [eleKeyIndex, eleValueIndex, levelKeyIndex, levelIndex]));
    }
  }
  return createVectorTile(layers: [
    createVectorTileLayer(
        name: options.contourLayer,
        extent: options.extent,
        version: 2,
        features: features,
        keys: keys,
        values: values)
  ]).writeToBuffer();
}

List<int> _toVectorLine(List<Point<double>> points) {
  final length = points.length;
  final line = <int>[];
  var x = 0;
  var y = 0;
  line.add(_command(1, 1));
  for (var i = 0; i < length; ++i) {
    final point = points[i];
    int dx = point.x.round() - x;
    int dy = point.y.round() - y;
    if (i == 1) {
      line.add(_command(2, length - 1));
    }
    line.add(_zigzag(dx));
    line.add(_zigzag(dy));
    x += dx;
    y += dy;
  }
  return line;
}

int _command(int cmd, int length) {
  return (length << 3) + (cmd & 0x7);
}

int _zigzag(int num) {
  return (num << 1) ^ (num >> 31);
}

int _valueIndex(List<VectorTile_Value> values, int value) {
  final int64 = Int64(value);
  var valueIndex = value >= 0
      ? values.indexWhere((v) => v.intValue == int64)
      : values.indexWhere((v) => v.sintValue == int64);
  if (valueIndex == -1) {
    final v = value < 0
        ? VectorTile_Value(sintValue: int64)
        : VectorTile_Value(intValue: int64);
    values.add(v);
    valueIndex = values.length - 1;
  }
  return valueIndex;
}
