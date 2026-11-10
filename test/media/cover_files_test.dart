import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/cover_files.dart';

void main() {
  final ok = 'ab/${'0123456789abcdef' * 2}';

  test('valid key', () => expect(isCoverKey(ok), isTrue));

  test('invalid keys rejected', () {
    for (final bad in [
      '../etc/passwd',
      '../${'a' * 32}',
      'AB/${'a' * 32}',
      'ab/${'A' * 32}',
      'ab/${'a' * 31}',
      'ab/${'a' * 33}',
      'a/${'a' * 32}',
      'ab/${'a' * 32}\n',
      '',
    ]) {
      expect(isCoverKey(bad), isFalse, reason: bad);
      expect(
        () => coverRelativePath(bad, CoverSize.thumb),
        throwsArgumentError,
      );
    }
  });

  test('relative path per size', () {
    expect(coverRelativePath(ok, CoverSize.thumb), 'covers/thumb/$ok.jpg');
    expect(coverRelativePath(ok, CoverSize.full), 'covers/full/$ok.jpg');
  });
}
