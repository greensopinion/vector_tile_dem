import 'package:test/test.dart';
import 'package:vector_tile_dem/vector_tile_dem.dart';

import 'test_data.dart';
import 'test_output.dart';

void main() {
  group('provides contour lines from a dem', () {
    test('provides isolines', () async {
      final buffer = await terrariumToContourLines(
          tile: centerTile(),
          demProvider: TestDemProvider(),
          options: ContourOptions());
      await writeOutput('contour_tile.pbf', buffer);
    });
  });
}
