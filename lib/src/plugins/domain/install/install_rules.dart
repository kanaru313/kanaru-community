import '../package/plugin_kind.dart';
import '../package/plugin_package.dart';
import 'held_package.dart';
import 'install_result.dart';
import 'update_diff.dart';

/// What an installed plugin looks like to the install rules.
class InstalledPlugin {
  const InstalledPlugin({
    required this.version,
    required this.kind,
    required this.packageSha256,
    required this.source,
    required this.consentedHosts,
  });

  final int version;

  /// Null for a kind this app does not know.
  final PluginKind? kind;
  final String? packageSha256;

  /// Null for a damaged row.
  final HeldSource? source;
  final List<String> consentedHosts;
}

enum InstallMode {
  /// A new plugin, or a removed one coming back.
  install,

  /// A newer version over the installed one.
  update,

  /// The same package written again.
  repair,
}

/// The verdict of [decideInstall]: either a [mode] to write in, or a
/// [failure].
class InstallDecision {
  const InstallDecision.go(InstallMode this.mode, [this.diff]) : failure = null;
  const InstallDecision.refuse(InstallFailure this.failure)
    : mode = null,
      diff = null;

  final InstallMode? mode;
  final InstallFailure? failure;

  /// What an update changes; null for a new install or a refusal.
  final UpdateDiff? diff;
}

/// Whether a package from [incoming] may replace a plugin installed from
/// [installed]: a repository plugin only from its own repository entry, a
/// file or link plugin only from a file or link (they share one id). The
/// package picks its own name and author, so the id alone proves nothing.
bool sameOrigin(HeldSource? installed, HeldSource incoming) =>
    switch ((installed, incoming)) {
      (RepoHeldSource a, RepoHeldSource b) =>
        a.repoUrl == b.repoUrl && a.slug == b.slug,
      (
        FileHeldSource() || LinkHeldSource(),
        FileHeldSource() || LinkHeldSource(),
      ) =>
        true,
      _ => false,
    };

/// Decides what installing [package] from [source] means over [installed]
/// (null: no live plugin). [allowRepair] lets the same version and the same
/// zip hash through as a repair; any other same version is refused.
InstallDecision decideInstall({
  required HeldSource source,
  required PluginPackage package,
  required InstalledPlugin? installed,
  bool allowRepair = false,
}) {
  if (installed == null) return const InstallDecision.go(InstallMode.install);
  if (!sameOrigin(installed.source, source)) {
    return const InstallDecision.refuse(InstallFailure.otherOrigin);
  }
  final installedKind = installed.kind;
  if (installedKind == null) {
    return const InstallDecision.refuse(InstallFailure.kindChange);
  }
  final diff = diffUpdate(
    consentedHosts: installed.consentedHosts,
    installedVersion: installed.version,
    installedKind: installedKind,
    candidate: UpdateCandidate.fromPackage(package),
  );
  if (diff.kindChange == KindChange.refused) {
    return const InstallDecision.refuse(InstallFailure.kindChange);
  }
  return switch (diff.versionOrder) {
    VersionOrder.older => const InstallDecision.refuse(
      InstallFailure.olderVersion,
    ),
    VersionOrder.same
        when allowRepair && installed.packageSha256 == package.sha256 =>
      InstallDecision.go(InstallMode.repair, diff),
    VersionOrder.same => const InstallDecision.refuse(
      InstallFailure.sameVersion,
    ),
    VersionOrder.newer => InstallDecision.go(InstallMode.update, diff),
  };
}
