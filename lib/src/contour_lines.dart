import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'contour_options.dart';
import 'decode.dart';
import 'dem_provider.dart';
import 'isolines_to_tile.dart';
import 'marching_squares.dart';
import 'tile.dart';
import 'tile_id.dart';

Future<Uint8List> terrariumToContourLines(
    {required TileId tile, required DemProvider demProvider, required ContourOptions options}) async {
  var virtualTile = await _retrieveDemWithNeighbours(tile, options, demProvider);
  virtualTile = virtualTile?.scale(options.multiplier).materialize(max(options.buffer, 1));
  return elevationTileToContourLines(tile: virtualTile, options: options);
}

Future<Uint8List> elevationTileToContourLines({required ElevationTile? tile, required ContourOptions options}) async {
  if (tile == null) {
    return isolinesToTile({}, options);
  }
  final algorithm = MarchingSquares(tile: tile, extent: options.extent, buffer: options.buffer);
  final isolines = algorithm.generateIsolines(options.minorLevel);
  return isolinesToTile(isolines, options);
}

Future<ElevationTile?> _retrieveDem(TileId tile, ContourOptions options, _FutureDemProvider provider) async {
  if (!tile.isValid()) {
    return null;
  }
  return await provider.fetch(tile, options);
}

Future<ElevationTile?> _retrieveDemWithNeighbours(TileId tile, ContourOptions options, DemProvider provider) async {
  final tileProvider = _FutureDemProvider(provider);
  final Future<ElevationTile?> center = _retrieveDem(tile, options, tileProvider);
  final Future<ElevationTile?> leftCenter = _retrieveDem(tile.copyWith(x: tile.x - 1), options, tileProvider);
  final Future<ElevationTile?> rightCenter = _retrieveDem(tile.copyWith(x: tile.x + 1), options, tileProvider);
  final Future<ElevationTile?> topLeft =
      _retrieveDem(tile.copyWith(x: tile.x - 1, y: tile.y - 1), options, tileProvider);
  final Future<ElevationTile?> topCenter = _retrieveDem(tile.copyWith(y: tile.y - 1), options, tileProvider);
  final Future<ElevationTile?> topRight =
      _retrieveDem(tile.copyWith(x: tile.x + 1, y: tile.y - 1), options, tileProvider);
  final Future<ElevationTile?> bottomLeft =
      _retrieveDem(tile.copyWith(x: tile.x - 1, y: tile.y + 1), options, tileProvider);
  final Future<ElevationTile?> bottomCenter = _retrieveDem(tile.copyWith(y: tile.y + 1), options, tileProvider);
  final Future<ElevationTile?> bottomRight =
      _retrieveDem(tile.copyWith(x: tile.x + 1, y: tile.y + 1), options, tileProvider);

  final centerTile = await center;
  if (centerTile == null) {
    return null;
  }
  return ElevationTileArea(
          center: centerTile,
          leftCenter: await leftCenter,
          rightCenter: await rightCenter,
          topLeft: await topLeft,
          topCenter: await topCenter,
          topRight: await topRight,
          bottomLeft: await bottomLeft,
          bottomCenter: await bottomCenter,
          bottomRight: await bottomRight)
      .combine();
}

class _FutureDemProvider {
  final DemProvider provider;
  final Map<TileId, Future<ElevationTile>> fetchFutures = {};

  _FutureDemProvider(this.provider);

  Future<ElevationTile> fetch(TileId tileId, ContourOptions options) {
    var future = fetchFutures[tileId];
    if (future == null) {
      final completer = Completer<ElevationTile>();
      _retrieve(completer, tileId, options);
      future = completer.future;
      fetchFutures[tileId] = future;
    }
    return future;
  }

  void _retrieve(Completer<ElevationTile> completer, TileId tileId, ContourOptions options) async {
    try {
      final dem = await provider.provide(tile: tileId);
      final image = decodePng(dem);
      completer.complete(DemTile.fromImage(image, options.encoding));
    } catch (e, stack) {
      completer.completeError(e, stack);
    }
  }
}