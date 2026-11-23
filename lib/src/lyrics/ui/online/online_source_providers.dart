import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/plugin_store_providers.dart';
import '../../state/online/lyrics_sources_provider.dart';

/// Whether the plugin [id] behind an online lyrics copy is gone: no installed
/// lyrics plugin has that install id. Decided from the installed list alone
/// (not from configuration or pauses, and an origin this build does not know
/// is still installed). False until the list is known, so a source is never
/// shown as removed while it is still loading.
final _lyricsKind = PluginKind.lyrics.wire;

final onlineSourceRemovedProvider = Provider.autoDispose.family<bool, String>((
  ref,
  id,
) {
  final rows = ref.watch(installedPluginsProvider).value;
  if (rows == null) return false;
  return !rows.any((row) => row.installId == id && row.kind == _lyricsKind);
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
