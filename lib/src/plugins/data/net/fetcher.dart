import 'dart:async';
import 'dart:io';

import '../../../foundation/result.dart';
import '../../domain/net/address_rules.dart';
import '../../domain/net/cancel_token.dart';
import '../../domain/net/fetch_failure.dart';
import '../../domain/net/net_policy.dart';
import 'capped_body.dart';
import 'pinned_http.dart';

/// At most this many redirects are followed; the next one is refused.
const maxRedirects = 3;
const connectTimeout = Duration(seconds: 10);
const totalTimeout = Duration(seconds: 20);

/// Sent when the caller gives no User-Agent. The app passes its own with the
/// version: `Kanaru/<version> (+<repository>)`.
const defaultUserAgent =
    'Kanaru (+https://github.com/kanaru313/kanaru-community)';

/// The only way the plugin feature reaches the network: GET of a catalog, a
/// plugin zip or an icon. It sends no user data and uses no credentials.
///
/// Every call builds a fresh `HttpClient` and every connection is pinned: the
/// host is resolved once, every resolved address is judged by [judgeAddress]
/// and the socket goes to those addresses only (see
/// [pinnedConnectionFactory]); TLS verifies the original host name and there
/// is no bad-certificate callback. Redirects are followed by hand, at most
/// [maxRedirects]; each hop is judged again with the catalog kind, which
/// narrows to public once any hop is public, so neither a public catalog nor
/// a public host in the middle of a chain can redirect into the local
/// network. Each hop uses a new connection, so no keep-alive socket can skip
/// the check. The whole call (all hops) is limited to [totalTimeout] and the
/// timeout, like a cancel, destroys the sockets. Proxies are never used.
///
/// Nothing is thrown: every error is a [FetchFailure].
class HttpFetcher {
  HttpFetcher({
    this._resolver = systemHostResolver,
    this._dialer = systemSocketDialer,
    this._context,
    this._connectLimit = connectTimeout,
    this._totalLimit = totalTimeout,
    this._userAgent = defaultUserAgent,
  });

  final HostResolver _resolver;
  final SocketDialer _dialer;
  final SecurityContext? _context;
  final Duration _connectLimit;
  final Duration _totalLimit;
  final String _userAgent;

  /// GETs [uri] under [policy]. [catalogKind] is the kind of the catalog a
  /// `package` or `icon` reference came from (a missing one is taken as
  /// `public`, the stricter); `repo` and `link` ignore it. [maxBytes] lowers
  /// the policy's cap (never raises it). [expectedSize] is the size the
  /// catalog declared, used as the progress total when given.
  Future<Result<FetchResult, FetchFailure>> get(
    Uri uri,
    NetPolicy policy, {
    AddressKind? catalogKind,
    int? maxBytes,
    int? expectedSize,
    CancelToken? cancel,
    void Function(int received, int? total)? onProgress,
  }) {
    final cap = maxBytes != null && maxBytes < policy.maxBytes
        ? maxBytes
        : policy.maxBytes;
    final kind = policy.fromCatalog
        ? (catalogKind ?? AddressKind.public)
        : null;
    final call = _Call(kind)..client.userAgent = _userAgent;
    call.client.connectionFactory = pinnedConnectionFactory(
      check: call.check,
      resolver: _resolver,
      dialer: _dialer,
      context: _context,
      connectTimeout: _connectLimit,
    );
    final result = Completer<Result<FetchResult, FetchFailure>>();
    void abort(FetchFailureKind why) {
      if (result.isCompleted) return;
      // Complete first: stopping the client fails the work in flight, and that
      // failure must not replace the real reason.
      result.complete(Err(FetchFailure(why)));
      // The work must stop, not just the wait: nothing new may start and the
      // sockets in flight are destroyed.
      call.stop();
    }

    final timer = Timer(_totalLimit, () => abort(FetchFailureKind.timeout));
    final unlisten = cancel?.listen(() => abort(FetchFailureKind.cancelled));
    if (!result.isCompleted) {
      _follow(call, uri, cap, expectedSize, onProgress).then(
        (ok) {
          if (!result.isCompleted) result.complete(Ok(ok));
        },
        onError: (Object e) {
          if (!result.isCompleted) result.complete(Err(_asFailure(e)));
        },
      );
    }
    return result.future.whenComplete(() {
      timer.cancel();
      unlisten?.call();
      call.stop();
    });
  }

  Future<FetchResult> _follow(
    _Call call,
    Uri start,
    int cap,
    int? expectedSize,
    void Function(int received, int? total)? onProgress,
  ) async {
    var url = start;
    for (var redirects = 0; ; redirects++) {
      // Shape and name rules first, so a bad URL never reaches the resolver.
      final shape = judgeAddress(url, catalogKind: call.kind);
      if (!shape.isAllowed) throw FetchFailure.blocked(shape.problem!);
      call.ensureActive();
      final request = await call.client.getUrl(url);
      request
        ..followRedirects = false
        ..persistentConnection = false;
      final response = await request.close();
      call.ensureActive();
      final status = response.statusCode;
      if (status >= 300 && status < 400) {
        final location = response.headers.value(HttpHeaders.locationHeader);
        await discardBody(response);
        final next = location == null ? null : Uri.tryParse(location);
        if (next == null || redirects >= maxRedirects) {
          throw const FetchFailure(FetchFailureKind.network);
        }
        url = url.resolveUri(next);
        continue;
      }
      if (status < 200 || status >= 300) {
        await discardBody(response);
        throw FetchFailure(FetchFailureKind.badStatus, status: status);
      }
      final bytes = await readCappedBody(
        response,
        cap,
        ensureActive: call.ensureActive,
        total: expectedSize,
        onProgress: onProgress,
      );
      return FetchResult(
        bytes: bytes,
        finalUrl: url,
        kind: call.kind ?? AddressKind.public,
      );
    }
  }
}

FetchFailure _asFailure(Object error) {
  if (error is FetchFailure) return error;
  if (error is TimeoutException || error is ConnectTimeout) {
    return const FetchFailure(FetchFailureKind.timeout);
  }
  // Socket, TLS, HTTP, closed client and anything else: the text of the
  // original may name the address, so it is dropped.
  return const FetchFailure(FetchFailureKind.network);
}

/// The state of one call, shared with its pinned connections: the catalog
/// kind the hops narrow, and whether the call was stopped.
class _Call {
  _Call(this.kind) : client = HttpClient()..findProxy = ((_) => 'DIRECT');

  final HttpClient client;

  /// The class of the catalog the fetched URLs belong to. For a catalog fetch
  /// it starts unknown and is decided by the hops. For every fetch it becomes
  /// `public` once any hop is public: a local address that redirects to a
  /// public host keeps no local privileges.
  AddressKind? kind;
  bool _stopped = false;

  void stop() {
    _stopped = true;
    client.close(force: true);
  }

  void ensureActive() {
    if (_stopped) throw const FetchFailure(FetchFailureKind.cancelled);
  }

  /// Runs inside the pinned connection on the one answer it will connect to.
  void check(Uri url, List<InternetAddress> addresses) {
    ensureActive();
    final verdict = judgeAddress(
      url,
      addresses: [for (final a in addresses) a.rawAddress],
      catalogKind: kind,
    );
    if (!verdict.isAllowed) throw FetchFailure.blocked(verdict.problem!);
    if (verdict.kind == AddressKind.public) {
      kind = AddressKind.public;
    } else {
      kind ??= verdict.kind;
    }
  }
}
