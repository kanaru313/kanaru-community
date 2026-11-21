import '../../playback/domain/playable.dart';
import 'lyrics.dart';

/// What the app knows about the lyrics of one track. Plain data for state
/// and UI.
sealed class TrackLyrics {
  const TrackLyrics();
}

/// Still reading; the body stays blank (never the previous track's lines).
class LyricsLoading extends TrackLyrics {
  const LyricsLoading();
}

/// Lyrics to show.
class LyricsShown extends TrackLyrics {
  const LyricsShown(this.lyrics);

  final Lyrics lyrics;

  @override
  bool operator ==(Object other) =>
      other is LyricsShown && other.lyrics == lyrics;

  @override
  int get hashCode => lyrics.hashCode;
}

/// No lyrics in the file or next to it.
class LyricsNone extends TrackLyrics {
  const LyricsNone();
}

/// The user turned lyrics off for this track; [available] is what automatic
/// selection would show (null when there is none).
class LyricsOff extends TrackLyrics {
  const LyricsOff(this.available);

  final Lyrics? available;

  @override
  bool operator ==(Object other) =>
      other is LyricsOff && other.available == available;

  @override
  int get hashCode => available.hashCode;
}

/// The track has no local file to read (missing, remote, CUE, no mount).
class LyricsUnavailable extends TrackLyrics {
  const LyricsUnavailable(this.reason);

  final UnplayableReason reason;

  @override
  bool operator ==(Object other) =>
      other is LyricsUnavailable && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
