import 'package:drift/drift.dart';

/// Values of `plugins.origin`: where the installed package came from. The
/// column has a CHECK on this set (a new origin after the first release is a
/// table rebuild).
abstract final class PluginOriginValues {
  /// Installed from a repository entry (`repo_url` + `repo_slug`).
  static const repo = 'repo';

  /// Installed from a file the user picked (`origin_label` = file name).
  static const file = 'file';

  /// Installed from a link (`origin_label` = the link, the re-download source).
  static const link = 'link';

  static const values = {repo, file, link};
}

/// Values of `plugin_repos.address_class`; a CHECK enforces the set.
abstract final class PluginAddressClassValues {
  static const public = 'public';
  static const local = 'local';
  static const values = {public, local};
}

/// Values of `plugins.kind`: the wire names of the plugin kinds. Raw strings:
/// the database layer knows no plugin types. The column has a CHECK on this
/// set. A test compares it with the wire names of `PluginKind`, so the two
/// cannot drift apart.
abstract final class PluginKindValues {
  static const values = {
    'lyrics',
    'translate',
    'ai-translate',
    'streaming',
    'ai-chat',
  };
}

/// A plugin repository the user added. Per device; a plugin keeps its own
/// `repo_url` / `repo_slug`, so removing a repository deletes only this row.
@DataClassName('PluginRepoRow')
class PluginRepos extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The canonical address (`canonicalRepoUrl`), unique.
  TextColumn get url => text().unique()();
  TextColumn get name => text()();

  /// The last good catalog (at most 1 MiB) as normalized JSON with every
  /// reference absolute (the plugin store writes the parsed catalog, not the
  /// received bytes); null before the first successful fetch. A failed
  /// refresh keeps it.
  TextColumn get catalogJson => text().nullable()();
  IntColumn get refreshedAt => integer().nullable()();
  IntColumn get lastAttemptAt => integer().nullable()();

  /// Kind of the last failure (not a message), null after a success.
  TextColumn get lastError => text().nullable()();
  IntColumn get addedAt => integer()();

  /// Address class of the catalog as the fetcher reported it at add or the
  /// last refresh (`public` or `local`). Package and icon fetches from this
  /// catalog are judged with it.
  TextColumn get addressClass =>
      text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(addressClass.isIn(PluginAddressClassValues.values))();
}

/// An installed (or removed) plugin. Removing keeps the row as a tombstone
/// (`removed_at`), so a later sync cannot bring it back and a later install
/// of the same id revives it. Live = `removed_at IS NULL`.
///
/// The id is derived from the install source (`plugin-` + 32 hex), so the
/// same plugin gets the same id on every device. No uid column: per device.
// One row per repository entry. Non-repository rows have both columns NULL
// (CHECK below) and NULLs never collide in a unique index.
@TableIndex(
  name: 'plugins_repo_entry',
  columns: {#repoUrl, #repoSlug},
  unique: true,
)
@DataClassName('PluginRow')
class Plugins extends Table {
  TextColumn get installId => text()();

  TextColumn get kind =>
      text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(kind.isIn(PluginKindValues.values))();
  TextColumn get name => text()();
  TextColumn get author => text().nullable()();
  IntColumn get version => integer()();
  IntColumn get apiVersion => integer()();

  /// The original `plugin.json` text (at most 64 KiB), parsed on read; fields
  /// this app does not know survive in it.
  TextColumn get manifestJson => text()();

  /// Folder of the package under `plugins/<install_id>/`
  /// (`v<version>-<epochMs>`). Null for a tombstone and for a row waiting for
  /// its package to be installed again.
  TextColumn get packageDir => text().nullable()();

  /// Lower-case hex SHA-256 of the package zip.
  TextColumn get packageSha256 => text()();

  TextColumn get origin =>
      text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(origin.isIn(PluginOriginValues.values))();

  /// Set exactly for `origin = 'repo'`.
  TextColumn get repoUrl => text().nullable()();
  TextColumn get repoSlug => text().nullable()();

  /// File name (`file`) or link (`link`); null for a repository install.
  TextColumn get originLabel => text().nullable()();

  /// JSON array of the hosts the user agreed to at install / update. A later
  /// package needing a host outside this set needs a new review.
  TextColumn get consentedHostsJson => text()();
  IntColumn get installedAt => integer()();

  /// Epoch ms of the last package switch or removal; strictly increases.
  IntColumn get updatedAt => integer()();

  /// Tombstone time; null while the plugin is installed.
  IntColumn get removedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {installId};

  @override
  List<String> get customConstraints => [
    // A repository install names its repository entry; the others never do.
    'CONSTRAINT plugins_origin_repo CHECK ('
        "(origin = 'repo' AND repo_url IS NOT NULL AND repo_slug IS NOT NULL) "
        "OR (origin <> 'repo' AND repo_url IS NULL AND repo_slug IS NULL))",
    // A link install keeps its link: it is the re-download source.
    'CONSTRAINT plugins_origin_link CHECK '
        "(origin <> 'link' OR origin_label IS NOT NULL)",
  ];
}

/// Config the user set for an installed plugin. Every value is plain text
/// (no secret store). A tombstone has no row; a new install starts with the
/// defaults.
@DataClassName('PluginDataRow')
class PluginData extends Table {
  TextColumn get installId =>
      text().references(Plugins, #installId, onDelete: KeyAction.restrict)();

  /// JSON object, field key to value (at most 64 KiB).
  TextColumn get configJson => text().withDefault(const Constant('{}'))();

  /// JSON object, field key to the list of `{value, subtitle?}` choices the
  /// user added to a `custom` select (at most 64 KiB). Never read by a script.
  TextColumn get customChoicesJson =>
      text().withDefault(const Constant('{}'))();

  /// The map the plugin's scripts keep between runs, as a JSON object of
  /// strings; '' means nothing stored. The runtime enforces the size quota.
  /// Written back only by a run that still matches the plugin's row, and
  /// emptied by the user's clear (see `storage_rev`). Kept on an update,
  /// deleted with the row on remove.
  TextColumn get storageJson => text().withDefault(const Constant(''))();

  /// Counts the clears of the storage. A run writes its result back only if
  /// the number is still the one it read at its start, so a clear made while
  /// a run was working is never undone by that run.
  IntColumn get storageRev => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {installId};
}
