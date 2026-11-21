import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/catalog/repo_url.dart';

void main() {
  group('canonicalRepoUrl', () {
    test('lower-cases, drops default ports and fragments, keeps the path', () {
      expect(
        canonicalRepoUrl('HTTPS://Repo.Example.COM:443/A/b/'),
        'https://repo.example.com/A/b/',
      );
      expect(
        canonicalRepoUrl('http://repo.lan:80/x.json#top'),
        'http://repo.lan/x.json',
      );
      expect(
        canonicalRepoUrl('http://repo.lan:8080/x.json'),
        'http://repo.lan:8080/x.json',
      );
      expect(
        canonicalRepoUrl('https://repo.example.com/catalog/'),
        'https://repo.example.com/catalog/',
      );
      expect(canonicalRepoUrl('http://[::1]:8080/p'), 'http://[::1]:8080/p');
    });

    test('a bare root slash goes, a query stays', () {
      expect(
        canonicalRepoUrl('  https://repo.example.com/  '),
        'https://repo.example.com',
      );
      expect(
        canonicalRepoUrl('https://repo.example.com/?v=1'),
        'https://repo.example.com?v=1',
      );
    });

    test('spellings of one repository are equal', () {
      expect(
        canonicalRepoUrl('https://a.example.com/p#x'),
        canonicalRepoUrl('HTTPS://A.EXAMPLE.COM:443/p'),
      );
    });

    test('is idempotent', () {
      final once = canonicalRepoUrl('HTTP://Repo.Lan:80/A?x=1#f')!;
      expect(canonicalRepoUrl(once), once);
    });

    test('rejects what is not an http(s) address with a host', () {
      for (final bad in [
        '',
        'x',
        'ftp://a.example.com',
        'https://',
        '/p',
        'file:///etc',
        'javascript:alert(1)',
        'https://[bad',
      ]) {
        expect(canonicalRepoUrl(bad), isNull, reason: bad);
      }
    });

    test('rejects user info', () {
      expect(canonicalRepoUrl('https://user:pw@repo.example.com/p'), isNull);
      expect(canonicalRepoUrl('https://user@repo.example.com/p'), isNull);
    });
  });
}
