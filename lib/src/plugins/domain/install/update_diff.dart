import '../catalog/catalog.dart';
import '../package/host_rules.dart';
import '../package/plugin_package.dart';

/// How the candidate's version compares with the installed one.
enum VersionOrder { newer, same, older }

/// Whether the candidate's kind may replace the installed one.
enum KindChange {
  /// Same kind.
  none,

  /// The translate family: `translate` and `ai-translate` may replace each
  /// other.
  allowed,

  /// Any other change (or a kind this app does not know): refused.
  refused,
}

/// What an update brings, read from a catalog entry or a package.
class UpdateCandidate {
  const UpdateCandidate({
    required this.version,
    required this.kind,
    required this.hosts,
  });

  /// From a catalog entry: a hint shown before anything is downloaded.
  UpdateCandidate.fromEntry(CatalogEntry entry)
    : this(version: entry.version, kind: entry.kind, hosts: entry.hosts);

  /// From a downloaded package: authoritative.
  UpdateCandidate.fromPackage(PluginPackage package)
    : this(
        version: package.manifest.version,
        kind: package.manifest.kind,
        hosts: package.manifest.hosts,
      );

  final int version;

  /// Null for a kind this app does not know.
  final PluginKind? kind;
  final List<String> hosts;
}

/// The result of [diffUpdate].
class UpdateDiff {
  const UpdateDiff({
    required this.newHosts,
    required this.versionOrder,
    required this.kindChange,
  });

  /// Candidate host entries the user has not consented to, in candidate
  /// order. A plain name under a consented wildcard is not new.
  final List<String> newHosts;
  final VersionOrder versionOrder;
  final KindChange kindChange;

  /// The update goes to the "Cần xem" screen instead of installing silently:
  /// it would send data to a host the user never agreed to.
  bool get needsReview => newHosts.isNotEmpty;
}

/// Compares [candidate] with an installed plugin: [consentedHosts] is what
/// the user agreed to at install, [installedVersion] and [installedKind] are
/// what is installed.
UpdateDiff diffUpdate({
  required Iterable<String> consentedHosts,
  required int installedVersion,
  required PluginKind installedKind,
  required UpdateCandidate candidate,
}) {
  final consented = consentedHosts.toSet();
  final kind = candidate.kind;
  return UpdateDiff(
    newHosts: [
      for (final host in candidate.hosts)
        if (!hostSetCovers(consented, [host])) host,
    ],
    versionOrder: switch (candidate.version.compareTo(installedVersion)) {
      > 0 => VersionOrder.newer,
      0 => VersionOrder.same,
      _ => VersionOrder.older,
    },
    kindChange: switch (kind) {
      null => KindChange.refused,
      _ when kind == installedKind => KindChange.none,
      _ when kind.isTranslation && installedKind.isTranslation =>
        KindChange.allowed,
      _ => KindChange.refused,
    },
  );
}

/// A field in which a downloaded package differs from the catalog entry that
/// offered it.
enum CatalogMismatch { kind, version, hosts, sha256, size }

/// How [package] differs from [entry], empty when they agree. The package is
/// authoritative; the install screen shows "Gói không khớp danh sách" when
/// this is not empty. `sha256` and `size` are compared only when the entry
/// gives them. Hosts compare as sets.
List<CatalogMismatch> catalogMatches(
  CatalogEntry entry,
  PluginPackage package,
) {
  final manifest = package.manifest;
  return [
    if (entry.kind != manifest.kind) CatalogMismatch.kind,
    if (entry.version != manifest.version) CatalogMismatch.version,
    if (!_sameSet(entry.hosts, manifest.hosts)) CatalogMismatch.hosts,
    if (entry.sha256 != null && entry.sha256 != package.sha256)
      CatalogMismatch.sha256,
    if (entry.size != null && entry.size != package.size) CatalogMismatch.size,
  ];
}

bool _sameSet(List<String> a, List<String> b) {
  final left = a.toSet();
  final right = b.toSet();
  return left.length == right.length && left.containsAll(right);
}
