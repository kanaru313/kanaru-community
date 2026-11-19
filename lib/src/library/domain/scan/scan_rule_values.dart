import 'format_groups.dart';

/// Longest minimum duration the settings accept.
const int maxMinDurationMs = 180000;

/// Step of the minimum-duration slider.
const int minDurationStepMs = 5000;

/// The minimum duration made valid: clamped to 0..[maxMinDurationMs] and
/// snapped to the nearest [minDurationStepMs].
int normalizeMinDurationMs(int value) {
  final clamped = value.clamp(0, maxMinDurationMs);
  return (clamped / minDurationStepMs).round() * minDurationStepMs;
}

/// Decimal kilobyte, as Android and the Linux file managers show sizes.
const int bytesPerKb = 1000;

/// Decimal megabyte (1000 KB).
const int bytesPerMb = 1000 * bytesPerKb;

/// Stops of the minimum-size slider: off, 100 KB to 1 MB in 100 KB steps,
/// then 1.5 MB to 10 MB in 0.5 MB steps.
final List<int> minSizeStopsBytes = [
  0,
  for (var kb = 100; kb <= 1000; kb += 100) kb * bytesPerKb,
  for (var half = 3; half <= 20; half++) half * bytesPerMb ~/ 2,
];

/// The stop of [minSizeStopsBytes] nearest to [value] (a tie goes to the
/// smaller stop); anything above the last stop becomes the last stop.
int snapMinSizeBytes(int value) {
  var best = minSizeStopsBytes.first;
  for (final stop in minSizeStopsBytes) {
    if ((stop - value).abs() < (best - value).abs()) best = stop;
  }
  return best;
}

/// Decodes `library.min_duration_ms`. Throws [FormatException] for anything
/// but an int, so the setting falls back to its default.
int decodeMinDurationMs(Object? json) {
  if (json is int) return normalizeMinDurationMs(json);
  throw FormatException('not an int: $json');
}

/// Decodes `library.min_size_bytes`. Throws [FormatException] for anything
/// but an int.
int decodeMinSizeBytes(Object? json) {
  if (json is int) return snapMinSizeBytes(json);
  throw FormatException('not an int: $json');
}

/// Decodes `library.format_groups`: known ids in list order. Unknown ids are
/// dropped; a list left empty means every group (a bad value must never make
/// the scan see no file). Throws [FormatException] when [json] is no list.
List<String> decodeFormatGroups(Object? json) {
  if (json is! List) throw FormatException('not a list: $json');
  final wanted = json.whereType<String>().toSet();
  final kept = [
    for (final id in allFormatGroupIds)
      if (wanted.contains(id)) id,
  ];
  return kept.isEmpty ? allFormatGroupIds : kept;
}
