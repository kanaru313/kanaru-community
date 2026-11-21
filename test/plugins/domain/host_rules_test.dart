import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/host_rules.dart';

void main() {
  group('publicHostProblem', () {
    for (final host in [
      'xn--80ak6aa92e.com',
      'music.xn--p1ai',
      'a1.example.co.uk',
      'lrclib.net',
    ]) {
      test('accepts $host', () => expect(publicHostProblem(host), isNull));
    }

    for (final host in [
      'localhost',
      'api.localhost',
      '10.0.0.1',
      '127.0.0.1',
      '169.254.1.1',
      '127.0.0.0x1',
      '0x7f.0x1',
      '127.1.0x0',
      '1.2.3.4a',
      'example.1com',
      '[::1]',
      'music',
      'lyrics.test.net:8443',
      'lyrics.test.net/path',
      'user@lyrics.test.net',
      'printer.local',
      'nas.home.arpa',
      'box.localdomain',
      'a.internal',
      'a.lan',
      '',
      'a..b.com',
      '-a.example.com',
      'a-.example.com',
      'https://lyrics.test.net',
      'UPPER.example.com',
    ]) {
      test('refuses "$host"', () => expect(publicHostProblem(host), isNotNull));
    }
  });

  group('hostPatternProblem', () {
    for (final pattern in [
      'googlevideo.com',
      '*.googlevideo.com',
      '*.a.b.example.com',
      '*.xn--p1ai.example',
    ]) {
      test('accepts $pattern', () {
        expect(hostPatternProblem(pattern), isNull);
      });
    }

    for (final pattern in [
      '*',
      '*.com',
      '*.local',
      '*.1.2.3',
      'a.*.b.com',
      '*foo.com',
      '**.a.com',
      '*.',
      '*.*.a.com',
      'a.com*',
      '*.localhost',
      '*.api.localhost',
      '*.127.0.0.1',
      '*.-a.com',
      '*.Example.com',
      '*.a.com:443',
      '',
    ]) {
      test('refuses "$pattern"', () {
        expect(hostPatternProblem(pattern), isNotNull);
      });
    }
  });

  group('hostListProblem', () {
    test('a plain list passes with or without wildcards allowed', () {
      for (final allowed in [true, false]) {
        expect(
          hostListProblem([
            'www.youtube.com',
            'youtubei.googleapis.com',
          ], wildcardsAllowed: allowed),
          isNull,
        );
      }
    });

    test('wildcards up to the cap pass when allowed', () {
      expect(
        hostListProblem([
          'www.youtube.com',
          for (var i = 0; i < maxHostWildcards; i++) '*.h$i.example.com',
        ], wildcardsAllowed: true),
        isNull,
      );
    });

    test('any wildcard is refused when wildcards are not allowed', () {
      for (final wildcard in ['*.googlevideo.com', '*.ytimg.com']) {
        final found = hostListProblem([
          'www.youtube.com',
          wildcard,
        ], wildcardsAllowed: false);
        expect(found?.entry, wildcard);
        expect(found?.reason, HostRefusal.wildcardNotAllowed);
      }
    });

    test('the first refused entry is reported', () {
      final cases = <List<String>, (String, HostRefusal)>{
        ['www.youtube.com', '*.googlevideo.com']: (
          '*.googlevideo.com',
          HostRefusal.wildcardNotAllowed,
        ),
        ['a.com', '*', '*.b.com']: ('*', HostRefusal.badWildcard),
        ['a.com', 'b..com']: ('b..com', HostRefusal.notPublic),
      };
      for (final MapEntry(key: hosts, value: (entry, reason))
          in cases.entries) {
        final found = hostListProblem(hosts, wildcardsAllowed: false);
        expect(found?.entry, entry, reason: '$hosts');
        expect(found?.reason, reason, reason: '$hosts');
      }
    });

    test('a malformed entry is refused even when wildcards are allowed', () {
      for (final bad in ['*.com', 'a.*.b.com', '*foo.com', '127.0.0.1']) {
        final found = hostListProblem(['a.com', bad], wildcardsAllowed: true);
        expect(found?.entry, bad);
        expect(
          found?.reason,
          bad.contains('*') ? HostRefusal.badWildcard : HostRefusal.notPublic,
        );
      }
    });

    test('a wildcard over a shared-hosting suffix is refused', () {
      expect(deniedWildcardBases, hasLength(16));
      for (final base in deniedWildcardBases) {
        final found = hostListProblem(['*.$base'], wildcardsAllowed: true);
        expect(found?.entry, '*.$base');
        expect(found?.reason, HostRefusal.sharedHostingWildcard);
      }
    });

    test('a plain host under a shared-hosting suffix stays allowed', () {
      expect(
        hostListProblem(['someone.github.io'], wildcardsAllowed: false),
        isNull,
      );
    });

    test('the first wildcard over the cap is refused', () {
      final found = hostListProblem([
        for (var i = 0; i < maxHostWildcards; i++) '*.h$i.example.com',
        'plain.com',
        '*.over.example.com',
      ], wildcardsAllowed: true);
      expect(found?.entry, '*.over.example.com');
      expect(found?.reason, HostRefusal.tooManyWildcards);
    });

    test('a repeated wildcard counts once toward the cap', () {
      expect(
        hostListProblem([
          '*.a.com',
          for (var i = 1; i < maxHostWildcards; i++) '*.h$i.example.com',
          '*.a.com',
        ], wildcardsAllowed: true),
        isNull,
      );
    });
  });

  group('HostPattern.matches', () {
    final wildcard = HostPattern.tryParse('*.googlevideo.com')!;
    final plain = HostPattern.tryParse('www.youtube.com')!;

    final wildcardTable = {
      'rr1---sn-x.googlevideo.com': true,
      'RR1.GoogleVideo.com': true,
      'a.googlevideo.com': true,
      'googlevideo.com': false,
      'a.b.googlevideo.com': false,
      'evilgooglevideo.com': false,
      'googlevideo.com.evil.com': false,
      'rr1.googlevideo.com.': false,
      '-a.googlevideo.com': false,
      'a-.googlevideo.com': false,
      '${'a' * 63}.googlevideo.com': true,
      '${'a' * 64}.googlevideo.com': false,
      '*.googlevideo.com': false,
      'a_b.googlevideo.com': false,
      '.googlevideo.com': false,
      '': false,
    };
    for (final MapEntry(key: host, value: allowed) in wildcardTable.entries) {
      test('wildcard ${allowed ? 'matches' : 'refuses'} "$host"', () {
        expect(wildcard.matches(host), allowed);
      });
    }

    test('a plain entry matches exactly, case-insensitively', () {
      expect(plain.matches('www.youtube.com'), isTrue);
      expect(plain.matches('WWW.YouTube.com'), isTrue);
      expect(plain.matches('m.youtube.com'), isFalse);
      expect(plain.matches('www.youtube.com.'), isFalse);
      expect(plain.matches(''), isFalse);
    });

    test('an entry that is not a valid pattern does not parse', () {
      for (final entry in [
        '*.com',
        '*.workers.dev',
        'a.*.b.com',
        '*foo.com',
        '*',
        '127.0.0.1',
        'localhost',
      ]) {
        expect(HostPattern.tryParse(entry), isNull, reason: entry);
      }
    });

    test('isWildcard tells the two kinds apart', () {
      expect(wildcard.isWildcard, isTrue);
      expect(plain.isWildcard, isFalse);
    });
  });

  group('hostSetCovers', () {
    test('an equal or smaller set is covered', () {
      expect(hostSetCovers(['a.com', 'b.com'], ['a.com']), isTrue);
      expect(hostSetCovers(['a.com', 'b.com'], ['b.com', 'a.com']), isTrue);
      expect(hostSetCovers(['a.com'], const []), isTrue);
    });

    test('a new host is not covered', () {
      expect(hostSetCovers(['a.com'], ['a.com', 'b.com']), isFalse);
      expect(hostSetCovers(const [], ['a.com']), isFalse);
    });

    test('a wildcard is covered only by the same wildcard', () {
      expect(hostSetCovers(['*.a.com'], ['*.a.com']), isTrue);
      expect(hostSetCovers(['a.com', 'x.a.com'], ['*.a.com']), isFalse);
      expect(hostSetCovers(['*.a.com'], ['*.b.com']), isFalse);
      expect(hostSetCovers(['*.a.com'], ['*.x.a.com']), isFalse);
    });

    test('a plain name one label under a consented wildcard is covered', () {
      expect(hostSetCovers(['*.a.com'], ['x.a.com']), isTrue);
      expect(hostSetCovers(['*.a.com'], ['x.y.a.com']), isFalse);
      expect(hostSetCovers(['*.a.com'], ['a.com']), isFalse);
    });

    test('a consented wildcard on a denied base covers nothing', () {
      expect(hostSetCovers(['*.workers.dev'], ['x.workers.dev']), isFalse);
    });
  });
}
