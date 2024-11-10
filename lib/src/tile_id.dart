class TileId {
  final int z;
  final int x;
  final int y;

  TileId({required this.z, required this.x, required this.y});

  TileId copyWith({int? z, int? x, int? y}) =>
      TileId(z: z ?? this.z, x: x ?? this.x, y: y ?? this.y);

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  bool operator ==(Object other) =>
      other is TileId && other.z == z && other.x == x && other.y == y;

  @override
  String toString() => 'TileId(z:$z,x:$x,y:$y)';

  bool isValid() {
    final max = 1 << z;
    return x >= 0 && x < max && y >= 0 && y < max;
  }
}
