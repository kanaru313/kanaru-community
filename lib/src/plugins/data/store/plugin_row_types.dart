import 'dart:convert';

import '../../../database/tables.dart';
import '../../domain/package/plugin_kind.dart';
import '../../domain/package/plugin_package.dart';

/// Where an installed package came from. The wire names are the values of
/// `plugins.origin`.
enum PluginOrigin {
  repo(PluginOriginValues.repo),
  file(PluginOriginValues.file),
  link(PluginOriginValues.link);

  const PluginOrigin(this.wire);

  final String wire;

  static PluginOrigin? fromWire(String value) {
    for (final origin in values) {
      if (origin.wire == value) return origin;
    }
    return null;
  }
}

/// The install source of a plugin: the only place an update or a repair may
/// come from.
class PluginSource {
  /// A repository entry: [url] is the canonical repository address.
  const PluginSource.repo(String url, String slug)
    : origin = PluginOrigin.repo,
      repoUrl = url,
      repoSlug = slug,
      label = null;

  /// A file the user picked; [fileName] is shown to the user.
  const PluginSource.file(String fileName)
    : origin = PluginOrigin.file,
      repoUrl = null,
      repoSlug = null,
      label = fileName;

  /// A link; [url] is the address the package is downloaded from again.
  const PluginSource.link(String url)
    : origin = PluginOrigin.link,
      repoUrl = null,
      repoSlug = null,
      label = url;

  final PluginOrigin origin;
  final String? repoUrl;
  final String? repoSlug;

  /// File name or link; null for a repository install.
  final String? label;

  /// Whether every part the origin needs is present and not empty.
  bool get isComplete => switch (origin) {
    PluginOrigin.repo =>
      (repoUrl ?? '').isNotEmpty && (repoSlug ?? '').isNotEmpty,
    PluginOrigin.file || PluginOrigin.link => (label ?? '').isNotEmpty,
  };
}

/// What a package switch writes into a `plugins` row: everything that comes
/// from the package, nothing about where it came from.
class PluginDraft {
  const PluginDraft({
    required this.kind,
    required this.name,
    required this.version,
    required this.apiVersion,
    required this.manifestJson,
    required this.packageDir,
    required this.packageSha256,
    required this.consentedHosts,
    this.author,
  });

  /// A draft of [package], whose files were written to the folder
  /// [packageDir]. [consentedHosts] defaults to the package's own hosts
  /// (installing or updating is the consent to them).
  factory PluginDraft.fromPackage(
    PluginPackage package, {
    required String packageDir,
    Iterable<String>? consentedHosts,
  }) {
    final manifest = package.manifest;
    return PluginDraft(
      kind: manifest.kind,
      name: manifest.name,
      author: manifest.author.isEmpty ? null : manifest.author,
      version: manifest.version,
      apiVersion: manifest.apiVersion,
      manifestJson: package.manifestText,
      packageDir: packageDir,
      packageSha256: package.sha256,
      consentedHosts: List.unmodifiable(consentedHosts ?? manifest.hosts),
    );
  }

  final PluginKind kind;
  final String name;
  final String? author;
  final int version;
  final int apiVersion;

  /// The original `plugin.json` text.
  final String manifestJson;

  /// The package folder name (`v<version>-<epochMs>`).
  final String packageDir;
  final String packageSha256;
  final List<String> consentedHosts;
}

/// How [PluginRows.installOrRevive] ended.
enum PluginInstallWrite {
  /// A new row.
  inserted,

  /// A tombstone came back to life with fresh config and new consent.
  revived,

  /// The plugin is installed already; nothing was written.
  alreadyLive,
}

/// How [PluginRows.remove] ended.
enum PluginRemoval { removed, alreadyRemoved, missing }

/// Reads of a stored row that need decoding.
extension PluginRowView on PluginRow {
  bool get isLive => removedAt == null;

  /// The hosts the user agreed to; empty for a damaged value.
  List<String> get consentedHosts {
    try {
      final value = jsonDecode(consentedHostsJson);
      if (value is List) {
        return [
          for (final h in value)
            if (h is String) h,
        ];
      }
    } on FormatException {
      // A damaged value counts as no consent: the next update asks again.
    }
    return const [];
  }

  PluginOrigin? get originKind => PluginOrigin.fromWire(origin);

  /// The kind, or null for a value this app does not know.
  PluginKind? get pluginKind => PluginKind.fromWire(kind);

  /// The install source; null only for a row the CHECKs would have refused.
  PluginSource? get source => switch (originKind) {
    PluginOrigin.repo when repoUrl != null && repoSlug != null =>
      PluginSource.repo(repoUrl!, repoSlug!),
    PluginOrigin.file when originLabel != null => PluginSource.file(
      originLabel!,
    ),
    PluginOrigin.link when originLabel != null => PluginSource.link(
      originLabel!,
    ),
    _ => null,
  };
}
