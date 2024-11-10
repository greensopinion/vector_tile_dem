import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:test/test.dart';
import 'package:vector_tile_dem/src/tile.dart';
import 'package:vector_tile_dem/vector_tile_dem.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import 'contours_theme.dart';
import 'test_data.dart';
import 'test_output.dart';

void main() {
  test('complete real-world tile', () async {
    await _processTerrariumTile(TileId(z: 12, x: 646, y: 1401));
  });
  test('another complete real-world tile', () async {
    final tile = await _processTerrariumTile(TileId(z: 12, x: 646, y: 1400));
    expect(tile.layers.length, 1);
    final layer = tile.layers.first;
    expect(layer.name, 'contours');
    expect(layer.features.length, 245);
    var majorLevels = 0;
    var minorLevels = 0;
    var maxElevation = -10000;
    var minElevation = 10000;
    for (var feature in layer.features) {
      expect(feature.hasPaths, true);
      expect(feature.hasPoints, false);
      expect(feature.type, TileFeatureType.linestring);
      final elevation = feature.properties['ele'];
      final level = feature.properties['level'];
      expect(elevation, isA<int>());
      expect(level, isA<int>());
      expect(elevation % 20, 0, reason: 'elevation=$elevation');
      expect(level, (elevation % 100 == 0) ? 1 : 0, reason: 'elevation=$elevation');
      if (level == 1) {
        ++majorLevels;
      } else {
        ++minorLevels;
      }
      maxElevation = max(elevation, maxElevation);
      minElevation = min(elevation, minElevation);
    }
    expect(majorLevels, 49);
    expect(minorLevels, 196);
    expect(maxElevation, 1060);
    expect(minElevation, 0);
  });

  group('geometries', () {
    const tileSize = 256;
    final midpoint = tileSize ~/ 2;
    const high = 21.0;
    const low = 10.0;

    test('vertical', () async {
      final range = (midpoint - 10, midpoint + 10);
      final tile = ElevationTile(
          width: tileSize, height: tileSize, elevation: (x, y) => (x >= range.$1 && x <= range.$2) ? high : low);
      final result = await _process('vertical', tile);
      _assertTile(result, (TileLayer layer) {
        expect(layer.features.length, 2);
        final first = layer.features.first;
        expect(first.type, TileFeatureType.linestring);
        expect(first.hasPaths, true);
        expect(first.paths.length, 1);
        expect(first.paths.first.bounds, Rect.fromLTRB(1887.0, -16.0, 1887.0, 4096.0));
        final second = layer.features.last;
        expect(second.type, TileFeatureType.linestring);
        expect(second.hasPaths, true);
        expect(second.paths.length, 1);
        expect(second.paths.first.bounds, Rect.fromLTRB(2209.0, -16.0, 2209.0, 4096.0));
      });
    });
    test('horizontal', () async {
      final range = (midpoint - 10, midpoint + 10);
      final tile = ElevationTile(
          width: tileSize, height: tileSize, elevation: (x, y) => (y >= range.$1 && y <= range.$2) ? high : low);
      final result = await _process('horizontal', tile);
      _assertTile(result, (TileLayer layer) {
        expect(layer.features.length, 2);
        final first = layer.features.first;
        expect(first.type, TileFeatureType.linestring);
        expect(first.hasPaths, true);
        expect(first.paths.length, 1);
        expect(first.paths.first.bounds, Rect.fromLTRB(-16.0, 1887.0, 4096.0, 1887.0));
        final second = layer.features.last;
        expect(second.type, TileFeatureType.linestring);
        expect(second.hasPaths, true);
        expect(second.paths.length, 1);
        expect(second.paths.first.bounds, Rect.fromLTRB(-16.0, 2209.0, 4096.0, 2209.0));
      });
    });

    test('diagonal top left to bottom right', () async {
      bool inBounds(int x, int y) {
        final range = (x - 10, x + 10);
        return y >= range.$1 && y <= range.$2;
      }

      final tile = ElevationTile(width: tileSize, height: tileSize, elevation: (x, y) => (inBounds(x, y)) ? high : low);
      final result = await _process('diagonal-tl-br', tile);
      _assertTile(result, (TileLayer layer) {
        expect(layer.features.length, 2);
        final first = layer.features.first;
        expect(first.type, TileFeatureType.linestring);
        expect(first.hasPaths, true);
        expect(first.paths.length, 1);
        expect(first.paths.first.bounds, Rect.fromLTRB(145.0, -16.0, 4096.0, 3935.0));
        final second = layer.features.last;
        expect(second.type, TileFeatureType.linestring);
        expect(second.hasPaths, true);
        expect(second.paths.length, 1);
        expect(second.paths.first.bounds, Rect.fromLTRB(-16.0, 145.0, 3935.0, 4096.0));
      });
    });

    test('diagonal top right to bottom left', () async {
      bool inBounds(int x, int y) {
        final yCenter = tileSize - x;
        final range = (yCenter - 10, yCenter + 10);
        return y >= range.$1 && y <= range.$2;
      }

      final tile = ElevationTile(width: tileSize, height: tileSize, elevation: (x, y) => (inBounds(x, y)) ? high : low);
      final result = await _process('diagonal-tr-bl', tile);
      _assertTile(result, (TileLayer layer) {
        expect(layer.features.length, 2);
        final first = layer.features.first;
        expect(first.type, TileFeatureType.linestring);
        expect(first.hasPaths, true);
        expect(first.paths.length, 1);
        expect(first.paths.first.bounds, Rect.fromLTRB(-16.0, -16.0, 3951.0, 3951.0));
        final second = layer.features.last;
        expect(second.type, TileFeatureType.linestring);
        expect(second.hasPaths, true);
        expect(second.paths.length, 1);
        expect(second.paths.first.bounds, Rect.fromLTRB(161.0, 161.0, 4096.0, 4096.0));
      });
    });

    test('circle-high', () async {
      bool inBounds(int x, int y) {
        final midpoint = tileSize / 2;
        final radius = (tileSize * 0.1).toInt();
        final r2 = radius * radius;
        final l = pow(x - midpoint, 2) + pow(y - midpoint, 2);
        return l <= r2;
      }

      final tile = ElevationTile(width: tileSize, height: tileSize, elevation: (x, y) => (inBounds(x, y)) ? high : low);
      final result = await _process('circle-high', tile);
      _assertTile(result, (TileLayer layer) {
        expect(layer.features.length, 1);
        final first = layer.features.first;
        expect(first.type, TileFeatureType.linestring);
        expect(first.hasPaths, true);
        expect(first.paths.length, 1);
        expect(first.paths.first.bounds, Rect.fromLTRB(1647.0, 1647.0, 2449.0, 2449.0));
      });
    });

    test('circle-low', () async {
      bool inBounds(int x, int y) {
        final midpoint = tileSize / 2;
        final radius = (tileSize * 0.1).toInt();
        final r2 = radius * radius;
        final l = pow(x - midpoint, 2) + pow(y - midpoint, 2);
        return l <= r2;
      }

      final tile = ElevationTile(width: tileSize, height: tileSize, elevation: (x, y) => (inBounds(x, y)) ? low : high);
      final result = await _process('circle-low', tile);
      _assertTile(result, (TileLayer layer) {
        expect(layer.features.length, 1);
        final first = layer.features.first;
        expect(first.type, TileFeatureType.linestring);
        expect(first.hasPaths, true);
        expect(first.paths.length, 1);
        expect(first.paths.first.bounds, Rect.fromLTRB(1633.0, 1633.0, 2463.0, 2463.0));
      });
    });
  });
}

void _assertTile(Tile tile, Function(TileLayer) contourLayerAsserts) {
  final contourLayer = _assertContourLayer(tile);
  contourLayerAsserts(contourLayer);
}

TileLayer _assertContourLayer(Tile tile) {
  expect(tile.layers.length, 1);
  final contourLayer = tile.layers.first;
  expect(contourLayer.name, 'contours');
  expect(contourLayer.extent, 4096);
  return contourLayer;
}

Future<Tile> _processTerrariumTile(TileId tile) async {
  final buffer = await terrariumToContourLines(
      tile: tile, demProvider: TestDemProvider(), options: ContourOptions(minorLevel: 20, majorLevel: 100));
  final vectorFile = await writeOutput('tile-${tile.filenameSuffix}.pbf', buffer);
  print('created ${vectorFile.path}');

  await _createImage(tile.filenameSuffix, buffer);

  return _readTile(buffer);
}

Future<Tile> _process(String name, ElevationTile tile) async {
  final buffer = await elevationTileToContourLines(tile: tile, options: ContourOptions(minorLevel: 20));
  final vectorFile = await writeOutput('tile-$name.pbf', buffer);
  print('created ${vectorFile.path}');

  await _createImage(name, buffer);

  return _readTile(buffer);
}

Future _createImage(String name, Uint8List buffer) async {
  final vectorTile = _readTile(buffer);
  final renderer = ImageRenderer(theme: _theme, scale: 4);

  final image =
      await renderer.render(TileSource(tileset: Tileset({'contour': vectorTile})), zoomScaleFactor: 4, zoom: 12);
  final imageBytes = await image.toPng();
  image.dispose();
  final imageFile = await writeOutput('tile-$name.png', imageBytes);
  print('created ${imageFile.path}');
}

Tile _readTile(Uint8List buffer) => TileFactory(_theme, Logger.console()).create(VectorTileReader().read(buffer));

extension _TileIdExtension on TileId {
  String get filenameSuffix => '${z}_${x}_$y';
}

final _theme = contoursTheme();
