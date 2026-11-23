/// A title or artist at least this similar counts as the same.
const titleSimilarityMin = 0.85;
const artistSimilarityMin = 0.85;

/// `1 - edits / longer length` over code points, 1 for equal strings and 0
/// when more than a fifth of the longer string has to change.
double similarity(String a, String b) {
  if (a == b) return 1;
  final ra = a.runes.toList();
  final rb = b.runes.toList();
  final longest = ra.length > rb.length ? ra.length : rb.length;
  final distance = _boundedDistance(ra, rb, (0.2 * longest).floor());
  return distance == null ? 0 : 1 - distance / longest;
}

/// Float rounding must not turn 0.85 into 0.8499999.
bool atLeast(double value, double min) => value + 1e-9 >= min;

/// Optimal string alignment distance (insert, delete, replace, swap of two
/// neighbours), or null when it is above [max].
int? _boundedDistance(List<int> a, List<int> b, int max) {
  if ((a.length - b.length).abs() > max) return null;
  var beforePrev = List<int>.filled(b.length + 1, 0);
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final row = List<int>.filled(b.length + 1, 0)..[0] = i;
    var rowMin = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      var d = prev[j - 1] + cost;
      if (prev[j] + 1 < d) d = prev[j] + 1;
      if (row[j - 1] + 1 < d) d = row[j - 1] + 1;
      if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
        if (beforePrev[j - 2] + 1 < d) d = beforePrev[j - 2] + 1;
      }
      row[j] = d;
      if (d < rowMin) rowMin = d;
    }
    // No later row can come back under max.
    if (rowMin > max) return null;
    beforePrev = prev;
    prev = row;
  }
  final d = prev[b.length];
  return d <= max ? d : null;
}
