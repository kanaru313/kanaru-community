import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/lyrics.dart';
import '../../domain/lyrics_status.dart';
import '../../domain/online/online_lyrics_ref.dart';
import '../online/online_labels.dart';
import '../online/online_row_info.dart';

/// Where the lyrics came from, for the "Nguồn lời" row and the full-lyrics
/// strip: "Trong tag của tệp", "Tệp .lrc cạnh bài · name", "Bản trực tuyến
/// đã giữ · plugin". An online copy found automatically (and an
/// instrumental result) is worded by the lyrics area's own row line
/// (`onlineRowSubtitle`: "NetEase · Đồng bộ · 4:12 · tự tìm"), so both
/// screens say the same.
///
/// [lrcName] is the file name of the matched `.lrc` (null when unknown);
/// [removed] marks a plugin that is no longer installed.
String lyricsInfoSourceLabel(
  AppLocalizations l10n,
  Lyrics lyrics, {
  String? lrcName,
  bool removed = false,
}) => switch (lyrics.origin) {
  LyricsOrigin.tag => l10n.lyricsInfoSourceTag,
  LyricsOrigin.lrc =>
    lrcName == null
        ? l10n.lyricsInfoSourceLrcBare
        : l10n.lyricsInfoSourceLrc(lrcName),
  LyricsOrigin.online => _online(
    l10n,
    onlineRowInfoOf(LyricsShown(lyrics), null)!,
    removed: removed,
  ),
};

/// The source of an instrumental result: the lyrics area's row line.
String lyricsInfoInstrumentalLabel(
  AppLocalizations l10n,
  LyricsInstrumental state, {
  bool removed = false,
}) => _online(l10n, onlineRowInfoOf(state, null)!, removed: removed);

String _online(
  AppLocalizations l10n,
  OnlineRowInfo info, {
  required bool removed,
}) => info.how == OnlineHow.kept && !info.instrumental
    ? l10n.lyricsInfoSourceKept(info.providerName)
    : onlineRowSubtitle(l10n, info, removed: removed);

/// "5 dòng" / "1 dòng": the count of lines that carry words.
int lyricsTextLineCount(Lyrics lyrics) =>
    lyrics.lines.where((l) => !l.isGap).length;

/// The short source of the full-lyrics strip, after the kind pill: no file
/// name, and for an online copy the plugin only (the pill already says
/// synced or plain).
String lyricsInfoStripSource(AppLocalizations l10n, Lyrics lyrics) =>
    switch (lyrics.origin) {
      LyricsOrigin.tag => l10n.lyricsInfoSourceTag,
      LyricsOrigin.lrc => l10n.lyricsInfoSourceLrcBare,
      LyricsOrigin.online =>
        lyrics.online!.how == OnlineHow.kept
            ? l10n.lyricsInfoSourceKept(lyrics.online!.providerName)
            : '${lyrics.online!.providerName} · ${l10n.lyricsOnlineAuto}',
    };

/// The text "Chép lời" puts on the clipboard: every line, stanza breaks kept,
/// without the empty lines at the start (the intro gap) and the end.
String lyricsCopyText(Lyrics lyrics) {
  final lines = lyrics.lines;
  var from = 0;
  var to = lines.length;
  while (from < to && lines[from].isGap) {
    from++;
  }
  while (to > from && lines[to - 1].isGap) {
    to--;
  }
  return lines.sublist(from, to).map((l) => l.text).join('\n');
}
