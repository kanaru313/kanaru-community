import '../lyrics.dart';
import '../lyrics_status.dart';
import 'lyrics_match.dart';
import 'lyrics_source.dart';
import 'online_lyrics_ref.dart';
import 'online_resolution.dart' show notFoundTtl;
import 'online_rows.dart';
import 'online_text.dart';

/// Results the user refused for the track: by id and by text hash.
class RejectedResults {
  const RejectedResults({this.refs = const {}, this.hashes = const {}});

  final Set<({String providerId, String remoteId})> refs;
  final Set<String> hashes;

  bool get isEmpty => refs.isEmpty && hashes.isEmpty;

  /// Whether the found [e] is a result this track refused.
  bool refuses(OnlineCacheEntry e) {
    if (!e.found || isEmpty) return false;
    final id = e.remoteId;
    if (id != null && refs.contains((providerId: e.providerId, remoteId: id))) {
      return true;
    }
    final text = e.text;
    return text != null && hashes.contains(lyricsContentHash(text.lines));
  }
}

bool _deltaOk(int? remoteMs, Duration? trackDuration) {
  if (remoteMs == null || trackDuration == null) return true;
  final diff = Duration(milliseconds: remoteMs) - trackDuration;
  return (diff.isNegative ? -diff : diff) <= maxDurationDelta;
}

/// The cached answer of a source that is still a miss: a fresh "not found",
/// or a result with neither lyrics nor the instrumental flag (a miss whatever
/// its age, so it never causes a new lookup).
bool isCacheMiss(OnlineCacheEntry e, DateTime now) =>
    e.found ? !e.hasResult : now.difference(e.fetchedAt) < notFoundTtl;

/// The state a cached result of a known source gives, or null. Lyrics beat
/// instrumental, sources keep their order, a duration further than
/// [maxDurationDelta] from [trackDuration] and a result the track refused are
/// ignored.
TrackLyrics? lyricsFromCache(
  List<OnlineCacheEntry> cache,
  List<LyricsSource> sources,
  Duration? trackDuration,
  RejectedResults rejected,
) {
  OnlineLyricsRef refOf(OnlineCacheEntry e, LyricsSource s) => OnlineLyricsRef(
    providerId: s.id,
    providerName: s.name,
    remoteId: e.remoteId ?? '',
    remoteDurationMs: e.remoteDurationMs,
    how: OnlineHow.auto,
  );
  final usable = <(OnlineCacheEntry, LyricsSource)>[
    for (final s in sources)
      for (final e in cache)
        if (e.providerId == s.id &&
            e.hasResult &&
            !rejected.refuses(e) &&
            _deltaOk(e.remoteDurationMs, trackDuration))
          (e, s),
  ];
  for (final (e, s) in usable) {
    final text = e.text;
    if (text != null) return LyricsShown(onlineLyricsOf(text, refOf(e, s)));
  }
  for (final (e, s) in usable) {
    if (e.instrumental) return LyricsInstrumental(refOf(e, s));
  }
  return null;
}

/// The lyrics of [text] with their online [ref].
Lyrics onlineLyricsOf(OnlineText text, OnlineLyricsRef ref) => Lyrics(
  lines: text.lines,
  synced: text.synced,
  origin: LyricsOrigin.online,
  online: ref,
);
