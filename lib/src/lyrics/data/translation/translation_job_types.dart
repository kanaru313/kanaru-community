import '../../../plugins/data/run/run_cancel.dart';
import '../../domain/translation/translate_input.dart';
import '../../domain/translation/translation_failure.dart';
import 'translation_cache_store.dart' show TranslationKey;

/// One translation: the lyrics text (hash), the plugin and the target
/// language.
typedef JobKey = ({String hash, String installId, String target});

/// What a job translates: the unique line texts and the song for context.
class JobRequest {
  const JobRequest({required this.lines, this.song});

  final List<String> lines;
  final SongContext? song;
}

/// What the engine says about a key while it is not just a saved row.
sealed class JobStatus {
  const JobStatus();
}

/// Sending chunks. [total] is 0 until the plugin's limits are known.
final class JobRunning extends JobStatus {
  const JobRunning(this.done, this.total, {this.forced = false});

  final int done;
  final int total;

  /// A forced re-run (the old row stays visible).
  final bool forced;

  @override
  bool operator ==(Object other) =>
      other is JobRunning &&
      other.done == done &&
      other.total == total &&
      other.forced == forced;

  @override
  int get hashCode => Object.hash(done, total, forced);
}

/// The job stopped with [failure]; it stays until a retry, a forced run, a
/// newer plugin version or a settings save of that plugin.
final class JobFailed extends JobStatus {
  const JobFailed(this.failure, {this.version, this.forced = false});

  final TranslationFailure failure;

  /// Plugin version the failure belongs to; null when unknown.
  final int? version;
  final bool forced;

  @override
  bool operator ==(Object other) =>
      other is JobFailed &&
      other.failure == failure &&
      other.version == version &&
      other.forced == forced;

  @override
  int get hashCode => Object.hash(failure, version, forced);
}

/// How one pass of a job ended.
sealed class JobEnd {
  const JobEnd();
}

/// Every line is translated and the row is complete.
final class JobFinished extends JobEnd {
  const JobFinished();
}

/// Nobody wants the job any more (or translation was switched off, or a
/// forced run was cancelled). Chunks already cached stay.
final class JobDropped extends JobEnd {
  const JobDropped();
}

final class JobFailedEnd extends JobEnd {
  const JobFailedEnd(this.failure, {this.version});

  final TranslationFailure failure;
  final int? version;
}

/// The mutable state of one job, owned by the engine.
class JobState {
  JobState(
    this.key,
    this.request, {
    this.forced = false,
    Set<Object>? watchers,
    this.keepFailure = false,
    this.priorFailure,
  }) : watchers = watchers ?? {},
       cancel = forced ? RunCancel() : null;

  final JobKey key;
  final JobRequest request;

  /// Bypasses the cache and replaces the row only when complete.
  final bool forced;

  /// The views that want this job's unsent chunks.
  final Set<Object> watchers;

  /// Only a forced run is ever cancelled while a chunk is running.
  final RunCancel? cancel;

  /// A retry of a failed job: the failure stays visible until it answers.
  final bool keepFailure;
  final JobFailed? priorFailure;

  /// Set when this job ended with a failure.
  JobFailed? failure;
  bool cancelled = false;

  /// The plugin's setting epoch this pass started in.
  int epochAtStart = 0;
  int autoRetries = 0;

  // What is only in memory: lost with the job, never reused across plugin
  // versions.
  final forcedLines = <String, String>{};
  final detected = <String, String?>{};
  int? partialVersion;

  TranslationKey get cacheKey =>
      (contentHash: key.hash, installId: key.installId, targetLang: key.target);

  bool get wanted => watchers.isNotEmpty && !cancelled;

  void dropPartial() {
    forcedLines.clear();
    detected.clear();
    partialVersion = null;
  }

  /// A new pass for the same request after a failure.
  JobState retry() => JobState(
    key,
    request,
    forced: forced,
    watchers: {...watchers},
    keepFailure: true,
    priorFailure: failure,
  );
}
