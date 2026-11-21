import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('plugin_state');

/// The error state for [error], with one log line (type only, no message).
AsyncError<R> asyncFailure<R>(Object error, StackTrace stack, String what) {
  _log.warning('Plugin state "$what" failed: ${error.runtimeType}');
  return AsyncError<R>(error, stack);
}

/// Joins two async values: an error of either is the error state (a failing
/// database must show as an error, not as an empty list), then loading, then
/// [combine] of both.
AsyncValue<R> joinAsync<A, B, R>(
  AsyncValue<A> a,
  AsyncValue<B> b,
  R Function(A a, B b) combine,
) {
  if (a.hasError) return asyncFailure(a.error!, a.stackTrace!, 'join');
  if (b.hasError) return asyncFailure(b.error!, b.stackTrace!, 'join');
  if (!a.hasValue || !b.hasValue) return const AsyncLoading();
  return AsyncData(combine(a.requireValue, b.requireValue));
}
