import 'dart:async';
import 'dart:collection';

/// A waiter of [TranslationGate] was dropped before it sent anything because
/// nobody wants its job any more. Not a failure: nothing was billed.
class TranslationSuperseded implements Exception {
  const TranslationSuperseded();

  @override
  String toString() => 'TranslationSuperseded';
}

/// Lets one translate run at a time go through, app-wide, in the order they
/// asked (no priority). Each waiter says whether it is still wanted; one that
/// is not, at the front of the line, is dropped before it sends. A task that
/// already started is never interrupted by the gate.
class TranslationGate {
  final _waiters = Queue<Completer<void>>();
  bool _busy = false;

  /// Runs waiting for their turn (not the one running).
  int get waiting => _waiters.length;

  /// Waits for the turn, then runs [task]. Throws [TranslationSuperseded]
  /// without running it when [stillWanted] is false at the front of the line.
  Future<T> run<T>(
    bool Function() stillWanted,
    Future<T> Function() task,
  ) async {
    if (_busy) {
      final turn = Completer<void>();
      _waiters.add(turn);
      await turn.future;
    } else {
      _busy = true;
    }
    // The turn is held until the finally block hands it on.
    try {
      if (!stillWanted()) throw const TranslationSuperseded();
      return await task();
    } finally {
      if (_waiters.isEmpty) {
        _busy = false;
      } else {
        _waiters.removeFirst().complete();
      }
    }
  }
}
