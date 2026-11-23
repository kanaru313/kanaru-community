import 'lyrics.dart';
import 'lyrics_status.dart';

/// One-word description of a track's lyrics, for subtitles and labels.
enum LyricsSummary {
  tagSynced,
  tagPlain,
  lrcSynced,
  lrcPlain,
  onlineSynced,
  onlinePlain,
  instrumental,
  searching,
  none,
  off,
  unavailable,
  loading,
}

LyricsSummary summaryOfLyrics(Lyrics lyrics) =>
    switch ((lyrics.origin, lyrics.synced)) {
      (LyricsOrigin.tag, true) => LyricsSummary.tagSynced,
      (LyricsOrigin.tag, false) => LyricsSummary.tagPlain,
      (LyricsOrigin.lrc, true) => LyricsSummary.lrcSynced,
      (LyricsOrigin.lrc, false) => LyricsSummary.lrcPlain,
      (LyricsOrigin.online, true) => LyricsSummary.onlineSynced,
      (LyricsOrigin.online, false) => LyricsSummary.onlinePlain,
    };

LyricsSummary summaryOf(TrackLyrics lyrics) => switch (lyrics) {
  LyricsLoading() => LyricsSummary.loading,
  LyricsShown(:final lyrics) => summaryOfLyrics(lyrics),
  LyricsInstrumental() => LyricsSummary.instrumental,
  LyricsSearching() => LyricsSummary.searching,
  LyricsNone() ||
  LyricsNotFound() ||
  LyricsNoSource() ||
  LyricsLookupFailed() ||
  LyricsLookupPaused() => LyricsSummary.none,
  LyricsOff() => LyricsSummary.off,
  LyricsUnavailable() => LyricsSummary.unavailable,
};
