import '../../../plugins/data/run/plugin_runner.dart';
import '../../../plugins/data/run/run_cancel.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/domain/run/run_request.dart';
import '../../domain/online/candidate_reader.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../lyrics_parse_jobs.dart';
import 'source_run.dart';

/// Base time limit of one lyrics script run.
const lyricsRunTimeout = Duration(seconds: 30);

/// Runs the `search` and `lyrics` scripts of lyrics plugins and reads their
/// output. Only tags are ever sent: never a path, a uid or a file name.
class LyricsRunClient {
  LyricsRunClient(this._runner, {this._run = runInIsolate});

  final PluginRunner _runner;
  final IsolateRunner _run;

  /// Automatic lookup: `search` by the song's tags (a missing tag is null).
  Future<SourceRun<SearchRead>> searchByTags(
    String installId, {
    required String? title,
    required String? artist,
    required List<String> artists,
    required String? album,
    required Duration? duration,
    RunCancel? cancel,
  }) => _search(installId, {
    'title': title,
    'artist': artist,
    'artists': artists.isEmpty ? null : artists,
    'album': album,
    'durationMs': duration?.inMilliseconds,
  }, cancel);

  /// Manual search: the free text only.
  Future<SourceRun<SearchRead>> searchByText(
    String installId,
    String text, {
    RunCancel? cancel,
  }) => _search(installId, {'text': text}, cancel);

  /// The lyrics of the result [remoteId]; null data is "no lyrics".
  Future<SourceRun<LyricsBody?>> fetchLyrics(
    String installId,
    String remoteId, {
    RunCancel? cancel,
  }) => _call<LyricsBody?>(
    installId,
    'lyrics',
    lyricsScriptInput(remoteId),
    cancel,
    (json) => json.length > lyricsIsolateThreshold
        ? _run(() => readLyricsOutput(json))
        : Future.value(readLyricsOutput(json)),
    (body) => body == null,
  );

  Future<SourceRun<SearchRead>> _search(
    String installId,
    Map<String, Object?> input,
    RunCancel? cancel,
  ) => _call<SearchRead>(
    installId,
    'search',
    input,
    cancel,
    (json) => json.length > lyricsIsolateThreshold
        ? _run(() => readSearchOutput(json, providerId: installId))
        : Future.value(readSearchOutput(json, providerId: installId)),
    (read) => read.candidates.isEmpty,
  );

  Future<SourceRun<T>> _call<T>(
    String installId,
    String script,
    Map<String, Object?> input,
    RunCancel? cancel,
    Future<T> Function(String json) read,
    bool Function(T value) isEmpty,
  ) async {
    final outcome = await _runner.run(
      PluginRunRequest(
        installId: installId,
        script: script,
        input: input,
        timeout: lyricsRunTimeout,
        kinds: const {PluginKind.lyrics},
      ),
      cancel: cancel,
    );
    switch (decideRun(outcome)) {
      case DecisionAbandoned():
        return const SourceAbandoned();
      case DecisionSkipped(:final reason, :final until):
        return SourceSkipped(reason, until: until);
      case DecisionFailed(:final failure):
        return SourceFailed(failure.kind, retryAfter: failure.retryAfter);
      case DecisionData(:final json, :final sticky):
        final T value;
        try {
          value = await read(json);
        } on PluginOutputException catch (e) {
          _runner.reportRejectedOutput(installId, script, e.reason);
          return const SourceFailed(SourceFailKind.invalid);
        }
        if (value is SearchRead) {
          final summary = value.rejectionSummary;
          if (summary != null) {
            _runner.reportRejectedOutput(installId, script, summary);
          }
        }
        // An empty answer with a failure inside the run is a failure, never
        // "no lyrics"; a non-empty one counts.
        if (sticky != null && isEmpty(value)) {
          return SourceFailed(sticky.kind, retryAfter: sticky.retryAfter);
        }
        return SourceOk(value);
    }
  }
}

/// The input of the `lyrics` script for a result id.
///
/// The lyrics plugins of the catalogue read `execute(id)` with `id` the bare
/// id string, but a run request carries its input as a JSON object
/// (`PluginRunRequest.input` is a `Map`), which cannot hold a bare string. Until
/// the runner takes any JSON value (tracked outside this change) the id travels
/// as `{id}`, and plugins that need the `lyrics` script do not get their id.
/// This is the one place that knows the shape.
Map<String, Object?> lyricsScriptInput(String remoteId) => {'id': remoteId};
