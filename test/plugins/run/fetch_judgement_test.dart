import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/net/plugin_http.dart';
import 'package:kanaru/src/plugins/data/run/fetch_judgement.dart';
import 'package:kanaru/src/plugins/data/run/plugin_limiter.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

import 'support/fetch_judgement_cases.dart';

JobContext _job({
  Set<String> manifest = const {judgementHost},
  Set<String> consented = const {judgementHost},
  Set<String> endpoints = const {},
}) => JobContext(
  installId: judgementInstallId,
  job: 1,
  cancel: RunCancel(),
  manifestHosts: manifest,
  consentedHosts: consented,
  userEndpoints: endpoints,
);

EngineFetchRequest _req(
  String url, {
  String installId = judgementInstallId,
  List<(String, String)> headers = const [],
}) => EngineFetchRequest(
  installId: installId,
  method: 'GET',
  url: url,
  headers: headers,
  body: Uint8List(0),
  deadlineMs: 5000,
  maxSends: 10,
);

PluginLimiter _limiter() => PluginLimiter(spacing: Duration.zero);

void main() {
  group('judgeFetch verdicts', () {
    for (final c in fetchJudgementCases) {
      test(c.name, () async {
        final verdict = await judgeFetch(
          _req(c.url, installId: c.installId, headers: c.headers),
          _job(
            manifest: c.manifest,
            consented: c.consented,
            endpoints: c.endpoints,
          ),
          _limiter(),
        );
        switch (verdict) {
          case AllowedFetch():
            expect(c.expected, isNull);
          case RefusedFetch(:final outcome):
            expect(outcome, c.expected);
        }
      });
    }
  });

  test('an allowed request carries the filtered headers', () async {
    final verdict = await judgeFetch(
      _req(
        'https://repo.example.test/a',
        headers: [('Accept', 'x/y'), ('Host', 'evil.example.test')],
      ),
      _job(),
      _limiter(),
    );
    expect(verdict, isA<AllowedFetch>());
    verdict as AllowedFetch;
    expect(verdict.headers, {'accept': 'x/y'});
    expect(verdict.method, 'GET');
  });

  test(
    'a cancelled token given by the caller abandons the spacing wait',
    () async {
      final limiter = PluginLimiter(spacing: const Duration(seconds: 2));
      await limiter.acquire(
        judgementInstallId,
        timeLeft: const Duration(seconds: 30),
      );
      final cancel = RunCancel();
      final pending = judgeFetch(
        _req('https://repo.example.test/a'),
        _job(),
        limiter,
        cancel: cancel,
      );
      cancel.cancel();
      final verdict = await pending;
      expect(
        verdict,
        isA<RefusedFetch>().having(
          (v) => v.outcome,
          'outcome',
          EngineFetchOutcome.abandoned,
        ),
      );
    },
  );

  test('registers Authorization and Cookie values as masks even for refused '
      'requests', () async {
    final context = _job();
    final verdict = await judgeFetch(
      _req(
        'https://unlisted.example.test/a',
        headers: [
          ('Authorization', 'Bearer secret-token-123'),
          ('Cookie', 'sid=abcdef123456'),
        ],
      ),
      context,
      _limiter(),
    );
    expect(verdict, isA<RefusedFetch>());
    expect(
      context.maskValues,
      containsAll([
        'Bearer secret-token-123',
        'secret-token-123',
        'sid=abcdef123456',
      ]),
    );
  });

  test('set-cookie values become masks after a response', () {
    final context = _job();
    noteResponse(
      context,
      PluginHttpResponse(
        status: 200,
        headers: const [('set-cookie', 'session=abcdef123456; Path=/')],
        body: Uint8List(0),
      ),
    );
    expect(context.maskValues, contains('session=abcdef123456'));
    expect(context.maskValues, contains('abcdef123456'));
    expect(context.rateLimitSeen, isNull);
  });

  test('a 429 answer sets the rate limit flag from retry-after', () {
    final context = _job();
    noteResponse(
      context,
      PluginHttpResponse(
        status: 429,
        headers: const [('retry-after', '30')],
        body: Uint8List(0),
      ),
    );
    expect(context.rateLimitSeen, const Duration(seconds: 30));
  });

  test('refused request is recorded with blocked = true', () {
    final context = _job();
    recordFetch(
      _req('https://unlisted.example.test/a?q=1'),
      context,
      EngineFetchOutcome.blockedHost,
      0,
      7,
    );
    final entry = context.requests.single;
    expect(entry.blocked, isTrue);
    expect(entry.status, isNull);
    expect(entry.host, 'unlisted.example.test');
    expect(entry.path, '/a');
    expect(entry.ms, 7);
  });

  test('an answered request is recorded with its status', () {
    final context = _job();
    recordFetch(
      _req('https://repo.example.test/a'),
      context,
      EngineFetchOutcome.ok,
      204,
      3,
    );
    expect(context.requests.single.status, 204);
    expect(context.requests.single.blocked, isFalse);
  });

  test('the record stops at 100 requests', () {
    final context = _job();
    for (var i = 0; i < 120; i++) {
      recordFetch(
        _req('https://repo.example.test/a'),
        context,
        EngineFetchOutcome.ok,
        200,
        1,
      );
    }
    expect(context.requests, hasLength(100));
  });
}
