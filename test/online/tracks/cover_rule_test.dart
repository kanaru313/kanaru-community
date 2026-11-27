import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/domain/tracks/cover_rule.dart';

String? rule(
  String? url, {
  Set<String> hosts = const {
    'i.ytimg.com',
    'usercontent.jamendo.com',
    '*.audius.co',
  },
  List<String> config = const [],
}) => persistableCoverUrl(url, manifestHosts: hosts, configValues: config);

void main() {
  group('kept', () {
    for (final url in [
      'https://i.ytimg.com/vi/x/hq720.jpg?sqp=abc&rs=def',
      'https://usercontent.jamendo.com/?type=album&id=1&width=300',
      'https://creatornode.audius.co/content/cover/480x480.jpg',
    ]) {
      test(url, () => expect(rule(url), url));
    }

    test('a config value that only shares letters with a segment', () {
      expect(
        rule('https://i.ytimg.com/vi/abcdef/a.jpg', config: ['abc']),
        isNotNull,
      );
    });
  });

  group('refused', () {
    const subsonic =
        'https://music.example.net/rest/getCoverArt.view?id=1&u=me&t=abc&s=salt';
    final cases = <String, String?>{
      'null': null,
      'http': 'http://i.ytimg.com/vi/x.jpg',
      'host not in the manifest': 'https://other.example.com/x.jpg',
      'userinfo': 'https://me:pw@i.ytimg.com/x.jpg',
      'port 443': 'https://i.ytimg.com:443/x.jpg',
      'other port': 'https://i.ytimg.com:8443/x.jpg',
      'ip literal': 'https://203.0.113.9/x.jpg',
      'wildcard two labels deep': 'https://a.b.audius.co/x.jpg',
      'token': 'https://i.ytimg.com/x.jpg?token=abc',
      'API_KEY in upper case': 'https://i.ytimg.com/x.jpg?API_KEY=abc',
      'fragment': 'https://i.ytimg.com/x.jpg#frag',
      'subsonic signature': subsonic,
    };
    cases.forEach((name, url) => test(name, () => expect(rule(url), isNull)));

    test('a user endpoint even when the manifest lists its host', () {
      expect(rule(subsonic, hosts: {'music.example.net'}), isNull);
    });

    test('a query value equal to a config value', () {
      expect(
        rule(
          'https://usercontent.jamendo.com/?id=1&c=secret123',
          config: ['secret123'],
        ),
        isNull,
      );
    });

    test('a path segment equal to a config value', () {
      expect(
        rule('https://i.ytimg.com/secret123/x.jpg', config: ['secret123']),
        isNull,
      );
      expect(rule('https://i.ytimg.com/a%20b/x.jpg', config: ['a b']), isNull);
    });

    test('an empty config value never matches', () {
      expect(rule('https://i.ytimg.com/vi/x.jpg', config: ['']), isNotNull);
    });

    test('a URL over 2000 characters', () {
      final long = 'https://i.ytimg.com/${'a' * 2000}.jpg';
      expect(long.length, greaterThan(2000));
      expect(rule(long), isNull);
    });
  });
}
