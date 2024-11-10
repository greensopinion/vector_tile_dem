import 'dart:typed_data';

import 'tile_id.dart';

abstract class DemProvider {
  abstract final int maxZoom;

  /// provides the bytes of a tile Digital Elevation Model (DEM) in png format
  Future<Uint8List> provide({required TileId tile});
}
