import 'dart:async';
import 'dart:io';

/// Resolves a host name to its addresses. Tests replace it.
typedef HostResolver = Future<List<InternetAddress>> Function(String host);

/// Opens a connection to one already checked [address]. Tests replace it.
typedef SocketDialer = Future<ConnectionTask<Socket>> Function(
  InternetAddress address,
  int port,
);

/// Looks at everything [url] resolved to and throws to refuse the connection.
typedef PinnedCheck = void Function(Uri url, List<InternetAddress> addresses);

/// The lookup, a dial or the TLS handshake ran past the connect limit. Not a
/// `TimeoutException`: `HttpClient` takes that for its own `connectionTimeout`
/// (which is not set here) and turns it into an assertion failure.
class ConnectTimeout implements Exception {
  const ConnectTimeout();

  @override
  String toString() => 'ConnectTimeout';
}

Future<List<InternetAddress>> systemHostResolver(String host) =>
    InternetAddress.lookup(host);

Future<ConnectionTask<Socket>> systemSocketDialer(
  InternetAddress address,
  int port,
) => Socket.startConnect(address, port);

/// A connection factory for `HttpClient` that closes the DNS rebinding gap:
/// the name is resolved exactly once, [check] sees every address of that one
/// answer, and the connection goes to those addresses and to nothing a later
/// lookup could return.
///
/// * An IP literal in the URL is checked without a lookup.
/// * For `https` the TLS handshake runs on the connected socket with the
///   original host name, so SNI and the certificate check use the name and not
///   the address. No bad-certificate callback is ever set: an untrusted
///   certificate fails the connection; [context] only adds trust anchors.
/// * Addresses are tried IPv4 first, then IPv6, one after the other. The whole
///   connect (dials and handshake) is bounded by [connectTimeout] together with the lookup; each dial
///   gets an equal share of what is left, so one blackholed address does not
///   use up the budget of the next. A cancelled connection stops dialing and
///   destroys its sockets.
/// * The client never uses a proxy (`findProxy` is DIRECT), because the
///   destination must be checked here, not by a proxy. If a proxy is asked
///   for anyway the connection is refused rather than sent unchecked.
Future<ConnectionTask<Socket>> Function(Uri, String?, int?)
pinnedConnectionFactory({
  required PinnedCheck check,
  HostResolver resolver = systemHostResolver,
  SocketDialer dialer = systemSocketDialer,
  SecurityContext? context,
  Duration connectTimeout = const Duration(seconds: 10),
}) {
  return (url, proxyHost, proxyPort) async {
    if (proxyHost != null || proxyPort != null) {
      throw const SocketException('Proxies are not used');
    }
    // One budget for lookup, dials and handshake.
    final clock = Stopwatch()..start();
    final addresses = await _resolveOnce(url.host, resolver, connectTimeout);
    check(url, addresses);
    final attempt = _PinnedAttempt(
      host: url.host,
      port: url.port,
      secure: url.scheme == 'https',
      addresses: addresses,
      dialer: dialer,
      context: context,
      budget: connectTimeout - clock.elapsed,
    );
    return ConnectionTask.fromSocket(attempt.connect(), attempt.cancel);
  };
}

Future<List<InternetAddress>> _resolveOnce(
  String host,
  HostResolver resolver,
  Duration timeout,
) async {
  final literal = InternetAddress.tryParse(host);
  if (literal != null) return [literal];
  final List<InternetAddress> found;
  try {
    found = await resolver(host).timeout(timeout);
  } on TimeoutException {
    throw const ConnectTimeout();
  }
  if (found.isEmpty) throw const SocketException('Host lookup found nothing');
  return found;
}

/// One connection attempt over the checked addresses, IPv4 first; [cancel]
/// stops it.
class _PinnedAttempt {
  _PinnedAttempt({
    required this.host,
    required this.port,
    required this.secure,
    required List<InternetAddress> addresses,
    required this.dialer,
    required this.context,
    required this.budget,
  }) : addresses = [
         ...addresses.where((a) => a.type == InternetAddressType.IPv4),
         ...addresses.where((a) => a.type != InternetAddressType.IPv4),
       ];

  final String host;
  final int port;
  final bool secure;
  final List<InternetAddress> addresses;
  final SocketDialer dialer;
  final SecurityContext? context;
  final Duration budget;

  bool _cancelled = false;
  ConnectionTask<Socket>? _dialing;
  Socket? _open;

  Future<Socket> connect() async {
    final clock = Stopwatch()..start();
    Object? last;
    for (var i = 0; i < addresses.length; i++) {
      if (_cancelled) break;
      final remaining = budget - clock.elapsed;
      if (remaining <= Duration.zero) {
        // The lookup (or earlier dials) used the whole budget.
        if (!_cancelled) last = const ConnectTimeout();
        break;
      }
      // An equal share of what is left for this and the addresses after it.
      final slice = remaining ~/ (addresses.length - i);
      try {
        final task = await dialer(addresses[i], port);
        _dialing = task;
        if (_cancelled) {
          // Observe the socket future so a socket that opened first is
          // destroyed and a cancellation error does not go unhandled.
          unawaited(task.socket.then((s) => s.destroy(), onError: (_) {}));
          task.cancel();
          break;
        }
        final plain = await task.socket.timeout(
          slice,
          onTimeout: () {
            task.cancel();
            unawaited(task.socket.then((s) => s.destroy(), onError: (_) {}));
            throw const ConnectTimeout();
          },
        );
        _open = plain;
        if (_cancelled) {
          plain.destroy();
          break;
        }
        if (!secure) return plain;
        final tls =
            await SecureSocket.secure(
              plain,
              host: host,
              context: context,
            ).timeout(
              budget - clock.elapsed,
              onTimeout: () {
                plain.destroy();
                throw const ConnectTimeout();
              },
            );
        _open = tls;
        if (_cancelled) {
          tls.destroy();
          break;
        }
        return tls;
      } on SocketException catch (e) {
        last = e;
      } on ConnectTimeout catch (e) {
        last = e;
      } on Object {
        // Destroying the socket of a cancelled attempt fails its handshake;
        // that is the cancellation, not an error to report. Any other error
        // (a TLS handshake failure, a certificate or host name mismatch) is
        // rethrown without trying the next address: another address of the
        // same name would present the same certificate, and falling through
        // would only repeat the failure and hide the cause.
        if (_cancelled) break;
        rethrow;
      }
    }
    // A dial that only timed out stays a ConnectTimeout so the caller can
    // tell "too slow" from "refused".
    throw last ?? const SocketException('Connection cancelled');
  }

  void cancel() {
    _cancelled = true;
    _dialing?.cancel();
    _open?.destroy();
  }
}
