import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http_stream.dart';
import 'package:kanaru/src/plugins/data/run/plugin_limiter.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/data/run/stream_fetch_handler.dart';
import 'package:kanaru/src/plugins/data/run/stream_table.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

import '../net/net_test_support.dart';
import 'support/fetch_judgement_cases.dart';
import 'support/stream_call_support.dart';

const _url = 'https://$judgementHost/s';

void main() {
  late TestServer server;
  late RecordingDialer dialer;
  late FakeResolver resolver;
  late PluginHttpClient client;
  var rawOpened = 0;
  var rawClosed = 0;

  setUp(() async {
    rawOpened = 0;
    rawClosed = 0;
    server = await TestServer.start(secure: true);
    dialer = RecordingDialer((_, _) => server.port);
    resolver = FakeResolver({
      judgementHost: [fakePublicIp],
      'my.server.example': [fakePublicIp],
    });
    client = PluginHttpClient(
      resolver: resolver.call,
      dialer: dialer.call,
      context: trustingTestCert(),
    );
  });

  tearDown(() => server.close());

  StreamFetchHandler handler({
    PluginLimiter? limiter,
    PluginHttpStreamClient? streams,
  }) => StreamFetchHandler(
    http: streams ?? PluginHttpStreamClient(client),
    limiter: limiter ?? PluginLimiter(spacing: Duration.zero),
  );

  /// Takes the raw socket, answers with [raw] (nothing when empty) and keeps
  /// the body open; counts the sockets the client has dropped (the server only
  /// learns it by reading the raw socket).
  Future<void> hold(HttpRequest r, String raw) async {
    final socket = await r.response.detachSocket(writeHeaders: false);
    rawOpened++;
    socket.listen(
      (_) {},
      onError: (_) {},
      onDone: () {
        rawClosed++;
        socket.destroy();
      },
    );
    if (raw.isNotEmpty) {
      socket.write(raw);
      await socket.flush();
    }
    await Completer<void>().future;
  }

  /// Head and a first chunk, then the body stays open.
  void serveOpenBody() {
    server.handler = (r) => hold(
      r,
      'HTTP/1.1 200 OK\r\ntransfer-encoding: chunked\r\n\r\n'
      '6\r\nfirst\n\r\n',
    );
  }

  /// Waits until the client has dropped every connection it made.
  Future<void> expectNoSockets() async {
    for (var i = 0; i < 100 && rawClosed < rawOpened; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(rawOpened, greaterThan(0));
    expect(rawClosed, rawOpened);
  }

  group('judgement table', () {
    for (final c in fetchJudgementCases) {
      test(c.name, () async {
        server.handler = (r) async => r.response.close();
        final cancel = RunCancel();
        final ctx = streamJob(
          cancel: cancel,
          manifest: c.manifest,
          consented: c.consented,
          endpoints: c.endpoints,
        );
        final table = StreamTable(cancel);
        addTearDown(table.dispose);
        final reply = await handler().handle(
          openCall(1, c.url, installId: c.installId, headers: c.headers),
          ctx,
          table,
        );
        final record = ctx.requests.single;
        if (c.expected == null) {
          // Judged allowed: the transport was reached (a host other than the
          // test certificate's fails its TLS check as a network failure).
          expect(resolver.lookups, isNotEmpty);
          expect(
            reply.outcome,
            anyOf(EngineFetchOutcome.ok, EngineFetchOutcome.network),
          );
          expect(table.length, reply.outcome == EngineFetchOutcome.ok ? 1 : 0);
        } else {
          expect(reply.outcome, c.expected);
          expect(resolver.lookups, isEmpty);
          expect(server.requests, isEmpty);
          expect(record.status, isNull);
          expect(table.length, 0);
        }
        expect(record.blocked, reply.outcome == EngineFetchOutcome.blockedHost);
      });
    }

    test('request secrets are collected, refused or not', () async {
      final ctx = streamJob();
      final cancel = ctx.cancel;
      final table = StreamTable(cancel);
      addTearDown(table.dispose);
      await handler().handle(
        openCall(
          1,
          'https://unlisted.example.test/a',
          headers: [('Authorization', 'Bearer secret-token-123')],
        ),
        ctx,
        table,
      );
      expect(ctx.maskValues, contains('secret-token-123'));
    });

    test('set-cookie values of an opened stream are collected', () async {
      server.handler = (r) async {
        r.response.headers.add('set-cookie', 'sid=cookiesecret; Path=/');
        await r.response.close();
      };
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      await handler().handle(openCall(1, _url), ctx, table);
      expect(ctx.maskValues, contains('cookiesecret'));
    });

    test('a 429 answer is an answer and the run notes the wait', () async {
      server.handler = (r) async {
        r.response.statusCode = 429;
        r.response.headers.set('retry-after', '30');
        await r.response.close();
      };
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final reply = await handler().handle(openCall(1, _url), ctx, table);
      expect(reply.outcome, EngineFetchOutcome.ok);
      expect(reply.status, 429);
      expect(ctx.rateLimitSeen, const Duration(seconds: 30));
    });
  });

  group('run log', () {
    test('refused stream open appears with blocked = true', () async {
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final reply = await handler().handle(
        openCall(1, 'https://unlisted.example.test/a?q=1'),
        ctx,
        table,
      );
      expect(reply.outcome, EngineFetchOutcome.blockedHost);
      final record = ctx.requests.single;
      expect(record.blocked, isTrue);
      expect(record.status, isNull);
      expect(record.host, 'unlisted.example.test');
      expect(record.path, '/a');
    });

    test('opened stream recorded with its status', () async {
      server.handler = (r) async {
        r.response.statusCode = 206;
        await r.response.close();
      };
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final reply = await handler().handle(openCall(1, _url), ctx, table);
      expect(reply.status, 206);
      expect(reply.sends, 1);
      expect(reply.url, _url);
      final record = ctx.requests.single;
      expect(record.status, 206);
      expect(record.blocked, isFalse);
      expect(record.path, '/s');
      expect(record.ms, greaterThanOrEqualTo(0));
    });
  });

  group('reads', () {
    test('open then reads lines to the end', () async {
      server.handler = (r) async {
        r.response.write('a\nb\n');
        await r.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        r.response.write('c\n');
        await r.response.close();
      };
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      final opened = await h.handle(openCall(1, _url), ctx, table);
      expect(opened.outcome, EngineFetchOutcome.ok);
      expect(opened.status, 200);
      var text = '';
      var done = false;
      for (var i = 0; i < 10 && !done; i++) {
        final r = await h.handle(readCall(1), ctx, table);
        expect(r.outcome, EngineFetchOutcome.ok);
        // An ok reply is bytes or the end, never an empty chunk.
        expect(r.chunk.isNotEmpty || r.done, isTrue);
        text += utf8.decode(r.chunk);
        done = r.done;
      }
      expect(text, 'a\nb\nc\n');
      expect(done, isTrue);
      // The end closed the stream: its slot is free and reads fail.
      expect(table.length, 0);
      final after = await h.handle(readCall(1), ctx, table);
      expect(after.outcome, EngineFetchOutcome.network);
      expect(after.done, isFalse);
    });

    test('a read on an unknown id fails network', () async {
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final r = await handler().handle(readCall(9), ctx, table);
      expect(r.outcome, EngineFetchOutcome.network);
      expect(r.done, isFalse);
    });

    test('idle is network, never an empty ok chunk', () async {
      serveOpenBody();
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      await h.handle(openCall(1, _url), ctx, table);
      expect((await h.handle(readCall(1), ctx, table)).chunk, isNotEmpty);
      final idle = await h.handle(readCall(1, waitMs: 100), ctx, table);
      expect(idle.outcome, EngineFetchOutcome.network);
      expect(idle.chunk, isEmpty);
      expect(idle.done, isFalse);
    });

    test('a body cut short is network, not done', () async {
      server.handler = (r) async {
        final socket = await r.response.detachSocket(writeHeaders: false);
        socket.write(
          'HTTP/1.1 200 OK\r\ntransfer-encoding: chunked\r\n\r\n'
          '2\r\nhi\r\n',
        );
        await socket.flush();
        socket.destroy();
      };
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      await h.handle(openCall(1, _url), ctx, table);
      var last = await h.handle(readCall(1), ctx, table);
      if (last.outcome == EngineFetchOutcome.ok) {
        last = await h.handle(readCall(1), ctx, table);
      }
      expect(last.outcome, EngineFetchOutcome.network);
      expect(last.done, isFalse);
    });
  });

  group('close and cancel', () {
    /// An open that never gets its head.
    void serveNoHead() {
      server.handler = (r) => hold(r, '');
    }

    test('close while open is pending aborts it and answers both', () async {
      serveNoHead();
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      final opening = h.handle(openCall(1, _url), ctx, table);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final closed = await h.handle(closeCall(1), ctx, table);
      expect(closed.outcome, EngineFetchOutcome.ok);
      final opened = await opening.timeout(const Duration(seconds: 2));
      expect(opened.outcome, EngineFetchOutcome.abandoned);
      expect(table.length, 0);
      await expectNoSockets();
    });

    test('close is answered within 50 ms while the open is aborting', () async {
      serveNoHead();
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      final opening = h.handle(openCall(1, _url), ctx, table);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final clock = Stopwatch()..start();
      final closed = await h.handle(closeCall(1), ctx, table);
      expect(clock.elapsedMilliseconds, lessThan(50));
      expect(closed.outcome, EngineFetchOutcome.ok);
      await opening;
    });

    test('close of an unknown or finished id is answered ok', () async {
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final r = await handler().handle(closeCall(7), ctx, table);
      expect(r.outcome, EngineFetchOutcome.ok);
    });

    test('close of an open stream closes its socket; reads fail', () async {
      serveOpenBody();
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      await h.handle(openCall(1, _url), ctx, table);
      await h.handle(closeCall(1), ctx, table);
      expect(
        (await h.handle(readCall(1), ctx, table)).outcome,
        EngineFetchOutcome.network,
      );
      await expectNoSockets();
    });

    test('close during spacing wait aborts before send', () async {
      final limiter = PluginLimiter(spacing: const Duration(seconds: 3));
      await limiter.acquire(
        judgementInstallId,
        timeLeft: const Duration(seconds: 30),
      );
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler(limiter: limiter);
      final opening = h.handle(
        openCall(1, _url, deadlineMs: 20000),
        ctx,
        table,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await h.handle(closeCall(1), ctx, table);
      final opened = await opening.timeout(const Duration(seconds: 2));
      expect(opened.outcome, EngineFetchOutcome.abandoned);
      expect(resolver.lookups, isEmpty);
      expect(server.requests, isEmpty);
    });

    test(
      'open completing after job cancel closes its socket and answers network',
      () async {
        serveOpenBody();
        final ctx = streamJob();
        final table = StreamTable(ctx.cancel);
        addTearDown(table.dispose);
        // A transport that ignores the cancel and finishes the open late.
        final h = handler(streams: _LateClient(client));
        final opening = h.handle(openCall(1, _url), ctx, table);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        ctx.cancel.cancel();
        final opened = await opening.timeout(const Duration(seconds: 5));
        expect(opened.outcome, EngineFetchOutcome.network);
        expect(table.length, 0);
        await expectNoSockets();
      },
    );

    test(
      'an open after the job was cancelled answers network, dials nothing',
      () async {
        final ctx = streamJob();
        final table = StreamTable(ctx.cancel);
        addTearDown(table.dispose);
        ctx.cancel.cancel();
        final r = await handler().handle(openCall(1, _url), ctx, table);
        expect(r.outcome, EngineFetchOutcome.network);
        expect(resolver.lookups, isEmpty);
        expect(dialer.dialed, isEmpty);
      },
    );

    test('lifetime passes → later read fails network', () async {
      serveOpenBody();
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      final opened = await h.handle(
        openCall(1, _url, lifetimeMs: 300),
        ctx,
        table,
      );
      expect(opened.outcome, EngineFetchOutcome.ok);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      // The buffered first chunk is discarded with the close.
      final r = await h.handle(readCall(1, waitMs: 500), ctx, table);
      expect(r.outcome, EngineFetchOutcome.network);
      expect(r.done, isFalse);
      await expectNoSockets();
    });

    test('job cancel closes every open stream', () async {
      serveOpenBody();
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      await h.handle(openCall(1, _url), ctx, table);
      await h.handle(openCall(2, _url), ctx, table);
      expect(table.length, 2);
      ctx.cancel.cancel();
      expect(table.isSealed, isTrue);
      expect(table.length, 0);
      for (final id in [1, 2]) {
        final r = await h.handle(readCall(id), ctx, table);
        expect(r.outcome, EngineFetchOutcome.network);
        expect(r.done, isFalse);
      }
      await expectNoSockets();
    });

    test('third open while two are open is refused', () async {
      serveOpenBody();
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final h = handler();
      expect(
        (await h.handle(openCall(1, _url), ctx, table)).outcome,
        EngineFetchOutcome.ok,
      );
      expect(
        (await h.handle(openCall(2, _url), ctx, table)).outcome,
        EngineFetchOutcome.ok,
      );
      final third = await h.handle(openCall(3, _url), ctx, table);
      expect(third.outcome, EngineFetchOutcome.invalidRequest);
      expect(server.requests, hasLength(2));
      // A closed stream frees its slot.
      await h.handle(closeCall(1), ctx, table);
      expect(
        (await h.handle(openCall(4, _url), ctx, table)).outcome,
        EngineFetchOutcome.ok,
      );
    });

    test('a throwing transport never throws out', () async {
      final ctx = streamJob();
      final table = StreamTable(ctx.cancel);
      addTearDown(table.dispose);
      final r = await handler(streams: _ThrowingClient())
          .handle(openCall(1, _url), ctx, table);
      expect(r.outcome, EngineFetchOutcome.network);
      expect(table.length, 0);
    });
  });
}

/// Opens late and ignores the cancel token: the head arrives after the job
/// was cancelled.
class _LateClient extends PluginHttpStreamClient {
  const _LateClient(super.client);

  @override
  Future<Result<PluginHttpStreamHandle, PluginHttpFailure>> open(
    PluginHttpRequest request, {
    required Duration deadline,
    CancelToken? cancel,
    Duration? lifetime,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return super.open(request, deadline: deadline, lifetime: lifetime);
  }
}

class _ThrowingClient extends PluginHttpStreamClient {
  _ThrowingClient() : super(PluginHttpClient());

  @override
  Future<Result<PluginHttpStreamHandle, PluginHttpFailure>> open(
    PluginHttpRequest request, {
    required Duration deadline,
    CancelToken? cancel,
    Duration? lifetime,
  }) => throw StateError('client');
}
