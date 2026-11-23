import 'dart:async';

import 'package:logging/logging.dart';

import '../../../media/domain/track_id.dart';
import '../../../plugins/data/run/run_cancel.dart';
import '../../domain/online/lookup_outcome.dart';
import '../../domain/online/lookup_target.dart';
import '../../domain/online/lyrics_source.dart';
import '../../domain/online/online_cache_pick.dart';
import '../../domain/online/online_resolution_skips.dart';
import '../../domain/lyrics_status.dart';
import '../lyrics_parse_jobs.dart';
import 'online_backoff.dart';
import 'online_cache_store.dart';
import '../../domain/online/lyrics_candidate.dart';
import 'online_row_mapper.dart';
import 'store_result.dart';
import 'reject_store.dart';
import 'run_online_lookup.dart';
import 'lyrics_run_client.dart';
import 'source_run.dart';

final _log = Logger('online_lookups');

/// Starts a timer; tests replace it to fire timers by hand.
typedef TimerFactory = Timer Function(Duration after, void Function() run);

Timer _realTimer(Duration after, void Function() run) => Timer(after, run);

/// A watcher's claim on one lookup; [release] when the track is no longer
/// wanted. Releasing twice is harmless.
class LookupWatch {
  LookupWatch._(this._release);

  final void Function() _release;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _release();
  }
}

class _Job {
  _Job(this.target);

  final LookupTarget target;

  /// Tracks that watch the job; their rejects all apply (two tracks of one
  /// key share the lookup and its cache row).
  final tracks = <TrackId, int>{};
  int watchers = 0;
  int epoch = 0;
  RunCancel cancel = RunCancel();
  Timer? start;
  bool running = false;
}

/// Runs the automatic lookups. Owns the jobs, their timers and the cache
/// writes; lives as long as the app and never touches a provider ref, so a
/// late answer cannot write through a disposed one.
///
/// One lookup per cache key: watchers of the same key join it. Sources are
/// asked one at a time in the user's order and the first result wins. When no
/// source gave a result the end is recorded in [outcomes] (never cached) with
/// its retry time. The caller that shows the end owns the wake-up: it watches
/// again at that time (the lookup service keeps no clock of its own, so a
/// retry cannot depend on a job that has already gone).
class OnlineLookups {
  OnlineLookups({
    required this.client,
    required this.cache,
    required this.rejects,
    required this.backoff,
    required this._now,
    required this._sources,
    required this._onOutcomes,
    this.debounce = Duration.zero,
    this.skipRetry = const Duration(seconds: 30),
    this._timer = _realTimer,
    this._parse = runInIsolate,
  });

  final LyricsRunClient client;
  final OnlineCacheStore cache;
  final RejectStore rejects;
  final OnlineBackoff backoff;
  final DateTime Function() _now;
  final List<LyricsSource> Function() _sources;
  final void Function(Map<String, LookupOutcome>) _onOutcomes;
  final TimerFactory _timer;
  final IsolateRunner _parse;

  /// How long a track stays watched before its lookup starts, so skipping
  /// through a queue sends nothing.
  final Duration debounce;

  /// When a source left unasked without a failure (busy, being switched) is
  /// tried again.
  final Duration skipRetry;

  final _jobs = <String, _Job>{};
  final _outcomes = <String, LookupOutcome>{};
  bool _disposed = false;

  /// The recorded ends of lookups by cache key.
  Map<String, LookupOutcome> get outcomes => Map.unmodifiable(_outcomes);

  int get runningJobs => _jobs.values.where((j) => j.running).length;

  /// Starts (or joins) the lookup of [target]. The caller [LookupWatch.release]s
  /// it when the track is no longer playing.
  LookupWatch watch(LookupTarget target) {
    if (_disposed || !target.searchable) return LookupWatch._(() {});
    final key = target.cacheKey;
    final isNew = !_jobs.containsKey(key);
    final job = _jobs.putIfAbsent(key, () => _Job(target));
    job.watchers++;
    job.tracks.update(target.trackId, (n) => n + 1, ifAbsent: () => 1);
    if (isNew) _schedule(key, job, first: true);
    return LookupWatch._(() => _release(key, job, target.trackId));
  }

  /// Drops every recorded end, the retry timers of the watched keys and
  /// restarts the running lookups: the sources, the settings or a plugin's
  /// configuration changed.
  void reset() {
    if (_disposed) return;
    final had = _outcomes.isNotEmpty;
    _outcomes.clear();
    for (final entry in _jobs.entries) {
      final job = entry.value;
      if (job.running) {
        job.epoch++;
        job.cancel.cancel();
        job.cancel = RunCancel();
        _schedule(entry.key, job, first: false);
      } else if (job.start == null) {
        _schedule(entry.key, job, first: false);
      }
    }
    if (had) _publish();
  }

  /// "Thử lại": lifts every backoff, then [reset].
  void retryAll() {
    backoff.clear();
    reset();
  }

  /// Forgets the recorded end of [cacheKey] (a rejected result: the lookup
  /// goes on with the next candidate).
  void forget(String cacheKey) {
    if (_disposed) return;
    if (_outcomes.remove(cacheKey) != null) _publish();
  }

  void dispose() {
    _disposed = true;
    for (final job in _jobs.values) {
      job.start?.cancel();
      job.cancel.cancel();
    }
    _jobs.clear();
    _outcomes.clear();
  }

  void _publish() {
    if (!_disposed) _onOutcomes(Map.unmodifiable(_outcomes));
  }

  void _release(String key, _Job job, TrackId track) {
    if (_disposed || job.watchers == 0) return;
    job.watchers--;
    final left = job.tracks[track]! - 1;
    left == 0 ? job.tracks.remove(track) : job.tracks[track] = left;
    if (job.watchers > 0) return;
    // A rebuild of the watcher releases and watches in one go: the job is
    // only cancelled when nobody came back by the next microtask.
    scheduleMicrotask(() {
      if (_disposed || job.watchers > 0 || _jobs[key] != job) return;
      _jobs.remove(key);
      job.epoch++;
      job.start?.cancel();
      job.cancel.cancel();
    });
  }

  void _schedule(String key, _Job job, {required bool first}) {
    job.start?.cancel();
    final epoch = job.epoch;
    void go() {
      job.start = null;
      unawaited(_run(key, job, epoch));
    }

    job.start = _timer(first ? debounce : Duration.zero, go);
  }

  bool _stale(_Job job, int epoch) =>
      _disposed || job.epoch != epoch || job.watchers == 0;

  Future<void> _run(String key, _Job job, int epoch) async {
    if (_stale(job, epoch)) return;
    job.running = true;
    // A recorded end that is over: this lookup replaces it.
    if (_outcomes.remove(key) != null) _publish();
    try {
      await _lookup(key, job, epoch);
    } on Object catch (e) {
      // A database failure: nothing is cached; the end is recorded as a
      // failure so the track does not spin.
      _log.warning('Online lyrics lookup failed: ${e.runtimeType}');
      if (!_stale(job, epoch)) {
        _record(
          key,
          job,
          LookupFailed(
            reason: LookupFailReason.noAnswer,
            asked: 0,
            retryAt: _now().add(skipRetry),
          ),
        );
      }
    } finally {
      if (job.epoch == epoch) job.running = false;
    }
  }

  Future<void> _lookup(String key, _Job job, int epoch) async {
    final target = job.target;
    final cancel = job.cancel;
    final now = _now();
    final rejected = await _rejectedOf(job);
    final rows = await cache.readFresh(key, now: now.millisecondsSinceEpoch);
    final entries = [for (final r in rows) await entryOfRow(r, _parse)];
    if (_stale(job, epoch)) return;
    // Sources that failed or were skipped in this lookup.
    final transient = <String, SourceBackoff>{};
    final answered = <String>{};
    final all = _sources();
    for (final source in all) {
      if (_stale(job, epoch)) return;
      if (!source.enabled) continue;
      if (isSourceClosed(
        entries,
        source.id,
        _now(),
        target.query.duration,
        rejected,
      )) {
        answered.add(source.id);
        continue;
      }
      if (!source.askable || backoff.of(source.id) != null) continue;
      final result = await runOnlineLookup(
        client: client,
        installId: source.id,
        target: target,
        rejected: rejected,
        cancel: cancel,
      );
      if (_stale(job, epoch)) return;
      switch (result) {
        case LookupAbandoned():
          return;
        case LookupFound(:final chosen):
          final stored = await _storeFound(key, source.id, chosen);
          if (_stale(job, epoch)) return;
          if (stored) {
            // The cache stream shows the result; nothing else to record.
            if (_outcomes.remove(key) != null) _publish();
            return;
          }
          // Not storable (no usable text): a miss that is not cached.
          transient[source.id] = SourceBackoff(
            until: _now().add(skipRetry),
            network: false,
          );
        case LookupMiss():
          // A found row of this source (shared with another track of the key,
          // which may use it) is never replaced by a miss of this track.
          if (!entries.any((e) => e.providerId == source.id && e.found)) {
            await cache.putNotFound(
              key,
              source.id,
              now: _now().millisecondsSinceEpoch,
            );
          }
          answered.add(source.id);
        case LookupSourceFailed(:final kind, :final retryAfter):
          backoff.failed(
            source.id,
            network: kind != SourceFailKind.invalid,
            retryAfter: retryAfter,
          );
        case LookupSourceSkipped(:final reason, :final until):
          switch (reason) {
            case SourceSkip.busy ||
                SourceSkip.pluginChanged ||
                SourceSkip.unavailable:
              transient[source.id] = SourceBackoff(
                until: _now().add(skipRetry),
                network: reason == SourceSkip.busy,
              );
            // The runner knows better than the sources snapshot (a pause or a
            // missing setting began after it): wait for the pause end, or
            // look again later; a configuration change resets sooner.
            case SourceSkip.needsConfig:
              transient[source.id] = SourceBackoff(
                until: _now().add(skipRetry),
                network: false,
              );
            case SourceSkip.paused:
              transient[source.id] = SourceBackoff(
                until: until ?? _now().add(skipRetry),
                network: true,
              );
          }
      }
    }
    if (_stale(job, epoch)) return;
    _record(key, job, _endOf(all, answered, transient));
  }

  LookupOutcome? _endOf(
    List<LyricsSource> all,
    Set<String> answered,
    Map<String, SourceBackoff> transient,
  ) {
    final enabled = [
      for (final s in all)
        if (s.enabled) s,
    ];
    final open = [
      for (final s in enabled)
        if (!answered.contains(s.id)) s,
    ];
    if (open.isEmpty) return null;
    final state = stateWithoutRun(open, enabled.length, {
      ...backoff.snapshot(),
      ...transient,
    }, _now());
    return switch (state) {
      LyricsLookupPaused(:final until) => LookupPaused(until),
      LyricsLookupFailed(:final reason, :final asked, :final retryAt) =>
        LookupFailed(reason: reason, asked: asked, retryAt: retryAt),
      _ => null,
    };
  }

  void _record(String key, _Job job, LookupOutcome? outcome) {
    if (outcome == null) return;
    _outcomes[key] = outcome;
    _publish();
  }

  Future<RejectedResults> _rejectedOf(_Job job) async {
    final refs = <({String providerId, String remoteId})>{};
    final hashes = <String>{};
    for (final track in job.tracks.keys.toList()) {
      final set = RejectedSet.of(await rejects.list(track));
      refs.addAll(set.refs);
      hashes.addAll(set.hashes);
    }
    return RejectedResults(refs: refs, hashes: hashes);
  }

  Future<bool> _storeFound(
    String key,
    String providerId,
    LyricsCandidate chosen,
  ) async {
    final body = chosen.body!;
    final stored = await cache.putFound(
      key,
      providerId,
      remoteId: chosen.remoteId,
      syncedText: body.syncedLrc,
      plainText: body.plain,
      instrumental: body.instrumental,
      remoteDurationMs: chosen.duration?.inMilliseconds,
      now: _now().millisecondsSinceEpoch,
    );
    return stored == StoreResult.stored;
  }
}
