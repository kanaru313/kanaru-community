import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/install_result.dart';
import '../../../plugins/domain/install/prepare_result.dart';
import '../install/package_band.dart';

/// A short reason an update did not happen, for "Không cập nhật được: …".
String updateReason(AppLocalizations l10n, InstallResult result) {
  return switch (result) {
    InstallPrepareFailed(:final failure) => switch (failure) {
      DownloadFailed(:final failure) => fetchReason(l10n, failure),
      EntryGone() => l10n.pluginsUpdateReasonGone,
      PackageUnreadable() ||
      EntryNeedsNewerApp() ||
      ScriptCheckUnavailable() => l10n.pluginsUpdateReasonProblems,
      _ => l10n.pluginsUpdateReasonOther,
    },
    InstallRefused(:final failure) => switch (failure) {
      InstallFailure.hasProblems ||
      InstallFailure.otherOrigin ||
      InstallFailure.kindChange ||
      InstallFailure.needsNewerApp => l10n.pluginsUpdateReasonProblems,
      InstallFailure.pluginGone ||
      InstallFailure.repoRemoved ||
      InstallFailure.entryGone => l10n.pluginsUpdateReasonGone,
      InstallFailure.noNewerVersion ||
      InstallFailure.sameVersion ||
      InstallFailure.olderVersion => l10n.pluginsUpdateReasonNoNewer,
      InstallFailure.diskFailed ||
      InstallFailure.databaseFailed => l10n.pluginsUpdateReasonStorage,
      InstallFailure.proRequired => l10n.pluginsUpdateReasonPro,
      _ => l10n.pluginsUpdateReasonOther,
    },
    _ => l10n.pluginsUpdateReasonOther,
  };
}

/// Whether the result means the new version adds hosts or permissions: the
/// row turns into [Xem].
bool needsReviewResult(InstallResult result) =>
    result is InstallNeedsReview ||
    (result is InstallRefused && result.failure == InstallFailure.needsReview);
