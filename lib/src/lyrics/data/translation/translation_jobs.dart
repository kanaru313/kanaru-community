import 'dart:async';

import 'package:logging/logging.dart';

import '../../domain/translation/translation_failure.dart';
import 'plugin_config_epochs.dart';
import 'translate_runner.dart';
import 'translation_cache_store.dart';
import 'translation_gate.dart';
import 'translation_job_types.dart';
import 'translation_job_work.dart';
import 'translation_services.dart';

final _log = Logger('translation_jobs');

/// Owns every translation run of the app: one gate, one run at a time, each
/// finished chunk cached at once. Lives as long as the app, never as long as
/// a view: a chunk that was sent finishes and is cached even when every view
/// has gone.
///
/// Views only [request] and [release]; a job whose views are all gone drops
/// its unsent chunks. A failed job stays failed (no loop that bills again)
/// until [request] with `retry` / `forced`, a newer plugin version, or a save
/// of that plugin's settings.
class TranslationJobs {
  TranslationJobs({
    required TranslateRunner runner,
    required TranslationCacheStore cache,
    required this.services,
    required bool Function(String installId) mayRun,
    required int Function() now,
    required this.onChange,
  }) {
    _work = TranslationJobWork(
      runner: runner,
      cache: cache,
      services: services,
      gate: TranslationGate(),
      now: now,
      mayRun: mayRun,
      alive: () => !_disposed,
    );
  }

  final TranslationServices services;

  /// Called after [statuses] changed.
  final void Function() onChange;
  late final TranslationJobWork _work;

  final _status = <JobKey, JobStatus>{};
  final _active = <JobKey, JobState>{};
  final _failed = <JobKey, JobState>{};

  /// What a forced run finished before it stopped without completing (no
  /// view left, or a failure): a later forced run of the same key, plugin
  /// version and settings sends only the lines still missing. In memory only;
  /// lost when the app is killed.
  ///
  /// At most [_maxForcedPartials] keys are kept; the oldest is dropped first.
  final _forcedPartials = <JobKey, ForcedPartial>{};
  static const _maxForcedPartials = 20;
  late final PluginConfigEpochs _epochs = PluginConfigEpochs(
    services,
    _onConfigSaved,
  );
  final _runs = <Future<void>>{};
  bool _disposed = false;

  /// What every key that is running or failed shows now.
  Map<JobKey, JobStatus> get statuses => Map.unmodifiable(_status);

  /// Asks for the translation of [key] for [watcher] (a view).
  ///
  /// A job that runs or failed is joined, not restarted; [retry] clears a
  /// failure and sends only the missing lines; [forced] ignores the cache and
  /// replaces the row only when complete (a running job ignores it).
  void request(
    JobKey key,
    JobRequest req,
    Object watcher, {
    bool forced = false,
    bool retry = false,
  }) {
    if (_disposed) return;
    final running = _active[key];
    if (running != null) {
      running.watchers.add(watcher);
      return;
    }
    final failed = _failed[key];
    if (failed != null && !forced && !retry) {
      failed.watchers.add(watcher);
      _track(_recheckVersion(failed));
      return;
    }
    _failed.remove(key);
    if (failed != null && retry) {
      // "Thử lại" restarts the failed job in its own mode (a failed forced
      // run stays forced) with all its views.
      failed.watchers.add(watcher);
      _begin(failed.retry(keepFailure: false));
      return;
    }
    _begin(
      JobState(
        key,
        req,
        forced: forced,
        watchers: {...?failed?.watchers, watcher},
      ),
    );
  }

  /// [watcher] no longer wants [key]: when nobody does, the job's unsent
  /// chunks are dropped (the chunk in flight still finishes and is cached).
  void release(JobKey key, Object watcher) {
    _active[key]?.watchers.remove(watcher);
    _failed[key]?.watchers.remove(watcher);
  }

  /// Stops a forced run now: its status goes, the run in flight is cancelled
  /// and nothing is written; the old row stays.
  void cancelForced(JobKey key) {
    final job = _active[key];
    if (job == null || !job.forced) return;
    job.cancelled = true;
    job.cancel?.cancel();
    _active.remove(key);
    _forcedPartials.remove(key);
    _setStatus(key, null);
    _syncConfigWatch(key.installId);
  }

  /// Completes when no job runs. For tests and shutdown.
  Future<void> whenIdle() async {
    while (_runs.isNotEmpty) {
      await Future.wait(_runs.toList());
    }
  }

  void dispose() {
    _disposed = true;
    _epochs.dispose();
    _active.clear();
    _failed.clear();
    _forcedPartials.clear();
    _status.clear();
  }

  void _begin(JobState job) {
    _active[job.key] = job;
    if (job.forced && !job.hasPartial) {
      final kept = _forcedPartials[job.key];
      if (kept != null) job.adoptPartial(kept);
    }
    job.epochAtStart = _epochs.of(job.key.installId);
    if (!job.keepFailure) {
      _setStatus(job.key, JobRunning(0, 0, forced: job.forced));
    }
    _syncConfigWatch(job.key.installId);
    _track(_drive(job));
  }

  Future<void> _drive(JobState job) async {
    JobEnd end;
    try {
      while (true) {
        end = await _work.run(job, (s) {
          if (_isCurrent(job) && !job.keepFailure) _setStatus(job.key, s);
        });
        if (_disposed) return;
        // The plugin's settings were saved while this pass ran: what failed
        // may have used the old ones, so it is tried once more.
        final epoch = _epochs.of(job.key.installId);
        if (end is JobFailedEnd &&
            job.autoRetries < 1 &&
            job.epochAtStart != epoch) {
          job.autoRetries++;
          job.epochAtStart = epoch;
          continue;
        }
        break;
      }
    } on Object catch (e) {
      _log.warning('Translation job crashed: ${e.runtimeType}');
      end = const JobFailedEnd(TranslationFailure.server());
    }
    _finishJob(job, end);
  }

  void _finishJob(JobState job, JobEnd end) {
    if (_disposed || !_isCurrent(job)) return;
    final key = job.key;
    _active.remove(key);
    if (job.forced) {
      if (end is JobFinished || !job.hasPartial) {
        _forcedPartials.remove(key);
      } else {
        _forcedPartials.remove(key);
        _forcedPartials[key] = job.toPartial();
        if (_forcedPartials.length > _maxForcedPartials) {
          _forcedPartials.remove(_forcedPartials.keys.first);
        }
      }
    }
    switch (end) {
      case JobFinished():
        _setStatus(key, null);
      case JobDropped():
        final prior = job.priorFailure;
        if (job.keepFailure && prior != null) {
          job.failure = prior;
          _failed[key] = job;
          _setStatus(key, prior);
        } else {
          _setStatus(key, null);
        }
      case JobFailedEnd(:final failure, :final version):
        final status = JobFailed(failure, version: version, forced: job.forced);
        job.failure = status;
        _failed[key] = job;
        _setStatus(key, status);
    }
    _syncConfigWatch(key.installId);
  }

  /// A newer plugin version than the one that failed gets one more try.
  Future<void> _recheckVersion(JobState failed) async {
    try {
      final snap = await services.snapshot(failed.key.installId);
      if (_disposed ||
          snap == null ||
          !identical(_failed[failed.key], failed) ||
          failed.watchers.isEmpty ||
          snap.version == failed.failure?.version) {
        return;
      }
      _failed.remove(failed.key);
      _begin(failed.retry());
    } on Object catch (e) {
      _log.warning('Translation version check failed: ${e.runtimeType}');
    }
  }

  void _onConfigSaved(String installId) {
    if (_disposed) return;
    final failedJobs = _failed.values
        .where((j) => j.key.installId == installId)
        .toList();
    for (final job in failedJobs) {
      _failed.remove(job.key);
      if (job.watchers.isEmpty) {
        // Nobody looks at it: it tries again when the song is shown.
        _setStatus(job.key, null);
      } else {
        // The failure stays visible until this try answers.
        _begin(job.retry());
      }
    }
    _syncConfigWatch(installId);
  }

  /// Watches a plugin's settings while it has a running or failed job.
  void _syncConfigWatch(String installId) => _epochs.sync(
    installId,
    hasJobs:
        _active.keys.any((k) => k.installId == installId) ||
        _failed.keys.any((k) => k.installId == installId),
  );

  bool _isCurrent(JobState job) => identical(_active[job.key], job);

  void _setStatus(JobKey key, JobStatus? status) {
    if (_disposed) return;
    if (status == null) {
      if (_status.remove(key) == null) return;
    } else {
      if (_status[key] == status) return;
      _status[key] = status;
    }
    onChange();
  }

  void _track(Future<void> run) {
    _runs.add(run);
    unawaited(run.whenComplete(() => _runs.remove(run)));
  }
}
