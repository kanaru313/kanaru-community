import '../../domain/net/cancel_token.dart';
import '../net/plugin_http_stream.dart';

/// One stream of a run: its slot in the [StreamTable], the token that stops
/// it, and its handle once the head arrived.
class StreamEntry {
  StreamEntry._(this.id);

  final int id;

  /// Fires when the job is cancelled (the table is sealed) or the runtime
  /// closes this stream: the open in flight, the spacing wait and the body all
  /// stop on it. It is the "job token plus this stream's close" of a request.
  final CancelToken cancel = CancelToken();

  /// Set once the open succeeded; null while the open is pending.
  PluginHttpStreamHandle? handle;

  /// The Dart side ended the stream (close, seal): reads fail `network`.
  bool get isClosed => cancel.isCancelled;
}

/// The streams of one run (one dispatch): at most [maxOpen] at a time, all
/// closed and refused for good once the run's cancel fires or [dispose] runs.
/// Single isolate, no locking.
class StreamTable {
  /// [jobCancel] is the run's token; the table seals when it fires.
  StreamTable(CancelToken jobCancel) {
    _unlisten = jobCancel.listen(seal);
  }

  /// Most streams open (or opening) at once, as in the runtime.
  static const maxOpen = 2;

  final Map<int, StreamEntry> _entries = {};
  late final void Function() _unlisten;
  bool _sealed = false;

  /// No stream may open any more.
  bool get isSealed => _sealed;

  /// Streams open or opening.
  int get length => _entries.length;

  StreamEntry? find(int id) => _entries[id];

  /// Takes the slot of stream [id]; null when sealed, full or [id] is taken.
  StreamEntry? reserve(int id) {
    if (_sealed || _entries.length >= maxOpen || _entries.containsKey(id)) {
      return null;
    }
    return _entries[id] = StreamEntry._(id);
  }

  /// Frees [entry]'s slot (only if it still holds it).
  void release(StreamEntry entry) {
    if (identical(_entries[entry.id], entry)) _entries.remove(entry.id);
  }

  /// Ends [entry]: frees its slot, stops whatever it is doing and closes its
  /// socket. Idempotent.
  void end(StreamEntry entry) {
    release(entry);
    entry.cancel.cancel();
    entry.handle?.close();
  }

  /// Refuses every later open and ends every stream.
  void seal() {
    _sealed = true;
    for (final entry in _entries.values.toList()) {
      end(entry);
    }
  }

  /// [seal], and stops listening to the run's token: call when the run ends.
  void dispose() {
    _unlisten();
    seal();
  }
}
