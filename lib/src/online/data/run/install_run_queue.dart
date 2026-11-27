import 'dart:async';

import '../../../plugins/domain/net/cancel_token.dart';

/// Runs one body at a time per plugin install. Waiters go first in, first
/// out; a priority waiter goes ahead of every non-priority one (never ahead
/// of the body in flight).
class InstallRunQueue {
  final _lanes = <String, _Lane>{};

  /// True when nothing runs or waits for [installId].
  bool isIdle(String installId) => !_lanes.containsKey(installId);

  /// Runs [body] when the install's turn comes and returns its result, or
  /// null without running it when [cancel] fires (or was fired) while
  /// waiting. A throwing body rethrows to its caller and frees the slot.
  Future<T?> run<T>(
    String installId,
    Future<T> Function() body, {
    bool priority = false,
    CancelToken? cancel,
  }) async {
    if (cancel != null && cancel.isCancelled) return null;
    final lane = _lanes[installId];
    if (lane == null) {
      _lanes[installId] = _Lane();
    } else {
      final waiter = _Waiter(priority);
      lane.add(waiter);
      final stop = cancel?.listen(() {
        if (lane.remove(waiter)) waiter.turn.complete(false);
      });
      final granted = await waiter.turn.future;
      stop?.call();
      if (!granted) return null;
    }
    try {
      return await body();
    } finally {
      _release(installId);
    }
  }

  void _release(String installId) {
    final lane = _lanes[installId]!;
    final next = lane.pop();
    if (next == null) {
      _lanes.remove(installId);
    } else {
      // The slot passes straight to the next waiter.
      next.turn.complete(true);
    }
  }
}

class _Waiter {
  _Waiter(this.priority);

  final bool priority;
  final turn = Completer<bool>();
}

class _Lane {
  final _waiters = <_Waiter>[];

  void add(_Waiter w) {
    if (!w.priority) {
      _waiters.add(w);
      return;
    }
    final at = _waiters.indexWhere((o) => !o.priority);
    _waiters.insert(at < 0 ? _waiters.length : at, w);
  }

  bool remove(_Waiter w) => _waiters.remove(w);

  _Waiter? pop() => _waiters.isEmpty ? null : _waiters.removeAt(0);
}
