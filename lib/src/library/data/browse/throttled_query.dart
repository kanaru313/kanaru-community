import 'dart:async';

import 'package:drift/drift.dart';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../../database/database.dart';

/// Reload interval of the lists while a scan writes.
const browseRefreshInterval = Duration(seconds: 1);

/// Reload interval of the folder tree (heavier to build).
const folderRefreshInterval = Duration(seconds: 3);

/// Longest adaptive wait.
const maxRefreshWait = Duration(seconds: 5);

/// Runs [load] when listened to and again after a write to any of [tables],
/// but never two loads at once and never sooner than [interval] after the
/// previous load finished.
///
/// drift's `.watch()` cancels and restarts a query after every write, so
/// during a scan a whole-library list never emits and the scan slows down.
/// Here a write only marks the result dirty; a running load is never
/// cancelled, so a result always arrives, at most [interval] late.
///
/// A failed load is emitted as an error and later writes still load. While
/// paused nothing loads; resuming after a write loads once. Cancelling stops
/// the timer and drops a result that arrives afterwards. Single-subscription.
///
/// The database runs on a background isolate, so a load no longer blocks
/// frames, but it shares that one serial worker with the scanner's writes:
/// waiting as long as the last load took keeps one query from taking more
/// than about half of the worker during a scan (several lists reload on their
/// own timers, so the total can be higher).
///
/// The wait after a load is `max(interval, its duration)`,
/// at most [maxRefreshWait]. A result [equals] to the one before is not
/// emitted ([equals] defaults to `==`); an error resets that memory, so the
/// same data after a failure is emitted again.
Stream<T> throttledQuery<T>(
  AppDatabase db,
  Set<ResultSetImplementation<dynamic, dynamic>> tables,
  Future<T> Function() load, {
  Duration interval = browseRefreshInterval,
  bool Function(T a, T b)? equals,
}) => throttledReload(
  () => db.tableUpdates(TableUpdateQuery.onAllTables(tables)),
  load,
  interval: interval,
  equals: equals,
);

/// [throttledQuery] over any change signal; [changes] is subscribed on listen.
/// Exposed so tests can drive the state machine without a database.
@visibleForTesting
Stream<T> throttledReload<T>(
  Stream<void> Function() changes,
  Future<T> Function() load, {
  Duration interval = browseRefreshInterval,
  bool Function(T a, T b)? equals,
  DateTime Function() now = DateTime.now,
}) =>
    _ThrottledQuery<T>(changes, load, interval, equals, now).controller.stream;

class _ThrottledQuery<T> {
  _ThrottledQuery(
    this._changes,
    this._load,
    this._interval,
    this._equals,
    this._now,
  ) {
    controller = StreamController<T>(
      onListen: _onListen,
      onPause: () => _paused = true,
      onResume: () {
        _paused = false;
        _schedule();
      },
      onCancel: _onCancel,
    );
  }

  final Stream<void> Function() _changes;
  final Future<T> Function() _load;
  final Duration _interval;
  final bool Function(T a, T b)? _equals;
  final DateTime Function() _now;
  T? _last;
  bool _hasLast = false;
  late final StreamController<T> controller;

  StreamSubscription<void>? _updates;

  /// Runs from the end of a load until the next one may start.
  Timer? _cooldown;
  bool _loading = false;

  /// A table changed since the last load started (true before the first).
  bool _dirty = true;
  bool _paused = false;
  bool _cancelled = false;

  void _onListen() {
    _updates = _changes().listen(
      (_) {
        _dirty = true;
        _schedule();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_cancelled) controller.addError(error, stackTrace);
      },
    );
    _schedule();
  }

  Future<void> _onCancel() async {
    _cancelled = true;
    _cooldown?.cancel();
    _cooldown = null;
    await _updates?.cancel();
  }

  void _schedule() {
    if (_cancelled || _paused || _loading || !_dirty || _cooldown != null) {
      return;
    }
    unawaited(_run());
  }

  Future<void> _run() async {
    _loading = true;
    _dirty = false;
    final started = _now();
    try {
      final result = await _load();
      if (!_cancelled) {
        final same =
            _hasLast &&
            (_equals != null ? _equals(_last as T, result) : _last == result);
        if (!same) controller.add(result);
        _last = result;
        _hasLast = true;
      }
    } catch (error, stackTrace) {
      _hasLast = false;
      _last = null;
      if (!_cancelled) controller.addError(error, stackTrace);
    } finally {
      _loading = false;
    }
    if (_cancelled) return;
    final cost = _now().difference(started);
    var wait = cost > _interval ? cost : _interval;
    if (wait > maxRefreshWait) wait = maxRefreshWait;
    if (wait > Duration.zero) {
      _cooldown = Timer(wait, () {
        _cooldown = null;
        _schedule();
      });
    }
    _schedule();
  }
}
