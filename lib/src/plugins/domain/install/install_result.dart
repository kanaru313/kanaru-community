import 'held_package.dart';
import 'prepare_result.dart';

/// What a successful write did to the plugin.
enum InstallOutcome {
  /// A new plugin.
  installed,

  /// A removed plugin came back as a fresh install (empty config).
  revived,

  /// A newer version replaced the installed one.
  updated,

  /// The same package was written again (folder lost or damaged).
  repaired,
}

/// Why an install, update, repair or restore did not write anything. Every
/// reason is a state the screen can show; none carries a message from the
/// outside.
enum InstallFailure {
  /// The held package is unknown, expired or was evicted.
  tokenExpired,

  /// The plugin changed since the user reviewed the package (another update,
  /// a remove): review it again.
  reviewStale,

  /// The installed plugin came from another kind of source (a repository
  /// plugin from a file, a file plugin from a repository).
  otherOrigin,

  /// The installed plugin has this version already.
  sameVersion,

  /// The package is older than the installed plugin.
  olderVersion,

  /// The package is another kind of plugin than the installed one.
  kindChange,

  /// The Free one-music-source rule: a second streaming plugin needs Pro.
  proRequired,

  /// The package has script or catalog problems and cannot be installed.
  hasProblems,

  /// The package differs from the catalog entry that offered it: refreshing
  /// the repository list can fix it.
  catalogMismatch,

  /// A silent path (update all, restore, repair) found new hosts: the user
  /// has to review the update.
  needsReview,

  /// The plugin is not installed (any more).
  pluginGone,

  /// The repository the plugin came from was removed.
  repoRemoved,

  /// The repository no longer lists the plugin.
  entryGone,

  /// The catalog entry needs a newer app.
  needsNewerApp,

  /// The catalog has no newer version.
  noNewerVersion,

  /// A file plugin: only the user can pick the file again.
  needsFile,

  /// The picked package is another plugin than the one being repaired.
  wrongPlugin,

  /// The package folder could not be written.
  diskFailed,

  /// The database refused the write; the new folder was deleted.
  databaseFailed,

  /// Anything else; the type is logged, never shown.
  unexpected,
}

/// The result of any call that writes a package. Never thrown.
sealed class InstallResult {
  const InstallResult();
}

final class Installed extends InstallResult {
  const Installed(this.installId, this.outcome);

  final String installId;
  final InstallOutcome outcome;
}

final class InstallRefused extends InstallResult {
  const InstallRefused(this.failure);

  final InstallFailure failure;
}

/// The package could not even be prepared (download, read, script check).
final class InstallPrepareFailed extends InstallResult {
  const InstallPrepareFailed(this.failure);

  final PrepareFailure failure;
}

/// The package is still held under [held].token: it adds hosts the user did
/// not agree to, so the "Cần xem" screen decides.
final class InstallNeedsReview extends InstallResult {
  const InstallNeedsReview(this.held);

  final HeldPackage held;
}

/// The refusal for a package with [review] problems: another origin, a
/// package that differs from the list, or a package defect.
InstallFailure failureOfProblems(ProblemsReview review) {
  if (review.hasOtherOrigin) return InstallFailure.otherOrigin;
  if (review.problems.any((p) => p is CatalogDiffers)) {
    return InstallFailure.catalogMismatch;
  }
  return InstallFailure.hasProblems;
}
