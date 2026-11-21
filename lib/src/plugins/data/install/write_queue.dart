import 'dart:async';

import 'package:logging/logging.dart';

final _log = Logger('plugin_queue');

/// The one place that mutates plugin state: install, update, repair, remove,
/// config writes, repository add / remove and the refresh writes all run here,
/// strictly one after another, so a sweep never sees a half-installed folder
/// and a remove never interleaves with an update.
///
/// The queue starts with a first job (sweep and restore check) that every
/// later job waits for. A job that throws reaches only its own caller. Jobs
/// run on the event loop and may await the network, so keep a long download
/// outside the queue and queue only the write that follows it.
///
/// A job must never call [run] and await it (it would wait for itself).
class PluginWriteQueue {
  PluginWriteQueue({required Future<void> Function() firstJob}) {
    _tail = _guarded(firstJob);
    startup = _tail;
  }

  late Future<void> _tail;
  final _inFlight = <String, Future<Object?>>{};
  bool _closed = false;

  /// Completes when the first job ended (it never fails).
  late final Future<void> startup;

  /// Runs [job] after every job queued before it. With [key], a call made
  /// while a job with the same key is queued or running returns that job's
  /// future: the same work is never queued twice (every caller of a key must
  /// expect the same result type). With [onError], an exception of the job
  /// becomes its return value instead of reaching the caller; a queue that
  /// was [close]d does the same.
  Future<T> run<T>(
    Future<T> Function() job, {
    String? key,
    T Function(Object error, StackTrace stack)? onError,
  }) {
    if (_closed) {
      return onError == null
          ? Future<T>.error(StateError('The plugin queue is closed'))
          : Future<T>.value(onError(StateError('closed'), StackTrace.current));
    }
    final shared = key == null ? null : _inFlight[key];
    if (shared != null) return shared as Future<T>;
    Future<T> work() async {
      try {
        return await job();
      } on Object catch (error, stack) {
        if (onError == null) rethrow;
        _log.warning('A plugin job failed: ${error.runtimeType}');
        return onError(error, stack);
      }
    }

    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    if (key != null) {
      _inFlight[key] = result;
      // The error belongs to the caller; here only the key is released.
      result.then<void>(
        (_) => _inFlight.remove(key),
        onError: (Object _) {
          _inFlight.remove(key);
        },
      );
    }
    return result;
  }

  /// Completes when every job queued so far has ended.
  Future<void> get idle => _tail;

  /// Refuses new jobs; the ones queued still run.
  void close() => _closed = true;

  Future<void> _guarded(Future<void> Function() job) async {
    try {
      await job();
    } on Object catch (error) {
      _log.warning('Plugin startup failed: ${error.runtimeType}');
    }
  }
}
