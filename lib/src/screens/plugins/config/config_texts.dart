import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/config_form_provider.dart' show ConfigWrite;
import 'config_checks.dart';

/// The line under a field for something the user typed that does not fit.
String configIssueText(AppLocalizations l10n, ConfigIssue issue) {
  final n = issue.n;
  // A whole bound reads without ".0".
  final bound = n == null
      ? ''
      : n == n.truncate()
      ? '${n.truncate()}'
      : '$n';
  return switch (issue.kind) {
    ConfigIssueKind.required => l10n.pluginsCfgRequired,
    ConfigIssueKind.notNumber => l10n.pluginsCfgNotNumber,
    ConfigIssueKind.notInteger => l10n.pluginsCfgNotInteger,
    ConfigIssueKind.belowMin => l10n.pluginsCfgMin(bound),
    ConfigIssueKind.aboveMax => l10n.pluginsCfgMax(bound),
    ConfigIssueKind.tooShort => l10n.pluginsCfgMinLength(bound),
    ConfigIssueKind.tooLong => l10n.pluginsCfgMaxLength(bound),
    ConfigIssueKind.badUrl => l10n.pluginsCfgBadUrl,
    ConfigIssueKind.tooFewItems => l10n.pluginsCfgTooFew(bound),
    ConfigIssueKind.tooManyItems => l10n.pluginsCfgTooMany(bound),
    ConfigIssueKind.badItem => l10n.pluginsCfgBadItem,
    ConfigIssueKind.badName => l10n.pluginsCfgBadName,
    ConfigIssueKind.duplicateName => l10n.pluginsCfgDuplicateName,
  };
}

/// The line under a field the store refused to save ([ConfigWrite.written]
/// has none).
String configRefusalText(AppLocalizations l10n, ConfigWrite result) =>
    switch (result) {
      ConfigWrite.invalidValue => l10n.pluginsCfgRefusedValue,
      ConfigWrite.tooLarge => l10n.pluginsCfgRefusedTooLarge,
      ConfigWrite.unknownKey => l10n.pluginsCfgRefusedGone,
      ConfigWrite.failed || ConfigWrite.written => l10n.pluginsCfgRefusedOther,
    };
