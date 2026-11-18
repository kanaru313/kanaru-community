import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../platform/state/document_picker_provider.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';
import '../../data/m3u/m3u_export_service.dart';
import '../../data/m3u/m3u_import_service.dart';
import '../../data/m3u/m3u_scan_rules.dart';
import '../playlists/playlist_providers.dart';
import '../scan/scan_settings.dart';
import '../scan_providers.dart';

/// Reads an M3U file and creates the playlist. Tests override it.
final m3uImportServiceProvider = Provider<M3uImportService>(
  (ref) => M3uImportService(
    ref.watch(appDatabaseProvider),
    ref.watch(playlistStoreProvider),
    ref.watch(documentPickerProvider),
    ref.watch(localAudioCatalogProvider).canonicalize,
    ref.watch(libraryScanCommandsProvider),
    ShortTrackRule(enabled: ref.watch(skipShortTracksProvider)),
    androidStorage: Platform.isAndroid,
  ),
);

/// Writes a playlist to an M3U file. Tests override it.
final m3uExportServiceProvider = Provider<M3uExportService>(
  (ref) => M3uExportService(
    ref.watch(appDatabaseProvider),
    ref.watch(documentPickerProvider),
    ref.watch(localAudioCatalogProvider).canonicalize,
  ),
);

/// Whether one flow (import or export) is running. A second start while it
/// is true is ignored; the flow resets it in `finally`.
class M3uBusy extends Notifier<bool> {
  @override
  bool build() => false;

  /// Takes the guard; false when a run already holds it.
  bool tryBegin() {
    if (state) return false;
    state = true;
    return true;
  }

  /// Releases the guard. Does nothing once the container is gone (a flow
  /// outliving the app's scope must not throw from its `finally`).
  void end() {
    if (ref.mounted) state = false;
  }
}

/// Guard of the import flow (separate from export: they never block each
/// other; the system dialog serialises the pickers).
final m3uImportBusyProvider = NotifierProvider<M3uBusy, bool>(M3uBusy.new);

/// Guard of the export flow.
final m3uExportBusyProvider = NotifierProvider<M3uBusy, bool>(M3uBusy.new);
