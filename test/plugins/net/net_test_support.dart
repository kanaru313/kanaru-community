import 'dart:async';
import 'dart:io';

const testCertPath = 'test/plugins/net/fixtures/test_cert.pem';
const testKeyPath = 'test/plugins/net/fixtures/test_key.pem';

/// A public address that tests never connect to: a test dialer sends the
/// connection to a loopback server instead.
const fakePublicIp = '93.184.216.34';

/// A security context that trusts only the test certificate (CN
/// `repo.example.test`, also valid for `localhost` and `127.0.0.1`).
SecurityContext trustingTestCert() =>
    SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificates(testCertPath);

/// A loopback HTTP or HTTPS server whose handler is replaced per test.
class TestServer {
  TestServer._(this.server);

  final HttpServer server;
  final requests = <HttpRequest>[];
  final userAgents = <String?>[];
  FutureOr<void> Function(HttpRequest request) handler = (r) async {
    r.response.statusCode = 404;
    await r.response.close();
  };

  int get port => server.port;

  static Future<TestServer> start({bool secure = false}) async {
    final HttpServer server;
    if (secure) {
      final context = SecurityContext()
        ..useCertificateChain(testCertPath)
        ..usePrivateKey(testKeyPath);
      server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
    } else {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    }
    final test = TestServer._(server);
    server.listen((request) async {
      test.requests.add(request);
      test.userAgents.add(request.headers.value(HttpHeaders.userAgentHeader));
      try {
        await test.handler(request);
      } on Object {
        // The client went away mid-answer (a cap was hit): fine.
      }
    }, onError: (_) {});
    return test;
  }

  Future<void> close() => server.close(force: true);
}

/// Sends every connection to a loopback port and records what the code under
/// test asked to reach. [portFor] picks the port from the asked one.
class RecordingDialer {
  RecordingDialer(this.portFor);

  final int Function(InternetAddress address, int askedPort) portFor;
  final dialed = <InternetAddress>[];

  Future<ConnectionTask<Socket>> call(InternetAddress address, int port) {
    dialed.add(address);
    return Socket.startConnect(
      InternetAddress.loopbackIPv4,
      portFor(address, port),
    );
  }
}

/// A resolver backed by a map; unknown names fail like a missing DNS entry.
class FakeResolver {
  FakeResolver(this.answers);

  final Map<String, List<String>> answers;
  final lookups = <String>[];

  Future<List<InternetAddress>> call(String host) async {
    lookups.add(host);
    final answer = answers[host];
    if (answer == null) throw SocketException('no such host: $host');
    return [for (final a in answer) InternetAddress(a)];
  }
}

/// A dialer whose connection never completes until it is cancelled.
class HangingDialer {
  int dialed = 0;
  int cancelled = 0;

  Future<ConnectionTask<Socket>> call(InternetAddress address, int port) async {
    dialed++;
    final socket = Completer<Socket>();
    return ConnectionTask.fromSocket(socket.future, () {
      cancelled++;
      if (!socket.isCompleted) {
        socket.completeError(const SocketException('cancelled'));
      }
    });
  }
}
