import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../media/domain/track_id.dart';
import '../../data/translation/translation_cache_store.dart';
import '../../data/translation/translation_job_types.dart';
import '../../data/translation/translation_jobs.dart';
import '../../domain/translation/translation_failure.dart';
import '../../domain/translation/translation_status.dart';
import '../track_lyrics_providers.dart';
import 'translation_engine_providers.dart';
import 'translation_plan.dart';
import 'translation_settings.dart';
import 'translation_target_provider.dart';
import 'translation_view.dart';

final _log = Logger('translation_view');

/// The translation of one track for the views. It only subscribes: the runs
/// belong to the keep-alive jobs owner, so closing the view drops the unsent
/// chunks of the song but never loses a chunk that was sent.
///
/// It listens (never watches) its inputs, so a change of one never rebuilds
/// it and never lets go of a running job.
class TrackTranslation extends Notifier<TranslationView> {
  TrackTranslation(this.trackId);

  final TrackId trackId;

  late TranslationJobs _engine;
  int _gen = 0;
  Timer? _debounce;
  JobKey? _held;
  TranslationView? _shown;
  StreamSubscription<Object?>? _configSub;
  String? _configFor;

  @override
  TranslationView build() {
    _engine = ref.read(translationJobsProvider.notifier).engine;
    ref.listen(translationOnProvider, (_, _) => unawaited(_recompute()));
    ref.listen(trackLyricsProvider(trackId), (_, _) => unawaited(_recompute()));
    ref.listen(
      effectiveTranslationServiceProvider,
      (_, _) => unawaited(_recompute()),
    );
    ref.listen(
      trackTranslationTargetProvider(trackId),
      (_, _) => unawaited(_recompute()),
    );
    ref.listen(translationTargetProvider, (_, _) => unawaited(_recompute()));
    ref.listen(
      translationAppLanguageProvider,
      (_, _) => unawaited(_recompute()),
    );
    ref.listen(
      lyricsFactsProvider(trackId)
          .select((facts) => (facts.value?.title, facts.value?.artist)),
      (_, _) => unawaited(_recompute()),
    );
    ref.listen(translationJobsProvider, _onJobs);
    final engine = _engine;
    ref.onDispose(() => _close(engine));
    scheduleMicrotask(() {
      if (ref.mounted) unawaited(_recompute());
    });
    return TranslationView.idle;
  }

  /// "Dịch lại": translates again with the chosen service, ignoring the saved
  /// row. The row on screen stays until the new one is complete.
  void retranslate() {
    final plan = readTranslationPlan(ref, trackId);
    final service = plan?.service;
    if (plan == null || service == null) return;
    _debounce?.cancel();
    _debounce = null;
    _hold(plan.keyFor(service));
    _engine.request(plan.keyFor(service), plan.request, this, forced: true);
  }

  /// "Thử lại": clears the failure and sends only the lines still missing.
  void retry() {
    final plan = readTranslationPlan(ref, trackId);
    final service = plan?.service;
    if (plan == null || service == null) {
      unawaited(_recompute());
      return;
    }
    final key = plan.keyFor(service);
    if (_engine.statuses[key] is! JobFailed) {
      unawaited(_recompute());
      return;
    }
    _hold(key);
    _engine.request(key, plan.request, this, retry: true);
  }

  /// Stops a running "Dịch lại"; the old translation stays.
  void cancelRetranslate() {
    final key = _held;
    if (key != null) _engine.cancelForced(key);
  }

  bool _isCurrent(int gen) => ref.mounted && gen == _gen;

  /// Publishes [view]. [settled] marks a finished translation (the one a
  /// forced run keeps on screen); [keepShown] leaves that memory alone (a
  /// forced run's own loading and failure views).
  void _emit(
    TranslationView view, {
    bool settled = false,
    bool keepShown = false,
  }) {
    if (!ref.mounted) return;
    if (settled) {
      _shown = view;
    } else if (!keepShown) {
      _shown = null;
    }
    if (state != view) state = view;
  }

  Future<void> _recompute({bool afterJob = false}) async {
    if (!ref.mounted) return;
    final gen = ++_gen;
    _debounce?.cancel();
    _debounce = null;
    final plan = readTranslationPlan(ref, trackId);
    if (plan == null) {
      _drop();
      _watchConfig(null);
      _emit(TranslationView.idle);
      return;
    }
    try {
      await _resolve(plan, gen, afterJob);
    } on Object catch (e) {
      // A read failure shows as a failure with a retry; it never reads as
      // "no translation" and never turns translation off.
      _log.warning('Translation lookup failed: ${e.runtimeType}');
      if (!_isCurrent(gen)) return;
      _drop();
      _emit(
        const TranslationView(
          status: TranslationStatus.failed(TranslationFailure.server()),
        ),
      );
    }
  }

  Future<void> _resolve(TranslationPlan plan, int gen, bool afterJob) async {
    final cache = ref.read(translationCacheStoreProvider);
    final service = plan.service;
    _watchConfig(service);
    if (service != null) {
      final row = await cache.lookup((
        contentHash: plan.hash,
        installId: service,
        targetLang: plan.target,
      ));
      if (!_isCurrent(gen)) return;
      if (row != null && row.complete) {
        final differ = await _settingsDiffer(service, row);
        if (!_isCurrent(gen)) return;
        final saved = savedTranslationView(
          row,
          service,
          plan.target,
          differ: differ,
        );
        final key = plan.keyFor(service);
        final job = ref.read(translationJobsProvider)[key];
        if (isForcedJob(job)) {
          // "Dịch lại" is under way: it keeps running (a change of an input
          // must not drop it) over the translation on screen.
          _hold(key);
          _shown = saved;
          _emit(jobTranslationView(job, base: saved), keepShown: true);
          _engine.request(key, plan.request, this);
          return;
        }
        _drop();
        _emit(saved, settled: true);
        return;
      }
    }
    final other = await cache.newestOther(
      plan.hash,
      plan.target,
      excluding: service ?? '',
    );
    if (!_isCurrent(gen)) return;
    if (other != null) {
      _drop();
      _emit(
        TranslationView(
          status: TranslationStatus.other(other.key.installId),
          map: other.lines,
          sourceLang: other.sourceLang,
          installId: other.key.installId,
          settingsJson: other.settingsJson,
        ),
        settled: true,
      );
      return;
    }
    if (service == null) {
      _drop();
      _emit(
        const TranslationView(
          status: TranslationStatus.failed(TranslationFailure.noService()),
        ),
      );
      return;
    }
    // A job that ended without a complete row (dropped, switched off) is not
    // started again here: the next change of an input is.
    if (afterJob) {
      _drop();
      _emit(TranslationView.idle);
      return;
    }
    _startJob(plan, service);
  }

  Future<bool> _settingsDiffer(String service, TranslationCacheRow row) async {
    final services = ref.read(translationServicesProvider);
    try {
      final snap = await services.snapshot(service);
      return snap != null && snap.settingsJson != row.settingsJson;
    } on Object catch (e) {
      _log.warning('Translation settings read failed: ${e.runtimeType}');
      return false;
    }
  }

  /// No complete row: show what the engine says and make sure a job exists.
  /// A job that already runs or failed is joined at once; a new one starts
  /// after the debounce.
  void _startJob(TranslationPlan plan, String service) {
    final key = plan.keyFor(service);
    _hold(key);
    final status = ref.read(translationJobsProvider)[key];
    _emitJob(status, key);
    final request = plan.request;
    if (status != null) {
      _engine.request(key, request, this);
      return;
    }
    _debounce = ref.read(translationTimerProvider)(
      ref.read(translationDebounceProvider),
      () {
        _debounce = null;
        if (ref.mounted && _held == key) _engine.request(key, request, this);
      },
    );
  }

  void _onJobs(Map<JobKey, JobStatus>? previous, Map<JobKey, JobStatus> next) {
    final key = _held;
    if (key == null || !ref.mounted) return;
    final before = previous?[key];
    final now = next[key];
    if (before == now) return;
    if (now == null) {
      unawaited(_recompute(afterJob: true));
    } else {
      _emitJob(now, key);
    }
  }

  /// Publishes what the engine says about [key]. A run that failed half way
  /// (not a forced one, which keeps its old row on screen) then adds the
  /// lines its saved chunks hold.
  void _emitJob(JobStatus? status, JobKey key) {
    final forced = isForcedJob(status);
    final view = jobTranslationView(status, base: forced ? _shown : null);
    _emit(view, keepShown: forced);
    if (status is JobFailed && !forced) unawaited(_addPartial(view, key));
  }

  Future<void> _addPartial(TranslationView failed, JobKey key) async {
    final gen = _gen;
    try {
      final row = await ref.read(translationCacheStoreProvider).lookup((
        contentHash: key.hash,
        installId: key.installId,
        targetLang: key.target,
      ));
      if (row == null || row.complete || row.lines.isEmpty) return;
      // Still the same failure of the same input, and nothing newer shown.
      if (!_isCurrent(gen) || _held != key || state != failed) return;
      final total = readTranslationPlan(ref, trackId)?.lines.length ?? 0;
      if (total == 0) return;
      _emit(partialFailureView(failed, row, total));
    } on Object catch (e) {
      // The failure itself stays on screen; only the saved lines are missing.
      _log.warning('Partial translation read failed: ${e.runtimeType}');
    }
  }

  void _hold(JobKey key) {
    if (_held == key) return;
    _release();
    _held = key;
  }

  void _release() {
    final key = _held;
    _held = null;
    if (key != null) _engine.release(key, this);
  }

  /// Nothing to run for this input: let go of the job and the timer.
  void _drop() {
    _debounce?.cancel();
    _debounce = null;
    _release();
  }

  /// Follows the plugin's settings so a save refreshes `settingsDiffer`.
  void _watchConfig(String? service) {
    if (_configFor == service) return;
    unawaited(_configSub?.cancel());
    _configSub = null;
    _configFor = service;
    if (service == null) return;
    var baseline = true;
    _configSub = ref
        .read(translationServicesProvider)
        .configChanges(service)
        .listen(
          (_) {
            if (baseline) {
              baseline = false;
              return;
            }
            unawaited(_recompute());
          },
          onError: (Object e) =>
              _log.warning('Plugin config watch failed: ${e.runtimeType}'),
        );
  }

  void _close(TranslationJobs engine) {
    _gen++;
    _debounce?.cancel();
    _debounce = null;
    unawaited(_configSub?.cancel());
    _configSub = null;
    final key = _held;
    _held = null;
    if (key != null) engine.release(key, this);
  }
}
