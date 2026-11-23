import '../../../plugins/data/run/run_cancel.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../../domain/online/lyrics_match.dart';
import '../../domain/online/lyrics_source.dart';
import '../../domain/online/online_cache_pick.dart';
import '../../domain/online/online_search_state.dart';
import 'lyrics_run_client.dart';
import 'source_run.dart';

SourceSearchFailure _failureOf(SourceFailKind kind) => switch (kind) {
  SourceFailKind.network => SourceSearchFailure.network,
  SourceFailKind.server => SourceSearchFailure.server,
  SourceFailKind.rateLimited => SourceSearchFailure.rateLimited,
  SourceFailKind.invalid => SourceSearchFailure.invalid,
};

/// The manual search: the free text goes to every given source at once, each
/// through the runner (which admits four runs at a time and queues the rest,
/// so waiting never counts against a run's time). Nothing here feeds the
/// automatic backoff.
class OnlineSearch {
  OnlineSearch(this._client);

  final LyricsRunClient _client;

  /// Asks every source of [sources] for [text]; [onSource] gets each source's
  /// part as it finishes (not for a run [cancel]led by a newer search). The
  /// future ends when every source has.
  Future<void> search({
    required String text,
    required List<LyricsSource> sources,
    required RejectedResults rejected,
    required Duration? trackDuration,
    required RunCancel cancel,
    required void Function(String id, SourceSearch part) onSource,
  }) => Future.wait([
    for (final source in sources)
      _searchOne(source.id, text, rejected, trackDuration, cancel).then((part) {
        if (part != null) onSource(source.id, part);
      }),
  ]);

  Future<SourceSearch?> _searchOne(
    String id,
    String text,
    RejectedResults rejected,
    Duration? trackDuration,
    RunCancel cancel,
  ) async {
    final run = await _client.searchByText(id, text, cancel: cancel);
    switch (run) {
      case SourceOk(:final value):
        // No title in the query: the manual order, Δ against the song.
        final matches = rankCandidates(
          LyricsQuery(duration: trackDuration),
          value.candidates,
          rejected: rejected.refs,
          rejectedHashes: rejected.hashes,
          keepRejected: true,
        );
        return SourceSearch(
          matches.isEmpty ? SourceSearchPhase.empty : SourceSearchPhase.results,
          matches: matches,
        );
      case SourceFailed(:final kind):
        return SourceSearch(
          SourceSearchPhase.failed,
          failure: _failureOf(kind),
        );
      case SourceSkipped(:final reason, :final until):
        return switch (reason) {
          SourceSkip.needsConfig => const SourceSearch(
            SourceSearchPhase.needsConfig,
          ),
          SourceSkip.paused => SourceSearch(
            SourceSearchPhase.paused,
            until: until,
          ),
          SourceSkip.busy ||
          SourceSkip.pluginChanged ||
          SourceSkip.unavailable => const SourceSearch(
            SourceSearchPhase.failed,
            failure: SourceSearchFailure.server,
          ),
        };
      case SourceAbandoned():
        return null;
    }
  }

  /// The lyrics of [candidate]: its own when it came with them, else a
  /// `lyrics` run.
  Future<SourceRun<LyricsBody?>> fetchBody(
    LyricsCandidate candidate, {
    RunCancel? cancel,
  }) async {
    final own = candidate.body;
    if (own != null && own.isUsable) return SourceOk(own);
    return _client.fetchLyrics(
      candidate.providerId,
      candidate.remoteId,
      cancel: cancel,
    );
  }
}

/// The failure of a [SourceFailed] kind, for the picker.
SourceSearchFailure searchFailureOf(SourceFailKind kind) => _failureOf(kind);
