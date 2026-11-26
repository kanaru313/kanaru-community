import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http_stream.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';

import 'net_test_support.dart';

const _greeting = ': open\n\n';

void main() {
  late TestServer tls;
  late PluginHttpStreamClient streams;
  var clientGone = Completer<void>();

  setUp(() async {
    clientGone = Completer();
    tls = await TestServer.start(secure: true);
    final dialer = RecordingDialer((_, _) => tls.port);
    final resolver = FakeResolver({
      'repo.example.test': [fakePublicIp],
      'inner.test': ['10.1.2.3'],
    });
    streams = PluginHttpStreamClient(
      PluginHttpClient(
        resolver: resolver.call,
        dialer: dialer.call,
        context: trustingTestCert(),
      ),
    );
  });

  tearDown(() => tls.close());

  PluginHttpRequest request({
    String method = 'GET',
    String host = 'repo.example.test',
    List<int> body = const [],
  }) => PluginHttpRequest(
    method: method,
    url: Uri.parse('https://$host:${tls.port}/'),
    headers: const {},
    body: Uint8List.fromList(body),
  );

  Future<PluginHttpStreamHandle> open({
    PluginHttpRequest? req,
    CancelToken? cancel,
    Duration? lifetime,
  }) async => switch (await streams.open(
    req ?? request(),
    deadline: const Duration(seconds: 5),
    cancel: cancel,
    lifetime: lifetime,
  )) {
    Ok(:final value) => value,
    Err(:final error) => fail('expected a handle, got $error'),
  };

  Future<PluginHttpFailure> openFails({
    PluginHttpRequest? req,
    CancelToken? cancel,
  }) async => switch (await streams.open(
    req ?? request(),
    deadline: const Duration(seconds: 5),
    cancel: cancel,
  )) {
    Err(:final error) => error,
    Ok() => fail('expected a failure'),
  };

  Future<Result<PluginStreamRead, PluginHttpFailure>> read(
    PluginHttpStreamHandle h, {
    int max = pluginMaxStreamRead,
    Duration wait = const Duration(seconds: 5),
  }) => h.read(maxBytes: max, wait: wait);

  /// Waits until the server sees no live connection.
  Future<void> expectNoSockets() async {
    for (var i = 0; i < 100; i++) {
      if (tls.server.connectionsInfo().total == 0) return;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(tls.server.connectionsInfo().total, 0);
  }

  /// Answers on the raw socket: the head and one SSE comment, then the body
  /// stays open. Records when the client drops the connection (the server only
  /// learns it by reading the raw socket).
  Future<Socket> openRaw(HttpResponse response) async {
    final socket = await response.detachSocket(writeHeaders: false);
    socket.listen(
      (_) {},
      onError: (_) {},
      onDone: () {
        if (!clientGone.isCompleted) clientGone.complete();
        socket.destroy();
      },
    );
    socket.write(
      'HTTP/1.1 200 OK\r\ncontent-type: text/event-stream\r\n'
      'transfer-encoding: chunked\r\n\r\n'
      '${_greeting.length.toRadixString(16)}\r\n$_greeting\r\n',
    );
    await socket.flush();
    return socket;
  }

  /// Never answers; ends when the client drops the connection.
  Future<void> hangSilently(HttpResponse response) async {
    final socket = await response.detachSocket(writeHeaders: false);
    socket.listen(
      (_) {},
      onError: (_) {},
      onDone: () {
        if (!clientGone.isCompleted) clientGone.complete();
        socket.destroy();
      },
    );
    await clientGone.future;
  }

  /// Keeps a handler busy until the client drops the connection.
  Future<void> hangOpen(HttpResponse response) async {
    await openRaw(response);
    await clientGone.future;
  }

  Future<void> finishRaw(Socket socket) async {
    socket.write('0\r\n\r\n');
    await socket.flush();
    await socket.close();
  }

  Future<void> expectClientGone() =>
      clientGone.future.timeout(const Duration(seconds: 2));

  /// Reads the greeting `openRaw` wrote.
  Future<void> skipGreeting(PluginHttpStreamHandle h) async {
    final got = await read(h) as Ok<PluginStreamRead, PluginHttpFailure>;
    expect(utf8.decode(got.value.bytes), _greeting);
  }

  test('reads a chunked SSE body in order', () async {
    final release = Completer<void>();
    tls.handler = (r) async {
      r.response.bufferOutput = false;
      r.response.headers.contentType = ContentType('text', 'event-stream');
      r.response.write('data: 1\n\n');
      await r.response.flush();
      await release.future;
      r.response.write('data: 2\n\n');
      await r.response.close();
    };
    final h = await open();
    expect(h.status, 200);
    expect(
      h.headers.any((e) => e.$1 == 'content-type' && e.$2.contains('event')),
      isTrue,
    );
    final first = (await read(h) as Ok<PluginStreamRead, PluginHttpFailure>);
    expect(utf8.decode(first.value.bytes), 'data: 1\n\n');
    release.complete();
    final second = (await read(h) as Ok<PluginStreamRead, PluginHttpFailure>);
    expect(utf8.decode(second.value.bytes), 'data: 2\n\n');
    final end = (await read(h) as Ok<PluginStreamRead, PluginHttpFailure>);
    expect(end.value.done, isTrue);
    await h.close();
    await expectNoSockets();
  });

  test('read waits up to the given time then reports idle', () async {
    final hold = Completer<void>();
    tls.handler = (r) async {
      final socket = await openRaw(r.response);
      await hold.future;
      await finishRaw(socket);
    };
    final h = await open();
    await skipGreeting(h);
    final clock = Stopwatch()..start();
    final got = await read(h, wait: const Duration(milliseconds: 150));
    expect(clock.elapsedMilliseconds, greaterThanOrEqualTo(140));
    expect((got as Ok<PluginStreamRead, PluginHttpFailure>).value.isIdle, true);
    // Still open: a later read works.
    hold.complete();
    final end = await read(h);
    expect((end as Ok<PluginStreamRead, PluginHttpFailure>).value.done, true);
    await h.close();
    await expectNoSockets();
  });

  test('body over 16 MiB fails tooLarge and closes', () async {
    final block = Uint8List(256 * 1024);
    tls.handler = (r) async {
      r.response.bufferOutput = false;
      for (var i = 0; i < 100; i++) {
        r.response.add(block);
        await r.response.flush();
      }
      await r.response.close();
    };
    final h = await open();
    PluginHttpFailure? failure;
    for (var i = 0; i < 100000 && failure == null; i++) {
      switch (await read(h)) {
        case Err(:final error):
          failure = error;
        case Ok(:final value):
          expect(value.done, isFalse);
      }
    }
    expect(failure, PluginHttpFailure.tooLarge);
    expect(await read(h), isA<Err<PluginStreamRead, PluginHttpFailure>>());
    await expectNoSockets();
  });

  test('cancel during header wait returns cancelled within 200 ms', () async {
    tls.handler = (r) => hangSilently(r.response);
    final cancel = CancelToken();
    final clock = Stopwatch()..start();
    final result = openFails(cancel: cancel);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final cancelledAt = clock.elapsedMilliseconds;
    cancel.cancel();
    expect(await result, PluginHttpFailure.cancelled);
    expect(clock.elapsedMilliseconds - cancelledAt, lessThan(200));
    await expectClientGone();
  });

  test('close before headers aborts the request', () async {
    tls.handler = (r) => hangSilently(r.response);
    final cancel = CancelToken();
    final result = openFails(cancel: cancel);
    while (tls.requests.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    cancel.cancel();
    expect(await result, PluginHttpFailure.cancelled);
    await expectClientGone();
    // A token that is already cancelled never reaches the server.
    final before = tls.requests.length;
    expect(await openFails(cancel: cancel), PluginHttpFailure.cancelled);
    expect(tls.requests.length, before);
  });

  test('lifetime passes → later read fails network, not done', () async {
    tls.handler = (r) async {
      await hangOpen(r.response);
    };
    final h = await open(lifetime: const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(
      await read(h, wait: const Duration(seconds: 1)),
      isA<Err<PluginStreamRead, PluginHttpFailure>>().having(
        (e) => e.error,
        'error',
        PluginHttpFailure.network,
      ),
    );
    await expectClientGone();
  });

  test('close fails a pending read with network and is idempotent', () async {
    tls.handler = (r) async {
      await hangOpen(r.response);
    };
    final h = await open();
    await skipGreeting(h);
    final pending = read(h);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await h.close();
    await h.close();
    expect(
      (await pending as Err<PluginStreamRead, PluginHttpFailure>).error,
      PluginHttpFailure.network,
    );
    expect(await read(h), isA<Err<PluginStreamRead, PluginHttpFailure>>());
    await expectClientGone();
  });

  test('cancel after open closes the handle', () async {
    tls.handler = (r) async {
      await hangOpen(r.response);
    };
    final cancel = CancelToken();
    final h = await open(cancel: cancel);
    cancel.cancel();
    expect(
      (await read(h) as Err<PluginStreamRead, PluginHttpFailure>).error,
      PluginHttpFailure.network,
    );
    expect(cancel.listenerCount, 0);
    await expectClientGone();
  });

  test('a body cut short fails network, not done', () async {
    tls.handler = (r) async {
      final socket = await r.response.detachSocket(writeHeaders: false);
      socket.write('HTTP/1.1 200 OK\r\ncontent-length: 100\r\n\r\nabc');
      await socket.flush();
      socket.destroy();
    };
    final h = await open();
    var sawFailure = false;
    for (var i = 0; i < 5 && !sawFailure; i++) {
      final got = await read(h, wait: const Duration(seconds: 2));
      if (got case Err(:final error)) {
        expect(error, PluginHttpFailure.network);
        sawFailure = true;
      } else if ((got as Ok<PluginStreamRead, PluginHttpFailure>).value.done) {
        fail('a cut body must not read done');
      }
    }
    expect(sawFailure, isTrue);
    await expectNoSockets();
  });

  test('real EOF reads done', () async {
    tls.handler = (r) async {
      r.response.write('abc');
      await r.response.close();
    };
    final h = await open();
    final a = await read(h) as Ok<PluginStreamRead, PluginHttpFailure>;
    expect(utf8.decode(a.value.bytes), 'abc');
    final b = await read(h) as Ok<PluginStreamRead, PluginHttpFailure>;
    expect(b.value.done, isTrue);
    await h.close();
    await expectNoSockets();
  });

  test('name resolving to a private address is blocked', () async {
    expect(
      await openFails(req: request(host: 'inner.test')),
      PluginHttpFailure.blockedAddress,
    );
    expect(tls.requests, isEmpty);
    await expectNoSockets();
  });

  test('3xx is returned as an answer', () async {
    tls.handler = (r) async {
      r.response.statusCode = 302;
      r.response.headers.set('location', 'https://other.test/');
      await r.response.close();
    };
    final h = await open();
    expect(h.status, 302);
    expect(h.headers, contains(('location', 'https://other.test/')));
    expect(tls.requests.length, 1);
    await h.close();
    await expectNoSockets();
  });

  test('sends a 1 MiB body', () async {
    final sent = Uint8List.fromList(List.generate(1 << 20, (i) => i % 251));
    var received = 0;
    var intact = false;
    tls.handler = (r) async {
      final got = await r.fold<List<int>>([], (a, b) => a..addAll(b));
      received = got.length;
      intact =
          got.length == sent.length &&
          Iterable<int>.generate(got.length).every((i) => got[i] == sent[i]);
      r.response.write('ok');
      await r.response.close();
    };
    final h = await open(
      req: request(method: 'POST', body: sent),
    );
    final got = await read(h) as Ok<PluginStreamRead, PluginHttpFailure>;
    expect(utf8.decode(got.value.bytes), 'ok');
    expect(received, 1 << 20);
    expect(intact, isTrue);
    await h.close();
    await expectNoSockets();
  });
}
