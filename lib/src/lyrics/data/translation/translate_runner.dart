import '../../../plugins/data/run/plugin_pauses.dart';
import '../../../plugins/data/run/plugin_runner.dart';
import '../../../plugins/data/run/run_cancel.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/domain/run/run_outcome.dart';
import '../../../plugins/domain/run/run_request.dart';
import '../../domain/translation/translate_input.dart';
import '../../domain/translation/translate_output.dart';
import '../../domain/translation/translation_failure.dart';

/// What one `translate` run came to, for the job that sent the chunk.
sealed class ChunkResult {
  const ChunkResult();
}

/// The answer passed the output rules; the job caches it.
final class ChunkDone extends ChunkResult {
  const ChunkDone(this.chunk);

  final TranslateChunk chunk;
}

/// The chunk failed; the job stops with [failure].
final class ChunkFailed extends ChunkResult {
  const ChunkFailed(this.failure);

  final TranslationFailure failure;
}

/// Why a chunk is sent again instead of failing.
enum RequeueReason {
  /// Every runtime slot was taken (the runner's admission should prevent it).
  busy,

  /// The plugin was switched (update, repair, remove) while the chunk ran.
  pluginChanged,
}

/// Nothing usable came back and nothing is wrong: ask again.
final class ChunkRequeue extends ChunkResult {
  const ChunkRequeue(this.reason);

  final RequeueReason reason;
}

/// The caller's own cancel ended the run: no failure, nothing cached.
final class ChunkCancelled extends ChunkResult {
  const ChunkCancelled();
}

const _translateKinds = {PluginKind.translate, PluginKind.aiTranslate};

/// The only code that calls the plugin runner for translation: builds the
/// `translate` request and maps every [RunOutcome] to a [ChunkResult]
/// (PLUG-02 run contract C3, Translation column).
///
/// No `configAppend` is ever sent: the model, style and note are the plugin's
/// own stored settings. Nothing here logs lyric text.
class TranslateRunner {
  TranslateRunner(this._runner, this._pauses, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final PluginRunner _runner;
  final PluginPauses _pauses;
  final DateTime Function() _now;

  /// Translates [lines] (already unique, trimmed) of the song into [to] with
  /// the plugin [installId]. [allLines] are every line of the song, sent as
  /// context. [timeout] is the plugin's own `timeoutSec`. Never throws.
  Future<ChunkResult> runChunk({
    required String installId,
    required List<String> lines,
    required String to,
    required Duration timeout,
    SongContext? song,
    List<String>? allLines,
    RunCancel? cancel,
  }) async {
    final outcome = await _runner.run(
      PluginRunRequest(
        installId: installId,
        script: 'translate',
        input: buildTranslateInput(lines, to, song: song, allLines: allLines),
        timeout: timeout,
        kinds: _translateKinds,
        logInput: false,
      ),
      cancel: cancel,
    );
    return switch (outcome) {
      final RunOk ok => _fromOk(ok, installId, lines, to),
      final RunScriptError e => ChunkFailed(_fromScriptError(e, installId)),
      final RunFailed f => ChunkFailed(switch (f.reason) {
        RunFailReason.timeout => const TranslationFailure.network(),
        RunFailReason.memory ||
        RunFailReason.stack ||
        RunFailReason.outputTooLarge =>
          const TranslationFailure.invalidResponse(),
        RunFailReason.internal => const TranslationFailure.server(),
      }),
      final RunCancelled c => switch (c.reason) {
        RunCancelReason.caller => const ChunkCancelled(),
        RunCancelReason.pluginChanged => const ChunkRequeue(
          RequeueReason.pluginChanged,
        ),
      },
      RunBusy() => const ChunkRequeue(RequeueReason.busy),
      final RunPaused p => ChunkFailed(TranslationFailure.rateLimited(p.until)),
      final RunNeedsConfig n => ChunkFailed(
        TranslationFailure.needsConfig(n.fieldTitles),
      ),
      final RunUnavailable u => ChunkFailed(switch (u.reason) {
        RunUnavailableReason.notInstalled =>
          const TranslationFailure.pluginGone(),
        RunUnavailableReason.packageUnreadable ||
        RunUnavailableReason.noScript => const TranslationFailure.server(),
      }),
    };
  }

  ChunkResult _fromOk(
    RunOk ok,
    String installId,
    List<String> lines,
    String to,
  ) {
    // A failure inside the run (a caught fetch error, a 429) never discards a
    // good answer, but an answer that is empty, rejected or a pure echo of
    // the source with such a failure behind it is that failure.
    final sticky = _stickyFailure(ok, installId);
    switch (readTranslateOutput(ok.outputJson, lines, to: to)) {
      case TranslateRejected(:final reason):
        _runner.reportRejectedOutput(installId, 'translate', reason);
        return ChunkFailed(
          sticky ?? const TranslationFailure.invalidResponse(),
        );
      case final TranslateChunk chunk:
        if (chunk.isEcho && sticky != null) return ChunkFailed(sticky);
        return ChunkDone(chunk);
    }
  }

  /// The failure a `RunOk` carries, or null. `rateLimitSeen` wins; then the
  /// first failing fetch by its kind:
  ///
  /// | fetch failure | translation failure |
  /// |---|---|
  /// | rateLimited | rateLimited |
  /// | network, abandoned | network |
  /// | blockedHost, notConsented, invalidRequest | server (host or plugin setup, a retry does not fix it) |
  /// | invalidResponse | invalidResponse |
  TranslationFailure? _stickyFailure(RunOk ok, String installId) {
    final seen = ok.rateLimitSeen;
    if (seen != null) return _rateLimited(installId, seen);
    final fetch = ok.fetchFailure;
    if (fetch == null) return null;
    return switch (fetch.kind) {
      FetchFailureKind.rateLimited => _rateLimited(installId, fetch.retryAfter),
      FetchFailureKind.network ||
      FetchFailureKind.abandoned => const TranslationFailure.network(),
      FetchFailureKind.blockedHost ||
      FetchFailureKind.notConsented ||
      FetchFailureKind.invalidRequest => const TranslationFailure.server(),
      FetchFailureKind.invalidResponse =>
        const TranslationFailure.invalidResponse(),
    };
  }

  TranslationFailure _fromScriptError(RunScriptError e, String installId) =>
      switch (e.kind) {
        RunErrorKind.rateLimited => _rateLimited(installId, e.retryAfter),
        RunErrorKind.invalidResponse =>
          const TranslationFailure.invalidResponse(),
        RunErrorKind.server => const TranslationFailure.server(),
        RunErrorKind.auth => const TranslationFailure.badKey(),
        RunErrorKind.quota => const TranslationFailure.quota(),
      };

  /// The end of the plugin's pause (the runner starts it before it answers);
  /// when it is already over or was never set, [wait] from now, else the
  /// runner's default pause.
  TranslationFailure _rateLimited(String installId, Duration? wait) =>
      TranslationFailure.rateLimited(
        _pauses.until(installId) ?? _now().add(wait ?? defaultRatePause),
      );
}
