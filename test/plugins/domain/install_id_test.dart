import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';

void main() {
  const url = 'https://repo.example.com/plugins.json';

  test('repo id vectors: plugin- plus 32 hex of the source', () {
    expect(
      repoInstallId(url, 'netease'),
      'plugin-c4ca8f8808a818bc6d01ffd02be59318',
    );
    expect(
      repoInstallId(url, 'lrclib'),
      'plugin-9e69e0f354889d04ae25307010f4a8c8',
    );
    expect(
      repoInstallId('http://192.168.1.5:8765/plugins.json', 'netease'),
      'plugin-0c6cc0df0ecb273219923a09cedba655',
    );
  });

  test('file id vectors: name and author, null author is empty', () {
    expect(
      fileInstallId('Demo', 'someone'),
      'plugin-65761beabd82c6ce792f88ea8a515a7f',
    );
    expect(
      fileInstallId('Demo', ''),
      'plugin-185c01390bc481204de3afe24ab0e66e',
    );
    expect(fileInstallId('Demo', null), fileInstallId('Demo', ''));
    expect(
      fileInstallId('Tiếng Việt', 'Hiếu'),
      'plugin-ee12d6b54dc33bcdd9d76dedbbf4d6b5',
    );
  });

  test('every id is plugin- plus 32 lower-case hex', () {
    final shape = RegExp(r'^plugin-[0-9a-f]{32}$');
    expect(shape.hasMatch(repoInstallId(url, 'a')), isTrue);
    expect(shape.hasMatch(fileInstallId('a', 'b')), isTrue);
  });

  test('repo and file ids never collide on the same words', () {
    expect(
      repoInstallId('Demo', 'someone'),
      isNot(fileInstallId('Demo', 'someone')),
    );
  });

  test('parts cannot be shifted into each other', () {
    expect(
      repoInstallId('https://a.example.com/x', 'y'),
      isNot(repoInstallId('https://a.example.com/', 'xy')),
    );
    expect(fileInstallId('ab', 'c'), isNot(fileInstallId('a', 'bc')));
  });

  test('a different slug or repository gives a different id', () {
    expect(repoInstallId(url, 'a'), isNot(repoInstallId(url, 'b')));
    expect(
      repoInstallId(url, 'a'),
      isNot(repoInstallId('https://other.example.com/plugins.json', 'a')),
    );
  });
}
