import 'lyrics_match.dart';

/// How far one source's part of a manual search has come.
enum SourceSearchPhase { loading, results, empty, failed, needsConfig, paused }

/// Why a source's part failed, for the picker's wording.
enum SourceSearchFailure { network, server, rateLimited, invalid }

/// One source's part of a manual search: its results ranked, with the verdict
/// of the gate for the song (Δ duration, rejected flag).
class SourceSearch {
  const SourceSearch(
    this.phase, {
    this.matches = const [],
    this.failure,
    this.until,
  });

  static const loading = SourceSearch(SourceSearchPhase.loading);

  final SourceSearchPhase phase;
  final List<LyricsMatch> matches;
  final SourceSearchFailure? failure;

  /// End of the pause for [SourceSearchPhase.paused].
  final DateTime? until;
}

/// The fetch of one result's lyrics (a result the search answered without
/// them). A finished fetch is not listed: the lyrics are in the result.
enum BodyFetchPhase { loading, failed, missing }

class BodyFetch {
  const BodyFetch(this.phase, {this.failure});

  final BodyFetchPhase phase;
  final SourceSearchFailure? failure;
}

typedef ResultRef = ({String providerId, String remoteId});

/// The state of the manual search of one track.
class OnlineSearchState {
  const OnlineSearchState({
    this.text = '',
    this.bySource = const {},
    this.onDemand = const {},
    this.bodyFetches = const {},
  });

  /// The text last searched.
  final String text;

  /// Source id to its part, in the user's order.
  final Map<String, SourceSearch> bySource;

  /// Disabled sources asked on request in this search.
  final Set<String> onDemand;
  final Map<ResultRef, BodyFetch> bodyFetches;

  bool get searching =>
      bySource.values.any((s) => s.phase == SourceSearchPhase.loading);

  OnlineSearchState copyWith({
    String? text,
    Map<String, SourceSearch>? bySource,
    Set<String>? onDemand,
    Map<ResultRef, BodyFetch>? bodyFetches,
  }) => OnlineSearchState(
    text: text ?? this.text,
    bySource: bySource ?? this.bySource,
    onDemand: onDemand ?? this.onDemand,
    bodyFetches: bodyFetches ?? this.bodyFetches,
  );
}
