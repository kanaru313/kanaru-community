import '../../playback/domain/playable.dart';
import 'lyrics.dart';
import 'online/lookup_outcome.dart';
import 'online/online_lyrics_ref.dart';

/// What the app knows about the lyrics of one track. Plain data for state
/// and UI.
sealed class TrackLyrics {
  const TrackLyrics();

  /// Nothing to show and nothing is being looked up: the body offers the
  /// search or the settings instead.
  bool get isEmpty => switch (this) {
    LyricsNone() ||
    LyricsNotFound() ||
    LyricsNoSource() ||
    LyricsInstrumental() ||
    LyricsLookupFailed() ||
    LyricsLookupPaused() => true,
    LyricsLoading() ||
    LyricsSearching() ||
    LyricsShown() ||
    LyricsOff() ||
    LyricsUnavailable() => false,
  };
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

/// Why a track with no lyrics is not being looked up.
enum LyricsNoneReason {
  /// Automatic online search is switched off.
  autoOff,

  /// Automatic search is on but the song has no title, real artist or
  /// duration to search by.
  notSearchable,
}

/// No lyrics in the file or next to it, and no automatic lookup (see
/// [reason]).
class LyricsNone extends TrackLyrics {
  const LyricsNone({this.reason = LyricsNoneReason.autoOff});

  final LyricsNoneReason reason;

  @override
  bool operator ==(Object other) =>
      other is LyricsNone && other.reason == reason;

  @override
  int get hashCode => Object.hash('none', reason);
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

/// The automatic lookup is running for the track, over [sourceCount] enabled
/// sources.
class LyricsSearching extends TrackLyrics {
  const LyricsSearching(this.sourceCount);

  final int sourceCount;

  @override
  bool operator ==(Object other) =>
      other is LyricsSearching && other.sourceCount == sourceCount;

  @override
  int get hashCode => Object.hash('searching', sourceCount);
}

/// Automatic search is on and every enabled source answered "not found" (a
/// fresh answer). [asked] is the number of enabled sources (0 when none is
/// enabled), [off] the number of disabled ones.
class LyricsNotFound extends TrackLyrics {
  const LyricsNotFound({required this.asked, required this.off});

  final int asked;
  final int off;

  @override
  bool operator ==(Object other) =>
      other is LyricsNotFound && other.asked == asked && other.off == off;

  @override
  int get hashCode => Object.hash('notFound', asked, off);
}

/// No lyrics plugin is installed.
class LyricsNoSource extends TrackLyrics {
  const LyricsNoSource();

  @override
  bool operator ==(Object other) => other is LyricsNoSource;

  @override
  int get hashCode => 'noSource'.hashCode;
}

/// An online source says the song has no words.
class LyricsInstrumental extends TrackLyrics {
  const LyricsInstrumental(this.ref);

  final OnlineLyricsRef ref;

  @override
  bool operator ==(Object other) =>
      other is LyricsInstrumental && other.ref == ref;

  @override
  int get hashCode => ref.hashCode;
}

/// The last lookup ended with every asked source failed, in backoff or
/// needing configuration; nothing was cached. [retryAt] is when the next try
/// starts (null when none is scheduled), [asked] the number of enabled sources
/// the lookup covered.
class LyricsLookupFailed extends TrackLyrics {
  const LyricsLookupFailed({
    required this.reason,
    required this.asked,
    this.retryAt,
  });

  final LookupFailReason reason;
  final int asked;
  final DateTime? retryAt;

  @override
  bool operator ==(Object other) =>
      other is LyricsLookupFailed &&
      other.reason == reason &&
      other.asked == asked &&
      other.retryAt == retryAt;

  @override
  int get hashCode => Object.hash('failed', reason, asked, retryAt);
}

/// Every enabled source is paused (a rate-limit answer) until [until].
class LyricsLookupPaused extends TrackLyrics {
  const LyricsLookupPaused(this.until);

  final DateTime until;

  @override
  bool operator ==(Object other) =>
      other is LyricsLookupPaused && other.until == until;

  @override
  int get hashCode => Object.hash('paused', until);
}
