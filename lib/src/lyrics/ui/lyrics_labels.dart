import '../../../l10n/gen/app_localizations.dart';
import '../domain/lyrics_status.dart';
import '../domain/lyrics_summary.dart';
import 'online/online_labels.dart';
import 'online/online_source_of.dart';

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
      LyricsSummary.onlineSynced ||
      LyricsSummary.onlinePlain ||
      LyricsSummary.instrumental ||
      LyricsSummary.searching ||
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
    LyricsSummary.onlineSynced ||
    LyricsSummary.onlinePlain ||
    LyricsSummary.instrumental ||
    LyricsSummary.searching ||
    LyricsSummary.loading => '',
  };
}

/// The words for what a track shows now: [lyricsSummaryLabel] for local
/// lyrics, "NetEase · Đồng bộ" for online ones, and the state of a lookup
/// ("Đang tìm…", "Chưa tìm được lời", "Nguồn lời tạm dừng"). [short] is the
/// word next to the card title: the plugin's name for online lyrics, empty
/// for a lookup state.
String lyricsLabelOf(
  AppLocalizations l10n,
  TrackLyrics lyrics, {
  bool short = false,
}) {
  final online = onlineShownOf(lyrics);
  if (online != null) {
    return short
        ? online.providerName
        : onlineSourceLabel(
            l10n,
            plugin: online.providerName,
            synced: online.synced,
            instrumental: online.instrumental,
          );
  }
  if (short) {
    return lyricsSummaryLabel(l10n, summaryOf(lyrics), short: true);
  }
  return switch (lyrics) {
    LyricsSearching() => l10n.lyricsLabelSearching,
    LyricsLookupFailed() => l10n.lyricsLabelFailed,
    LyricsLookupPaused() => l10n.lyricsLabelPaused,
    _ => lyricsSummaryLabel(l10n, summaryOf(lyrics)),
  };
}
