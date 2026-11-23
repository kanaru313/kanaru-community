import 'dart:async';

import '../../domain/net/cancel_token.dart';
import '../../domain/net/plugin_fetch_rules.dart';

/// How a wait for a request start ended.
enum LimiterResult {
  /// The caller may send now.
  granted,

  /// The wait would leave too little time to send: nothing was reserved.
  tooLate,

  /// The caller cancelled while waiting.
  cancelled,
}

/// Keeps the request starts of one plugin at least [spacing] apart. Waiters of
/// a plugin are served in the order they came (each takes the next free
/// start); plugins do not wait for each other.
class PluginLimiter {
  PluginLimiter({
    this.spacing = pluginSpacing,
    this.minTimeLeft = const Duration(seconds: 1),
    Duration Function()? clock,
  }) : _clock = clock ?? _stopwatchClock();

  final Duration spacing;

  /// A request that has to wait is sent only when at least this much of its
  /// deadline is left after the wait.
  final Duration minTimeLeft;
  final Duration Function() _clock;

  /// The next free start of each plugin that sent lately.
  final _next = <String, Duration>{};

  /// Waits for the next start of [installId]. [timeLeft] is what is left of
  /// the request's deadline; the wait counts against it. Never throws.
  Future<LimiterResult> acquire(
    String installId, {
    required Duration timeLeft,
    CancelToken? cancel,
  }) async {
    if (cancel != null && cancel.isCancelled) return LimiterResult.cancelled;
    final now = _clock();
    _next.removeWhere((_, free) => free <= now);
    final previous = _next[installId];
    final start = previous ?? now;
    final wait = start - now;
    if (wait <= Duration.zero) {
      _next[installId] = now + spacing;
      return LimiterResult.granted;
    }
    if (timeLeft - wait < minTimeLeft) return LimiterResult.tooLate;

    final reserved = start + spacing;
    _next[installId] = reserved;
    final done = Completer<LimiterResult>();
    final timer = Timer(wait, () {
      if (!done.isCompleted) done.complete(LimiterResult.granted);
    });
    final unlisten = cancel?.listen(() {
      timer.cancel();
      if (done.isCompleted) return;
      done.complete(LimiterResult.cancelled);
      // Give the slot back when nobody queued behind this waiter.
      if (_next[installId] == reserved) _next[installId] = start;
    });
    try {
      return await done.future;
    } finally {
      timer.cancel();
      unlisten?.call();
    }
  }
}

Duration Function() _stopwatchClock() {
  final watch = Stopwatch()..start();
  return () => watch.elapsed;
}
