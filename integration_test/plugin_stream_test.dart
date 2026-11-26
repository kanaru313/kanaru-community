import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http_stream.dart';
import 'package:kanaru/src/plugins/data/run/fetch_handler.dart';
import 'package:kanaru/src/plugins/data/run/plugin_limiter.dart';
import 'package:kanaru/src/plugins/data/run/plugin_pauses.dart';
import 'package:kanaru/src/plugins/data/run/plugin_runner.dart';
import 'package:kanaru/src/plugins/data/run/run_admission.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/data/run/run_log_recorder.dart';
import 'package:kanaru/src/plugins/data/run/rust_plugin_engine.dart';
import 'package:kanaru/src/plugins/data/run/stream_fetch_handler.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';
import 'package:kanaru/src/platform/data/native_library.dart';

import '../test/plugins/data/install_test_support.dart';
import '../test/plugins/domain/plugin_test_support.dart';
import '../test/plugins/fixtures/zip_builders.dart';

/// The streaming round trip on the real plugin runtime (Linux): a script
/// opens `fetch({stream: true})` to a local SSE server, reads it line by line
/// and `emit`s each event, through the real runner, stream handler and HTTP
/// stream client.
///
/// The server is on loopback, which the app never allows a plugin to reach.
/// It is reached here only because this test builds its own
/// [PluginHttpClient]: a resolver that answers a public address for
/// `stream.example.com`, a dialer that sends the connection to the server, and a
/// security context that trusts the test certificate. Nothing in `lib/` is
/// changed and no provider of the app is used.
///
/// Run (through the main checkout's `main-build.sh`):
/// `flutter test integration_test/plugin_stream_test.dart -d linux`

const _host = 'stream.example.com';

/// What the script does: opens the stream at `input.path`, emits the parsed payload
/// of every `data:` line, answers the number of events.
const _script =
    """
function execute(input) {
  var r = fetch('https://$_host' + input.path, {stream: true});
  var line, n = 0;
  while ((line = r.readLine()) !== null) {
    if (line.indexOf('data: ') === 0) { emit(JSON.parse(line.slice(6))); n++; }
  }
  r.close();
  return Response.success({n: n});
}
""";

/// A self-signed, test-only certificate and key for `stream.example.com`.
const _certPem = """-----BEGIN CERTIFICATE-----
MIIDPDCCAiSgAwIBAgIUGat58+Qe/98NB7VtKKSkFpudfSswDQYJKoZIhvcNAQEL
BQAwHTEbMBkGA1UEAwwSc3RyZWFtLmV4YW1wbGUuY29tMCAXDTI2MTEyNjE4MTky
N1oYDzIxMjYxMTAyMTgxOTI3WjAdMRswGQYDVQQDDBJzdHJlYW0uZXhhbXBsZS5j
b20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC5ZArvueqBe3DxWenr
ZmCfD3/L1jHZt8+9gvxgkQAlA2D8+cbJd1kadjLZue3eLvdIAYKn4sz7SgU/x3BC
rz29V7h/rH+l9liFn0xK1ZQ1zerpT1MkHwKGJ8qFkabpvEW+Wea2hNr3DTLO3tZP
8Zre7yyAEBIfXnWqpH8J363kknnJMcX3PNBkzFy7qm8/7zy1YMPSiie2EaX9CsYO
lftV5MKz0+e5/eCDbvx164ssL9qUM8r3crh6QZLYxLWVOap2aUvrd2Xi9M/5SZsb
NXcCAQ/0HpCQ5HylWkhgkbrA1tPFf17jshEf/+JeinhSgh91FZdEKnwbT7upLxyE
C6dbAgMBAAGjcjBwMB0GA1UdDgQWBBRAsMCSp2LUNdmPYJ0UAPzMYp3RUjAfBgNV
HSMEGDAWgBRAsMCSp2LUNdmPYJ0UAPzMYp3RUjAdBgNVHREEFjAUghJzdHJlYW0u
ZXhhbXBsZS5jb20wDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEA
XhfOl0DBaPKcw7qoHf20rz3PGhhaLKi0DhB3MT3tukllNoGcTxK1zxkGJHgryIo2
otOEI09WgFy396nq02E7jnLqIryTA4lDPMXQ380oJOg8CqjTdW1hiiZilX/PtxU/
wvVXL8l0U4zdCl6EzQO7OqRnyxmHkRBBIfSgS3d2lw1ZCE+rmD/0g6yqWty3lR06
W2EG7aD/BWaUOygv7Ru8ksbqUQ18nmgw6VfJAlKVwb280nY3DimiWpmbPhG6WHr4
s/bT/zV6KUCjcnFarKF8pwTx6VV/hWhhrxDKsyL9Vwm3p4Q95jyo3LEO5LBSqzpD
VNh9WWmWjCakqwtmc3Wfig==
-----END CERTIFICATE-----""";
const _keyPem = """-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC5ZArvueqBe3Dx
WenrZmCfD3/L1jHZt8+9gvxgkQAlA2D8+cbJd1kadjLZue3eLvdIAYKn4sz7SgU/
x3BCrz29V7h/rH+l9liFn0xK1ZQ1zerpT1MkHwKGJ8qFkabpvEW+Wea2hNr3DTLO
3tZP8Zre7yyAEBIfXnWqpH8J363kknnJMcX3PNBkzFy7qm8/7zy1YMPSiie2EaX9
CsYOlftV5MKz0+e5/eCDbvx164ssL9qUM8r3crh6QZLYxLWVOap2aUvrd2Xi9M/5
SZsbNXcCAQ/0HpCQ5HylWkhgkbrA1tPFf17jshEf/+JeinhSgh91FZdEKnwbT7up
LxyEC6dbAgMBAAECggEABz6aks2gFVk+i5/o3TMN+YlAhDWlkw10x8ITnK5t5ARi
yN/13a+VQsx1pj52xiTtstmkQm1Bd1xoIhroDyML9Zc09YBHKLQct3QHJjF8bjHS
yTU5WYMAtT9e0aNkc2PREeQveNhuOhNA9gaNN2iIlceg5Iw8OQ+W54kwEbG0+OaT
WttYT+JQXb63hcUAv8BLubvlBqxkiEsZyTazA5jn042hPeZ2XyfTZUzwn9Krg0Gv
CTT2HIYxOYPGRXySaf0ZdD6SqmTU1criSXk1fZ6bLpPoC3XPQ0bc4iNPJDzBxxqv
JKdg9+r2XMdzJk2HQWBTe5t0wOobZwnUrQA1yF8gYQKBgQDqujhMoRS2HW4zoB4O
bITiL/0/SMKwElOqd8LjBXryEteKYWZ3XbJHx1IxON8qBhp9oXvaqDPMgiT/GPGU
TaeClau0BT6JE97S0IxGEMRj6pL6N73Pgz40khWQu2TY5afT9IBV+Av/CY6wtDX4
0vm3YB0tIWZUnGmpc0k5V9NKcQKBgQDKMTDvd65TQCmN62ojxjdTa7ybX1qW29tc
830+RTCvc3yya9jep9iWH4pCNzig7mK0IABHU7azOHyPn/PtWANeBbk0PdaT+Zju
B4DCaktovVs64npFl8hzwhS1Sp7vqigTxlkjLjrI15XjBVOkfkZySNswnwgYlkQp
t9vQHzv8iwKBgB5jz8g0Dr9pXgw3Dc0mRaoXNn2MCRDMvqJScRv9aKaQw/E5nQ+V
RPDAIKcYyuPg+GsNjkCICHTQ4MNaUmS2DRr+D8X169vJg87di1vC7fpVs4PL1bpZ
LqOVyk77xBnE2g66GCeJPtxdO2krW9WEUypnuj9OlLYdrhxvPaq78TIxAoGBAMTm
rq8lr+Bm5ZDNpyl7iLl2e9AbRg8PwEp+3ILdwpG6N79Rg3shnaxkvrHJMR6XyAt9
9od/oLZb1gHQVS3Xvj+79yZG6kZklWeIav3podI4RTXNBCHttEn2wU/jgXAIFstb
J8c46Apa2B6jO1c/mb8F8F8jIDFBdNPjtu6w3CwNAoGBAISrMYkdJnLyLeegRRBA
fjIsPxLVDd2yoKVODNf/bnSxUr1icQlL6Xp5QRm84Duq/63yEE9RGl+Ltm5IjpY0
RDlI1hnNlwVJ/7USPKjYkkBatHoPxdiMhybwXCYzRZffi6qG39KuZUBJiIdUDqAh
engTdPR2gSUFsAxVi8KUOsL4
-----END PRIVATE KEY-----""";

/// A TLS server on loopback with a few behaviours chosen by path.
class _SseServer {
  _SseServer._(this.server);

  final HttpServer server;

  /// Paths of the requests that reached the handler, in order.
  final requests = <String>[];

  /// Completed to let a held answer go on.
  final release = Completer<void>();

  static Future<_SseServer> start() async {
    final context = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(_certPem))
      ..usePrivateKeyBytes(utf8.encode(_keyPem));
    final server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    // The client asks for gzip; a compressed body is not sent until it ends,
    // which would hide every event of a held stream.
    server.autoCompress = false;
    final sse = _SseServer._(server);
    server.listen((request) async {
      sse.requests.add(request.uri.path);
      try {
        await sse._answer(request);
      } on Object {
        // The client went away mid-answer: expected in the cancel cases.
      }
    }, onError: (_) {});
    return sse;
  }

  Future<void> _event(HttpResponse response, int n) async {
    response.write('data: {"n":$n}\n\n');
    await response.flush();
  }

  /// Writes comment lines until [release]; returns when a write fails.
  Future<void> _pingUntilGone(HttpResponse response) async {
    while (!release.isCompleted) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      try {
        response.write(': ping\n\n');
        await response.flush();
      } on Object {
        return;
      }
    }
  }

  Future<void> _answer(HttpRequest request) async {
    final response = request.response;
    // Without this the server holds a body back until the response closes.
    response.bufferOutput = false;
    response.headers.contentType = ContentType('text', 'event-stream');
    switch (request.uri.path) {
      case '/three':
        for (var i = 1; i <= 3; i++) {
          await _event(response, i);
        }
        await response.close();
      case '/mid':
        // Two events, then pings until [release]. A ping that cannot be
        // written means the client left: the connection is then finished.
        await _event(response, 1);
        await _event(response, 2);
        await _pingUntilGone(response);
        await response.close();
      case '/slow-head':
        // No byte of the head until [release]: the open stays pending. The
        // raw socket shows when the client leaves.
        final socket = await response.detachSocket(writeHeaders: false);
        final left = Completer<void>();
        socket.listen(
          (_) {},
          onDone: left.complete,
          onError: (Object _) => left.complete(),
        );
        await Future.any([release.future, left.future]);
        socket.destroy();
      case '/held':
        // One event, then the stream stays open until [release].
        await _event(response, 1);
        await release.future;
        await _event(response, 2);
        await response.close();
      default:
        response.statusCode = 404;
        await response.close();
    }
  }

  /// Open connections (active plus idle).
  int get connections {
    final info = server.connectionsInfo();
    return info.total;
  }

  Future<void> close() async {
    if (!release.isCompleted) release.complete();
    await server.close(force: true);
  }
}

/// Spins the event loop until [done]; fails with [what] after [timeout].
Future<void> _until(
  bool Function() done,
  String what, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (!done()) {
    if (DateTime.now().isAfter(end)) fail('timed out waiting for: $what');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _SseServer server;
  late InstallHarness h;
  late PluginRunner runner;
  late PluginPauses pauses;
  late RunAdmission streamAdmission;
  late String installId;

  setUpAll(() async {
    await loadNativeLibrary();
  });

  Future<void> build({
    Duration grace = const Duration(seconds: 1),
    Duration settle = const Duration(milliseconds: 500),
  }) async {
    server = await _SseServer.start();
    final context = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(utf8.encode(_certPem));
    final http = PluginHttpClient(
      resolver: (name) async => [InternetAddress('93.184.216.34')],
      dialer: (_, _) =>
          Socket.startConnect(InternetAddress.loopbackIPv4, server.server.port),
      context: context,
    );
    final limiter = PluginLimiter();
    h = InstallHarness();
    pauses = PluginPauses();
    streamAdmission = RunAdmission(slots: 1);
    runner = PluginRunner(
      engine: const RustPluginEngine(),
      handler: HttpPluginFetchHandler(http: http, limiter: limiter),
      gate: h.runGate,
      pauses: pauses,
      rows: h.rows,
      files: h.files,
      config: h.config,
      storage: h.storage,
      recorder: RunLogRecorder(
        log: h.logs,
        rows: h.rows,
        config: h.config,
        storage: h.storage,
      ),
      streamAdmission: streamAdmission,
      streamHandler: StreamFetchHandler(
        http: PluginHttpStreamClient(http),
        limiter: limiter,
      ),
      grace: grace,
      settle: settle,
    );
    final manifest = withMeta((m) => m['hosts'] = [_host]);
    final held = await h.prepareFile(
      validZip(manifest: manifest, extra: {'src/search.js': _script}),
    );
    final result = await h.actions.installer.install(held.token);
    if (result is! Installed) fail('install failed: $result');
    installId = fileInstallId('Demo', 'someone');
  }

  PluginRunRequest request(
    String path, {
    required void Function(String) onEvent,
    Duration timeout = const Duration(seconds: 30),
  }) => PluginRunRequest(
    installId: installId,
    script: 'search',
    input: {'path': path},
    timeout: timeout,
    persistStorage: false,
    stream: StreamOptions(idle: const Duration(seconds: 30), onEvent: onEvent),
  );

  Future<void> noConnectionsLeft() => _until(
    () => server.connections == 0,
    'the server to have no open connection',
  );

  tearDown(() async {
    pauses.dispose();
    await server.close();
    await h.dispose();
  });

  test('events arrive in order before the outcome', () async {
    await build();
    final order = <String>[];
    final outcome = await runner.run(request('/three', onEvent: order.add));
    order.add('outcome');

    expect(outcome, isA<RunOk>(), reason: '$outcome');
    expect(order, ['{"n":1}', '{"n":2}', '{"n":3}', 'outcome']);
    expect((outcome as RunOk).outputJson, '{"n":3}');
    expect(server.requests, ['/three']);
    await noConnectionsLeft();
  });

  test('stop in the middle of a read ends the run cancelled', () async {
    await build();
    final events = <String>[];
    final cancel = RunCancel();
    final run = runner.run(
      request('/mid', onEvent: events.add),
      cancel: cancel,
    );
    await _until(() => events.length == 2, 'two events');

    cancel.cancel();

    final outcome = await run.timeout(const Duration(seconds: 10));
    expect(outcome, isA<RunCancelled>(), reason: '$outcome');
    expect((outcome as RunCancelled).reason, RunCancelReason.caller);
    expect(events, ['{"n":1}', '{"n":2}']);
    await noConnectionsLeft();
    // The slot is free again: the next streaming run starts at once.
    expect(streamAdmission.inUse, 0);
  });

  test('stop while the open is pending closes the connection', () async {
    await build();
    final events = <String>[];
    final cancel = RunCancel();
    final run = runner.run(
      request('/slow-head', onEvent: events.add),
      cancel: cancel,
    );
    await _until(() => server.requests.isNotEmpty, 'the request to arrive');
    // Give the script time to be blocked in the open.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    cancel.cancel();

    final outcome = await run.timeout(const Duration(seconds: 10));
    expect(outcome, isA<RunCancelled>(), reason: '$outcome');
    expect(events, isEmpty);
    await noConnectionsLeft();
    expect(streamAdmission.inUse, 0);
  });

  test('the outer deadline ends a silent stream as a timeout', () async {
    await build(grace: const Duration(milliseconds: 300));
    final events = <String>[];
    final started = Stopwatch()..start();
    final outcome = await runner.run(
      request('/mid', onEvent: events.add, timeout: const Duration(seconds: 2)),
    );

    expect(outcome, isA<RunFailed>(), reason: '$outcome');
    expect((outcome as RunFailed).reason, RunFailReason.timeout);
    expect(started.elapsed, lessThan(const Duration(seconds: 8)));
    expect(events, ['{"n":1}', '{"n":2}']);
    await noConnectionsLeft();
    await _until(
      () => streamAdmission.inUse == 0,
      'the stream slot to be free',
    );
  });

  test('a second stream run waits for the slot, then runs', () async {
    await build();
    final first = <String>[];
    final second = <String>[];
    final a = runner.run(request('/held', onEvent: first.add));
    await _until(() => first.length == 1, 'the first run to hold the slot');

    final b = runner.run(request('/three', onEvent: second.add));
    await _until(() => streamAdmission.waiting == 1, 'the second run to wait');
    // Waiting means nothing was sent for it.
    expect(server.requests, ['/held']);
    expect(second, isEmpty);

    server.release.complete();

    final outcomeA = await a.timeout(const Duration(seconds: 10));
    final outcomeB = await b.timeout(const Duration(seconds: 10));
    expect(outcomeA, isA<RunOk>(), reason: '$outcomeA');
    expect(outcomeB, isA<RunOk>(), reason: '$outcomeB');
    expect(first, ['{"n":1}', '{"n":2}']);
    expect(second, ['{"n":1}', '{"n":2}', '{"n":3}']);
    expect(server.requests, ['/held', '/three']);
    await noConnectionsLeft();
  });
}
