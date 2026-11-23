import 'dart:async';

import 'package:logging/logging.dart';

import '../../domain/net/cancel_token.dart';

final _log = Logger('plugin_run');

/// How long an exclusive lease waits for the runs in flight to end after it
/// cancelled them (the runtime shows a cancel within ~100 ms).
const defaultExclusiveWait = Duration(seconds: 2);

/// A run's shared hold on one plugin. [changed] is cancelled when an
/// exclusive lease starts: the run stops (running) or starts over once the
/// gate reopens (not dispatched yet).
class RunLease {
  RunLease._(this._gate, this.installId);

  final RunGate _gate;
  final String installId;

  /// Cancelled when the plugin is about to be switched or removed.
  final changed = CancelToken();
  bool _released = false;

  /// Gives the hold back (more than once is harmless).
  void release() {
    if (_released) return;
    _released = true;
    _gate._release(this);
  }
}

/// Keeps plugin runs and package switches apart, per install id.
///
/// A run takes a shared lease ([enter]); install-over, update, repair and
/// remove take an exclusive one ([exclusive]): it closes the id (new shared
/// leases wait), cancels the runs in flight, waits for them for at most
/// [exclusiveWait], runs its action, then reopens. Other ids are unaffected.
class RunGate {
  RunGate({this.exclusiveWait = defaultExclusiveWait});

  final Duration exclusiveWait;
  final _shared = <String, Set<RunLease>>{};
  final _closed = <String, int>{};
  final _reopen = <String, List<Completer<void>>>{};
  final _drained = <String, List<Completer<void>>>{};

  /// Whether an exclusive lease holds [installId] now.
  bool isClosed(String installId) => (_closed[installId] ?? 0) > 0;

  /// A shared lease for [installId]; waits while the id is closed. Null when
  /// [cancel] is cancelled first (nothing is held then).
  Future<RunLease?> enter(String installId, {CancelToken? cancel}) async {
    while (isClosed(installId)) {
      if (cancel != null && cancel.isCancelled) return null;
      final wake = Completer<void>();
      (_reopen[installId] ??= []).add(wake);
      final unlisten = cancel?.listen(() {
        if (!wake.isCompleted) wake.complete();
      });
      try {
        await wake.future;
      } finally {
        unlisten?.call();
        _reopen[installId]?.remove(wake);
      }
    }
    if (cancel != null && cancel.isCancelled) return null;
    final lease = RunLease._(this, installId);
    (_shared[installId] ??= {}).add(lease);
    return lease;
  }

  /// Runs [action] while no run of [installId] holds the plugin: closes the
  /// id, cancels the runs in flight, waits for them for [exclusiveWait], then
  /// goes on anyway. Reopens the id when [action] ends, however it ends.
  Future<T> exclusive<T>(String installId, Future<T> Function() action) async {
    _closed[installId] = (_closed[installId] ?? 0) + 1;
    try {
      for (final lease in [...?_shared[installId]]) {
        try {
          lease.changed.cancel();
        } on Object catch (error) {
          // One run's failing listener must not keep the others running.
          _log.warning('A run could not be stopped: ${error.runtimeType}');
        }
      }
      await _waitDrained(installId);
      return await action();
    } finally {
      final left = (_closed[installId] ?? 1) - 1;
      if (left <= 0) {
        _closed.remove(installId);
        for (final wake in [...?_reopen.remove(installId)]) {
          if (!wake.isCompleted) wake.complete();
        }
      } else {
        _closed[installId] = left;
      }
    }
  }

  Future<void> _waitDrained(String installId) async {
    if ((_shared[installId] ?? const {}).isEmpty) return;
    final done = Completer<void>();
    (_drained[installId] ??= []).add(done);
    final timer = Timer(exclusiveWait, () {
      if (!done.isCompleted) done.complete();
    });
    try {
      await done.future;
    } finally {
      timer.cancel();
      _drained[installId]?.remove(done);
      if (_drained[installId]?.isEmpty ?? false) _drained.remove(installId);
    }
  }

  void _release(RunLease lease) {
    final id = lease.installId;
    final held = _shared[id];
    if (held == null) return;
    held.remove(lease);
    if (held.isNotEmpty) return;
    _shared.remove(id);
    for (final done in [...?_drained[id]]) {
      if (!done.isCompleted) done.complete();
    }
  }
}
