import 'dart:typed_data';

import 'tile_id.dart';

abstract class DemProvider {
  abstract final int maxZoom;

  Future<Uint8List> provide({required TileId tile});
}
