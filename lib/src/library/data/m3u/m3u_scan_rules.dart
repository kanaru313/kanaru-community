import '../../../platform/domain/local_audio_catalog.dart';
import '../scan/tag_pass_types.dart';

/// The short-track setting as the scanner applies it.
class ShortTrackRule {
  const ShortTrackRule({
    required this.enabled,
    this.thresholdMs = shortTrackMs,
  });

  const ShortTrackRule.off() : this(enabled: false);

  final bool enabled;
  final int thresholdMs;

  /// Mirrors the scanner filter (`media_store_audio_catalog.dart` and
  /// `tag_pass.dart`): a known positive duration under the threshold.
  bool isShort(int? durationMs) =>
      enabled &&
      durationMs != null &&
      durationMs > 0 &&
      durationMs < thresholdMs;
}

/// Mirrors `_volumeAppData` of `media_store_audio_catalog.dart`.
final _volumeAppData = RegExp(
  r'^/storage/(?:emulated/\d+|[^/]+)/Android(?:/|$)',
);

/// Whether a scan of [root] would list the file at [locator]. A placeholder
/// the scanner never lists would stay greyed forever, so such lines are not
/// imported. Each test mirrors one scanner filter:
/// - a folder below the root with `isSkippedFolderName`
///   (`audio_tree_walk.dart`, `media_store_audio_catalog.dart`);
/// - a file name starting with `.` (both scanners);
/// - `<volume>/Android/**` unless the root itself is there (Android only:
///   the Linux walk has no such filter, so [androidAppData] gates it);
/// - the short-track filter (setting on, known duration under the threshold).
bool scannerWouldList({
  required String root,
  required String locator,
  required int? durationMs,
  required ShortTrackRule short,
  bool androidAppData = false,
}) {
  final parts = locator.split('/');
  for (var i = 0; i < parts.length - 1; i++) {
    if (isSkippedFolderName(parts[i])) return false;
  }
  if (parts.last.startsWith('.')) return false;
  final full = root == '/' ? '/$locator' : '$root/$locator';
  if (androidAppData &&
      !_volumeAppData.hasMatch(root) &&
      _volumeAppData.hasMatch(full)) {
    return false;
  }
  return !short.isShort(durationMs);
}
