import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/held_package.dart';
import '../../../plugins/domain/install/update_diff.dart';
import '../../../plugins/domain/package/host_rules.dart';
import '../../../plugins/domain/package/package_problem.dart';
import 'install_problem.dart';

/// The line of the "Lý do" box for [reason].
String reasonText(AppLocalizations l10n, ProblemReason reason) =>
    switch (reason) {
      PackageReason(:final problem) => packageProblemText(l10n, problem),
      ScriptReason(:final error) =>
        error.problem.line == null
            ? l10n.pluginsReasonScriptError(error.file)
            : l10n.pluginsReasonScriptErrorLine(
                error.file,
                error.problem.line!,
              ),
      MismatchReason(:final field) => switch (field) {
        CatalogMismatch.kind => l10n.pluginsMismatchKind,
        CatalogMismatch.version => l10n.pluginsMismatchVersion,
        CatalogMismatch.hosts => l10n.pluginsMismatchHosts,
        CatalogMismatch.sha256 => l10n.pluginsMismatchSha,
        CatalogMismatch.size => l10n.pluginsMismatchSize,
      },
      SameVersionReason() => l10n.pluginsReasonSameVersion,
      OlderVersionReason() => l10n.pluginsReasonOlderVersion,
      KindChangeReason() => l10n.pluginsReasonKindChange,
      OtherOriginReason(:final existing) => l10n.pluginsReasonOtherOrigin(
        originText(l10n, existing),
      ),
      CheckUnavailableReason() => l10n.pluginsReasonCheckUnavailable,
      UnknownReason() => l10n.pluginsReasonInvalidManifestPlain,
    };

/// Where an installed plugin came from, for "đã được cài từ …".
String originText(AppLocalizations l10n, HeldSource? source) =>
    switch (source) {
      RepoHeldSource(:final repoUrl) => l10n.pluginsOriginRepo(repoUrl),
      FileHeldSource(:final fileName) => l10n.pluginsOriginFile(fileName),
      LinkHeldSource() => l10n.pluginsOriginLink,
      null => l10n.pluginsOriginOther,
    };

/// One reason of a package that could not be read.
String packageProblemText(AppLocalizations l10n, PackageProblem problem) {
  final detail = problem.detail;
  return switch (problem) {
    InvalidManifest() =>
      detail.isEmpty
          ? l10n.pluginsReasonInvalidManifestPlain
          : l10n.pluginsReasonInvalidManifest(detail),
    UnknownConfigFormat() => l10n.pluginsReasonUnknownFormat(detail),
    NeedsNewerApp() || UnsupportedFeature() => l10n.pluginsReasonNeedsNewerApp,
    UnsupportedKind() => l10n.pluginsReasonUnsupportedKind,
    InvalidHost() => l10n.pluginsReasonBadHost(detail),
    InvalidWildcardHost() => l10n.pluginsReasonBadWildcard(detail),
    WildcardHostNotAllowed() => l10n.pluginsReasonWildcardNotAllowed(detail),
    SharedHostingWildcard() => l10n.pluginsReasonSharedHosting(detail),
    TooManyWildcardHosts() => l10n.pluginsReasonTooManyWildcards(
      detail,
      maxHostWildcards,
    ),
    NotAZip() => l10n.pluginsReasonNotZip,
    PackageTooLarge() => l10n.pluginsReasonTooLarge,
    UnsafeEntry() => l10n.pluginsReasonUnsafeEntry(detail),
    TooManyEntries() => l10n.pluginsReasonTooManyEntries,
    MissingManifest() => l10n.pluginsReasonMissingManifest,
    MissingScript() => l10n.pluginsReasonMissingScript(detail),
    ScriptNotUtf8() => l10n.pluginsReasonScriptNotUtf8(detail),
  };
}

/// Whether a host line is among the reasons (the box then adds its note that
/// only public names are allowed).
bool hasHostReason(InstallProblem problem) => problem.reasons.any(
  (r) =>
      r is PackageReason &&
      (r.problem is InvalidHost ||
          r.problem is InvalidWildcardHost ||
          r.problem is WildcardHostNotAllowed ||
          r.problem is SharedHostingWildcard ||
          r.problem is TooManyWildcardHosts),
);
