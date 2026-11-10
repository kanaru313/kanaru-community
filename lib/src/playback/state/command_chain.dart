import 'dart:async';

import 'package:logging/logging.dart';

final _log = Logger('SerialChain');

/// Runs tasks one after another, in call order. An error fails only its own
/// task. After the last queued task, [onDrain] runs once (as the next task),
/// so a burst of commands is followed by a single reconcile.
///
/// A task must not call [run] on its own chain and wait for it: that would
/// never finish. Debug builds assert it.
class SerialChain {
  SerialChain({this.onDrain});

  /// Runs after the queue becomes empty.
  Future<void> Function()? onDrain;

  Future<void> _tail = Future.value();
  int _pending = 0;
  bool _closed = false;

  Future<T> run<T>(Future<T> Function() task) {
    assert(
      Zone.current[this] != true,
      'a task of the chain must not run another task of it',
    );
    if (_closed) return Future.error(StateError('the command chain is closed'));
    _pending++;
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await runZoned(task, zoneValues: {this: true}));
      } on Object catch (e, st) {
        result.completeError(e, st);
      }
      _pending--;
      final drain = onDrain;
      if (_pending == 0 && drain != null && !_closed) {
        try {
          await runZoned(drain, zoneValues: {this: true});
        } on Object catch (e, st) {
          _log.warning('drain failed: $e', e, st);
        }
      }
    });
    return result.future;
  }

  /// Completes when every queued task and the drain after it have finished.
  Future<void> whenIdle() async {
    Future<void> seen;
    do {
      seen = _tail;
      await seen;
    } while (!identical(seen, _tail));
  }

  /// No new tasks; queued ones still run. Completes when they are done.
  Future<void> close() {
    _closed = true;
    return _tail;
  }
}
