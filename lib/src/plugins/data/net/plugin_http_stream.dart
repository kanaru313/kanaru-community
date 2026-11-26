import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import '../../../foundation/result.dart';
import '../../domain/net/cancel_token.dart';
import 'plugin_http.dart';

/// Largest streamed body read in all, in bytes.
const pluginMaxStreamBytes = 16 * 1024 * 1024;

/// Most bytes one read returns.
const pluginMaxStreamRead = 64 * 1024;

/// Bytes buffered before the connection is paused until a read drains them.
const _bufferBytes = 1024 * 1024;

/// What one successful read found.
class PluginStreamRead {
  const PluginStreamRead._(this.bytes, {this.done = false});

  /// Bytes arrived (never empty).
  PluginStreamRead.chunk(Uint8List bytes) : this._(bytes);

  /// The body really reached its end.
  PluginStreamRead.done() : this._(Uint8List(0), done: true);

  /// Nothing came within the wait; the stream stays open.
  PluginStreamRead.idle() : this._(Uint8List(0));

  final Uint8List bytes;
  final bool done;
  bool get isIdle => bytes.isEmpty && !done;
}

/// Opens streamed responses on the same pinned transport as
/// [PluginHttpClient.send] (same resolver, dialer and TLS rules).
class PluginHttpStreamClient {
  const PluginHttpStreamClient(this._client);

  final PluginHttpClient _client;

  /// Sends [request] and returns once the response head is in; a redirect is
  /// an answer like any other. [deadline] bounds connect and head. [cancel]
  /// aborts the open and, afterwards, the body. [lifetime] (from now) closes
  /// the handle by itself. Nothing is thrown.
  Future<Result<PluginHttpStreamHandle, PluginHttpFailure>> open(
    PluginHttpRequest request, {
    required Duration deadline,
    CancelToken? cancel,
    Duration? lifetime,
  }) {
    final session = _client.newSession(request);
    final result =
        Completer<Result<PluginHttpStreamHandle, PluginHttpFailure>>();
    void Function()? unlisten;
    Timer? headTimer;
    Timer? lifeTimer;
    PluginHttpStreamHandle? handle;
    void abort(PluginHttpFailure why) {
      if (result.isCompleted) {
        // Opened already: a Dart-side end closes the handle.
        handle?._fail(PluginHttpFailure.network, discard: true);
        return;
      }
      // Complete first: stopping fails the work in flight, and that failure
      // must not replace the real reason.
      result.complete(Err(why));
      session.stop();
    }

    headTimer = Timer(deadline, () => abort(PluginHttpFailure.timeout));
    if (lifetime != null) {
      lifeTimer = Timer(lifetime, () => abort(PluginHttpFailure.network));
    }
    unlisten = cancel?.listen(() => abort(PluginHttpFailure.cancelled));
    if (!result.isCompleted) {
      session
          .start(request)
          .then(
            (response) {
              if (result.isCompleted) {
                // Aborted while the head was arriving: drop the connection.
                session.stop();
                return;
              }
              headTimer?.cancel();
              handle = PluginHttpStreamHandle._(
                session,
                response,
                lifeTimer,
                unlisten,
              );
              result.complete(Ok(handle!));
            },
            onError: (Object e) {
              if (!result.isCompleted) {
                result.complete(Err(pluginHttpFailureOf(e)));
              }
              session.stop();
            },
          );
    }
    return result.future.then((r) {
      if (r is Err) {
        headTimer?.cancel();
        lifeTimer?.cancel();
        unlisten?.call();
        session.stop();
      }
      return r;
    });
  }
}

/// An opened response: the head, and the body read in turns. At most one
/// [read] may be pending. Every end (close, cancel, lifetime, budget, error,
/// body end) releases the socket, timers and subscription.
class PluginHttpStreamHandle {
  PluginHttpStreamHandle._(
    this._session,
    HttpClientResponse response,
    this._lifeTimer,
    this._unlisten,
  ) : status = response.statusCode,
      headers = pluginResponseHeaders(response) {
    _subscription = response.listen(
      _onData,
      onError: (Object _) => _fail(PluginHttpFailure.network),
      onDone: _onDone,
      cancelOnError: true,
    );
  }

  final PluginHttpSession _session;
  final int status;

  /// Lower-case names, one pair per value.
  final List<(String, String)> headers;

  late final StreamSubscription<List<int>> _subscription;
  final Timer? _lifeTimer;
  Timer? _idleTimer;
  final void Function()? _unlisten;

  final Queue<Uint8List> _chunks = Queue();
  int _offset = 0;
  int _buffered = 0;
  int _total = 0;
  bool _paused = false;
  bool _ended = false;
  bool _released = false;
  PluginHttpFailure? _failure;
  Completer<Result<PluginStreamRead, PluginHttpFailure>>? _pending;
  int _pendingMax = 0;

  /// Waits up to [wait] for bytes and returns at most [maxBytes] (capped at
  /// 64 KiB; buffered bytes at once). `done` only when the body really ended;
  /// idle when nothing came; a handle closed from the Dart side fails
  /// `network`; a body past 16 MiB fails `tooLarge`.
  Future<Result<PluginStreamRead, PluginHttpFailure>> read({
    required int maxBytes,
    required Duration wait,
  }) {
    if (_pending != null) {
      // Two reads at once break the contract; the first stays untouched.
      return Future.value(const Err(PluginHttpFailure.network));
    }
    final limit = maxBytes.clamp(1, pluginMaxStreamRead);
    if (_buffered > 0) return Future.value(Ok(_take(limit)));
    final failure = _failure;
    if (failure != null) return Future.value(Err(failure));
    if (_ended) return Future.value(Ok(PluginStreamRead.done()));
    if (wait <= Duration.zero) {
      return Future.value(Ok(PluginStreamRead.idle()));
    }
    final pending = _pending = Completer();
    _pendingMax = limit;
    _idleTimer = Timer(wait, () {
      _idleTimer = null;
      _pending = null;
      pending.complete(Ok(PluginStreamRead.idle()));
    });
    return pending.future;
  }

  /// Closes the connection. Idempotent; a pending read fails `network`.
  Future<void> close() {
    _fail(PluginHttpFailure.network, discard: true);
    return Future.value();
  }

  void _onData(List<int> data) {
    if (_released || data.isEmpty) return;
    _total += data.length;
    if (_total > pluginMaxStreamBytes) {
      _fail(PluginHttpFailure.tooLarge, discard: true);
      return;
    }
    _chunks.add(data is Uint8List ? data : Uint8List.fromList(data));
    _buffered += data.length;
    if (_buffered >= _bufferBytes && !_paused) {
      _paused = true;
      _subscription.pause();
    }
    _settle();
  }

  void _onDone() {
    if (_released) return;
    _ended = true;
    _release();
    _settle();
  }

  /// Ends the body with [why]; buffered bytes stay readable first unless
  /// [discard]. The first failure wins. A body that ended by itself is not
  /// touched by later timers: they were released with it.
  void _fail(PluginHttpFailure why, {bool discard = false}) {
    _failure ??= why;
    _release();
    if (discard) _discard();
    _settle();
  }

  void _discard() {
    _chunks.clear();
    _buffered = 0;
  }

  void _release() {
    if (_released) return;
    _released = true;
    _lifeTimer?.cancel();
    _idleTimer?.cancel();
    _idleTimer = null;
    _unlisten?.call();
    unawaited(_subscription.cancel().then((_) {}, onError: (_) {}));
    _session.stop();
  }

  void _settle() {
    final pending = _pending;
    if (pending == null) return;
    final Result<PluginStreamRead, PluginHttpFailure> answer;
    if (_buffered > 0) {
      answer = Ok(_take(_pendingMax));
    } else if (_failure != null) {
      answer = Err(_failure!);
    } else if (_ended) {
      answer = Ok(PluginStreamRead.done());
    } else {
      return;
    }
    _pending = null;
    _idleTimer?.cancel();
    _idleTimer = null;
    pending.complete(answer);
  }

  PluginStreamRead _take(int max) {
    final out = BytesBuilder(copy: false);
    var left = max;
    while (left > 0 && _chunks.isNotEmpty) {
      final chunk = _chunks.first;
      final available = chunk.length - _offset;
      if (available <= left) {
        out.add(_offset == 0 ? chunk : Uint8List.sublistView(chunk, _offset));
        _chunks.removeFirst();
        _offset = 0;
        left -= available;
        _buffered -= available;
      } else {
        out.add(Uint8List.sublistView(chunk, _offset, _offset + left));
        _offset += left;
        _buffered -= left;
        left = 0;
      }
    }
    if (_paused && _buffered < _bufferBytes) {
      _paused = false;
      if (!_released) _subscription.resume();
    }
    return PluginStreamRead.chunk(out.takeBytes());
  }
}
