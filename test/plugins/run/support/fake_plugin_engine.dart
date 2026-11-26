import 'dart:async';

import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

/// What a scripted run does: answer from the request and the fetch callback.
typedef EngineScript = Future<EngineResult> Function(
  EngineRequest request,
  EngineFetch fetch,
);

/// One step of a scripted streaming run, played in order.
sealed class StreamStep {
  const StreamStep();

  /// The script emits an event (JSON text).
  const factory StreamStep.event(String json) = _EventStep;

  /// The runtime asks the host a stream call; the reply is recorded.
  const factory StreamStep.call(EngineStreamCall call) = _CallStep;

  /// Time passes (a fake-async friendly delay).
  const factory StreamStep.delay(Duration duration) = _DelayStep;
}

class _EventStep extends StreamStep {
  const _EventStep(this.json);
  final String json;
}

class _CallStep extends StreamStep {
  const _CallStep(this.call);
  final EngineStreamCall call;
}

class _DelayStep extends StreamStep {
  const _DelayStep(this.duration);
  final Duration duration;
}

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

  // Streaming runs: play [streamSteps], then end with [streamResult].
  /// Steps every streaming run plays before it ends.
  List<StreamStep> streamSteps = [];

  /// How a streaming run ends (`EngineStatus.busy` for a busy worker).
  EngineResult streamResult = okResult();

  /// True: after its steps the streaming run waits until its job is
  /// cancelled, then ends cancelled.
  var streamUntilCancelled = false;

  /// True: after its steps the streaming run never completes.
  var streamNeverCompletes = false;

  /// Throws from the engine instead of returning (a broken bridge).
  var streamThrows = false;
  final streamRequests = <EngineRequest>[];
  final streamIdles = <Duration>[];

  /// Every stream call issued and the reply the host gave, in order.
  final streamExchanges = <(EngineStreamCall, EngineStreamReply)>[];

  /// The `onEvent` of the latest streaming run, to fire a late event by hand.
  void Function(String json)? lastOnEvent;

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

  @override
  Future<EngineResult> runStreaming(
    EngineRequest request,
    EngineFetch fetch,
    EngineStream stream, {
    required Duration idle,
    required void Function(String json) onEvent,
  }) async {
    streamRequests.add(request);
    streamIdles.add(idle);
    lastOnEvent = onEvent;
    startOrder.add(request.job);
    active++;
    if (!_started.isCompleted) _started.complete();
    if (active > maxActive) maxActive = active;
    try {
      if (streamThrows) throw StateError('stream failed');
      for (final step in streamSteps) {
        switch (step) {
          case _EventStep(:final json):
            onEvent(json);
          case _CallStep(:final call):
            streamExchanges.add((call, await stream(call)));
          case _DelayStep(:final duration):
            await Future<void>.delayed(duration);
        }
      }
      if (streamNeverCompletes) await Completer<void>().future;
      if (streamUntilCancelled) return await untilCancelled(request.job);
      return streamResult;
    } finally {
      active--;
    }
  }
}
