enum DemEncoding { mapbox, normal }

/// Options that determine how contour lines are created.
class ContourOptions {
  /// Factor to scale elevation meters, to support different units
  final double multiplier;

  /// The key for the elevation property to set on each contour line.
  final String? elevationKey;

  /// The key for the level property to set on each contour line. Minor levels have level=0 and
  /// major levels have level=1
  final String? levelKey;

  /// The name of the vector tile layer for contour lines.
  final String contourLayer;

  /// The extent of the vector tile.
  final int extent;

  /// The number of indices to generate into the neighbouring tile to reduce rendering artifacts.
  final int buffer;

  /// The threshold used for minor contour lines
  final int minorLevel;

  /// The threshold used for major contour lines
  final int majorLevel;

  /// The encoding, which is needed to interpret elevation values from the DEM image.
  final DemEncoding encoding;

  ContourOptions(
      {this.multiplier = 1,
      this.elevationKey = 'ele',
      this.levelKey = 'level',
      this.contourLayer = 'contours',
      this.extent = 4096,
      this.encoding = DemEncoding.normal,
      this.buffer = 1,
      this.minorLevel = 50,
      this.majorLevel = 200}) {
    assert(multiplier >= 0);
    assert(extent > 0);
    assert(majorLevel > 0);
    assert(minorLevel > 0 && minorLevel < majorLevel);
    assert(majorLevel % minorLevel == 0);
  }
}
