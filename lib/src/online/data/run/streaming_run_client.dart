import '../../../plugins/data/run/plugin_runner.dart';
import '../../../plugins/data/run/run_cancel.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/domain/run/run_outcome.dart';
import '../../../plugins/domain/run/run_request.dart';
import '../../domain/contract/contract_limits.dart';
import '../../domain/contract/online_output_exception.dart';
import '../../domain/contract/online_page.dart';
import '../../domain/contract/stream_answer.dart';
import '../../domain/failure/online_failure.dart';
import '../../domain/failure/run_outcome_failures.dart';
import '../contract/autocomplete_reader.dart';
import '../contract/page_reader.dart';
import '../contract/stream_reader.dart';
import 'install_run_queue.dart';
import 'isolate_runner.dart';

const autocompleteTimeout = Duration(seconds: 5);
const pageRunTimeout = Duration(seconds: 20);
const streamRunTimeout = Duration(seconds: 20);

/// How long a `stream` call waits for its turn behind a run in flight.
const streamQueueWait = Duration(seconds: 5);

/// The only way the online module runs a streaming plugin's scripts.
///
/// `search` and `stream` run one at a time per install (a `stream` goes
/// ahead of waiting searches). `autocomplete` runs outside that queue with
/// empty storage that is never saved, so a whole-map storage write-back
/// cannot race a search, and a newer autocomplete cancels the older one.
/// Inputs are never written to the run log: they hold what the user typed.
class StreamingRunClient {
  StreamingRunClient(
    this._runner, {
    IsolateRunner run = runInIsolate,
    InstallRunQueue? queue,
    Duration streamWait = streamQueueWait,
  }) : _isolate = run,
       _queueWait = streamWait,
       _queue = queue ?? InstallRunQueue();

  final PluginRunner _runner;
  final IsolateRunner _isolate;
  final InstallRunQueue _queue;
  final Duration _queueWait;
  final _autocompletes = <String, RunCancel>{};

  Future<OnlineResult<PageRead>> search(
    String installId,
    String query, {
    String? next,
    String? filter,
    RunCancel? cancel,
  }) async {
    final text = _checkedQuery(query);
    final outcome = await _queued(
      installId,
      PluginRunRequest(
        installId: installId,
        script: 'search',
        input: {'query': text, 'next': ?next, 'filter': ?filter},
        timeout: pageRunTimeout,
        kinds: const {PluginKind.streaming},
        logInput: false,
      ),
      priority: false,
      cancel: cancel,
    );
    if (outcome == null) return const OnlineAbandoned();
    return _finish<PageRead>(
      installId,
      'search',
      outcome,
      OnlineScriptRole.page,
      (json) => _readSearch(_isolate, json, next),
      isEmpty: (read) => read.page.sections.every((s) => s.cards.isEmpty),
      notes: (read) => read.rejectionSummary,
    );
  }

  /// A playable answer, or [StreamUnsupported] (returned as `OnlineOk`: the
  /// caller maps it to the item-level cause and keeps the media type).
  Future<OnlineResult<StreamRead>> stream(
    String installId,
    String itemId, {
    bool fresh = false,
    RunCancel? cancel,
  }) async {
    if (itemId.isEmpty) throw ArgumentError('itemId must not be empty');
    final RunOutcome? outcome;
    try {
      outcome = await _queued(
        installId,
        PluginRunRequest(
          installId: installId,
          script: 'stream',
          input: {'id': itemId, if (fresh) 'fresh': true},
          timeout: streamRunTimeout,
          kinds: const {PluginKind.streaming},
          logInput: false,
        ),
        priority: true,
        cancel: cancel,
        maxWait: _queueWait,
      );
    } on QueueWaitExceeded {
      return const OnlineFailed(OnlineFailure(OnlineFailureKind.busy));
    }
    if (outcome == null) return const OnlineAbandoned();
    return _finish<StreamRead>(
      installId,
      'stream',
      outcome,
      OnlineScriptRole.stream,
      (json) => _readStream(_isolate, json),
    );
  }

  Future<OnlineResult<List<String>>> autocomplete(
    String installId,
    String query,
  ) async {
    final text = query.trim();
    if (text.isEmpty) return const OnlineOk(<String>[]);
    if (text.runes.length > maxQueryRunes) {
      throw ArgumentError('query must be at most $maxQueryRunes code points');
    }
    _autocompletes.remove(installId)?.cancel();
    final cancel = RunCancel();
    _autocompletes[installId] = cancel;
    try {
      final outcome = await _runner.run(
        PluginRunRequest(
          installId: installId,
          script: 'autocomplete',
          input: {'query': text},
          timeout: autocompleteTimeout,
          kinds: const {PluginKind.streaming},
          logInput: false,
          persistStorage: false,
        ),
        cancel: cancel,
      );
      if (cancel.isCancelled) return const OnlineAbandoned();
      return await _finish<List<String>>(
        installId,
        'autocomplete',
        outcome,
        OnlineScriptRole.page,
        (json) => Future.value(readAutocompleteOutput(json)),
        isEmpty: (list) => list.isEmpty,
        // A broken autocomplete only shows no suggestions: never reported.
        report: false,
      );
    } finally {
      if (identical(_autocompletes[installId], cancel)) {
        _autocompletes.remove(installId);
      }
    }
  }

  /// Cancels the install's running autocomplete, if any (its call returns
  /// `OnlineAbandoned`).
  void cancelAutocomplete(String installId) =>
      _autocompletes.remove(installId)?.cancel();

  Future<RunOutcome?> _queued(
    String installId,
    PluginRunRequest request, {
    required bool priority,
    RunCancel? cancel,
    Duration? maxWait,
  }) => _queue.run<RunOutcome>(
    installId,
    () => _runner.run(request, cancel: cancel),
    priority: priority,
    cancel: cancel,
    maxWait: maxWait,
  );

  Future<OnlineResult<T>> _finish<T>(
    String installId,
    String script,
    RunOutcome outcome,
    OnlineScriptRole role,
    Future<T> Function(String json) read, {
    bool Function(T value)? isEmpty,
    String? Function(T value)? notes,
    bool report = true,
  }) async {
    switch (decideOnlineRun(outcome, role: role)) {
      case OnlineRunAbandoned():
        return OnlineAbandoned<T>();
      case OnlineRunFailed(:final failure):
        return OnlineFailed<T>(failure);
      case OnlineRunData(:final json, :final sticky):
        final T value;
        try {
          value = await read(json);
        } on OnlineOutputException catch (e) {
          if (report) _runner.reportRejectedOutput(installId, script, e.reason);
          return const OnlineFailed(
            OnlineFailure(OnlineFailureKind.invalidOutput),
          );
        }
        final summary = notes?.call(value);
        if (report && summary != null) {
          _runner.reportRejectedOutput(installId, script, summary);
        }
        // An empty answer with a failure inside the run is a failure, never
        // "no results"; a non-empty one counts.
        if (sticky != null && (isEmpty?.call(value) ?? false)) {
          return OnlineFailed<T>(sticky);
        }
        return OnlineOk<T>(value);
    }
  }
}

String _checkedQuery(String query) {
  final text = query.trim();
  final length = text.runes.length;
  if (length < 1 || length > maxQueryRunes) {
    throw ArgumentError('query must be 1-$maxQueryRunes code points');
  }
  return text;
}

// These take only plain values, so what reaches the isolate is the output
// text and the cursor: a closure made inside a client method would carry the
// whole client (database, ports), which an isolate cannot receive.
Future<PageRead> _readSearch(IsolateRunner run, String json, String? next) =>
    json.length > onlineIsolateThreshold
    ? run(() => readSearchOutput(json, inputNext: next))
    : Future.value(readSearchOutput(json, inputNext: next));

Future<StreamRead> _readStream(IsolateRunner run, String json) =>
    json.length > onlineIsolateThreshold
    ? run(() => readStreamOutput(json))
    : Future.value(readStreamOutput(json));
