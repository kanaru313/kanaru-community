import 'dart:async';

import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

/// What a scripted run does: answer from the request and the fetch callback.
typedef EngineScript = Future<EngineResult> Function(
  EngineRequest request,
  EngineFetch fetch,
);

/// A [PluginEngine] that answers from a script and records every call. A run
/// can wait until its job is cancelled ([untilCancelled]).
class FakePluginEngine implements PluginEngine {
  FakePluginEngine([EngineScript? script])
    : script = script ?? ((_, _) async => okResult());

  EngineScript script;
  var resetCalls = 0;
  var beginCalls = 0;
  final cancelled = <int>[];
  final requests = <EngineRequest>[];
  final _cancelWaiters = <int, Completer<void>>{};
  var active = 0;
  final _started = Completer<void>();

  /// Completes when the first run reaches the engine.
  Future<void> get started => _started.future;
  var maxActive = 0;
  final startOrder = <int>[];
  var cancelCalls = 0;
  var resetThrows = false;
  var cancelThrows = false;

  /// Answer of a script that returned [output].
  static EngineResult okResult([String output = '[]']) =>
      EngineResult(status: EngineStatus.ok, outputJson: output);

  /// Completes (as a cancelled run) when [job] is cancelled; at once when it
  /// was cancelled before.
  Future<EngineResult> untilCancelled(int job) async {
    if (!cancelled.contains(job)) {
      await (_cancelWaiters[job] ??= Completer<void>()).future;
    }
    return const EngineResult(status: EngineStatus.cancelled);
  }

  @override
  void reset() {
    resetCalls++;
    if (resetThrows) throw StateError('reset failed');
  }

  @override
  int begin() => ++beginCalls;

  @override
  void cancel(int job) {
    cancelCalls++;
    // Like the runtime: a second cancel of a job does nothing.
    if (cancelled.contains(job)) return;
    cancelled.add(job);
    _cancelWaiters[job]?.complete();
    if (cancelThrows) throw StateError('cancel failed');
  }

  @override
  Future<EngineResult> run(EngineRequest request, EngineFetch fetch) async {
    requests.add(request);
    startOrder.add(request.job);
    active++;
    if (!_started.isCompleted) _started.complete();
    if (active > maxActive) maxActive = active;
    try {
      return await script(request, fetch);
    } finally {
      active--;
    }
  }
}
