import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import 'plugin_actions_provider.dart';
import 'plugin_services_provider.dart';

/// Size cap of a plugin's own storage, as the runtime enforces it (KB), for
/// the "38 KB / 64 KB" line of the plugin page.
const pluginStorageQuotaKb = 64;

/// Lyrics a lyrics plugin found and Kanaru saved: how many songs and the
/// size of their text in bytes. "Not found" rows hold no lyrics and are not
/// counted.
class SavedLyricsStats {
  const SavedLyricsStats({required this.count, required this.bytes});

  static const none = SavedLyricsStats(count: 0, bytes: 0);

  final int count;
  final int bytes;
}

/// Bytes the plugin's scripts keep in their own storage.
final pluginStorageBytesProvider = FutureProvider.autoDispose
    .family<int, String>(
      (ref, installId) =>
          ref.watch(pluginStorageStoreProvider).sizeBytes(installId),
    );

/// Saved lyrics of the lyrics plugin [providerId]: one grouped query on the
/// start of the primary key.
final savedLyricsStatsProvider = FutureProvider.autoDispose
    .family<SavedLyricsStats, String>((ref, providerId) async {
      final rows = await ref
          .watch(appDatabaseProvider)
          .customSelect(
            'SELECT COUNT(*) AS n, '
            'COALESCE(SUM(COALESCE(LENGTH(CAST(synced_text AS BLOB)), 0) '
            '+ COALESCE(LENGTH(CAST(plain_text AS BLOB)), 0)), 0) AS bytes '
            "FROM online_lyrics WHERE provider_id = ?1 AND status = 'found'",
            variables: [Variable<String>(providerId)],
          )
          .get();
      if (rows.isEmpty) return SavedLyricsStats.none;
      return SavedLyricsStats(
        count: rows.first.read<int>('n'),
        bytes: rows.first.read<int>('bytes'),
      );
    });

/// What the Dữ liệu block deletes. Each call refreshes the numbers the page
/// shows; a failure throws (the page says "Không xoá được dữ liệu").
abstract interface class PluginDataOps {
  /// Empties the plugin's own storage; its next run starts without it.
  Future<void> clearStorage(String installId);

  /// Deletes the saved lyrics of the lyrics plugin [providerId]. Pinned
  /// lyrics (a separate table) and `.lrc` files are never touched.
  Future<void> clearSavedLyrics(String providerId);
}

class _DbPluginDataOps implements PluginDataOps {
  _DbPluginDataOps(this._ref);

  final Ref _ref;

  @override
  Future<void> clearStorage(String installId) async {
    await _ref.read(pluginActionsProvider).clearStorage(installId);
    _ref.invalidate(pluginStorageBytesProvider(installId));
  }

  @override
  Future<void> clearSavedLyrics(String providerId) async {
    final db = _ref.read(appDatabaseProvider);
    await (db.delete(
      db.onlineLyrics,
    )..where((t) => t.providerId.equals(providerId))).go();
    _ref.invalidate(savedLyricsStatsProvider(providerId));
  }
}

/// The deletes of the Dữ liệu block. Tests override it with a fake.
final pluginDataOpsProvider = Provider<PluginDataOps>(_DbPluginDataOps.new);
