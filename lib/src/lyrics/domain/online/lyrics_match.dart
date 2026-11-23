import 'lyrics_artist_match.dart';
import 'lyrics_candidate.dart';
import 'lyrics_match_keys.dart';
import 'lyrics_match_similarity.dart';
import 'online_text.dart';

export 'lyrics_artist_match.dart' show isUnknownArtist;
export 'lyrics_match_similarity.dart';
export 'lyrics_rank.dart';

/// Largest difference between the song's and the result's duration,
/// inclusive. Also the "khớp" threshold of the picker.
const maxDurationDelta = Duration(seconds: 3);

/// A candidate with its verdict for one query.
class LyricsMatch {
  const LyricsMatch({
    required this.candidate,
    required this.score,
    required this.delta,
    required this.goodMatch,
    required this.metadataGood,
    this.rejected = false,
  });

  final LyricsCandidate candidate;

  /// Title similarity, 0 to 1.
  final double score;

  /// Absolute duration difference; null when either side has no duration.
  final Duration? delta;

  /// Title, artist and duration pass and the result is not rejected,
  /// whatever its body.
  final bool metadataGood;

  /// [metadataGood] and, when the result came with a body, a body with
  /// lyrics or the instrumental flag. A result with no body at all (a
  /// two-step source answers the search without lyrics) is judged by its
  /// metadata only; its body is fetched next and checked then.
  final bool goodMatch;

  /// The user marked this result "Không đúng bài" for the song. Only a search
  /// that keeps rejected results ever shows such a match.
  final bool rejected;
}

/// Whether [query] has what an automatic search needs: a title, a real artist
/// (not "Unknown Artist") and a duration above zero. Without them only the
/// manual search runs.
bool isAutoSearchable(LyricsQuery query) {
  final title = query.title?.trim() ?? '';
  final artist = primaryArtist(query.artist)?.trim() ?? '';
  final duration = query.duration;
  if (title.isEmpty || artist.isEmpty) return false;
  if (duration == null || duration <= Duration.zero) return false;
  return !isUnknownArtist(artist);
}

/// Judges [candidate] against [query]. The gate needs: duration within
/// [maxDurationDelta] (skipped when [query] has no duration, as in a manual
/// search), title equal, joined-equal or [titleSimilarityMin] similar, the
/// artist rule, and lyrics or the instrumental flag (a result with no body at
/// all passes on its metadata).
///
/// A candidate without a duration fails a song that has one, except when its
/// title and artist match exactly after normalisation (similarity 1).
///
/// A result in [rejected], or whose text hashes into [rejectedHashes], never
/// matches.
LyricsMatch matchCandidate(
  LyricsQuery query,
  LyricsCandidate candidate, {
  Set<({String providerId, String remoteId})> rejected = const {},
  Set<String> rejectedHashes = const {},
}) {
  final wanted = query.duration;
  final has = candidate.duration;
  final delta = wanted == null || has == null
      ? null
      : Duration(microseconds: (wanted - has).inMicroseconds.abs());
  final title = query.title?.trim() ?? '';
  var score = 0.0;
  var titleOk = false;
  if (title.isNotEmpty) {
    final mine = normalizeTitle(title);
    final theirs = normalizeTitle(candidate.title);
    score = similarity(mine, theirs);
    titleOk =
        mine.isNotEmpty &&
        theirs.isNotEmpty &&
        (atLeast(score, titleSimilarityMin) ||
            joinedTitle(mine) == joinedTitle(theirs));
  }
  final artistOk = artistMatches(query.artist, candidate.artist);
  final bool durationOk;
  if (wanted == null) {
    durationOk = true;
  } else if (delta != null) {
    durationOk = delta <= maxDurationDelta;
  } else {
    // No duration to compare: only an exact title and artist is believed.
    durationOk =
        titleOk &&
        normalizeTitle(title) == normalizeTitle(candidate.title) &&
        artistMatchesExactly(query.artist, candidate.artist);
  }
  final isRejected = _isRejected(candidate, rejected, rejectedHashes);
  final bodyOk = candidate.body == null || candidate.hasBody;
  final metadataGood = !isRejected && durationOk && titleOk && artistOk;
  return LyricsMatch(
    candidate: candidate,
    score: score,
    delta: delta,
    rejected: isRejected,
    metadataGood: metadataGood,
    goodMatch: metadataGood && bodyOk,
  );
}

bool _isRejected(
  LyricsCandidate candidate,
  Set<({String providerId, String remoteId})> rejected,
  Set<String> rejectedHashes,
) {
  if (rejected.contains(candidate.ref)) return true;
  if (rejectedHashes.isEmpty) return false;
  final hash = candidateContentHash(candidate);
  return hash != null && rejectedHashes.contains(hash);
}
