import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:vector_tile_dem/vector_tile_dem.dart';

import 'api_key.dart';

final _dataDir = Directory('test/data');
final _z = 10;
final _x = [162, 163, 164];
final _y = [348, 349, 350];

final _testDemProvider = TestDemProvider._();

TileId centerTile() => TileId(z: _z, x: _x[1], y: _y[1]);

class TestDemProvider extends DemProvider {
  @override
  int get maxZoom => 12;

  TestDemProvider._();

  factory TestDemProvider() => _testDemProvider;

  @override
  Future<Uint8List> provide({required TileId tile}) async {
    await fetchTestData(tile);
    return _terrariumFile(tile.z, tile.x, tile.y).readAsBytes();
  }
}

Future fetchTestData(TileId tile) async {
  if (!(await _dataDir.exists())) {
    await _dataDir.create(recursive: true);
  }

  await _fetchTerrariumTile(tile.z, tile.x, tile.y);
}

Future _fetchTerrariumTile(int z, int x, int y) async {
  final file = _terrariumFile(z, x, y);
  if (!(await file.exists())) {
    final uri = Uri.parse(
        'https://tiles.stadiamaps.com/data/terrarium/$z/$x/$y.png?api_key=$stadiaMapsApiKey');
    final bytes = await _get(uri);
    await file.writeAsBytes(bytes);
  }
}

Future<Uint8List> _get(Uri uri) async {
  final client = RetryClient(Client());
  try {
    final response = await client.get(uri);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception(
        'HTTP ${response.statusCode}: ${response.reasonPhrase}: ${response.body}');
  } finally {
    client.close();
  }
}

File _terrariumFile(int z, int x, int y) =>
    File('${_dataDir.path}/terrarium_${z}_${x}_$y.png');
