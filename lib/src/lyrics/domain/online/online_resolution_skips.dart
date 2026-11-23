import '../lyrics_status.dart';
import 'lookup_outcome.dart';
import 'lyrics_source.dart';

/// The state of a lookup that has no source left to ask: every [open] source
/// is paused, in backoff or needs configuration (or is broken).
TrackLyrics stateWithoutRun(
  List<LyricsSource> open,
  int asked,
  Map<String, SourceBackoff> backoff,
  DateTime now,
) {
  final pausedEnds = [
    for (final s in open)
      if (s.problem == SourceProblem.paused && s.pausedUntil != null)
        s.pausedUntil!,
  ];
  if (pausedEnds.length == open.length) {
    return LyricsLookupPaused(_earliest(pausedEnds)!);
  }
  final counts = {for (final r in LookupFailReason.values) r: 0};
  final ends = <DateTime>[];
  for (final s in open) {
    final b = backoff[s.id];
    final LookupFailReason reason;
    switch (s.problem) {
      case SourceProblem.needsConfig:
        reason = LookupFailReason.needsConfig;
      case SourceProblem.broken:
        reason = LookupFailReason.noAnswer;
      case SourceProblem.paused:
        reason = LookupFailReason.network;
        if (s.pausedUntil != null) ends.add(s.pausedUntil!);
      case null:
        reason = b != null && !b.network
            ? LookupFailReason.noAnswer
            : LookupFailReason.network;
        if (b != null) ends.add(b.until);
    }
    counts[reason] = counts[reason]! + 1;
  }
  // The most frequent reason; a tie goes to the network (listed first).
  var reason = LookupFailReason.network;
  for (final r in LookupFailReason.values) {
    if (counts[r]! > counts[reason]!) reason = r;
  }
  return LyricsLookupFailed(
    reason: reason,
    asked: asked,
    retryAt: _earliest(ends),
  );
}

DateTime? _earliest(List<DateTime> times) {
  DateTime? best;
  for (final t in times) {
    if (best == null || t.isBefore(best)) best = t;
  }
  return best;
}
