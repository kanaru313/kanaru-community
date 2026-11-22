import '../../../plugins/domain/install/held_package.dart';
import '../../../plugins/domain/install/install_result.dart';
import '../../../plugins/domain/install/prepare_result.dart';
import '../../../plugins/domain/install/update_diff.dart';
import '../../../plugins/domain/package/package_problem.dart';
import 'problem_reasons.dart';

export 'problem_reasons.dart';

/// Which dialog explains a package that cannot be installed.
enum InstallProblemKind {
  /// "Không cài được" with a box of reasons.
  invalid,

  /// "Cần Kanaru mới hơn": no box.
  newerApp,

  /// "Gói không khớp danh sách": the differences and a refresh-and-retry.
  mismatch,
}

/// Everything a problem dialog needs, with no text: [subject] is the file
/// name (when [subjectIsFile]) or the plugin name; [held] is kept for a
/// mismatch, whose retry prepares the same entry again.
class InstallProblem {
  const InstallProblem({
    required this.kind,
    required this.subject,
    this.subjectIsFile = false,
    this.reasons = const [],
    this.held,
    this.apiVersion,
    this.repoLabel,
  });

  final InstallProblemKind kind;
  final String subject;
  final bool subjectIsFile;
  final List<ProblemReason> reasons;
  final HeldPackage? held;

  /// The `apiVersion` of a package that needs a newer app, when known.
  final int? apiVersion;

  /// The repository a mismatching package came from.
  final String? repoLabel;
}

/// The problem a package that failed to read stands for.
InstallProblem problemOfPackage(
  PackageProblem problem, {
  required String subject,
  required bool isFile,
}) => switch (problem) {
  NeedsNewerApp(:final detail) => InstallProblem(
    kind: InstallProblemKind.newerApp,
    subject: subject,
    apiVersion: int.tryParse(detail),
  ),
  UnsupportedKind() => InstallProblem(
    kind: InstallProblemKind.newerApp,
    subject: subject,
  ),
  _ => InstallProblem(
    kind: InstallProblemKind.invalid,
    subject: subject,
    subjectIsFile: isFile,
    reasons: [PackageReason(problem)],
  ),
};

/// The problem a prepare failure that is not an error band stands for; null
/// for the failures the screen shows as a band.
InstallProblem? problemOfPrepareFailure(
  PrepareFailure failure, {
  required String subject,
  required bool isFile,
}) => switch (failure) {
  PackageUnreadable(:final problem) => problemOfPackage(
    problem,
    subject: subject,
    isFile: isFile,
  ),
  EntryNeedsNewerApp() => InstallProblem(
    kind: InstallProblemKind.newerApp,
    subject: subject,
  ),
  ScriptCheckUnavailable() => InstallProblem(
    kind: InstallProblemKind.invalid,
    subject: subject,
    subjectIsFile: isFile,
    reasons: const [CheckUnavailableReason()],
  ),
  _ => null,
};

/// What is wrong with the prepared [held] package, or null when it can be
/// installed or updated (new hosts are for the screen to show, not a problem).
InstallProblem? problemOfHeld(HeldPackage held) {
  final source = held.source;
  final isFile = source is FileHeldSource;
  final subject = isFile ? source.fileName : held.package.manifest.name;
  InstallProblem invalid(List<ProblemReason> reasons) => InstallProblem(
    kind: InstallProblemKind.invalid,
    subject: subject,
    subjectIsFile: isFile,
    reasons: reasons,
  );
  switch (held.review) {
    case InstallReview():
      return null;
    case RepairReview():
      return invalid(const [SameVersionReason()]);
    case UpdateReview(:final diff):
      if (diff.kindChange == KindChange.refused) {
        return invalid(const [KindChangeReason()]);
      }
      return switch (diff.versionOrder) {
        VersionOrder.same => invalid(const [SameVersionReason()]),
        VersionOrder.older => invalid(const [OlderVersionReason()]),
        VersionOrder.newer => null,
      };
    case ProblemsReview(:final problems):
      final reasons = <List<ProblemReason>>[
        for (final p in problems)
          switch (p) {
            CatalogDiffers(:final differences) => <ProblemReason>[
              for (final d in differences) MismatchReason(d),
            ],
            ScriptSyntaxError() => <ProblemReason>[ScriptReason(p)],
            OtherOrigin(:final existing) => <ProblemReason>[
              OtherOriginReason(existing),
            ],
            InstalledKindUnknown() => <ProblemReason>[const KindChangeReason()],
          },
      ].expand((r) => r).toList();
      final onlyMismatch =
          reasons.isNotEmpty && reasons.every((r) => r is MismatchReason);
      if (!onlyMismatch) return invalid(reasons);
      return InstallProblem(
        kind: InstallProblemKind.mismatch,
        subject: subject,
        reasons: reasons,
        held: held,
        repoLabel: source is RepoHeldSource ? source.repoUrl : null,
      );
  }
}

/// The problem a refused write stands for; null for the failures that are
/// not about the package (shown as a band).
InstallProblem? problemOfFailure(
  InstallFailure failure, {
  required String subject,
  required bool isFile,
  HeldSource? existing,
}) {
  final reason = switch (failure) {
    InstallFailure.sameVersion => const SameVersionReason(),
    InstallFailure.olderVersion => const OlderVersionReason(),
    InstallFailure.kindChange => const KindChangeReason(),
    InstallFailure.otherOrigin => OtherOriginReason(existing),
    InstallFailure.hasProblems ||
    InstallFailure.catalogMismatch => const UnknownReason(),
    _ => null,
  };
  if (reason == null) return null;
  return InstallProblem(
    kind: InstallProblemKind.invalid,
    subject: subject,
    subjectIsFile: isFile,
    reasons: [reason],
  );
}
