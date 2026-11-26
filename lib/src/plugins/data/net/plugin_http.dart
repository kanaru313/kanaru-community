import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../../foundation/result.dart';
import '../../domain/net/cancel_token.dart';
import '../../domain/net/fetch_failure.dart';
import '../../domain/net/plugin_fetch_rules.dart';
import 'capped_body.dart';
import 'fetcher.dart' show defaultUserAgent;
import 'pinned_http.dart';

/// One request of a plugin, already judged by the fetch rules.
class PluginHttpRequest {
  const PluginHttpRequest({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
  });

  /// `GET` or `POST`.
  final String method;
  final Uri url;

  /// Lower-case names, already filtered by `pluginRequestHeaders`.
  final Map<String, String> headers;
  final Uint8List body;
}

/// What came back; a redirect is an answer like any other.
class PluginHttpResponse {
  const PluginHttpResponse({
    required this.status,
    required this.headers,
    required this.body,
  });

  final int status;

  /// Lower-case names, one pair per value.
  final List<(String, String)> headers;
  final Uint8List body;
}

/// Why no answer came back. Carries no URL, header or body.
enum PluginHttpFailure {
  /// Socket, TLS, lookup or protocol failure.
  network,

  /// The overall time passed.
  timeout,

  /// The name resolved to an address a plugin may not reach.
  blockedAddress,

  /// The body is over [pluginMaxResponseBytes].
  tooLarge,

  /// The caller cancelled.
  cancelled,
}

/// Exactly one HTTP exchange for a plugin, on the pinned transport.
///
/// Every request builds a new `HttpClient` that never uses a proxy; the host
/// is resolved once and every address of that answer must be public (a
/// private, loopback, reserved or mixed answer is refused before a socket is
/// opened); TLS checks the original name and no bad-certificate callback
/// exists. Redirects are not followed and connections are not reused. The
/// whole exchange is bounded by the deadline given to [send]; a timeout or a
/// cancel destroys the sockets. Nothing is thrown.
class PluginHttpClient {
  PluginHttpClient({
    this._resolver = systemHostResolver,
    this._dialer = systemSocketDialer,
    this._context,
    this._connectLimit = pluginConnectTimeout,
  });

  final HostResolver _resolver;
  final SocketDialer _dialer;
  final SecurityContext? _context;
  final Duration _connectLimit;

  /// Sends [request]; ends within [deadline] (the connect step is bounded by
  /// the connect limit as well). A script `user-agent` replaces
  /// [defaultUserAgent], which is sent only when the script set none.
  Future<Result<PluginHttpResponse, PluginHttpFailure>> send(
    PluginHttpRequest request, {
    required Duration deadline,
    CancelToken? cancel,
  }) {
    final session = newSession(request);

    final result = Completer<Result<PluginHttpResponse, PluginHttpFailure>>();
    void stop() => session.stop();

    void abort(PluginHttpFailure why) {
      if (result.isCompleted) return;
      // Complete first: stopping fails the work in flight, and that failure
      // must not replace the real reason.
      result.complete(Err(why));
      stop();
    }

    final timer = Timer(deadline, () => abort(PluginHttpFailure.timeout));
    final unlisten = cancel?.listen(() => abort(PluginHttpFailure.cancelled));
    if (!result.isCompleted) {
      _exchange(session, request).then(
        (ok) {
          if (!result.isCompleted) result.complete(Ok(ok));
        },
        onError: (Object e) {
          if (!result.isCompleted) result.complete(Err(pluginHttpFailureOf(e)));
        },
      );
    }
    return result.future.whenComplete(() {
      timer.cancel();
      unlisten?.call();
      stop();
    });
  }

  /// One new transport for one exchange: its own `HttpClient`, no proxy, the
  /// pinned connection rules. Shared by [send] and the stream reader so both
  /// obey the same rules. The caller must [PluginHttpSession.stop] it.
  PluginHttpSession newSession(PluginHttpRequest request) {
    final client = HttpClient()
      ..findProxy = ((_) => 'DIRECT')
      ..userAgent = request.headers['user-agent'] ?? defaultUserAgent;
    final session = PluginHttpSession._(client);
    final pinned = pinnedConnectionFactory(
      check: (url, addresses) {
        if (session.stopped) {
          throw const FetchFailure(FetchFailureKind.cancelled);
        }
        if (!isPublicOnly([for (final a in addresses) a.rawAddress])) {
          throw const _BlockedAddress();
        }
      },
      resolver: _resolver,
      dialer: _dialer,
      context: _context,
      connectTimeout: _connectLimit,
    );
    // `HttpClient.close(force)` cannot cancel a dial it does not track yet: a
    // socket that connects after a stop is destroyed here and never used.
    client.connectionFactory = (url, proxyHost, proxyPort) async {
      final task = await pinned(url, proxyHost, proxyPort);
      void refuse() => throw const FetchFailure(FetchFailureKind.cancelled);
      if (session.stopped) {
        task.cancel();
        unawaited(task.socket.then((s) => s.destroy(), onError: (_) {}));
        refuse();
      }
      return ConnectionTask.fromSocket(
        task.socket.then((socket) {
          if (session.stopped) {
            socket.destroy();
            refuse();
          }
          return socket;
        }),
        task.cancel,
      );
    };
    return session;
  }

  Future<PluginHttpResponse> _exchange(
    PluginHttpSession session,
    PluginHttpRequest request,
  ) async {
    final response = await session.start(request);
    final body = await readCappedBody(
      response,
      pluginMaxResponseBytes,
      ensureActive: session.ensureActive,
    );
    return PluginHttpResponse(
      status: response.statusCode,
      headers: pluginResponseHeaders(response),
      body: body,
    );
  }
}

/// The header pairs of [response], lower-case names, one pair per value.
List<(String, String)> pluginResponseHeaders(HttpClientResponse response) {
  final headers = <(String, String)>[];
  response.headers.forEach((name, values) {
    for (final value in values) {
      headers.add((name.toLowerCase(), value));
    }
  });
  return headers;
}

/// One exchange on its own transport (see [PluginHttpClient.newSession]).
class PluginHttpSession {
  PluginHttpSession._(this._client);

  final HttpClient _client;

  /// Set by [stop]; a dial that finishes after it is destroyed.
  bool stopped = false;

  /// Destroys every socket of the session. Safe to call again.
  void stop() {
    stopped = true;
    try {
      _client.close(force: true);
    } on Object {
      // Closing a client that already failed is not an error to report.
    }
  }

  /// Throws a `cancelled` failure once the session was stopped.
  void ensureActive() {
    if (stopped) throw const FetchFailure(FetchFailureKind.cancelled);
  }

  /// Sends [request] and returns once the response head is in; redirects are
  /// not followed and the connection is not kept alive.
  Future<HttpClientResponse> start(PluginHttpRequest request) async {
    final call = await _client.openUrl(request.method, request.url);
    call
      ..followRedirects = false
      ..persistentConnection = false;
    for (final MapEntry(key: name, value: value) in request.headers.entries) {
      // Set through `HttpClient.userAgent`.
      if (name == 'user-agent') continue;
      call.headers.set(name, value);
    }
    if (request.method == 'POST') {
      call.contentLength = request.body.length;
      if (request.body.isNotEmpty) call.add(request.body);
    }
    final response = await call.close();
    ensureActive();
    return response;
  }
}

/// The name resolved to an address a plugin may not reach.
class _BlockedAddress implements Exception {
  const _BlockedAddress();

  @override
  String toString() => 'BlockedAddress';
}

/// Maps anything an exchange threw to a failure that carries no text.
PluginHttpFailure pluginHttpFailureOf(Object error) {
  if (error is _BlockedAddress) return PluginHttpFailure.blockedAddress;
  if (error is FetchFailure) {
    return switch (error.kind) {
      FetchFailureKind.tooLarge => PluginHttpFailure.tooLarge,
      FetchFailureKind.cancelled => PluginHttpFailure.cancelled,
      _ => PluginHttpFailure.network,
    };
  }
  if (error is TimeoutException || error is ConnectTimeout) {
    return PluginHttpFailure.timeout;
  }
  // Socket, TLS, HTTP, closed client and anything else: the text of the
  // original may name the address, so it is dropped.
  return PluginHttpFailure.network;
}
