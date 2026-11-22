import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/install_result.dart';
import '../../../plugins/domain/install/prepare_result.dart';
import '../../../plugins/domain/net/fetch_failure.dart';
import '../../../platform/domain/document_picker.dart';

/// The error band of the install screen for a failed preparation or write.
/// [onRetry] prepares the package again.
class PackageErrorBand extends StatelessWidget {
  const PackageErrorBand({
    super.key,
    this.prepareFailure,
    this.writeFailure,
    required this.onRetry,
  });

  final PrepareFailure? prepareFailure;
  final InstallFailure? writeFailure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, message) = _texts(l10n);
    return KInlineNotice(
      icon: KIcons.warning,
      tone: KInlineNoticeTone.errorFilled,
      title: title.isEmpty ? null : title,
      message: message,
      actionLabel: l10n.pluginsRetry,
      onAction: onRetry,
    );
  }

  (String, String) _texts(AppLocalizations l10n) {
    final write = writeFailure;
    if (write != null) {
      return switch (write) {
        InstallFailure.diskFailed ||
        InstallFailure.databaseFailed => ('', l10n.pluginsPkgErrWrite),
        InstallFailure.pluginGone ||
        InstallFailure.repoRemoved ||
        InstallFailure.entryGone => ('', l10n.pluginsPkgErrGone),
        _ => ('', l10n.pluginsPkgErrUnexpected),
      };
    }
    return switch (prepareFailure) {
      DownloadFailed(:final failure) => (
        l10n.pluginsPkgErrDownload(fetchReason(l10n, failure)),
        _networkLike(failure)
            ? l10n.pluginsPkgNothingNetwork
            : l10n.pluginsPkgNothing,
      ),
      FileUnreadable(:final error) => (
        l10n.pluginsPkgErrFile(_fileReason(l10n, error)),
        l10n.pluginsPkgNothing,
      ),
      FileTimedOut() => (
        l10n.pluginsPkgErrFile(l10n.pluginsPkgReasonFileSlow),
        l10n.pluginsPkgNothing,
      ),
      EntryGone() => ('', l10n.pluginsPkgErrGone),
      ScriptCheckUnavailable() => ('', l10n.pluginsReasonCheckUnavailable),
      _ => ('', l10n.pluginsPkgErrUnexpected),
    };
  }

  static bool _networkLike(FetchFailure failure) =>
      failure.kind == FetchFailureKind.network ||
      failure.kind == FetchFailureKind.timeout;

  static String _fileReason(AppLocalizations l10n, DocumentError error) =>
      switch (error) {
        DocumentError.notAFile => l10n.pluginsPkgReasonNotZip,
        DocumentError.tooLarge => l10n.pluginsPkgReasonFileLarge,
        _ => l10n.pluginsPkgReasonUnreadable,
      };
}

/// A short reason a download failed, for "Không tải được …: lý do".
String fetchReason(AppLocalizations l10n, FetchFailure failure) =>
    switch (failure.kind) {
      FetchFailureKind.network => l10n.pluginsPkgReasonNetwork,
      FetchFailureKind.timeout => l10n.pluginsPkgReasonTimeout,
      FetchFailureKind.tooLarge => l10n.pluginsPkgReasonTooLarge,
      FetchFailureKind.blockedAddress => l10n.pluginsPkgReasonBlocked,
      FetchFailureKind.badStatus =>
        failure.status == null
            ? l10n.pluginsPkgReasonNetwork
            : l10n.pluginsPkgReasonStatus(failure.status!),
      FetchFailureKind.invalidUrl => l10n.pluginsPkgReasonInvalidUrl,
      FetchFailureKind.cancelled => l10n.pluginsPkgReasonCancelled,
    };
