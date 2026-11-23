import '../lyrics.dart';
import '../lyrics_status.dart';
import 'lookup_outcome.dart';
import 'lyrics_match.dart';
import 'lyrics_source.dart';
import 'online_lyrics_ref.dart';
import 'online_rows.dart';
import 'online_resolution_skips.dart';
import 'online_text.dart';

/// How long a "not found" answer is trusted before the source is asked again.
const notFoundTtl = Duration(days: 14);

/// The user's per-track choice; no choice is automatic selection.
enum LyricsChoice {
  /// "Không hiện lời".
  off,

  /// "Lời trong file": the file's lyrics win over a kept online copy.
  file,
}

/// What a track shows, and which sources a lookup still has to ask.
class LyricsResolution {
  const LyricsResolution(this.state, {this.sourcesToAsk = const []});

  final TrackLyrics state;

  /// Enabled sources to ask, in the user's order: not cached, not paused, not
  /// in backoff, not needing configuration. Non-empty exactly when [state] is
  /// [LyricsSearching] and a lookup has to start.
  final List<String> sourcesToAsk;

  bool get needsLookup => sourcesToAsk.isNotEmpty;
}

Lyrics _lyricsOf(OnlineText text, OnlineLyricsRef ref) => Lyrics(
  lines: text.lines,
  synced: text.synced,
  origin: LyricsOrigin.online,
  online: ref,
);

OnlineLyricsRef _pickRef(OnlinePick pick) => OnlineLyricsRef(
  providerId: pick.providerId,
  providerName: pick.providerName,
  remoteId: pick.remoteId,
  remoteDurationMs: pick.remoteDurationMs,
  how: OnlineHow.kept,
);

TrackLyrics? _fromPick(OnlinePick? pick) {
  if (pick == null || !pick.usable) return null;
  final ref = _pickRef(pick);
  final text = pick.text;
  return text != null
      ? LyricsShown(_lyricsOf(text, ref))
      : LyricsInstrumental(ref);
}

bool _deltaOk(int? remoteMs, Duration? trackDuration) {
  if (remoteMs == null || trackDuration == null) return true;
  final diff = Duration(milliseconds: remoteMs) - trackDuration;
  return (diff.isNegative ? -diff : diff) <= maxDurationDelta;
}

/// The cached answer of a source that is still a miss: a fresh "not found",
/// or a result with neither lyrics nor the instrumental flag (a miss whatever
/// its age, so it never causes a new lookup).
bool _isMiss(OnlineCacheEntry e, DateTime now) =>
    e.found ? !e.hasResult : now.difference(e.fetchedAt) < notFoundTtl;

/// Resolves what a track shows, the one place the order is written. Pure.
///
/// 1. [choice] `off`: off ([LyricsOff] holds what automatic would show).
/// 2. [choice] `file` with [local] lyrics: the file's, even with a [pin].
/// 3. a usable [pin]: the kept copy.
/// 4. [local] lyrics.
/// 5. a cached result of a known source (lyrics before instrumental, sources
///    in order, a duration further than [maxDurationDelta] from
///    [trackDuration] ignored).
/// 6. no lyrics plugin installed: [LyricsNoSource].
/// 7. [autoOn] false or the track not [autoSearchable]: [LyricsNone].
/// 8. no source enabled, or every enabled source has a fresh miss:
///    [LyricsNotFound].
/// 9. [lookup] of this track (while its retry time is still ahead): paused or
///    failed.
/// 10. sources to ask: [LyricsSearching] with them; none left (all disabled
///    sources aside, every one is paused, in backoff or needs configuration):
///    paused when all are paused, failed otherwise, without any run.
///
/// [sources] are the live lyrics plugins in the user's order; [backoff] is the
/// in-memory failure backoff by source id. [cache] rows of plugins not in
/// [sources] are ignored.
LyricsResolution resolveTrackLyrics({
  required LyricsChoice? choice,
  required OnlinePick? pin,
  required Lyrics? local,
  required List<OnlineCacheEntry> cache,
  required List<LyricsSource> sources,
  required bool autoOn,
  required bool autoSearchable,
  required DateTime now,
  Duration? trackDuration,
  Map<String, SourceBackoff> backoff = const {},
  LookupOutcome? lookup,
}) {
  final pinned = _fromPick(pin);
  if (choice == LyricsChoice.off) {
    final available = switch (pinned) {
      LyricsShown(:final lyrics) => lyrics,
      _ => local,
    };
    return LyricsResolution(LyricsOff(available));
  }
  if (choice == LyricsChoice.file && local != null) {
    return LyricsResolution(LyricsShown(local));
  }
  if (pinned != null) return LyricsResolution(pinned);
  if (local != null) return LyricsResolution(LyricsShown(local));

  final cached = _fromCache(cache, sources, trackDuration);
  if (cached != null) return LyricsResolution(cached);
  if (sources.isEmpty) return const LyricsResolution(LyricsNoSource());
  if (!autoOn || !autoSearchable) return const LyricsResolution(LyricsNone());

  final enabled = [
    for (final s in sources)
      if (s.enabled) s,
  ];
  final off = sources.length - enabled.length;
  final open = [
    for (final s in enabled)
      if (!cache.any((e) => e.providerId == s.id && _isMiss(e, now))) s,
  ];
  if (open.isEmpty) {
    return LyricsResolution(LyricsNotFound(asked: enabled.length, off: off));
  }
  final outcome = _liveOutcome(lookup, now);
  if (outcome is LookupPaused) {
    return LyricsResolution(LyricsLookupPaused(outcome.until));
  }
  if (outcome is LookupFailed) {
    return LyricsResolution(
      LyricsLookupFailed(
        reason: outcome.reason,
        asked: outcome.asked,
        retryAt: outcome.retryAt,
      ),
    );
  }
  final ask = [
    for (final s in open)
      if (s.askable && !_inBackoff(backoff[s.id], now)) s.id,
  ];
  if (ask.isNotEmpty) {
    return LyricsResolution(LyricsSearching(enabled.length), sourcesToAsk: ask);
  }
  return LyricsResolution(stateWithoutRun(open, enabled.length, backoff, now));
}

TrackLyrics? _fromCache(
  List<OnlineCacheEntry> cache,
  List<LyricsSource> sources,
  Duration? trackDuration,
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
            _deltaOk(e.remoteDurationMs, trackDuration))
          (e, s),
  ];
  for (final (e, s) in usable) {
    final text = e.text;
    if (text != null) return LyricsShown(_lyricsOf(text, refOf(e, s)));
  }
  for (final (e, s) in usable) {
    if (e.instrumental) return LyricsInstrumental(refOf(e, s));
  }
  return null;
}

LookupOutcome? _liveOutcome(LookupOutcome? lookup, DateTime now) =>
    switch (lookup) {
      LookupPaused(:final until) when !until.isAfter(now) => null,
      LookupFailed(:final retryAt?) when !retryAt.isAfter(now) => null,
      _ => lookup,
    };

bool _inBackoff(SourceBackoff? b, DateTime now) =>
    b != null && b.until.isAfter(now);
