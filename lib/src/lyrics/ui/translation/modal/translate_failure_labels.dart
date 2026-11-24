import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/translation/translation_failure.dart';

/// A button of the status line.
enum TranslateAction { configure, retry, changeService, choose, cancel }

/// What the status line says for one state: a bold [title], one [line] and
/// the [actions] (in the order they are drawn).
class TranslateStatusText {
  const TranslateStatusText({
    required this.title,
    required this.icon,
    this.line,
    this.actions = const [],
  });

  final String title;
  final String? line;
  final IconData icon;
  final List<TranslateAction> actions;
}

/// The status line of [failure]. [service] is the chosen service's name,
/// [language] names a language code, [clock] formats the time a 429 ends.
TranslateStatusText failureStatusText(
  AppLocalizations l10n,
  TranslationFailure failure, {
  required String service,
  required String Function(String code) language,
  required String Function(DateTime time) clock,
}) => switch (failure) {
  RateLimited(:final until) => TranslateStatusText(
    // The clock: the pause ends by itself, nothing to press.
    icon: KIcons.comingSoon,
    title: l10n.lyricsTranslatePausedTitle(service),
    line: l10n.lyricsTranslatePausedLine(clock(until)),
  ),
  NetworkFailure() => TranslateStatusText(
    icon: KIcons.offline,
    title: l10n.lyricsTranslateNetworkTitle(service),
    line: l10n.lyricsTranslateNetworkLine,
    actions: const [TranslateAction.retry],
  ),
  ServerFailure() => TranslateStatusText(
    icon: KIcons.offline,
    title: l10n.lyricsTranslateServerTitle(service),
    line: l10n.lyricsTranslateServerLine,
    actions: const [TranslateAction.retry],
  ),
  Quota() => TranslateStatusText(
    icon: KIcons.offline,
    title: l10n.lyricsTranslateQuotaTitle(service),
    line: l10n.lyricsTranslateQuotaLine,
    actions: const [TranslateAction.changeService],
  ),
  BadKey() => TranslateStatusText(
    icon: KIcons.offline,
    title: l10n.lyricsTranslateBadKeyTitle(service),
    line: l10n.lyricsTranslateBadKeyLine,
    actions: const [TranslateAction.configure, TranslateAction.retry],
  ),
  NeedsConfig(:final fieldTitles) => TranslateStatusText(
    icon: KIcons.offline,
    title: l10n.lyricsTranslateConfigTitle(service),
    line: l10n.lyricsTranslateConfigLine(fieldTitles.join(', ')),
    actions: const [TranslateAction.configure],
  ),
  InvalidResponse() => TranslateStatusText(
    icon: KIcons.offline,
    title: l10n.lyricsTranslateInvalidTitle,
    line: l10n.lyricsTranslateInvalidLine(service),
    actions: const [TranslateAction.retry, TranslateAction.changeService],
  ),
  TooLong() => TranslateStatusText(
    icon: KIcons.offline,
    title: l10n.lyricsTranslateTooLongTitle,
    line: l10n.lyricsTranslateTooLongLine(service),
    actions: const [TranslateAction.changeService],
  ),
  UnsupportedLanguage(:final target) => TranslateStatusText(
    icon: KIcons.offline,
    title: l10n.lyricsTranslateUnsupportedTitle(service, language(target)),
    line: l10n.lyricsTranslateUnsupportedLine,
    actions: const [TranslateAction.changeService],
  ),
  PluginGone() => goneStatusText(l10n),
  NoService() => unsetStatusText(l10n),
};

/// The service was chosen once and is no longer installed.
TranslateStatusText goneStatusText(AppLocalizations l10n) =>
    TranslateStatusText(
      icon: KIcons.offline,
      title: l10n.lyricsTranslateGoneTitle,
      line: l10n.lyricsTranslateGoneLine,
      actions: const [TranslateAction.choose],
    );

/// No service was ever chosen.
TranslateStatusText unsetStatusText(AppLocalizations l10n) =>
    TranslateStatusText(
      icon: KIcons.help,
      title: l10n.lyricsTranslateUnsetTitle,
      line: l10n.lyricsTranslateUnsetLine,
      actions: const [TranslateAction.choose],
    );

/// Why a run stopped half way, in one lower-case clause for "Phần còn lại
/// lỗi: …".
String failureReason(
  AppLocalizations l10n,
  TranslationFailure failure, {
  required String service,
  required String Function(String code) language,
}) => switch (failure) {
  RateLimited() => l10n.lyricsTranslateReasonPaused(service),
  NetworkFailure() => l10n.lyricsTranslateReasonNetwork(service),
  ServerFailure() => l10n.lyricsTranslateReasonServer(service),
  Quota() => l10n.lyricsTranslateReasonQuota(service),
  BadKey() => l10n.lyricsTranslateReasonBadKey,
  NeedsConfig() => l10n.lyricsTranslateReasonConfig(service),
  InvalidResponse() => l10n.lyricsTranslateReasonInvalid,
  TooLong() => l10n.lyricsTranslateReasonTooLong,
  UnsupportedLanguage(:final target) => l10n.lyricsTranslateReasonUnsupported(
    service,
    language(target),
  ),
  PluginGone() => l10n.lyricsTranslateReasonGone,
  NoService() => l10n.lyricsTranslateReasonNoService,
};
