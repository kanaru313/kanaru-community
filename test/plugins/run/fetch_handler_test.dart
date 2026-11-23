import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';
import 'package:kanaru/src/plugins/data/run/fetch_handler.dart';
import 'package:kanaru/src/plugins/data/run/plugin_limiter.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

import '../net/net_test_support.dart';

const _id = 'plug-1';
const _host = 'repo.example.test';

void main() {
  late TestServer server;
  late RecordingDialer dialer;
  late FakeResolver resolver;

  setUp(() async {
    server = await TestServer.start(secure: true);
    dialer = RecordingDialer((_, _) => server.port);
    resolver = FakeResolver({
      _host: [fakePublicIp],
      'private.example.test': ['10.0.0.9'],
      'my.server.example': [fakePublicIp],
    });
  });

  tearDown(() => server.close());

  HttpPluginFetchHandler handler({PluginLimiter? limiter}) =>
      HttpPluginFetchHandler(
        http: PluginHttpClient(
          resolver: resolver.call,
          dialer: dialer.call,
          context: trustingTestCert(),
        ),
        limiter: limiter ?? PluginLimiter(spacing: Duration.zero),
      );

  JobContext job({
    Set<String> manifest = const {_host},
    Set<String> consented = const {_host},
    Set<String> endpoints = const {},
    RunCancel? cancel,
  }) => JobContext(
    installId: _id,
    job: 1,
    cancel: cancel ?? RunCancel(),
    manifestHosts: manifest,
    consentedHosts: consented,
    userEndpoints: endpoints,
  );

  EngineFetchRequest req(
    String url, {
    String installId = _id,
    String method = 'GET',
    List<(String, String)> headers = const [],
    List<int> body = const [],
    int deadlineMs = 5000,
  }) => EngineFetchRequest(
    installId: installId,
    method: method,
    url: url,
    headers: headers,
    body: Uint8List.fromList(body),
    deadlineMs: deadlineMs,
    maxSends: 10,
  );

  // No port: the dialer sends every connection to the loopback server.
  String onServer(String path, {String host = _host}) => 'https://$host$path';

  void expectNothingSent() {
    expect(resolver.lookups, isEmpty);
    expect(dialer.dialed, isEmpty);
    expect(server.requests, isEmpty);
  }

  group('refused before anything is sent', () {
    test('an install id that is not the job\'s', () async {
      final r = await handler().handle(
        req(onServer('/'), installId: 'other'),
        job(),
      );
      expect(r.outcome, EngineFetchOutcome.invalidRequest);
      expectNothingSent();
    });

    test('a cancelled job is abandoned', () async {
      final cancel = RunCancel()..cancel();
      final r = await handler().handle(req(onServer('/')), job(cancel: cancel));
      expect(r.outcome, EngineFetchOutcome.abandoned);
      expectNothingSent();
    });

    test('no consented host is not consented', () async {
      final r = await handler().handle(req(onServer('/')), job(consented: {}));
      expect(r.outcome, EngineFetchOutcome.notConsented);
      expectNothingSent();
    });

    test('blocked urls', () async {
      for (final url in [
        'http://$_host/',
        'https://u:p@$_host/',
        'https://93.184.216.34/',
        'https://localhost/',
        'https://$_host:8443/',
        'https://unlisted.example.test/',
        'ftp://$_host/',
      ]) {
        final r = await handler().handle(req(url), job());
        expect(r.outcome, EngineFetchOutcome.blockedHost, reason: url);
      }
      expectNothingSent();
    });

    test('a url that is not a url is an invalid request', () async {
      final r = await handler().handle(req('not a url'), job());
      expect(r.outcome, EngineFetchOutcome.invalidRequest);
      expectNothingSent();
    });

    test('bad header, method or body', () async {
      final cases = [
        req(onServer('/'), headers: [('x-a', 'a\r\nb: c')]),
        req(onServer('/'), headers: [('bad name', 'x')]),
        req(onServer('/'), method: 'DELETE'),
        req(onServer('/'), method: 'GET', body: [1]),
      ];
      for (final c in cases) {
        final r = await handler().handle(c, job());
        expect(r.outcome, EngineFetchOutcome.invalidRequest);
      }
      expectNothingSent();
    });

    test('a spacing wait that leaves under a second sends nothing', () async {
      final limiter = PluginLimiter(spacing: const Duration(seconds: 2));
      await limiter.acquire(_id, timeLeft: const Duration(seconds: 30));
      final r = await handler(limiter: limiter)
          .handle(req(onServer('/'), deadlineMs: 1500), job());
      expect(r.outcome, EngineFetchOutcome.network);
      expectNothingSent();
    });

    test('a cancel during the spacing wait is abandoned', () async {
      final limiter = PluginLimiter(spacing: const Duration(seconds: 3));
      await limiter.acquire(_id, timeLeft: const Duration(seconds: 30));
      final cancel = RunCancel();
      final pending = handler(limiter: limiter)
          .handle(req(onServer('/'), deadlineMs: 20000), job(cancel: cancel));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      cancel.cancel();
      expect((await pending).outcome, EngineFetchOutcome.abandoned);
      expectNothingSent();
    });
  });

  test(
    'a private resolution of an allowed name is blocked, not dialed',
    () async {
      final r = await handler().handle(
        req(onServer('/', host: 'private.example.test')),
        job(
          manifest: {'private.example.test'},
          consented: {'private.example.test'},
        ),
      );
      expect(r.outcome, EngineFetchOutcome.blockedHost);
      expect(resolver.lookups, ['private.example.test']);
      expect(dialer.dialed, isEmpty);
    },
  );

  group('user endpoints', () {
    test('a saved url with a port allows that host and port', () async {
      server.handler = (r) async => r.response.close();
      final ctx = job(
        manifest: {'x.example.com'},
        consented: {'x.example.com'},
        endpoints: {'https://$_host:${server.port}'},
      );
      final r = await handler().handle(
        req('https://$_host:${server.port}/v1'),
        ctx,
      );
      expect(r.outcome, EngineFetchOutcome.ok);
      expect(server.requests, hasLength(1));
    });

    test('a saved url without a port allows the default port only', () async {
      server.handler = (r) async => r.response.close();
      final ctx = job(
        manifest: {'x.example.com'},
        consented: {'x.example.com'},
        endpoints: {'https://$_host'},
      );
      final withPort = await handler().handle(
        req('https://$_host:${server.port}/'),
        ctx,
      );
      expect(withPort.outcome, EngineFetchOutcome.blockedHost);
      expectNothingSent();
      final plain = await handler().handle(req('https://$_host/'), ctx);
      expect(plain.outcome, EngineFetchOutcome.ok);
    });

    test('http, local and unsaved endpoints are refused', () async {
      final ctx = job(
        manifest: {'x.example.com'},
        consented: {'x.example.com'},
        endpoints: {'http://$_host', 'https://192.168.1.5'},
      );
      for (final url in [
        'http://$_host/',
        'https://$_host/',
        'https://192.168.1.5/',
      ]) {
        final r = await handler().handle(req(url), ctx);
        expect(r.outcome, EngineFetchOutcome.blockedHost, reason: url);
      }
      expectNothingSent();
    });

    test(
      'a saved name that resolves to a private address is refused',
      () async {
        resolver.answers['my.server.example'] = ['192.168.1.20'];
        final ctx = job(
          manifest: {'x.example.com'},
          consented: {'x.example.com'},
          endpoints: {'https://my.server.example'},
        );
        final r = await handler().handle(
          req('https://my.server.example/'),
          ctx,
        );
        expect(r.outcome, EngineFetchOutcome.blockedHost);
        expect(dialer.dialed, isEmpty);
      },
    );
  });

  group('the exchange', () {
    test(
      'answers carry status, headers, body, the requested url, one send',
      () async {
        server.handler = (r) async {
          r.response.statusCode = 404;
          r.response.headers.set('x-a', 'b');
          r.response.write('nope');
          await r.response.close();
        };
        final url = onServer('/missing?q=1');
        final r = await handler().handle(req(url), job());
        expect(r.outcome, EngineFetchOutcome.ok);
        expect(r.status, 404);
        expect(r.url, url);
        expect(r.sends, 1);
        expect(utf8.decode(r.body), 'nope');
        expect(r.headers, contains(('x-a', 'b')));
      },
    );

    test('Host, Proxy-*, Content-Length and Expect of a script never reach the server', () async {
      server.handler = (r) async => r.response.close();
      final r = await handler().handle(
        req(
          onServer('/'),
          method: 'POST',
          body: utf8.encode('abc'),
          headers: [
            ('Host', 'evil.example.org'),
            ('Proxy-Authorization', 'Basic eHg6eHg='),
            ('Proxy-Connection', 'keep-alive'),
            ('Content-Length', '999'),
            ('Expect', '100-continue'),
            ('Transfer-Encoding', 'chunked'),
            ('X-Ok', '1'),
          ],
        ),
        job(),
      );
      expect(r.outcome, EngineFetchOutcome.ok);
      final seen = server.requests.single.headers;
      expect(seen.value('x-ok'), '1');
      expect(seen.value('host'), isNot(contains('evil')));
      expect(seen.value('host'), _host);
      expect(seen.value('proxy-authorization'), isNull);
      expect(seen.value('proxy-connection'), isNull);
      expect(seen.value('expect'), isNull);
      expect(seen.value('transfer-encoding'), isNull);
      expect(seen.value('content-length'), '3');
    });

    test('a 302 is returned as it is, the target is never contacted', () async {
      final target = await TestServer.start(secure: true);
      addTearDown(target.close);
      server.handler = (r) async {
        r.response.statusCode = 302;
        r.response.headers.set('location', 'https://$_host:${target.port}/t');
        await r.response.close();
      };
      final url = onServer('/start');
      final r = await handler().handle(req(url), job());
      expect(r.outcome, EngineFetchOutcome.ok);
      expect(r.status, 302);
      expect(r.url, url);
      expect(r.sends, 1);
      expect(r.headers.any((h) => h.$1 == 'location'), isTrue);
      expect(server.requests, hasLength(1));
      expect(target.requests, isEmpty);
    });

    test('a body over 4 MiB is an invalid response', () async {
      server.handler = (r) async {
        r.response.add(Uint8List(4 * 1024 * 1024 + 1));
        await r.response.close();
      };
      final r = await handler().handle(req(onServer('/')), job());
      expect(r.outcome, EngineFetchOutcome.invalidResponse);
    });

    test('the deadline ends a hanging request as a network failure', () async {
      server.handler = (r) async => Completer<void>().future;
      final r = await handler().handle(
        req(onServer('/'), deadlineMs: 300),
        job(),
      );
      expect(r.outcome, EngineFetchOutcome.network);
    });

    test('a cancel during the exchange is abandoned', () async {
      final arrived = Completer<void>();
      server.handler = (r) async {
        arrived.complete();
        await Completer<void>().future;
      };
      final cancel = RunCancel();
      final pending = handler().handle(req(onServer('/')), job(cancel: cancel));
      await arrived.future.timeout(const Duration(seconds: 3));
      cancel.cancel();
      expect((await pending).outcome, EngineFetchOutcome.abandoned);
      expect(cancel.listenerCount, 0);
    });

    test('two requests of one plugin start one spacing apart', () async {
      server.handler = (r) async => r.response.close();
      const spacing = Duration(milliseconds: 150);
      final h = handler(limiter: PluginLimiter(spacing: spacing));
      final ctx = job();
      final clock = Stopwatch()..start();
      final results = await Future.wait([
        h.handle(req(onServer('/1')), ctx),
        h.handle(req(onServer('/2')), ctx),
      ]);
      expect(
        results.map((r) => r.outcome),
        everyElement(EngineFetchOutcome.ok),
      );
      expect(clock.elapsed, greaterThanOrEqualTo(spacing * 0.8));
    });
  });

  group('429 and 503', () {
    test('reach the script as Ok; the run notes the wait', () async {
      for (final (status, retry, expected) in [
        (429, '30', const Duration(seconds: 30)),
        (503, null, const Duration(seconds: 60)),
        (429, '99999', const Duration(minutes: 15)),
      ]) {
        server.handler = (r) async {
          r.response.statusCode = status;
          if (retry != null) r.response.headers.set('retry-after', retry);
          r.response.write('slow down');
          await r.response.close();
        };
        final ctx = job();
        final r = await handler().handle(req(onServer('/')), ctx);
        expect(r.outcome, EngineFetchOutcome.ok);
        expect(r.status, status);
        expect(utf8.decode(r.body), 'slow down');
        expect(ctx.rateLimitSeen, expected);
      }
    });

    test(
      'a 429 then a 200 in one run keeps the note and refuses nothing',
      () async {
        var calls = 0;
        server.handler = (r) async {
          r.response.statusCode = ++calls == 1 ? 429 : 200;
          r.response.headers.set('retry-after', '5');
          await r.response.close();
        };
        final h = handler();
        final ctx = job();
        final first = await h.handle(req(onServer('/')), ctx);
        final second = await h.handle(req(onServer('/')), ctx);
        expect(first.status, 429);
        expect(second.status, 200);
        expect(second.outcome, EngineFetchOutcome.ok);
        expect(ctx.rateLimitSeen, const Duration(seconds: 5));
      },
    );

    test('other statuses leave the note empty', () async {
      server.handler = (r) async {
        r.response.statusCode = 500;
        await r.response.close();
      };
      final ctx = job();
      await handler().handle(req(onServer('/')), ctx);
      expect(ctx.rateLimitSeen, isNull);
    });
  });

  group('mask set', () {
    test('request secrets and Set-Cookie values are collected', () async {
      server.handler = (r) async {
        r.response.headers.add('set-cookie', 'sid=cookiesecret; Path=/');
        await r.response.close();
      };
      final ctx = job();
      await handler().handle(
        req(onServer('/'), headers: [('Authorization', 'Bearer tok-123456')]),
        ctx,
      );
      expect(
        ctx.maskValues,
        containsAll([
          'Bearer tok-123456',
          'tok-123456',
          'sid=cookiesecret',
          'cookiesecret',
        ]),
      );
    });
  });

  group('request records', () {
    test('header secrets of a refused request are collected', () async {
      final ctx = job();
      await handler().handle(
        req(
          onServer('/', host: 'private.example.test'),
          headers: [('X-Api-Key', 'refused-key-123456')],
        ),
        ctx,
      );
      expect(ctx.maskValues, contains('refused-key-123456'));
    });

    test('the whole path is kept for the log to cut after redaction', () async {
      final ctx = job();
      final long = '/${'p' * 400}';
      await handler().handle(req(onServer(long)), ctx);
      expect(ctx.requests.single.path, long);
    });

    test(
      'an answered request keeps method, host, path, status, time',
      () async {
        server.handler = (r) async {
          r.response.statusCode = 404;
          await r.response.close();
        };
        final ctx = job();
        await handler().handle(
          req(
            onServer('/v2/search?token=abc123&q=song'),
            method: 'POST',
            body: utf8.encode('secret body'),
            headers: [('Authorization', 'Bearer tok-123456')],
          ),
          ctx,
        );
        final record = ctx.requests.single;
        expect(record.method, 'POST');
        expect(record.host, _host);
        expect(record.path, '/v2/search');
        expect(record.status, 404);
        expect(record.ms, greaterThanOrEqualTo(0));
        expect(record.blocked, isFalse);
        // Nothing of the query, headers or body is in what is kept.
        expect(record.toJson().toString(), isNot(contains('abc123')));
        expect(record.toJson().toString(), isNot(contains('tok-123456')));
        expect(record.toJson().toString(), isNot(contains('secret body')));
      },
    );

    test('refused requests are recorded without a status', () async {
      final ctx = job();
      await handler().handle(
        req(onServer('/x?k=v', host: 'private.example.test')),
        ctx,
      );
      await handler().handle(req('not a url'), ctx);
      await handler().handle(req(onServer('/'), method: 'DELETE'), ctx);
      expect(ctx.requests, hasLength(3));
      expect(ctx.requests.every((r) => r.status == null), isTrue);
      expect(ctx.requests.first.host, 'private.example.test');
      expect(ctx.requests.first.path, '/x');
      expect(ctx.requests[1].host, '');
    });

    test('a blocked address is flagged', () async {
      final ctx = job(
        manifest: {'private.example.test'},
        consented: {'private.example.test'},
      );
      final r = await handler().handle(
        req(onServer('/', host: 'private.example.test')),
        ctx,
      );
      expect(r.outcome, EngineFetchOutcome.blockedHost);
      expect(ctx.requests.single.blocked, isTrue);
    });

    test('a run keeps at most 100 records', () async {
      // Refused requests are recorded too and never reach the network.
      final ctx = job(consented: {});
      final h = handler();
      for (var i = 0; i < 105; i++) {
        await h.handle(req(onServer('/')), ctx);
      }
      expect(ctx.requests, hasLength(100));
    });
  });

  test('a snapshot is not changed by later changes of its sources', () async {
    server.handler = (r) async => r.response.close();
    final manifest = {_host};
    final consented = {_host};
    final endpoints = <String>{};
    final ctx = job(
      manifest: manifest,
      consented: consented,
      endpoints: endpoints,
    );
    // The live plugin changes after the run started.
    manifest
      ..clear()
      ..add('new.example.test');
    consented.clear();
    endpoints.add('https://other.example.test');
    final h = handler();
    expect(
      (await h.handle(req(onServer('/')), ctx)).outcome,
      EngineFetchOutcome.ok,
    );
    expect(
      (await h.handle(req('https://other.example.test/'), ctx)).outcome,
      EngineFetchOutcome.blockedHost,
    );
  });

  test('a throwing resolver, client or limiter never throws out', () async {
    final failing = HttpPluginFetchHandler(
      http: PluginHttpClient(
        resolver: (_) => throw const SocketException('x'),
        dialer: dialer.call,
      ),
      limiter: PluginLimiter(spacing: Duration.zero),
    );
    expect(
      (await failing.handle(req(onServer('/')), job())).outcome,
      EngineFetchOutcome.network,
    );
    final badClient = HttpPluginFetchHandler(
      http: _ThrowingClient(),
      limiter: PluginLimiter(spacing: Duration.zero),
    );
    expect(
      (await badClient.handle(req(onServer('/')), job())).outcome,
      EngineFetchOutcome.network,
    );
    final badLimiter = HttpPluginFetchHandler(
      http: PluginHttpClient(),
      limiter: _ThrowingLimiter(),
    );
    expect(
      (await badLimiter.handle(req(onServer('/')), job())).outcome,
      EngineFetchOutcome.network,
    );
  });
}

class _ThrowingClient extends PluginHttpClient {
  @override
  Future<Result<PluginHttpResponse, PluginHttpFailure>> send(
    PluginHttpRequest request, {
    required Duration deadline,
    CancelToken? cancel,
  }) => throw StateError('client');
}

class _ThrowingLimiter extends PluginLimiter {
  @override
  Future<LimiterResult> acquire(
    String installId, {
    required Duration timeLeft,
    CancelToken? cancel,
  }) => throw StateError('limiter');
}
