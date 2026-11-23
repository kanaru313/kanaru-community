import 'lyrics_candidate.dart';
import 'lyrics_match.dart';

int _bodyRank(LyricsBody? body) {
  if (body?.syncedLrc != null) return 0;
  if (body?.plain != null) return 1;
  return body != null && body.instrumental ? 2 : 3;
}

int _byDelta(Duration? a, Duration? b) {
  if (a == b) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Judges every candidate not in [rejected] (by id or text, [rejectedHashes])
/// and orders them.
///
/// Automatic order (the query has a title): good matches first, then
/// synced < plain < instrumental < no body, then a candidate with a duration
/// before one without, smaller difference, higher title similarity, and the
/// given order for ties.
///
/// Manual order (no title in the query): body rank, then the difference
/// against the song's duration when known, then the given order; the picker
/// shows what is left.
///
/// With [keepRejected] (the manual search) rejected results stay in the list,
/// flagged and after every other one; automatic lookups leave it off.
List<LyricsMatch> rankCandidates(
  LyricsQuery query,
  Iterable<LyricsCandidate> candidates, {
  Set<({String providerId, String remoteId})> rejected = const {},
  Set<String> rejectedHashes = const {},
  bool keepRejected = false,
}) {
  final manual = (query.title?.trim() ?? '').isEmpty;
  final indexed = <(int, LyricsMatch)>[
    for (final (i, c) in candidates.indexed)
      (
        i,
        matchCandidate(
          query,
          c,
          rejected: rejected,
          rejectedHashes: rejectedHashes,
        ),
      ),
  ];
  if (!keepRejected) indexed.removeWhere((e) => e.$2.rejected);
  indexed.sort((a, b) {
    final x = a.$2;
    final y = b.$2;
    if (x.rejected != y.rejected) return x.rejected ? 1 : -1;
    if (!manual && x.goodMatch != y.goodMatch) return x.goodMatch ? -1 : 1;
    // A result without a duration ranks after every one with a duration.
    if (!manual &&
        (x.candidate.duration == null) != (y.candidate.duration == null)) {
      return x.candidate.duration == null ? 1 : -1;
    }
    final body = _bodyRank(x.candidate.body)
        .compareTo(_bodyRank(y.candidate.body));
    if (body != 0) return body;
    final delta = _byDelta(x.delta, y.delta);
    if (delta != 0) return delta;
    if (!manual) {
      final score = y.score.compareTo(x.score);
      if (score != 0) return score;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final (_, m) in indexed) m];
}
