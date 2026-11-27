import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../../plugins/domain/package/plugin_kind.dart';
import '../../plugins/state/plugin_run_provider.dart';
import '../../plugins/state/plugin_store_providers.dart';
import '../data/run/streaming_run_client.dart';
import '../data/tracks/online_track_writer.dart';
import '../domain/contract/online_capabilities.dart';

/// The only way the module runs a streaming plugin's scripts.
final streamingRunClientProvider = Provider<StreamingRunClient>(
  (ref) => StreamingRunClient(ref.watch(pluginRunnerProvider)),
);

final onlineTrackWriterProvider = Provider<OnlineTrackWriter>(
  (ref) => OnlineTrackWriter(
    ref.watch(appDatabaseProvider),
    ref.watch(pluginRowsProvider),
    ref.watch(pluginConfigStoreProvider),
  ),
);

/// What the streaming plugin [installId] offers; null when it is not
/// installed, not a streaming plugin, or its manifest does not parse.
final onlineCapabilitiesProvider = Provider.autoDispose
    .family<OnlineCapabilities?, String>((ref, installId) {
      final row = ref.watch(installedPluginProvider(installId)).value;
      if (row == null || row.kind != PluginKind.streaming.wire) return null;
      final manifest = ref.watch(pluginRowsProvider).manifestOf(row);
      if (manifest == null) return null;
      return OnlineCapabilities.fromScripts(manifest.scripts.keys);
    });
