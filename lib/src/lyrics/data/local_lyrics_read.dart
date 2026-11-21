import '../../media/domain/track_id.dart';
import '../../playback/domain/playable.dart';
import '../domain/lyrics.dart';
import 'local_lyrics_reader.dart';

/// What to read for one track.
class LyricsRequest {
  const LyricsRequest({
    required this.trackId,
    required this.audioPath,
    required this.trackRevision,
    required this.lrcPath,
  });

  final TrackId trackId;

  /// The resolved local audio file.
  final String audioPath;

  /// `tracks.revision` of the audio file.
  final String? trackRevision;

  /// The `.lrc` the scan matched; null = probe `<stem>.lrc` / `.LRC`.
  final String? lrcPath;
}

/// What both local sources gave for one track, before the selection order and
/// the user's choice are applied.
class LocalLyricsRead {
  const LocalLyricsRead({this.tag, this.lrc, this.incomplete = false})
    : unavailable = null;

  /// A track with no local file to read: no source was asked.
  const LocalLyricsRead.unavailable(UnplayableReason this.unavailable)
    : tag = null,
      lrc = null,
      incomplete = false;

  final Lyrics? tag;
  final Lyrics? lrc;

  /// A source failed in a way that may pass (timeout, I/O error): the other
  /// source still shows, and the result is not cached.
  final bool incomplete;

  /// Set when the track cannot be read from this device.
  final UnplayableReason? unavailable;

  /// Characters of lyrics text held; the cache budget counts them.
  int get textLength => (tag?.textLength ?? 0) + (lrc?.textLength ?? 0);

  @override
  bool operator ==(Object other) =>
      other is LocalLyricsRead &&
      other.tag == tag &&
      other.lrc == lrc &&
      other.incomplete == incomplete &&
      other.unavailable == unavailable;

  @override
  int get hashCode => Object.hash(tag, lrc, incomplete, unavailable);
}

/// Lets a requester withdraw a [LyricsLoader.load] it no longer waits for
/// (its provider was disposed): a tag read still waiting in the queue is then
/// dropped, unless another requester still wants the same read.
class LoadCancel {
  final _listeners = <void Function()>[];
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final l in _listeners) {
      l();
    }
    _listeners.clear();
  }

  /// Runs [listener] on cancel, at once if already cancelled.
  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

/// The request was dropped before it ran: every requester cancelled it while
/// it waited for the native tag reader.
class LyricsSuperseded implements Exception {
  const LyricsSuperseded();

  @override
  String toString() => 'LyricsSuperseded';
}

/// The identity of one read: the same key means the same bytes.
typedef LyricsCacheKey = (TrackId, String, String?, LrcStat?);
