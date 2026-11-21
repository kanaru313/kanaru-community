import 'dart:async';

import '../../../foundation/result.dart';
import '../../../platform/domain/document_picker.dart';
import '../net/cancel_token.dart';
import '../net/fetch_failure.dart';
import '../package/package_problem.dart';
import 'held_package.dart';

/// Why a package could not be prepared at all (nothing to show but the
/// reason). A package that was read but cannot be installed is a
/// `ProblemsReview` instead.
sealed class PrepareFailure {
  const PrepareFailure();
}

/// The download failed (network, size, refused address, bad status).
final class DownloadFailed extends PrepareFailure {
  const DownloadFailed(this.failure);

  final FetchFailure failure;
}

/// The bytes are not an acceptable plugin zip.
final class PackageUnreadable extends PrepareFailure {
  const PackageUnreadable(this.problem);

  final PackageProblem problem;
}

/// The picked file could not be read (missing, over 5 MiB, unreadable).
final class FileUnreadable extends PrepareFailure {
  const FileUnreadable(this.error);

  final DocumentError error;
}

/// The file provider did not answer in time.
final class FileTimedOut extends PrepareFailure {
  const FileTimedOut();
}

/// The repository was removed, has no catalog, or the entry is not in it.
final class EntryGone extends PrepareFailure {
  const EntryGone();
}

/// The catalog entry needs a newer app (unknown type or API version).
final class EntryNeedsNewerApp extends PrepareFailure {
  const EntryNeedsNewerApp();
}

/// The script check could not run (native library missing or it timed out).
/// The package is refused: accepting it would claim the scripts were looked
/// at.
final class ScriptCheckUnavailable extends PrepareFailure {
  const ScriptCheckUnavailable();
}

/// The caller cancelled.
final class PrepareCancelled extends PrepareFailure {
  const PrepareCancelled();
}

/// Anything not listed above; the type name is logged, never shown.
final class PrepareUnexpected extends PrepareFailure {
  const PrepareUnexpected();
}

enum PrepareStage { downloading, reading, checkingScripts }

/// How far a preparation is. [total] is the expected size or script count,
/// null when unknown.
class PrepareProgress {
  const PrepareProgress(this.stage, {this.done = 0, this.total});

  final PrepareStage stage;
  final int done;
  final int? total;
}

/// A running preparation: watch [progress], await [result], [cancel] to stop
/// the download. [result] never throws.
class PrepareOperation {
  PrepareOperation(this._cancel, this.progress, this.result);

  final CancelToken _cancel;
  final Stream<PrepareProgress> progress;
  final Future<Result<HeldPackage, PrepareFailure>> result;

  void cancel() => _cancel.cancel();
}
