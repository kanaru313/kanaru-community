import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/net/fetcher.dart' show defaultUserAgent;
import 'package:kanaru/src/plugins/data/net/plugin_http.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';
import 'package:kanaru/src/plugins/domain/net/plugin_fetch_rules.dart';

import 'net_test_support.dart';

void main() {
  late TestServer tls;
  late RecordingDialer dialer;
  late FakeResolver resolver;

  setUp(() async {
    tls = await TestServer.start(secure: true);
    dialer = RecordingDialer((_, _) => tls.port);
    resolver = FakeResolver({
      'repo.example.test': [fakePublicIp],
      'mixed.test': [fakePublicIp, '10.0.0.1'],
      'inner.test': ['10.1.2.3'],
      'loop.test': ['127.0.0.1'],
      'mapped.test': ['::ffff:127.0.0.1'],
    });
  });

  tearDown(() => tls.close());

  PluginHttpClient client({Duration connect = const Duration(seconds: 5)}) =>
      PluginHttpClient(
        resolver: resolver.call,
        dialer: dialer.call,
        context: trustingTestCert(),
        connectLimit: connect,
      );

  PluginHttpRequest request({
    String method = 'GET',
    String host = 'repo.example.test',
    String path = '/',
    Map<String, String> headers = const {},
    List<int> body = const [],
  }) => PluginHttpRequest(
    method: method,
    url: Uri.parse('https://$host:${tls.port}$path'),
    headers: headers,
    body: Uint8List.fromList(body),
  );

  Future<PluginHttpResponse> ok(
    Future<Result<PluginHttpResponse, PluginHttpFailure>> call,
  ) async => switch (await call) {
    Ok(:final value) => value,
    Err(:final error) => fail('expected an answer, got $error'),
  };

  Future<PluginHttpFailure> failed(
    Future<Result<PluginHttpResponse, PluginHttpFailure>> call,
  ) async => switch (await call) {
    Err(:final error) => error,
    Ok() => fail('expected a failure'),
  };

  const deadline = Duration(seconds: 5);

  test('a POST body and the given headers reach the server', () async {
    String? seenBody;
    String? seenType;
    String? seenLength;
    tls.handler = (r) async {
      seenBody = await utf8.decoder.bind(r).join();
      seenType = r.headers.value('content-type');
      seenLength = r.headers.value('content-length');
      r.response.headers.set('x-answer', 'yes');
      r.response.write('pong');
      await r.response.close();
    };
    final answer = await ok(
      client().send(
        request(
          method: 'POST',
          headers: {'content-type': 'application/json', 'x-key': 'abc'},
          body: utf8.encode('{"a":1}'),
        ),
        deadline: deadline,
      ),
    );
    expect(seenBody, '{"a":1}');
    expect(seenType, 'application/json');
    expect(seenLength, '7');
    expect(tls.requests.single.headers.value('x-key'), 'abc');
    expect(answer.status, 200);
    expect(utf8.decode(answer.body), 'pong');
    expect(answer.headers, contains(('x-answer', 'yes')));
  });

  test(
    'the default user agent is sent only when the script set none',
    () async {
      tls.handler = (r) async => r.response.close();
      await ok(client().send(request(), deadline: deadline));
      await ok(
        client().send(
          request(headers: {'user-agent': 'Script/1'}),
          deadline: deadline,
        ),
      );
      expect(tls.userAgents, [defaultUserAgent, 'Script/1']);
    },
  );

  test('a redirect is returned as it is and never followed', () async {
    final target = await TestServer.start(secure: true);
    addTearDown(target.close);
    tls.handler = (r) async {
      r.response.statusCode = 302;
      r.response.headers.set(
        'location',
        'https://repo.example.test:${target.port}/x',
      );
      await r.response.close();
    };
    final answer = await ok(client().send(request(), deadline: deadline));
    expect(answer.status, 302);
    expect(
      answer.headers,
      contains(('location', 'https://repo.example.test:${target.port}/x')),
    );
    expect(tls.requests, hasLength(1));
    expect(target.requests, isEmpty);
  });

  test('429, 503 and 404 are answers with their body', () async {
    for (final status in [429, 503, 404, 500]) {
      tls.handler = (r) async {
        r.response.statusCode = status;
        r.response.headers.set('retry-after', '7');
        r.response.write('body$status');
        await r.response.close();
      };
      final answer = await ok(client().send(request(), deadline: deadline));
      expect(answer.status, status);
      expect(utf8.decode(answer.body), 'body$status');
      expect(answer.headers, contains(('retry-after', '7')));
    }
  });

  test('every Set-Cookie value is kept, names are lower-case', () async {
    tls.handler = (r) async {
      r.response.headers.add('Set-Cookie', 'a=1; Path=/');
      r.response.headers.add('Set-Cookie', 'b=2; Path=/');
      await r.response.close();
    };
    final answer = await ok(client().send(request(), deadline: deadline));
    expect(
      answer.headers.where((h) => h.$1 == 'set-cookie').map((h) => h.$2),
      containsAll(['a=1; Path=/', 'b=2; Path=/']),
    );
  });

  group('body cap', () {
    test('exactly 4 MiB arrives', () async {
      tls.handler = (r) async {
        r.response.add(Uint8List(pluginMaxResponseBytes));
        await r.response.close();
      };
      final answer = await ok(client().send(request(), deadline: deadline));
      expect(answer.body, hasLength(pluginMaxResponseBytes));
    });

    test('one byte more is too large', () async {
      tls.handler = (r) async {
        r.response.add(Uint8List(pluginMaxResponseBytes + 1));
        await r.response.close();
      };
      expect(
        await failed(client().send(request(), deadline: deadline)),
        PluginHttpFailure.tooLarge,
      );
    });
  });

  group('deadline', () {
    test('a slow answer inside a larger deadline arrives', () async {
      tls.handler = (r) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        r.response.write('late');
        await r.response.close();
      };
      final answer = await ok(
        client().send(request(), deadline: const Duration(seconds: 4)),
      );
      expect(utf8.decode(answer.body), 'late');
    });

    test('the timeout is the given deadline and closes the socket', () async {
      final closed = Completer<void>();
      tls.handler = (r) async {
        final socket = await r.response.detachSocket(writeHeaders: false);
        socket.listen((_) {}, onDone: closed.complete, onError: (_) {});
        await closed.future;
      };
      final clock = Stopwatch()..start();
      final failure = await failed(
        client().send(request(), deadline: const Duration(milliseconds: 400)),
      );
      expect(failure, PluginHttpFailure.timeout);
      expect(clock.elapsed, lessThan(const Duration(seconds: 3)));
      await closed.future.timeout(const Duration(seconds: 3));
    });

    test('a cancel stops the exchange and closes the socket', () async {
      final closed = Completer<void>();
      final arrived = Completer<void>();
      tls.handler = (r) async {
        final socket = await r.response.detachSocket(writeHeaders: false);
        socket.listen((_) {}, onDone: closed.complete, onError: (_) {});
        arrived.complete();
        await closed.future;
      };
      final cancel = CancelToken();
      final call = client().send(request(), deadline: deadline, cancel: cancel);
      await arrived.future.timeout(const Duration(seconds: 3));
      cancel.cancel();
      expect(await failed(call), PluginHttpFailure.cancelled);
      await closed.future.timeout(const Duration(seconds: 3));
      expect(cancel.listenerCount, 0);
    });

    test('a token already cancelled sends nothing', () async {
      final cancel = CancelToken()..cancel();
      expect(
        await failed(
          client().send(request(), deadline: deadline, cancel: cancel),
        ),
        PluginHttpFailure.cancelled,
      );
      expect(dialer.dialed, isEmpty);
      expect(resolver.lookups, isEmpty);
    });
  });

  group('public only', () {
    for (final host in [
      'inner.test',
      'loop.test',
      'mixed.test',
      'mapped.test',
    ]) {
      test('$host is refused after the lookup and never dialed', () async {
        expect(
          await failed(client().send(request(host: host), deadline: deadline)),
          PluginHttpFailure.blockedAddress,
        );
        expect(resolver.lookups, [host]);
        expect(dialer.dialed, isEmpty);
        expect(tls.requests, isEmpty);
      });
    }

    test('an IP literal is judged without a lookup', () async {
      expect(
        await failed(
          client().send(request(host: '10.0.0.1'), deadline: deadline),
        ),
        PluginHttpFailure.blockedAddress,
      );
      expect(resolver.lookups, isEmpty);
      expect(dialer.dialed, isEmpty);
    });

    test('an unknown name is a network failure', () async {
      expect(
        await failed(
          client().send(request(host: 'nowhere.test'), deadline: deadline),
        ),
        PluginHttpFailure.network,
      );
    });

    test('a certificate for another name fails the connection', () async {
      resolver.answers['other.example.test'] = [fakePublicIp];
      expect(
        await failed(
          client().send(
            request(host: 'other.example.test'),
            deadline: deadline,
          ),
        ),
        PluginHttpFailure.network,
      );
      expect(tls.requests, isEmpty);
    });

    test('a socket that connects after a cancel is never used', () async {
      final release = Completer<void>();
      Future<ConnectionTask<Socket>> slowDial(InternetAddress a, int p) async {
        await release.future;
        return Socket.startConnect(InternetAddress.loopbackIPv4, tls.port);
      }

      final slow = PluginHttpClient(
        resolver: resolver.call,
        dialer: slowDial,
        context: trustingTestCert(),
      );
      final cancel = CancelToken();
      final call = slow.send(request(), deadline: deadline, cancel: cancel);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cancel.cancel();
      release.complete();
      expect(await failed(call), PluginHttpFailure.cancelled);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(tls.requests, isEmpty);
    });

    test('an untrusted certificate fails the connection', () async {
      final strict = PluginHttpClient(
        resolver: resolver.call,
        dialer: dialer.call,
        context: SecurityContext(withTrustedRoots: false),
      );
      expect(
        await failed(strict.send(request(), deadline: deadline)),
        PluginHttpFailure.network,
      );
      expect(tls.requests, isEmpty);
    });
  });
}
