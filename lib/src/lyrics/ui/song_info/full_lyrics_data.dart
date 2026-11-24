import '../../domain/lyrics.dart';

/// What the full-lyrics modal shows, fixed when it opens: the lyrics, the
/// "name · artist" of the song and the words for where they came from.
class FullLyricsData {
  const FullLyricsData({
    required this.lyrics,
    required this.songTitle,
    required this.song,
    required this.source,
  });

  final Lyrics lyrics;

  /// The song's name alone (the subtitle of the phone page bar).
  final String songTitle;

  /// "Name · Artist" for the header; empty when the song has neither.
  final String song;

  /// The short source of the strip (see `lyricsInfoStripSource`).
  final String source;
}
