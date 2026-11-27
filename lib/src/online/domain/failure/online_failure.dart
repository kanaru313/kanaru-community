/// Who a failure is about: the one item, the whole source, or the connection.
enum OnlineFailureClass { track, source, network }

/// Why an online call failed, with the class it belongs to.
enum OnlineFailureKind {
  // Track level: this item cannot be used, the source is fine.
  gone(OnlineFailureClass.track),
  unsupported(OnlineFailureClass.track),
  authRequired(OnlineFailureClass.track),
  invalidOutput(OnlineFailureClass.track),
  blockedHost(OnlineFailureClass.track),
  pluginMissing(OnlineFailureClass.track),

  // Source level: the plugin as a whole cannot answer now.
  rateLimited(OnlineFailureClass.source),
  paused(OnlineFailureClass.source),
  needsConfig(OnlineFailureClass.source),
  busy(OnlineFailureClass.source),
  timeout(OnlineFailureClass.source),
  pluginChanged(OnlineFailureClass.source),
  server(OnlineFailureClass.source),
  authFailed(OnlineFailureClass.source),
  noScript(OnlineFailureClass.source),
  internal(OnlineFailureClass.source),

  // The connection.
  network(OnlineFailureClass.network);

  const OnlineFailureKind(this.failureClass);

  final OnlineFailureClass failureClass;
}

/// A failed online call. [retryAfter] / [until] / [fieldTitles] are filled
/// only for the kinds that carry them.
class OnlineFailure {
  const OnlineFailure(
    this.kind, {
    this.retryAfter,
    this.until,
    this.fieldTitles = const [],
  });

  final OnlineFailureKind kind;
  final Duration? retryAfter;
  final DateTime? until;
  final List<String> fieldTitles;

  OnlineFailureClass get failureClass => kind.failureClass;

  @override
  bool operator ==(Object other) =>
      other is OnlineFailure &&
      other.kind == kind &&
      other.retryAfter == retryAfter &&
      other.until == until &&
      _sameList(other.fieldTitles, fieldTitles);

  @override
  int get hashCode =>
      Object.hash(kind, retryAfter, until, Object.hashAll(fieldTitles));

  @override
  String toString() => 'OnlineFailure(${kind.name})';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The answer of an online call. Switch over it without a default.
sealed class OnlineResult<T> {
  const OnlineResult();
}

final class OnlineOk<T> extends OnlineResult<T> {
  const OnlineOk(this.value);

  final T value;
}

final class OnlineFailed<T> extends OnlineResult<T> {
  const OnlineFailed(this.failure);

  final OnlineFailure failure;
}

/// The caller (or a newer call) cancelled it: nothing to show.
final class OnlineAbandoned<T> extends OnlineResult<T> {
  const OnlineAbandoned();
}

/// Which kind of script ran: it decides how an `auth` error reads.
/// Autocomplete counts as [page].
enum OnlineScriptRole { page, stream }
