import '../package/plugin_package.dart';
import 'script_checker.dart';
import 'update_diff.dart';

/// Where a held package came from. It maps onto the install source a row
/// stores, but lives in the domain so screens can read it.
sealed class HeldSource {
  const HeldSource();

  /// Whether [other] is exactly the same source: same origin and the same
  /// repository entry, file name or link (never the repository row id). Used
  /// by the stale-review check; the looser "may replace" rule is
  /// `sameOrigin` in `install_rules.dart`.
  bool sameSource(HeldSource? other) => switch ((this, other)) {
    (RepoHeldSource a, RepoHeldSource b) =>
      a.repoUrl == b.repoUrl && a.slug == b.slug,
    (FileHeldSource a, FileHeldSource b) => a.fileName == b.fileName,
    (LinkHeldSource a, LinkHeldSource b) => a.url == b.url,
    _ => false,
  };
}

/// An entry of a repository the user added: [repoUrl] is the canonical
/// address, [repoId] the row the entry was read from (null when the source
/// was read from an installed plugin, whose repository may be gone; compare
/// `repoUrl` and `slug`, never the id).
final class RepoHeldSource extends HeldSource {
  const RepoHeldSource({
    this.repoId,
    required this.repoUrl,
    required this.slug,
  });

  final int? repoId;
  final String repoUrl;
  final String slug;
}

/// A file the user picked; [fileName] is shown to the user.
final class FileHeldSource extends HeldSource {
  const FileHeldSource(this.fileName);

  final String fileName;
}

/// A link the user typed; the package is downloaded from it again to repair.
final class LinkHeldSource extends HeldSource {
  const LinkHeldSource(this.url);

  final String url;
}

/// What the installed plugin looked like when the package was prepared. The
/// install step compares it with the row it finds: any difference means the
/// review the user saw is out of date.
class InstallSnapshot {
  const InstallSnapshot({
    required this.installId,
    required this.version,
    required this.consentedHosts,
    required this.packageSha256,
    required this.source,
  });

  final String installId;
  final int version;
  final List<String> consentedHosts;

  /// Hash of the installed zip; null for a row that stored none.
  final String? packageSha256;

  /// The install source of the installed plugin; null for a damaged row.
  final HeldSource? source;

  /// Whether [other] describes the same installed state (hosts compare as
  /// sets).
  bool sameAs(InstallSnapshot? other) =>
      other != null &&
      other.installId == installId &&
      (source == null
          ? other.source == null
          : source!.sameSource(other.source)) &&
      other.version == version &&
      other.packageSha256 == packageSha256 &&
      other.consentedHosts.toSet().length == consentedHosts.toSet().length &&
      other.consentedHosts.toSet().containsAll(consentedHosts);
}

/// A reason a prepared package cannot be installed. The package is still held
/// so the screen can show it next to the reasons.
sealed class HeldProblem {
  const HeldProblem();
}

/// The zip differs from the catalog entry that offered it.
final class CatalogDiffers extends HeldProblem {
  const CatalogDiffers(this.differences);

  final List<CatalogMismatch> differences;
}

/// A script of the package does not compile.
final class ScriptSyntaxError extends HeldProblem {
  const ScriptSyntaxError(this.file, this.problem);

  /// File name inside `src/` (`search.js`).
  final String file;
  final ScriptProblem problem;
}

/// A live plugin with this id was installed from another origin (a
/// repository entry against a file or link, or another repository or entry):
/// a package may only replace a plugin from its own source. [existing] is the
/// source of the installed plugin (null for a damaged row).
final class OtherOrigin extends HeldProblem {
  const OtherOrigin(this.existing);

  final HeldSource? existing;
}

/// The installed plugin's stored kind is not one this app knows, so a kind
/// change cannot be judged: the update is refused.
final class InstalledKindUnknown extends HeldProblem {
  const InstalledKindUnknown();
}

/// What installing the held package would be, decided against the installed
/// plugin (if any) when the package was prepared.
sealed class PackageReview {
  const PackageReview();
}

/// No live plugin has this id: a fresh install.
final class InstallReview extends PackageReview {
  const InstallReview();
}

/// A live plugin has this id: [diff] says what changes (new hosts mean the
/// "Cần xem" screen, an older or equal version is refused at install).
final class UpdateReview extends PackageReview {
  const UpdateReview(this.diff);

  final UpdateDiff diff;
}

/// The same version and zip as the installed plugin: a reinstall of the
/// folder, allowed only as a repair.
final class RepairReview extends PackageReview {
  const RepairReview();
}

/// The package cannot be installed; [problems] is never empty.
final class ProblemsReview extends PackageReview {
  const ProblemsReview(this.problems);

  final List<HeldProblem> problems;

  /// Whether one of the problems is [OtherOrigin] (the install is refused as
  /// `otherOrigin`, not as a package defect).
  bool get hasOtherOrigin => problems.any((p) => p is OtherOrigin);
}

/// A package that passed reading, kept in memory under [token] until the
/// user installs or discards it. Nothing of it is on disk or in the database.
class HeldPackage {
  const HeldPackage({
    required this.token,
    required this.package,
    required this.installId,
    required this.source,
    required this.review,
    required this.snapshot,
  });

  /// Random handle owned by the screen that asked.
  final String token;
  final PluginPackage package;

  /// The id the plugin would be installed under (decided by [source], not by
  /// what the package says about itself, except for a file or link).
  final String installId;
  final HeldSource source;
  final PackageReview review;

  /// The state of the live plugin with [installId], or null when none.
  final InstallSnapshot? snapshot;

  String get sha256 => package.sha256;
}
