import 'package:test/test.dart';
import 'package:vector_tile_dem/vector_tile_dem.dart';

import 'test_data.dart';
import 'test_output.dart';

void main() {
  group('provides contour lines from a dem', () {
    test('provides isolines', () async {
      final buffer =
          await terrariumToContourLines(tile: centerTile(), demProvider: TestDemProvider(), options: ContourOptions());
      await writeOutput('contour_tile.pbf', buffer);
    });

    test('provides contiguous isolines', () async {
      final tile = TileId(z: 12, x: 646, y: 1401);
      final buffer = await terrariumToContourLines(
          tile: tile, demProvider: TestDemProvider(), options: ContourOptions(minorLevel: 20));
      await writeOutput('contour_tile_${tile.z}_${tile.x}_${tile.y}.pbf', buffer);
    });
  });
}
