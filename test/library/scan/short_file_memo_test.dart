import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/tag_pass_types.dart';
import 'package:kanaru/src/storage/domain/local_folder_listing.dart';

ListedFile _f({int mtime = 10, int size = 100}) =>
    ListedFile(locator: 'a.mp3', sizeBytes: size, mtimeMs: mtime);

void main() {
  test(
    'skips a remembered short file while the minimum is above its length',
    () {
      final memo = ShortFileMemo()..remember(1, _f(), 40000);
      expect(memo.skips(1, _f(), 60000), isTrue);
      expect(memo.skips(1, _f(), 40001), isTrue);
    },
  );

  test('a minimum at or below the remembered length reads the file again', () {
    final memo = ShortFileMemo()..remember(1, _f(), 40000);
    expect(memo.skips(1, _f(), 40000), isFalse);
    expect(memo.skips(1, _f(), 30000), isFalse);
  });

  test('the rule off never skips', () {
    final memo = ShortFileMemo()..remember(1, _f(), 1000);
    expect(memo.skips(1, _f(), 0), isFalse);
  });

  test('a changed mtime or size, or another source, is not skipped', () {
    final memo = ShortFileMemo()..remember(1, _f(), 1000);
    expect(memo.skips(1, _f(mtime: 11), 30000), isFalse);
    expect(memo.skips(1, _f(size: 101), 30000), isFalse);
    expect(memo.skips(2, _f(), 30000), isFalse);
  });

  test('forget removes the note; remember replaces an older one', () {
    final memo = ShortFileMemo()..remember(1, _f(), 1000);
    memo.remember(1, _f(mtime: 20), 50000);
    expect(memo.length, 1);
    expect(memo.skips(1, _f(), 60000), isFalse);
    expect(memo.skips(1, _f(mtime: 20), 60000), isTrue);
    memo.forget(1, _f(mtime: 20));
    expect(memo.length, 0);
    expect(memo.skips(1, _f(mtime: 20), 60000), isFalse);
  });
}
