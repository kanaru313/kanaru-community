import 'package:drift/drift.dart';

/// Values of `sources.kind`. The column has no CHECK, so adding a kind needs
/// no table rebuild; code validates against [values].
abstract final class SourceKind {
  static const local = 'local';
  static const webdav = 'webdav';
  static const s3 = 's3';
  static const gdrive = 'gdrive';
  static const onedrive = 'onedrive';
  static const dropbox = 'dropbox';
  static const subsonic = 'subsonic';
  static const jellyfin = 'jellyfin';

  /// Reference-only source of an installed plugin; its tracks are `remote`.
  static const plugin = 'plugin';

  static const Set<String> values = {
    local,
    webdav,
    s3,
    gdrive,
    onedrive,
    dropbox,
    subsonic,
    jellyfin,
    plugin,
  };
}

/// Where tracks come from: a local folder set, a remote server or a plugin.
/// Removing a source is a tombstone (`deleted_at`), so re-adding the same
/// root revives it. `uid` is the only unique key.
@DataClassName('Source')
class Sources extends Table {
  // Identity
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().unique()();
  TextColumn get kind => text()();
  TextColumn get name => text()();

  /// Account identity, remote sources only.
  TextColumn get account => text().nullable()();

  /// Remote base URL, bucket, drive root or plugin install id; null = local.
  TextColumn get root => text().nullable()();

  // Configuration
  /// Non-secret options only.
  TextColumn get configJson => text().withDefault(const Constant('{}'))();

  /// Key in the platform secret store; secrets never go in other columns.
  TextColumn get credentialRef => text().nullable()();

  // Lifecycle
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
}

/// Per-device mount of a source (canonical local path, scan cursor). The row
/// stays when the source is removed so the same root revives the source.
@DataClassName('SourceMount')
@TableIndex.sql(
  'CREATE UNIQUE INDEX source_mounts_root ON source_mounts (root) '
  'WHERE root IS NOT NULL',
)
class SourceMounts extends Table {
  IntColumn get sourceId =>
      integer().references(Sources, #id, onDelete: KeyAction.cascade)();

  /// Canonical local path; null for remote sources.
  TextColumn get root => text().nullable()();

  /// False = disabled; its tracks are hidden.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Incremental scan token (for example a Drive changes token).
  TextColumn get scanCursor => text().nullable()();
  IntColumn get lastScanAt => integer().nullable()();
  IntColumn get addedAt => integer()();

  @override
  Set<Column> get primaryKey => {sourceId};
}

/// A folder of a source the user left out of the library.
@DataClassName('ExcludedFolder')
@TableIndex(name: 'excluded_folders_source', columns: {#sourceId, #folderKey})
class ExcludedFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().unique()();
  IntColumn get sourceId =>
      integer().references(Sources, #id, onDelete: KeyAction.cascade)();

  /// Relative path (path-based sources) or folder id (id-based sources).
  TextColumn get folderKey => text()();

  /// Path shown in the UI.
  TextColumn get displayPath => text()();
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
}
