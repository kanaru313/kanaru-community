import 'package:logging/logging.dart';

import '../../domain/translation/translation_failure.dart';
import '../../domain/translation/translation_language.dart';
import '../../domain/translation/translation_lines.dart';
import 'translate_runner.dart';
import 'translation_cache_store.dart';
import 'translation_gate.dart';
import 'translation_job_types.dart';
import 'translation_services.dart';

final _log = Logger('translation_job');

/// A chunk whose plugin was switched this many times in a row ends the job:
/// each lost chunk may have been billed.
const _maxPluginSwitches = 3;

/// One pass of a job: send the missing chunks one by one through the gate,
/// cache each answer at once, then complete the row. Never throws.
class TranslationJobWork {
  TranslationJobWork({
    required this.runner,
    required this.cache,
    required this.services,
    required this.gate,
    required this.now,
    required this.mayRun,
    required this.alive,
  });

  final TranslateRunner runner;
  final TranslationCacheStore cache;
  final TranslationServices services;
  final TranslationGate gate;

  /// Milliseconds since the epoch.
  final int Function() now;

  /// Whether translation is on and [installId] is the chosen service.
  final bool Function(String installId) mayRun;

  /// False once the engine is disposed: nothing is written after that.
  final bool Function() alive;

  bool _wanted(JobState job) =>
      alive() && job.wanted && mayRun(job.key.installId);

  /// Runs [job]; [onProgress] gets the running status before each chunk.
  Future<JobEnd> run(JobState job, void Function(JobStatus) onProgress) async {
    var busyRetried = false;
    var switches = 0;
    try {
      while (true) {
        if (!alive()) return const JobDropped();
        final snap = await services.snapshot(job.key.installId);
        if (!alive()) return const JobDropped();
        if (snap == null) {
          return const JobFailedEnd(TranslationFailure.pluginGone());
        }
        final lines = job.request.lines;
        final all = chunkLines(lines, snap.spec);
        if (exceedsTranslationCaps(lines, all)) {
          return JobFailedEnd(
            const TranslationFailure.tooLong(),
            version: snap.version,
          );
        }
        // What an older version left in memory is never reused.
        if (job.partialVersion != null && job.partialVersion != snap.version) {
          job.dropPartial();
        }
        // A read failure is an error of this job (B1), never "no cache".
        final have = job.forced
            ? job.forcedLines
            : (await cache.lookup(job.cacheKey))?.lines ?? const {};
        if (!alive()) return const JobDropped();
        final missing = [
          for (final line in lines)
            if (!have.containsKey(line)) line,
        ];
        if (missing.isEmpty) return await _finish(job, snap);
        if (!_wanted(job)) return const JobDropped();
        final remaining = chunkLines(missing, snap.spec);
        onProgress(
          JobRunning(
            all.length - remaining.length,
            all.length,
            forced: job.forced,
          ),
        );
        final result = await gate.run(
          () => _wanted(job),
          () => _send(job, snap, remaining.first),
        );
        // A sent chunk is cached even when nobody wants the job any more;
        // only a disposed engine (database about to close) skips the write.
        if (!alive()) return const JobDropped();
        switch (result) {
          case ChunkDone(:final chunk):
            busyRetried = false;
            switches = 0;
            job.partialVersion = snap.version;
            job.detected.addAll(chunk.detected);
            final end = await _keep(job, snap, chunk.texts);
            if (end != null) return end;
          case ChunkFailed(:final failure):
            return JobFailedEnd(failure, version: snap.version);
          case ChunkRequeue(:final reason):
            switch (reason) {
              case RequeueReason.busy:
                if (busyRetried) {
                  return JobFailedEnd(
                    const TranslationFailure.server(),
                    version: snap.version,
                  );
                }
                busyRetried = true;
              case RequeueReason.pluginChanged:
                job.dropPartial();
                if (++switches >= _maxPluginSwitches) {
                  return JobFailedEnd(
                    const TranslationFailure.server(),
                    version: snap.version,
                  );
                }
            }
          case ChunkCancelled():
            return const JobDropped();
        }
      }
    } on TranslationSuperseded {
      return const JobDropped();
    } on Object catch (e) {
      // Only the type: the message of a plugin or database error may hold
      // lyric text or settings.
      _log.warning('Translation job failed: ${e.runtimeType}');
      return const JobFailedEnd(TranslationFailure.server());
    }
  }

  /// Runs inside the gate: re-reads the plugin, so a switch since planning
  /// sends nothing, then sends the chunk.
  Future<ChunkResult> _send(
    JobState job,
    ServiceSnapshot planned,
    List<String> chunk,
  ) async {
    final snap = await services.snapshot(job.key.installId);
    if (!_wanted(job)) throw const TranslationSuperseded();
    if (snap == null) {
      return const ChunkFailed(TranslationFailure.pluginGone());
    }
    if (snap.version != planned.version) {
      return const ChunkRequeue(RequeueReason.pluginChanged);
    }
    return runner.runChunk(
      installId: job.key.installId,
      lines: chunk,
      to: job.key.target,
      timeout: Duration(seconds: snap.spec.timeoutSec),
      song: job.request.song,
      allLines: job.request.lines,
      cancel: job.cancel,
    );
  }

  /// Stores a finished chunk: merged into the row at once (a normal run), or
  /// kept in memory until the whole song is done (a forced run).
  Future<JobEnd?> _keep(
    JobState job,
    ServiceSnapshot snap,
    Map<String, String> texts,
  ) async {
    if (job.forced) {
      job.forcedLines.addAll(texts);
      return null;
    }
    final write = await cache.mergeChunk(
      job.cacheKey,
      texts,
      settingsJson: snap.settingsJson,
      now: now(),
    );
    return _failureOf(write, snap);
  }

  /// All lines are there: complete the row (a forced run replaces it).
  Future<JobEnd> _finish(JobState job, ServiceSnapshot snap) async {
    final source = dominantSource(job.detected);
    if (job.forced) {
      if (job.cancelled) return const JobDropped();
      final write = await cache.replace(
        TranslationCacheRow(
          key: job.cacheKey,
          sourceLang: source,
          lines: Map.of(job.forcedLines),
          settingsJson: snap.settingsJson,
          complete: true,
          createdAt: now(),
        ),
      );
      return _failureOf(write, snap) ?? const JobFinished();
    }
    final write = await cache.markComplete(job.cacheKey, sourceLang: source);
    return _failureOf(write, snap) ?? const JobFinished();
  }

  JobEnd? _failureOf(TranslationWrite write, ServiceSnapshot snap) =>
      switch (write) {
        TranslationWrite.stored => null,
        TranslationWrite.tooLarge => JobFailedEnd(
          const TranslationFailure.tooLong(),
          version: snap.version,
        ),
        TranslationWrite.missing || TranslationWrite.failed => JobFailedEnd(
          const TranslationFailure.server(),
          version: snap.version,
        ),
      };
}
