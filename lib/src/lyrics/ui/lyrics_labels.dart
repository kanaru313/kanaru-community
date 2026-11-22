import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics_summary.dart';

/// The words for a [LyricsSummary]: "Lời trong tag · Đồng bộ", "Tệp .lrc ·
/// Thường", "Tắt lời", "Không có lời". [short] drops the kind ("Trong tag",
/// "Tệp .lrc", "Tắt") and is empty when there is nothing to name; the card
/// shows it next to its title.
String lyricsSummaryLabel(
  AppLocalizations l10n,
  LyricsSummary summary, {
  bool short = false,
}) {
  if (short) {
    return switch (summary) {
      LyricsSummary.tagSynced ||
      LyricsSummary.tagPlain => l10n.lyricsLabelShortTag,
      LyricsSummary.lrcSynced ||
      LyricsSummary.lrcPlain => l10n.lyricsLabelShortLrc,
      LyricsSummary.off => l10n.lyricsLabelShortOff,
      LyricsSummary.none ||
      LyricsSummary.unavailable ||
      LyricsSummary.loading => '',
    };
  }
  return switch (summary) {
    LyricsSummary.tagSynced => l10n.lyricsLabelTagSynced,
    LyricsSummary.tagPlain => l10n.lyricsLabelTagPlain,
    LyricsSummary.lrcSynced => l10n.lyricsLabelLrcSynced,
    LyricsSummary.lrcPlain => l10n.lyricsLabelLrcPlain,
    LyricsSummary.off => l10n.lyricsLabelOff,
    LyricsSummary.none || LyricsSummary.unavailable => l10n.lyricsLabelNone,
    LyricsSummary.loading => '',
  };
}
