import 'dart:async';
import 'dart:convert';

import 'package:kanaru/src/plugins/data/run/plugin_runner.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';

/// What a scripted source answers to one run.
typedef FakeScript = FutureOr<RunOutcome> Function(
  PluginRunRequest request,
  RunCancel? cancel,
);

/// A `PluginRunner` whose answers the test scripts per plugin and script.
/// Records every request and every run that was cancelled while running, and
/// can admit only [slots] runs at a time (FIFO) like the real runner. An
/// unscripted plugin answers `RunUnavailable(notInstalled)`.
class FakePluginRunner implements PluginRunner {
  FakePluginRunner({this.slots});

  @override
  Future<void> get lastRejectionLogged => Future.value();

  @override
  Duration get spacing => Duration.zero;

  @override
  Duration get grace => Duration.zero;

  /// Runs admitted at once; null admits every run.
  final int? slots;

  /// Every request, in the order it was asked.
  final calls = <PluginRunRequest>[];

  /// Requests whose run ended because the caller cancelled it.
  final cancelled = <PluginRunRequest>[];

  /// `(installId, script, reason)` of every refused output.
  final rejectedOutputs = <(String, String, String)>[];

  /// The most runs that were admitted at the same time.
  int maxInFlight = 0;
  final _scripts = <String, List<FakeScript>>{};

  static String _key(String installId, String script) => '$installId/$script';

  /// Answers every run of [script] of [installId] with [script]'s result.
  void on(String installId, String script, FakeScript handler) =>
      _scripts[_key(installId, script)] = [handler];

  /// Answers the runs of [script] of [installId] one after the other with
  /// [outcomes]; the last one repeats.
  void answerInOrder(
    String installId,
    String script,
    List<RunOutcome> outcomes,
  ) => _scripts[_key(installId, script)] = [
    for (final o in outcomes) (_, _) => o,
  ];

  /// Answers every run of the script with [outcome].
  void answer(String installId, String script, RunOutcome outcome) =>
      on(installId, script, (_, _) => outcome);

  /// A run that never ends by itself: only the caller's cancel ends it.
  void blockUntilCancelled(String installId, String script) =>
      on(installId, script, (_, _) => Completer<RunOutcome>().future);

  int callsOf(String installId, [String? script]) => calls
      .where(
        (c) =>
            c.installId == installId && (script == null || c.script == script),
      )
      .length;

  @override
  Future<RunOutcome> run(PluginRunRequest request, {RunCancel? cancel}) async {
    calls.add(request);
    if (!await _admit(cancel)) {
      cancelled.add(request);
      return const RunCancelled(RunCancelReason.caller);
    }
    try {
      final handlers = _scripts[_key(request.installId, request.script)];
      if (handlers == null) {
        return const RunUnavailable(RunUnavailableReason.notInstalled);
      }
      final handler = handlers.length == 1
          ? handlers.first
          : handlers.removeAt(0);
      final done = Completer<RunOutcome>();
      final stop = cancel?.listen(() {
        if (!done.isCompleted) {
          cancelled.add(request);
          done.complete(const RunCancelled(RunCancelReason.caller));
        }
      });
      unawaited(
        Future.sync(() => handler(request, cancel)).then((outcome) {
          if (!done.isCompleted) done.complete(outcome);
        }),
      );
      final outcome = await done.future;
      stop?.call();
      return outcome;
    } finally {
      _release();
    }
  }

  int _active = 0;
  final _queue = <Completer<bool>>[];

  void _count() {
    if (_active > maxInFlight) maxInFlight = _active;
  }

  Future<bool> _admit(RunCancel? cancel) async {
    if (cancel != null && cancel.isCancelled) return false;
    final limit = slots;
    if (limit == null || _active < limit) {
      _active++;
      _count();
      return true;
    }
    final turn = Completer<bool>();
    _queue.add(turn);
    final stop = cancel?.listen(() {
      if (_queue.remove(turn)) turn.complete(false);
    });
    final admitted = await turn.future;
    stop?.call();
    return admitted;
  }

  void _release() {
    if (_queue.isEmpty) {
      _active--;
    } else {
      // The slot passes to the next waiter.
      _queue.removeAt(0).complete(true);
    }
  }

  @override
  void reportRejectedOutput(String installId, String script, String reason) =>
      rejectedOutputs.add((installId, script, reason));
}

/// A `search` answer with [items] (maps with `id`, `title`, `artist`, ...).
RunOk searchAnswer(List<Map<String, Object?>> items) =>
    RunOk(jsonEncode(items));

/// A `lyrics` answer: synced or plain text, or `null` for no lyrics.
RunOk lyricsAnswer({String? synced, String? plain, bool instrumental = false}) {
  if (instrumental) return RunOk(jsonEncode({'instrumental': true}));
  final text = synced ?? plain;
  if (text == null) return const RunOk('null');
  return RunOk(
    jsonEncode({'data': text, 'type': synced != null ? 'lrc' : 'txt'}),
  );
}

/// One search item of the song `Song` by `Artist`, 200 s, with the lyrics
/// inline when [lyrics] is given.
Map<String, Object?> searchItem({
  String id = '1',
  String title = 'Song',
  String artist = 'Artist',
  int? durationMs = 200000,
  String? lyrics,
}) => {
  'id': id,
  'title': title,
  'artist': artist,
  'durationMs': ?durationMs,
  'lyrics': ?lyrics,
};
