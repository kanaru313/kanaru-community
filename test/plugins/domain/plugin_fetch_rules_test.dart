import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/net/plugin_fetch_rules.dart';

PluginUrlVerdict judge(
  String url, {
  Set<String> manifest = const {'api.example.com', '*.cdn.example.com'},
  Set<String> consented = const {'api.example.com', '*.cdn.example.com'},
  Set<String> endpoints = const {},
}) => judgePluginUrl(
  url,
  manifestHosts: manifest,
  consentedHosts: consented,
  userEndpoints: endpoints,
).verdict;

List<int> ip(String text) => Uri.parseIPv4Address(text);

void main() {
  group('judgePluginUrl', () {
    test('a consented manifest host is allowed, wildcard included', () {
      expect(judge('https://api.example.com/x?q=1'), PluginUrlVerdict.allowed);
      expect(judge('https://a.cdn.example.com/'), PluginUrlVerdict.allowed);
      expect(judge('https://API.Example.com/'), PluginUrlVerdict.allowed);
    });

    test('the host must be in both the manifest and the consent', () {
      expect(
        judge('https://api.example.com/', consented: {'other.example.com'}),
        PluginUrlVerdict.blocked,
      );
      expect(
        judge('https://api.example.com/', manifest: {'other.example.com'}),
        PluginUrlVerdict.blocked,
      );
      expect(judge('https://evil.example.org/'), PluginUrlVerdict.blocked);
    });

    test('a bare wildcard base and a deeper name are not covered', () {
      expect(judge('https://cdn.example.com/'), PluginUrlVerdict.blocked);
      expect(judge('https://a.b.cdn.example.com/'), PluginUrlVerdict.blocked);
    });

    test('shape: http, user info, IP literals, local names are blocked', () {
      for (final url in [
        'http://api.example.com/',
        'https://user:pw@api.example.com/',
        'https://user@api.example.com/',
        'https://93.184.216.34/',
        'https://[2606:2800:220:1::1]/',
        'https://127.0.0.1/',
        'https://localhost/',
        'https://nas.lan/',
        'https://intranet/',
        'ftp://api.example.com/',
        'https://*.cdn.example.com/',
        'https://a_b.example.com/',
        'https://-a.example.com/',
      ]) {
        expect(
          judge(
            url,
            manifest: {'api.example.com', 'localhost', 'nas.lan', 'intranet'},
            consented: {'api.example.com', 'localhost', 'nas.lan', 'intranet'},
            endpoints: {url},
          ),
          PluginUrlVerdict.blocked,
          reason: url,
        );
      }
    });

    test('not a URL is invalid', () {
      for (final url in ['', 'not a url', '/relative/path', 'https://']) {
        expect(judge(url), PluginUrlVerdict.invalid, reason: url);
      }
    });

    test('an explicit port is refused for a manifest host', () {
      expect(judge('https://api.example.com:8443/'), PluginUrlVerdict.blocked);
      // Dart drops the default port while parsing, so `:443` is no port.
      expect(judge('https://api.example.com:443/'), PluginUrlVerdict.allowed);
    });

    test('a saved user endpoint allows its host, with and without port', () {
      final saved = {'https://my.server.example', 'https://other.example:8443'};
      expect(
        judge('https://my.server.example/api', endpoints: saved),
        PluginUrlVerdict.allowed,
      );
      expect(
        judge('https://other.example:8443/api', endpoints: saved),
        PluginUrlVerdict.allowed,
      );
    });

    test('a user endpoint needs the exact host and port', () {
      final saved = {'https://my.server.example', 'https://other.example:8443'};
      for (final url in [
        'https://my.server.example:8443/',
        'https://other.example/',
        'https://other.example:9443/',
        'https://sub.my.server.example/',
        'https://my.server.example.evil.test/',
      ]) {
        expect(
          judge(url, endpoints: saved),
          PluginUrlVerdict.blocked,
          reason: url,
        );
      }
    });

    test('a user endpoint that is http, local or has user info is ignored', () {
      for (final saved in [
        'http://my.server.example',
        'https://192.168.1.5',
        'https://nas.lan',
        'https://u:p@my.server.example',
        'my.server.example',
        'not a url',
      ]) {
        expect(
          judge('https://my.server.example/', endpoints: {saved}),
          PluginUrlVerdict.blocked,
          reason: saved,
        );
      }
    });

    test('the fragment is dropped from the allowed URL', () {
      final result = judgePluginUrl(
        'https://api.example.com/a#frag',
        manifestHosts: {'api.example.com'},
        consentedHosts: {'api.example.com'},
        userEndpoints: {},
      );
      expect(result.uri.toString(), 'https://api.example.com/a');
    });
  });

  group('pluginRequestHeaders', () {
    PluginRequestHeaders? headers(Map<String, String> m) =>
        pluginRequestHeaders([...m.entries.map((e) => (e.key, e.value))]);

    test('names are lower-cased, the last of equal names wins', () {
      expect(headers({'X-Token': 'a', 'Referer': 'https://x/'})!.headers, {
        'x-token': 'a',
        'referer': 'https://x/',
      });
      expect(
        pluginRequestHeaders([('X-A', '1'), ('x-a', '2')])!.headers['x-a'],
        '2',
      );
    });

    test('user-agent and accept pass; accept is not added', () {
      expect(headers({'User-Agent': 'Mozilla/5.0 X'})!.headers, {
        'user-agent': 'Mozilla/5.0 X',
      });
    });

    test('every dropped name is removed in any case', () {
      const dropped = [
        'host',
        'connection',
        'content-length',
        'transfer-encoding',
        'te',
        'upgrade',
        'keep-alive',
        'proxy-authorization',
        'proxy-connection',
        'proxy-x-anything',
        'trailer',
        'expect',
        'accept-encoding',
      ];
      for (final name in dropped) {
        expect(headers({name.toUpperCase(): 'x', 'x-ok': '1'})!.headers, {
          'x-ok': '1',
        }, reason: name);
      }
    });

    test('a bad value is invalid, even on a dropped name', () {
      for (final value in [
        'a\r\nX: b',
        'a\nb',
        'a\rb',
        'a\u0000b',
        'a\u007fb',
        'café',
      ]) {
        expect(headers({'x-a': value}), isNull, reason: value);
        expect(headers({'host': value}), isNull, reason: value);
      }
    });

    test('tab is allowed in a value', () {
      expect(headers({'x-a': 'a\tb c'})!.headers['x-a'], 'a\tb c');
    });

    test('a name that is not a token is invalid, even a dropped one', () {
      for (final name in ['', 'a b', 'a:b', 'a\nb', 'hé', 'user agent']) {
        expect(headers({name: 'x'}), isNull, reason: name);
      }
    });

    test('short values are not masked', () {
      final r = headers({
        'X-Token-Version': '2',
        'X-Key-Id': 'a',
        'Authorization': 'Bot abc',
      })!;
      expect(r.secrets, isEmpty);
    });

    test('secret values go to the mask set, sent ones only', () {
      final r = headers({
        'Authorization': 'Bearer abc123xyz',
        'Cookie': 'sid=secretsecret',
        'X-Api-Key': 'k-12345678',
        'X-Auth-Token': 't-12345678',
        'Accept': 'text/html',
        'Proxy-Authorization': 'Basic dropped-secret',
      })!;
      expect(
        r.secrets,
        containsAll([
          'Bearer abc123xyz',
          'abc123xyz',
          'sid=secretsecret',
          'k-12345678',
          't-12345678',
        ]),
      );
      expect(r.secrets, isNot(contains('text/html')));
      expect(r.secrets, isNot(contains('Basic dropped-secret')));
    });
  });

  group('setCookieSecrets', () {
    test('the line and its pair, only when long enough', () {
      expect(
        setCookieSecrets('sid=abcdef123; Path=/; HttpOnly'),
        containsAll(['sid=abcdef123; Path=/; HttpOnly', 'sid=abcdef123']),
      );
      expect(setCookieSecrets('a=b'), isEmpty);
    });
  });

  group('isPublicOnly', () {
    test('public addresses pass', () {
      expect(isPublicOnly([ip('93.184.216.34')]), isTrue);
      expect(isPublicOnly([ip('93.184.216.34'), ip('8.8.8.8')]), isTrue);
    });

    test('private, loopback, link-local, mixed and empty fail', () {
      for (final a in ['10.0.0.1', '127.0.0.1', '192.168.1.1', '169.254.1.1']) {
        expect(isPublicOnly([ip(a)]), isFalse, reason: a);
      }
      expect(isPublicOnly([ip('93.184.216.34'), ip('10.0.0.1')]), isFalse);
      expect(isPublicOnly(const []), isFalse);
    });

    test('198.18.0.0/15 counts as public (fake-ip proxies)', () {
      expect(isPublicOnly([ip('198.18.0.5')]), isTrue);
      expect(isPublicOnly([ip('198.19.255.1')]), isTrue);
    });

    test('IPv4-mapped and NAT64 take the class of the IPv4 they carry', () {
      List<int> v6(String text) => Uri.parseIPv6Address(text);
      expect(isPublicOnly([v6('::ffff:127.0.0.1')]), isFalse);
      expect(isPublicOnly([v6('::ffff:10.0.0.1')]), isFalse);
      expect(isPublicOnly([v6('64:ff9b::192.168.0.1')]), isFalse);
      expect(isPublicOnly([v6('::ffff:93.184.216.34')]), isTrue);
      expect(isPublicOnly([v6('64:ff9b::93.184.216.34')]), isTrue);
      expect(isPublicOnly([v6('::1')]), isFalse);
      expect(isPublicOnly([v6('fe80::1')]), isFalse);
    });
  });

  group('parseRetryAfter', () {
    final now = DateTime.utc(1994, 11, 6, 8, 49, 37);

    test('seconds', () {
      expect(parseRetryAfter('30'), const Duration(seconds: 30));
      expect(parseRetryAfter(' 120 '), const Duration(seconds: 120));
    });

    test('HTTP date', () {
      expect(
        parseRetryAfter('Sun, 06 Nov 1994 08:50:37 GMT', now: now),
        const Duration(seconds: 60),
      );
      expect(
        parseRetryAfter('Sun, 06 Nov 1994 08:49:57 GMT', now: now),
        const Duration(seconds: 20),
      );
    });

    test('clamped to 1 s .. 15 min', () {
      expect(parseRetryAfter('0'), const Duration(seconds: 1));
      expect(parseRetryAfter('5000'), const Duration(minutes: 15));
      expect(parseRetryAfter('99999999999999999999999'), maxRetryAfter);
      expect(
        parseRetryAfter('Sun, 06 Nov 1994 08:00:00 GMT', now: now),
        const Duration(seconds: 1),
      );
      expect(
        parseRetryAfter('Mon, 07 Nov 1994 08:49:37 GMT', now: now),
        const Duration(minutes: 15),
      );
    });

    test('a date that does not exist is unreadable', () {
      for (final v in [
        'Sun, 99 Nov 1994 99:99:99 GMT',
        'Mon, 31 Feb 1994 08:00:00 GMT',
        'Mon, 06 Nov 1994 24:00:00 GMT',
        'Mon, 06 Nov 1994 08:60:00 GMT',
      ]) {
        expect(
          parseRetryAfter(v, now: now),
          const Duration(seconds: 60),
          reason: v,
        );
      }
    });

    test('missing or unreadable gives 60 s', () {
      for (final v in [null, '', '  ', 'soon', '-5', '1.5', 'Sunday']) {
        expect(parseRetryAfter(v), const Duration(seconds: 60), reason: '$v');
      }
    });
  });
}
