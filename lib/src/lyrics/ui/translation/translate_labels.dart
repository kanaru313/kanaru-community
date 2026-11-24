import '../../../../l10n/gen/app_localizations.dart';
import 'translate_entry_state.dart';
import 'translation_language_name.dart';

/// "Đang dịch sang {ngôn ngữ}" / "Đang tắt": the ⋮ item's second line and the
/// state part of the entry points' tooltips.
String translateStateText(AppLocalizations l10n, TranslateEntryState s) {
  final target = s.target;
  return s.on && target != null
      ? l10n.lyricsTranslateMenuOn(translationLanguageName(l10n, target))
      : l10n.lyricsTranslateMenuOff;
}

/// The tooltip and spoken label of an entry point: "Dịch lời · {state}"; the
/// state is the failure, the run, the language, "off" or why it is inert.
String translateEntryLabel(AppLocalizations l10n, TranslateEntryState s) {
  final state = !s.available
      ? l10n.lyricsTranslateEntryNoLyrics
      : s.working
      ? l10n.lyricsTranslateWorking
      : s.failed
      ? l10n.lyricsTranslateEntryFailed
      : translateStateText(l10n, s);
  return '${l10n.lyricsTranslateTitle} · $state';
}
