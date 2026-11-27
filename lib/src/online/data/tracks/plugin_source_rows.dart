import 'package:drift/drift.dart' show Value;

import '../../../database/app_database.dart';
import '../../../database/row_uids.dart';
import '../../../database/tables.dart';
import '../../../database/tombstone_upsert.dart';
import '../../../plugins/data/store/plugin_row_types.dart';
import '../../../plugins/domain/package/plugin_kind.dart';

/// The `sources.account` of the streaming install [row]: null for a
/// repository install (its id is the same after remove + install), and
/// `install:<installed_at>` for a file or link install (its id is the same
/// for the same name and author, so a new install must not inherit the old
/// tracks). A source row belongs to the live install only when its `root`
/// is the install id and its `account` equals this.
String? pluginSourceAccount(PluginRow row) =>
    row.origin == PluginOriginValues.repo ? null : 'install:${row.installedAt}';

/// The `sources` row of one streaming install.
class PluginSourceRef {
  const PluginSourceRef({
    required this.sourceId,
    required this.sourceUid,
    required this.installId,
  });

  final int sourceId;
  final String sourceUid;
  final String installId;
}

/// The `sources` row of the streaming install [row], created or revived.
/// There is no `source_mounts` row: a plugin source has no path on a device.
/// Throws [ArgumentError] when [row] is removed or not a streaming plugin.
Future<PluginSourceRef> ensurePluginSource(
  AppDatabase db,
  PluginRow row, {
  required int now,
}) async {
  if (!row.isLive || row.kind != PluginKind.streaming.wire) {
    throw ArgumentError.value(
      row.installId,
      'row',
      'not a live streaming plugin',
    );
  }
  final account = pluginSourceAccount(row);
  final source = await insertOrRevive(
    db,
    db.sources,
    SourcesCompanion.insert(
      uid: sourceUidForRemote(SourceKind.plugin, account, row.installId),
      kind: SourceKind.plugin,
      name: row.name,
      account: Value(account),
      root: Value(row.installId),
      addedAt: now,
      updatedAt: now,
    ),
    now: now,
    reviveColumns: {'name'},
  );
  return PluginSourceRef(
    sourceId: source.id,
    sourceUid: source.uid,
    installId: row.installId,
  );
}
