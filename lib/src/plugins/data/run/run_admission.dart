import 'dart:async';
import 'dart:collection';

import '../../domain/net/cancel_token.dart';

/// Runtime workers: the most jobs the Rust side executes at once.
const runtimeWorkerCount = 4;

/// One taken slot; [release] gives it back (more than once is harmless).
class RunSlot {
  RunSlot._(this._admission);

  final RunAdmission _admission;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _admission._release();
  }
}

/// The admission queue of plugin runs: [slots] at once, first come first
/// served. A run takes a slot just before it starts the engine and gives it
/// back when the engine returns, so nothing queues inside the runtime and
/// queue time never counts against a run's own time limits.
class RunAdmission {
  RunAdmission({this.slots = runtimeWorkerCount});

  final int slots;
  var _inUse = 0;
  final _waiting = Queue<_Waiter>();

  /// Slots taken now.
  int get inUse => _inUse;

  /// Runs waiting for a slot.
  int get waiting => _waiting.length;

  /// A slot, or null when [abort] is cancelled first (nothing is held then).
  /// A slot freed while others wait goes to the oldest waiter directly, so
  /// a newcomer cannot overtake it.
  Future<RunSlot?> acquire({CancelToken? abort}) async {
    if (abort != null && abort.isCancelled) return null;
    if (_inUse < slots && _waiting.isEmpty) {
      _inUse++;
      return RunSlot._(this);
    }
    final waiter = _Waiter();
    _waiting.add(waiter);
    final unlisten = abort?.listen(() {
      if (_waiting.remove(waiter)) waiter.complete(null);
    });
    try {
      return await waiter.future;
    } finally {
      unlisten?.call();
    }
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      // The slot stays counted: it moves to the next waiter.
      _waiting.removeFirst().complete(RunSlot._(this));
      return;
    }
    _inUse--;
  }
}

/// One run waiting for a slot.
typedef _Waiter = Completer<RunSlot?>;
