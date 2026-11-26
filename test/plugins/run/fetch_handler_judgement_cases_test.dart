import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http.dart';
import 'package:kanaru/src/plugins/data/run/fetch_handler.dart';
import 'package:kanaru/src/plugins/data/run/plugin_limiter.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

import '../net/net_test_support.dart';
import 'support/fetch_judgement_cases.dart';
import 'support/stream_call_support.dart';

/// The shared judgement table, run through [HttpPluginFetchHandler] like the
/// stream handler does, so both network paths keep agreeing with it.
void main() {
  late TestServer server;
  late RecordingDialer dialer;
  late FakeResolver resolver;

  setUp(() async {
    server = await TestServer.start(secure: true);
    dialer = RecordingDialer((_, _) => server.port);
    resolver = FakeResolver({
      judgementHost: [fakePublicIp],
      'my.server.example': [fakePublicIp],
    });
    server.handler = (r) async => r.response.close();
  });

  tearDown(() => server.close());

  for (final c in fetchJudgementCases) {
    test(c.name, () async {
      final handler = HttpPluginFetchHandler(
        http: PluginHttpClient(
          resolver: resolver.call,
          dialer: dialer.call,
          context: trustingTestCert(),
        ),
        limiter: PluginLimiter(spacing: Duration.zero),
      );
      final ctx = streamJob(
        manifest: c.manifest,
        consented: c.consented,
        endpoints: c.endpoints,
      );
      final reply = await handler.handle(
        EngineFetchRequest(
          installId: c.installId,
          method: 'GET',
          url: c.url,
          headers: c.headers,
          body: Uint8List(0),
          deadlineMs: 5000,
          maxSends: 10,
        ),
        ctx,
      );
      final record = ctx.requests.single;
      if (c.expected == null) {
        // Allowed: the transport was reached. The test certificate covers only
        // the judgement host; another host fails TLS, a network failure.
        final covered = Uri.parse(c.url).host == judgementHost;
        expect(resolver.lookups, isNotEmpty);
        expect(
          reply.outcome,
          covered ? EngineFetchOutcome.ok : EngineFetchOutcome.network,
        );
        if (c.name.startsWith('host owned header')) {
          final host = server.requests.single.headers.value('host');
          expect(host, startsWith(judgementHost));
          expect(host, isNot(contains('evil')));
        }
      } else {
        expect(reply.outcome, c.expected);
        expect(resolver.lookups, isEmpty);
        expect(server.requests, isEmpty);
        expect(record.status, isNull);
      }
      expect(record.blocked, reply.outcome == EngineFetchOutcome.blockedHost);
    });
  }

  test('request secrets of a refused fetch are collected as masks', () async {
    final handler = HttpPluginFetchHandler(
      http: PluginHttpClient(
        resolver: resolver.call,
        dialer: dialer.call,
        context: trustingTestCert(),
      ),
      limiter: PluginLimiter(spacing: Duration.zero),
    );
    final ctx = streamJob();
    await handler.handle(
      EngineFetchRequest(
        installId: judgementInstallId,
        method: 'GET',
        url: 'https://unlisted.example.test/a',
        headers: const [('Authorization', 'Bearer secret-token-123')],
        body: Uint8List(0),
        deadlineMs: 5000,
        maxSends: 10,
      ),
      ctx,
    );
    expect(ctx.maskValues, contains('secret-token-123'));
  });
}
