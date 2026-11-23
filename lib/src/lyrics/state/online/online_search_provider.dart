import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../database/state/database_providers.dart';
import '../../../media/domain/track_id.dart';
import '../../../plugins/data/run/run_cancel.dart';
import '../../data/lyrics_facts_query.dart';
import '../../data/online/online_search.dart';
import '../../data/online/source_run.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../../domain/online/lyrics_match.dart';
import '../../domain/online/lyrics_source.dart';
import '../../domain/online/online_cache_pick.dart';
import '../../domain/online/online_search_state.dart';
import 'lyrics_sources_provider.dart';
import 'online_lookup_providers.dart';

final _log = Logger('online_search');

/// The manual search of the picker for one track. Every enabled source runs
/// at once; a newer search cancels the older one and its late answers are
/// dropped. Disabled sources are asked only on request, and settings stay as
/// they are.
class OnlineSearchNotifier extends Notifier<OnlineSearchState> {
  OnlineSearchNotifier(this.trackId);

  final TrackId trackId;
  int _generation = 0;
  RunCancel _cancel = RunCancel();
  RejectedResults _rejected = const RejectedResults();
  Duration? _duration;

  @override
  OnlineSearchState build() {
    ref.onDispose(() => _cancel.cancel());
    return const OnlineSearchState();
  }

  OnlineSearch get _search => OnlineSearch(ref.read(lyricsRunClientProvider));

  bool _current(int generation) => ref.mounted && generation == _generation;

  /// Searches every enabled source for [text]. A blank text does nothing.
  Future<void> search(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;
    final generation = ++_generation;
    _cancel.cancel();
    final cancel = _cancel = RunCancel();
    // A search by the user lifts the failure pauses of the sources.
    ref.read(onlineBackoffProvider).clear();
    if (!await _sourcesLoaded(generation)) return;
    final sources = [
      for (final s in ref.read(lyricsSourcesProvider))
        if (s.enabled) s,
    ];
    state = OnlineSearchState(
      text: query,
      bySource: {for (final s in sources) s.id: SourceSearch.loading},
    );
    try {
      await _loadContext();
    } on Object catch (e) {
      // Without the rejects and the duration the results are not judged for
      // the song; the search still lists them.
      _log.warning('manual search context failed: ${e.runtimeType}');
      _rejected = const RejectedResults();
      _duration = null;
    }
    if (!_current(generation)) return;
    await _run(query, sources, generation, cancel);
  }

  /// Runs the current text again.
  Future<void> retry() => search(state.text);

  /// Asks the disabled sources [ids] (all of them when null) that this search
  /// has not asked yet or that failed, with the current text.
  Future<void> searchDisabled({Set<String>? ids}) async {
    final generation = _generation;
    final query = state.text;
    if (query.isEmpty || !_current(generation)) return;
    final todo = [
      for (final s in ref.read(lyricsSourcesProvider))
        if (!s.enabled &&
            (ids == null || ids.contains(s.id)) &&
            (state.bySource[s.id] == null ||
                state.bySource[s.id]!.phase == SourceSearchPhase.failed))
          s,
    ];
    if (todo.isEmpty) return;
    state = state.copyWith(
      onDemand: {...state.onDemand, for (final s in todo) s.id},
      bySource: {
        ...state.bySource,
        for (final s in todo) s.id: SourceSearch.loading,
      },
    );
    await _run(query, todo, generation, _cancel);
  }

  /// Asks the source [id] again alone.
  Future<void> retrySource(String id) async {
    final generation = _generation;
    final source = ref
        .read(lyricsSourcesProvider)
        .where((s) => s.id == id)
        .firstOrNull;
    if (source == null || state.text.isEmpty || !_current(generation)) return;
    state = state.copyWith(
      bySource: {...state.bySource, id: SourceSearch.loading},
    );
    await _run(state.text, [source], generation, _cancel);
  }

  Future<void> _run(
    String text,
    List<LyricsSource> sources,
    int generation,
    RunCancel cancel,
  ) => _search.search(
    text: text,
    sources: sources,
    rejected: _rejected,
    trackDuration: _duration,
    cancel: cancel,
    onSource: (id, part) {
      if (!_current(generation)) return;
      state = state.copyWith(bySource: {...state.bySource, id: part});
    },
  );

  /// The lyrics of [candidate]: its own, or a `lyrics` run whose state shows
  /// in [OnlineSearchState.bodyFetches]. Null when there are none or the
  /// fetch failed.
  Future<LyricsBody?> fetchLyrics(LyricsCandidate candidate) async {
    final own = candidate.body;
    if (own != null && own.isUsable) return own;
    final generation = _generation;
    final ref0 = candidate.ref;
    if (state.bodyFetches[ref0]?.phase == BodyFetchPhase.loading) return null;
    _setFetch(ref0, const BodyFetch(BodyFetchPhase.loading));
    final run = await _search.fetchBody(candidate, cancel: _cancel);
    if (!_current(generation)) return null;
    switch (run) {
      case SourceOk(:final value):
        if (value == null) {
          _setFetch(ref0, const BodyFetch(BodyFetchPhase.missing));
          return null;
        }
        _replaceBody(candidate, value);
        _setFetch(ref0, null);
        return value;
      case SourceFailed(:final kind):
        _setFetch(
          ref0,
          BodyFetch(BodyFetchPhase.failed, failure: searchFailureOf(kind)),
        );
      case SourceSkipped():
        _setFetch(
          ref0,
          const BodyFetch(
            BodyFetchPhase.failed,
            failure: SourceSearchFailure.server,
          ),
        );
      case SourceAbandoned():
        _setFetch(ref0, null);
    }
    return null;
  }

  void _setFetch(ResultRef ref0, BodyFetch? fetch) {
    final next = {...state.bodyFetches};
    fetch == null ? next.remove(ref0) : next[ref0] = fetch;
    state = state.copyWith(bodyFetches: next);
  }

  void _replaceBody(LyricsCandidate candidate, LyricsBody body) {
    final part = state.bySource[candidate.providerId];
    if (part == null) return;
    final matches = [
      for (final m in part.matches)
        m.candidate.ref == candidate.ref
            ? LyricsMatch(
                candidate: m.candidate.withBody(body),
                score: m.score,
                delta: m.delta,
                goodMatch: m.metadataGood,
                metadataGood: m.metadataGood,
                rejected: m.rejected,
              )
            : m,
    ];
    state = state.copyWith(
      bySource: {
        ...state.bySource,
        candidate.providerId: SourceSearch(
          part.phase,
          matches: matches,
          failure: part.failure,
          until: part.until,
        ),
      },
    );
  }

  Future<void> _loadContext() async {
    final facts = await watchLyricsFacts(
      ref.read(appDatabaseProvider),
      trackId,
    ).first;
    _duration = facts?.duration;
    final rows = await ref.read(rejectStoreProvider).list(trackId);
    final set = <({String providerId, String remoteId})>{
      for (final r in rows) (providerId: r.providerId, remoteId: r.remoteId),
    };
    _rejected = RejectedResults(
      refs: set,
      hashes: {
        for (final r in rows)
          if (r.contentHash != null) r.contentHash!,
      },
    );
  }

  Future<bool> _sourcesLoaded(int generation) async {
    if (!ref.read(lyricsSourcesLoadedProvider)) {
      final done = Completer<void>();
      final sub = ref.listen(lyricsSourcesLoadedProvider, (_, loaded) {
        if (loaded && !done.isCompleted) done.complete();
      });
      ref.onDispose(() {
        if (!done.isCompleted) done.complete();
      });
      await done.future;
      sub.close();
    }
    return _current(generation);
  }
}

final onlineSearchProvider = NotifierProvider.autoDispose
    .family<OnlineSearchNotifier, OnlineSearchState, TrackId>(
      OnlineSearchNotifier.new,
    );
