import 'lrc_parser.dart';
import 'lyrics.dart';

/// The lyrics stored in one audio file, as the data layer maps them from the
/// native reader. At least one part is present.
class EmbeddedLyrics {
  const EmbeddedLyrics({this.text, this.synced = const []});

  /// Plain or LRC text as stored in the file.
  final String? text;

  /// Lines of an ID3v2 `SYLT` frame, sorted by time; empty when none.
  final List<LyricLine> synced;
}

/// Tag lyrics: the `SYLT` lines when there are any (already sorted and
/// capped), else the text, which may itself be LRC. `null` when the tag has
/// nothing to show.
Lyrics? lyricsFromTag(EmbeddedLyrics? data) {
  if (data == null) return null;
  if (data.synced.isNotEmpty) {
    return Lyrics(lines: data.synced, synced: true, origin: LyricsOrigin.tag);
  }
  final text = data.text;
  return text == null ? null : parseLyricsText(text, LyricsOrigin.tag);
}
