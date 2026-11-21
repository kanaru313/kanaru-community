import '../../../database/tables.dart';
import '../../domain/install/held_package.dart';
import '../store/plugin_row_types.dart';

/// The install source a row stores for a held package's [source].
PluginSource pluginSourceOf(HeldSource source) => switch (source) {
  RepoHeldSource(:final repoUrl, :final slug) => PluginSource.repo(
    repoUrl,
    slug,
  ),
  FileHeldSource(:final fileName) => PluginSource.file(fileName),
  LinkHeldSource(:final url) => PluginSource.link(url),
};

/// The domain form of a row's install source. A repository source read from
/// a row has no `repoId` (the repository may be gone).
HeldSource? heldSourceOf(PluginSource? source) {
  if (source == null) return null;
  return switch (source.origin) {
    PluginOrigin.repo => RepoHeldSource(
      repoUrl: source.repoUrl ?? '',
      slug: source.repoSlug ?? '',
    ),
    PluginOrigin.file => FileHeldSource(source.label ?? ''),
    PluginOrigin.link => LinkHeldSource(source.label ?? ''),
  };
}

/// What a live [row] looks like to an install check.
InstallSnapshot snapshotOfRow(PluginRow row) => InstallSnapshot(
  installId: row.installId,
  version: row.version,
  consentedHosts: row.consentedHosts,
  packageSha256: row.packageSha256,
  source: heldSourceOf(row.source),
);
