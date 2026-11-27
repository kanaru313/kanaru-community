import 'dart:async';
import 'dart:isolate';

/// Runs [computation] on another isolate (tests inject an inline runner to
/// count the calls).
typedef IsolateRunner = Future<R> Function<R>(
  FutureOr<R> Function() computation,
);

Future<R> runInIsolate<R>(FutureOr<R> Function() computation) =>
    Isolate.run(computation);

/// Output longer than this many characters is read off the UI isolate;
/// smaller output is cheaper inline than the isolate hand-off.
const onlineIsolateThreshold = 64 * 1024;
