import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugins/data/store/plugin_row_types.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/plugin_run_provider.dart';
import '../../../plugins/state/plugin_store_providers.dart';
import '../../domain/online/lyrics_source.dart';
import '../../domain/online/source_prefs.dart';
import '../lyrics_settings.dart';

LyricsSourceOrigin? _originOf(String wire) =>
    switch (PluginOrigin.fromWire(wire)) {
      PluginOrigin.repo => LyricsSourceOrigin.repo,
      PluginOrigin.file => LyricsSourceOrigin.file,
      PluginOrigin.link => LyricsSourceOrigin.link,
      null => null,
    };

/// Whether the lists of plugins and settings have their first value. Lookups
/// wait for it: before it the source list is empty, which is not "no plugin".
/// (The prefs are read synchronously, so only the plugin stream can lag.)
final lyricsSourcesLoadedProvider = Provider<bool>(
  (ref) => ref.watch(installedPluginsProvider).hasValue,
);

/// The live lyrics plugins in the user's order, each with its switch and
/// problem. Empty until [lyricsSourcesLoadedProvider]. A plugin that was never
/// ordered follows the saved ones in install order and starts on only when it
/// came from a repository; a removed plugin drops out.
final lyricsSourcesProvider = Provider<List<LyricsSource>>((ref) {
  final rows = ref.watch(installedPluginsProvider).value;
  if (rows == null) return const [];
  final saved = ref.watch(lyricsOnlineSourcesProvider);
  final installed = <LyricsSource>[];
  for (final row in rows) {
    if (row.kind != PluginKind.lyrics.wire) continue;
    final origin = _originOf(row.origin);
    if (origin == null) continue;
    final pausedUntil = ref.watch(pluginPauseProvider(row.installId));
    final status = ref.watch(pluginConfigStatusProvider(row.installId)).value;
    final SourceProblem? problem;
    if (status != null && status.manifest == null) {
      problem = SourceProblem.broken;
    } else if (status != null && status.missingRequired.isNotEmpty) {
      problem = SourceProblem.needsConfig;
    } else if (pausedUntil != null) {
      problem = SourceProblem.paused;
    } else {
      problem = null;
    }
    installed.add(
      LyricsSource(
        id: row.installId,
        name: row.name,
        version: row.version,
        origin: origin,
        enabled: defaultSourceEnabled(origin),
        problem: problem,
        pausedUntil: pausedUntil,
      ),
    );
  }
  return applySourcePrefs(saved, installed);
});
