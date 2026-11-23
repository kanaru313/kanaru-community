import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/logs/log_redaction.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_event.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_limits.dart';

RunLogEvent event({
  Object? query,
  String? message,
  String? stack,
  List<String> console = const [],
  List<RunLogRequest> requests = const [],
}) => RunLogEvent(
  time: DateTime.utc(2026, 11, 23),
  installId: 'plugin-${'a' * 32}',
  pluginName: 'Demo',
  version: '3',
  script: 'search',
  query: query,
  kind: 'server',
  message: message,
  stack: stack,
  console: console,
  requests: requests,
);

const apiKey = 'mega-key-9f8e7d6c5b4a';
const spDc = 'AQC3-sp_dc-cookie-value-123456';
const userToken = '2301ab5c9d9e4f7a-token';
const mxmToken = 'mxm-token-ABCDEFGH1234';
const spotifyAccess = 'BQDx-spotify-access-0987654321';

final schema = <ConfigField>[
  const InputField(key: 'apiKey', title: 'Key'),
  const InputField(key: 'spDc', title: 'Cookie', format: InputFormat.multiline),
  const InputField(key: 'userToken', title: 'Token'),
  const InputField(key: 'pin', title: 'Pin', format: InputFormat.integer),
  const SelectField(
    key: 'mode',
    title: 'Mode',
    options: [ConfigOption(value: 'default', title: 'Default')],
  ),
  const ToggleField(key: 'safe', title: 'Safe'),
  const ListField(key: 'hosts', title: 'Hosts'),
  const MapField(key: 'extra', title: 'Extra'),
];

final stored = <String, Object?>{
  'apiKey': apiKey,
  'spDc': spDc,
  'userToken': userToken,
  'pin': 123456,
  'mode': 'default',
  'safe': true,
  'hosts': ['https://my.server.example/api', 'ab'],
  'extra': {'header-name-x': 'value-of-extra-1'},
  'stale-key': 'stale-secret-value',
};

LogRedactor redactor({
  Iterable<String> append = const [],
  Iterable<String> headers = const [],
  Object? hiddenInput,
}) => LogRedactor(
  schema: schema,
  storedConfig: stored,
  configAppend: append,
  storageJsons: [
    jsonEncode({'mxm_token': mxmToken, 'short': 'abc'}),
    jsonEncode({'spotify_access_token': spotifyAccess}),
  ],
  headerSecrets: headers,
  hiddenInput: hiddenInput,
);

void main() {
  group('config values', () {
    test('real manifest fields are hidden in every text field', () {
      final out = redactor().apply(
        event(
          query: {
            'title': 'Song',
            'deep': ['x $apiKey'],
          },
          message: 'bad key $apiKey',
          stack: 'at $spDc',
          console: ['token=$userToken'],
          requests: [
            RunLogRequest(
              method: 'GET',
              host: 'my.server.example',
              path: '/k/$apiKey',
              status: 401,
              ms: 3,
            ),
          ],
        ),
      );
      final line = jsonEncode(out.toJson());
      for (final secret in [apiKey, spDc, userToken]) {
        expect(line, isNot(contains(secret)));
      }
      expect(out.message, 'bad key ***');
      expect(out.requests.single.path, '/k/…');
    });

    test('numbers, list items, map keys and values and stale keys', () {
      final r = redactor();
      expect(r.text('pin 123456'), 'pin ***');
      expect(r.text('see https://my.server.example/api now'), 'see *** now');
      expect(r.text('header-name-x: value-of-extra-1'), '***: ***');
      expect(r.text('stale-secret-value'), '***');
    });

    test('selects, toggles and short values stay readable', () {
      final r = redactor();
      expect(
        r.text('mode default, safe true, ab'),
        'mode default, safe true, ab',
      );
    });

    test('percent-encoded and whole-URL forms are hidden', () {
      final r = LogRedactor(
        schema: schema,
        storedConfig: {'apiKey': 'a b&c=d/e?f'},
      );
      expect(r.text('q=${Uri.encodeComponent('a b&c=d/e?f')}'), 'q=***');
      expect(r.text('u=${Uri.encodeFull('a b&c=d/e?f')}'), 'u=***');
    });

    test('tokens of a multi-value setting are hidden on their own', () {
      final r = LogRedactor(
        schema: schema,
        storedConfig: {'apiKey': 'first-key-12345, second-key-67890; ab'},
      );
      expect(r.text('using second-key-67890'), 'using ***');
    });

    test('the longest value is replaced first', () {
      final r = LogRedactor(
        schema: schema,
        storedConfig: {'apiKey': 'abcd', 'userToken': 'abcdefgh-long'},
      );
      expect(r.text('abcdefgh-long and abcd'), '*** and ***');
    });
  });

  group('storage, appends, headers', () {
    test('storage values of 8 or more characters, before and after', () {
      final r = redactor();
      expect(r.text('t=$mxmToken s=$spotifyAccess'), 't=*** s=***');
      expect(r.text('short abc'), 'short abc');
      expect(r.text('key mxm_token'), 'key mxm_token');
    });

    test('a configAppend value and a header value', () {
      final r = redactor(
        append: ['Dich sang tieng Viet thoai mai'],
        headers: ['Bearer abcdefgh12345', 'abcdefgh12345'],
      );
      expect(r.text('note Dich sang tieng Viet thoai mai'), 'note ***');
      expect(
        r.text('Authorization: Bearer abcdefgh12345'),
        'Authorization: ***',
      );
    });
  });

  group('paths', () {
    test('a token segment of 16 or more characters becomes an ellipsis', () {
      final r = redactor();
      final token = 'AbCdEf0123456789AbCdEf0123456789';
      expect(r.path('/v2/stream/$token/x.mp3'), '/v2/stream/…/x.mp3');
      expect(r.path('/v2/search'), '/v2/search');
    });

    test('request host and path go through both rules', () {
      final out = redactor().apply(
        event(
          requests: [
            RunLogRequest(
              method: 'GET',
              host: 'h.example',
              path: '/s/0123456789abcdef0123/$apiKey',
              status: 200,
              ms: 1,
            ),
          ],
        ),
      );
      expect(out.requests.single.path, '/s/…/…');
    });
  });

  group('input of a script whose input is not logged', () {
    final input = {
      'lines': ['Hello darling how are you', 'short'],
      'title': 'A very long title',
      'artist': 'Some Artist',
      'context': 'first line of context\nsecond line of context',
    };

    test('a top-level string input is hidden too', () {
      final out = redactor(hiddenInput: 'Translate this exact sentence').apply(
        event(
          message: 'bad: Translate this exact sentence',
          stack: 'at Translate this exact sentence',
          console: ['sent Translate this exact sentence'],
        ),
      );
      expect(out.message, 'bad: ***');
      expect(out.stack, 'at ***');
      expect(out.console, ['sent ***']);
    });

    test('every input string of 8 or more characters is hidden', () {
      final r = redactor(hiddenInput: input);
      final out = r.apply(
        event(
          message: 'bad prompt: Hello darling how are you',
          stack: 'for A very long title by Some Artist',
          console: ['second line of context', 'short ok'],
        ),
      );
      expect(out.message, 'bad prompt: ***');
      expect(out.stack, 'for *** by ***');
      expect(out.console, ['***', 'short ok']);
    });

    test('nothing of the input is hidden when it is logged', () {
      expect(redactor().text('A very long title'), 'A very long title');
    });
  });

  test('a corpus of events never shows a secret in a serialized line', () {
    final input = {
      'title': 'Hidden input title',
      'lines': ['Hidden line one'],
    };
    final secrets = [
      apiKey,
      spDc,
      userToken,
      mxmToken,
      spotifyAccess,
      'Bearer abcdefgh12345',
      'Hidden input title',
      'Hidden line one',
      Uri.encodeComponent(apiKey),
    ];
    final r = redactor(headers: ['Bearer abcdefgh12345'], hiddenInput: input);
    for (final secret in secrets) {
      for (final template in [
        'x $secret y',
        'json {"k":"$secret"}',
        '$secret$secret',
        'a=$secret&b=$secret',
      ]) {
        final out = capRunLogEvent(
          r.apply(
            event(
              message: template,
              stack: template,
              console: [template, template],
              query: {'q': template},
              requests: [
                RunLogRequest(
                  method: 'GET',
                  host: secret,
                  path: '/$secret/z',
                  status: 200,
                  ms: 1,
                ),
              ],
            ),
          ),
        );
        final line = jsonEncode(out.toJson());
        expect(line, isNot(contains(secret)), reason: template);
      }
    }
  });

  group('urls, overlaps and the path cut', () {
    LogRedactor withUrl(String url) => LogRedactor(
      schema: const [InputField(key: 'u', title: 'U', format: InputFormat.url)],
      storedConfig: {'u': url},
    );

    test('a saved endpoint is hidden by host, path, segment and query', () {
      final out =
          withUrl(
            'https://My-Proxy.Example.com/v1/abc:defghijk?token=querysecret1',
          ).apply(
            event(
              message: 'blocked my-proxy.example.com and My-Proxy.Example.com',
              requests: [
                const RunLogRequest(
                  method: 'GET',
                  host: 'my-proxy.example.com',
                  path: '/v1/abc:defghijk/chat',
                  status: 200,
                  ms: 1,
                ),
              ],
              console: ['q=querysecret1'],
            ),
          );
      final line = jsonEncode(out.toJson()).toLowerCase();
      expect(line, isNot(contains('my-proxy')));
      expect(line, isNot(contains('defghijk')));
      expect(line, isNot(contains('querysecret1')));
    });

    // Short segments with dots: the long-token rule never applies, so only the
    // saved value can hide the secret, and it must be found before the cut.
    String pathWithSecretAt(int start, String secret) {
      final filler = List.filled(start, 'a.').join().substring(0, start - 1);
      return '/$filler/$secret';
    }

    RunLogEvent cappedPath(String path) => capRunLogEvent(
      redactor(append: const ['sec.ret.abcdef12345']).apply(
        event(
          requests: [
            RunLogRequest(
              method: 'GET',
              host: 'h',
              path: path,
              status: 200,
              ms: 1,
            ),
          ],
        ),
      ),
    );

    test('a path longer than the cap is redacted before it is cut', () {
      final path = '${pathWithSecretAt(296, 'sec.ret.abcdef12345')}/tail.end';
      // The secret starts at 297, so the cut at 300 falls inside it.
      expect(path.indexOf('sec.ret'), inInclusiveRange(296, 299));
      expect(path.length, greaterThan(300));
      final kept = cappedPath(path).requests.single.path;
      expect(kept, contains('***'));
      expect(kept, isNot(contains('sec.re')));
      expect(kept.length, lessThanOrEqualTo(301));
    });

    test('a secret that straddles the old cut is masked whole', () {
      // The secret starts at index 291 and would be cut at 300 by a cut that
      // ran first, leaving nine characters of it visible.
      final path = pathWithSecretAt(290, 'sec.ret.abcdef12345');
      expect(path.indexOf('sec.ret'), inInclusiveRange(285, 295));
      final kept = cappedPath(path).requests.single.path;
      expect(kept, isNot(contains('sec.re')));
      expect(kept, endsWith('***'));
    });

    test('overlapping secrets leave no tail visible', () {
      final r = LogRedactor(
        configAppend: const ['XXXXabcdefgh', 'abcdefghYYYY'],
      );
      expect(r.text('see XXXXabcdefghYYYY now'), 'see *** now');
    });
  });

  group('event json', () {
    test('round trips, and tolerates a bad line', () {
      final original = event(
        message: 'm',
        console: ['a'],
        requests: [
          RunLogRequest(
            method: 'GET',
            host: 'h',
            path: '/p',
            status: null,
            ms: 4,
          ),
        ],
      );
      final back = RunLogEvent.tryParse(
        jsonDecode(jsonEncode(original.toJson())),
      )!;
      expect(back.kind, 'server');
      expect(back.requests.single.status, isNull);
      expect(back.console, ['a']);
      expect(RunLogEvent.tryParse('nope'), isNull);
      expect(RunLogEvent.tryParse({'ts': 'x', 'kind': 'k'}), isNull);
      expect(RunLogEvent.tryParse({'ts': '2026-11-23T00:00:00Z'}), isNull);
      final odd = RunLogEvent.tryParse({
        'ts': '2026-11-23T00:00:00Z',
        'kind': 'k',
        'console': [1, 'ok'],
        'requests': [
          'bad',
          {'host': 5},
        ],
      })!;
      expect(odd.console, ['ok']);
      expect(odd.requests.single.host, '');
    });

    test('caps keep one line small', () {
      final big = capRunLogEvent(
        event(
          message: 'm' * 100000,
          stack: 's' * 100000,
          console: List.filled(500, 'c' * 5000),
          query: {'x': 'q' * 100000},
        ),
      );
      expect(jsonEncode(big.toJson()).length, lessThan(100 * 1024));
      expect(big.console, hasLength(50));
    });
  });
}
