import '../../domain/online/lyrics_source.dart';

/// Shortest pause after a failed lookup of a source.
const minBackoff = Duration(seconds: 60);

/// Largest share of the wait added at random, so clients do not retry in step.
const maxBackoffJitter = 0.3;

/// A service's own wait request is kept within these bounds.
const minRetryAfter = Duration(seconds: 1);
const maxRetryAfter = Duration(minutes: 15);

/// In-memory pause of automatic lookups per source after a failure. An entry
/// whose time has passed is as good as none. A failing source pauses only
/// itself. The clock and the randomness are injected so tests are exact.
class OnlineBackoff {
  OnlineBackoff({required this._now, required this._random});

  final DateTime Function() _now;
  final double Function() _random;
  final _byId = <String, SourceBackoff>{};

  /// Pauses [id] for [minBackoff], or for [retryAfter] (kept within
  /// [minRetryAfter]..[maxRetryAfter]) when that is longer, plus up to
  /// [maxBackoffJitter] of it. A pause never gets shorter. [network]: a
  /// network or service failure (else the source answered badly).
  void failed(String id, {required bool network, Duration? retryAfter}) {
    var wait = minBackoff;
    if (retryAfter != null) {
      final asked = retryAfter < minRetryAfter
          ? minRetryAfter
          : (retryAfter > maxRetryAfter ? maxRetryAfter : retryAfter);
      if (asked > wait) wait = asked;
    }
    final jitter = _random().clamp(0.0, 1.0);
    final until = _now().add(
      Duration(
        microseconds: (wait.inMicroseconds * (1 + jitter * maxBackoffJitter))
            .round(),
      ),
    );
    final current = _byId[id];
    if (current == null || until.isAfter(current.until)) {
      _byId[id] = SourceBackoff(until: until, network: network);
    }
  }

  /// The running pause of [id], or null.
  SourceBackoff? of(String id) {
    final b = _byId[id];
    return b != null && b.until.isAfter(_now()) ? b : null;
  }

  /// The running pauses by source id.
  Map<String, SourceBackoff> snapshot() {
    final now = _now();
    return {
      for (final e in _byId.entries)
        if (e.value.until.isAfter(now)) e.key: e.value,
    };
  }

  /// Lifts every pause (a manual retry, a new manual search).
  void clear() => _byId.clear();
}
