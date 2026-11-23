import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/online/lyrics_sources_provider.dart';

/// Whether the plugin [id] behind an online lyrics copy is gone. False until
/// the plugin list is known, so a source is never shown as removed while it
/// is still loading.
final onlineSourceRemovedProvider = Provider.autoDispose.family<bool, String>((
  ref,
  id,
) {
  if (!ref.watch(lyricsSourcesLoadedProvider)) return false;
  return !ref.watch(lyricsSourcesProvider).any((source) => source.id == id);
});

/// How many lyrics plugins are installed, and how many of them are on or off
/// for the automatic search.
class OnlineSourceCounts {
  const OnlineSourceCounts({
    required this.loaded,
    required this.enabled,
    required this.disabled,
  });

  /// The plugin list is known; before that the counts are zero and mean
  /// nothing.
  final bool loaded;
  final int enabled;
  final int disabled;

  int get installed => enabled + disabled;

  @override
  bool operator ==(Object other) =>
      other is OnlineSourceCounts &&
      other.loaded == loaded &&
      other.enabled == enabled &&
      other.disabled == disabled;

  @override
  int get hashCode => Object.hash(loaded, enabled, disabled);
}

/// The source counts of the "Tìm lời trực tuyến…" row.
final onlineSourceCountsProvider = Provider.autoDispose<OnlineSourceCounts>((
  ref,
) {
  if (!ref.watch(lyricsSourcesLoadedProvider)) {
    return const OnlineSourceCounts(loaded: false, enabled: 0, disabled: 0);
  }
  final sources = ref.watch(lyricsSourcesProvider);
  final enabled = sources.where((s) => s.enabled).length;
  return OnlineSourceCounts(
    loaded: true,
    enabled: enabled,
    disabled: sources.length - enabled,
  );
});
