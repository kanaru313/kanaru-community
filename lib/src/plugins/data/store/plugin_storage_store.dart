import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../install/write_queue.dart';
import 'plugin_store_rules.dart';

/// What a run starts from: the stored map and the clear counter it was read
/// at. `json` is empty when nothing is stored.
typedef StoredStorage = ({String json, int rev});

/// UTF-8 bytes of every key and value of the stored map [json] (empty or an
/// unreadable text counts as 0). The runtime owns the size quota; this only
/// measures, for the plugin's detail screen.
int storageSizeBytes(String json) {
  if (json.isEmpty) return 0;
  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map) return 0;
    var total = 0;
    for (final e in decoded.entries) {
      final value = e.value;
      total += utf8Length(e.key as String);
      if (value is String) total += utf8Length(value);
    }
    return total;
  } on FormatException {
    return 0;
  } on TypeError {
    return 0;
  }
}

/// The key-value map a plugin's scripts keep between runs, in `plugin_data`.
/// Both writers run as jobs of the plugin write queue, so they never
/// interleave with an update or a remove.
class PluginStorageStore {
  PluginStorageStore(this._db, this._queue);

  final AppDatabase _db;
  final PluginWriteQueue _queue;

  /// The stored map and clear counter; `('', 0)` when the plugin has no data
  /// row.
  Future<StoredStorage> read(String installId) async {
    final row = await (_db.select(
      _db.pluginData,
    )..where((t) => t.installId.equals(installId))).getSingleOrNull();
    return (json: row?.storageJson ?? '', rev: row?.storageRev ?? 0);
  }

  /// Bytes of the stored map of [installId] (see [storageSizeBytes]).
  Future<int> sizeBytes(String installId) async =>
      storageSizeBytes((await read(installId)).json);

  /// Saves [storageJson] as the result of a run, in one statement that holds
  /// only while nothing changed since the run began: the clear counter is
  /// still [expectedRev] and the plugin is live with `updated_at` equal to
  /// [expectedUpdatedAt] (no update, repair or remove since). Returns whether
  /// it wrote. Last writer wins between runs that started at the same
  /// counter. A database failure throws (the caller logs it).
  Future<bool> writeBack(
    String installId,
    String storageJson, {
    required int expectedRev,
    required int expectedUpdatedAt,
  }) => _queue.run<bool>(() async {
    final changed = await _db.customUpdate(
      'UPDATE plugin_data SET storage_json = ?1 '
      'WHERE install_id = ?2 AND storage_rev = ?3 '
      'AND EXISTS (SELECT 1 FROM plugins WHERE install_id = ?2 '
      'AND removed_at IS NULL AND updated_at = ?4)',
      variables: [
        Variable<String>(storageJson),
        Variable<String>(installId),
        Variable<int>(expectedRev),
        Variable<int>(expectedUpdatedAt),
      ],
      updates: {_db.pluginData},
      updateKind: UpdateKind.update,
    );
    return changed > 0;
  });

  /// Empties the storage and counts the clear, so a run that began earlier
  /// cannot write its result back afterwards. Nothing happens for a plugin
  /// without a data row.
  Future<void> clear(String installId) => _queue.run<void>(() async {
    await _db.customUpdate(
      'UPDATE plugin_data SET storage_json = \'\', '
      'storage_rev = storage_rev + 1 WHERE install_id = ?1',
      variables: [Variable<String>(installId)],
      updates: {_db.pluginData},
      updateKind: UpdateKind.update,
    );
  });
}
