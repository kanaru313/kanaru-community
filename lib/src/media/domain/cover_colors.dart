/// Bump when the palette algorithm changes; rows with an older version are
/// recomputed.
const int coverColorsVersion = 1;

/// Colours extracted from a cover, ARGB ints. Used for the Now Playing
/// gradient, the queue strip and album page tint; the seed of the playing
/// cover's colours also drives the app theme.
class CoverColors {
  const CoverColors({required this.seed, required this.palette});

  final int seed;
  final List<int> palette;

  @override
  bool operator ==(Object other) =>
      other is CoverColors &&
      other.seed == seed &&
      _listEquals(other.palette, palette);

  @override
  int get hashCode => Object.hash(seed, Object.hashAll(palette));

  @override
  String toString() => 'CoverColors(seed: $seed, palette: $palette)';
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
