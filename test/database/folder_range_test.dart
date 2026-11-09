import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

bool _inside(String folder, String locator) {
  final r = folderLocatorRange(folder);
  if (r == null) return true;
  return locator.compareTo(r.from) >= 0 && locator.compareTo(r.to) < 0;
}

void main() {
  test('bounds of a folder', () {
    expect(folderLocatorRange('Music/A'), (from: 'Music/A/', to: 'Music/A0'));
  });

  test('the root has no bound', () {
    expect(folderLocatorRange(''), isNull);
  });

  test('files below the folder are inside, at any depth', () {
    expect(_inside('a', 'a/x.flac'), isTrue);
    expect(_inside('a', 'a/b/c/x.flac'), isTrue);
    expect(_inside('a/b', 'a/b/c'), isTrue);
  });

  test('siblings with similar names are outside', () {
    for (final other in [
      'a b/x',
      'a-b/x',
      'a.b/x',
      'a0',
      'a0/x',
      'A/x',
      'a',
      'ab/x',
    ]) {
      expect(_inside('a', other), isFalse, reason: other);
    }
    expect(_inside('A B', 'A B/x'), isTrue);
    expect(_inside('A', 'A B/x'), isFalse);
    expect(_inside('a', 'a/b'), isTrue);
    expect(_inside('a/b', 'a/b0/x'), isFalse);
  });

  test('a key with a slash at either end throws', () {
    expect(() => folderLocatorRange('/a'), throwsArgumentError);
    expect(() => folderLocatorRange('a/'), throwsArgumentError);
  });
}
