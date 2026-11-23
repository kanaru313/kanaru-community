import '../../../plugins/data/run/run_cancel.dart';
import '../../domain/online/lookup_target.dart';
import '../../domain/online/candidate_reader.dart' show SearchRead;
import '../../domain/online/lyrics_candidate.dart';
import '../../domain/online/lyrics_match.dart';
import '../../domain/online/lyrics_match_keys.dart';
import '../../domain/online/online_cache_pick.dart';
import 'lyrics_run_client.dart';
import 'source_run.dart';

/// Most `lyrics` calls one source's lookup makes for good matches that came
/// without lyrics.
const maxLookupFetches = 3;

/// How one source's automatic lookup ended.
sealed class SourceLookup {
  const SourceLookup();
}

/// A good match with lyrics (or the instrumental flag).
final class LookupFound extends SourceLookup {
  const LookupFound(this.chosen);

  final LyricsCandidate chosen;
}

/// The source answered and has nothing for the song.
final class LookupMiss extends SourceLookup {
  const LookupMiss();
}

final class LookupSourceFailed extends SourceLookup {
  const LookupSourceFailed(this.kind, {this.retryAfter});

  final SourceFailKind kind;
  final Duration? retryAfter;
}

final class LookupSourceSkipped extends SourceLookup {
  const LookupSourceSkipped(this.reason, {this.until});

  final SourceSkip reason;
  final DateTime? until;
}

/// The caller cancelled; nothing to record.
final class LookupAbandoned extends SourceLookup {
  const LookupAbandoned();
}

/// Looks [target] up at one source: `search` by the tags, the match gate and
/// ranking, then the first good match that carries lyrics, else up to
/// [maxLookupFetches] `lyrics` calls for good matches without. A result the
/// user [rejected] (by id or text) never wins. A failure is returned, never
/// turned into a miss; nothing is written here.
Future<SourceLookup> runOnlineLookup({
  required LyricsRunClient client,
  required String installId,
  required LookupTarget target,
  required RejectedResults rejected,
  RunCancel? cancel,
}) async {
  final query = target.query;
  final searched = await client.searchByTags(
    installId,
    title: query.title,
    artist: primaryArtist(query.artist),
    artists: target.artists,
    album: query.album,
    duration: query.duration,
    cancel: cancel,
  );
  final SearchRead read;
  switch (searched) {
    case SourceOk(:final value):
      read = value;
    case SourceFailed(:final kind, :final retryAfter):
      return LookupSourceFailed(kind, retryAfter: retryAfter);
    case SourceSkipped(:final reason, :final until):
      return LookupSourceSkipped(reason, until: until);
    case SourceAbandoned():
      return const LookupAbandoned();
  }
  final ranked = rankCandidates(
    query,
    read.candidates,
    rejected: rejected.refs,
    rejectedHashes: rejected.hashes,
  );
  var fetches = 0;
  for (final match in ranked) {
    if (!match.goodMatch) continue;
    var candidate = match.candidate;
    if (!candidate.hasBody) {
      if (fetches >= maxLookupFetches) break;
      fetches++;
      final fetched = await client.fetchLyrics(
        installId,
        candidate.remoteId,
        cancel: cancel,
      );
      switch (fetched) {
        case SourceOk(:final value):
          if (value == null) continue;
          candidate = candidate.withBody(value);
          // The fetched text is judged again: it may be a refused one.
          final judged = matchCandidate(
            query,
            candidate,
            rejected: rejected.refs,
            rejectedHashes: rejected.hashes,
          );
          if (!judged.goodMatch) continue;
        case SourceFailed(:final kind, :final retryAfter):
          return LookupSourceFailed(kind, retryAfter: retryAfter);
        case SourceSkipped(:final reason, :final until):
          return LookupSourceSkipped(reason, until: until);
        case SourceAbandoned():
          return const LookupAbandoned();
      }
    }
    return LookupFound(candidate);
  }
  return const LookupMiss();
}
