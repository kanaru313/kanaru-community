import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_relative_path.dart';

void main() {
  for (final (from, to, want) in [
    ('/a/b', '/a/b/c.mp3', 'c.mp3'),
    ('/a/b', '/a/b/x/c.mp3', 'x/c.mp3'),
    ('/a/b', '/a/x/c.mp3', '../x/c.mp3'),
    ('/a/b/c', '/a/x/y.mp3', '../../x/y.mp3'),
    ('/a', '/b/c.mp3', '../b/c.mp3'),
    ('/', '/a/c.mp3', 'a/c.mp3'),
    ('/a/b', '/c.mp3', '../../c.mp3'),
    // The file name is never a shared folder.
    ('/a/b', '/a/b', '../b'),
    ('/a/b', '/a/b/b', 'b'),
  ]) {
    test('$from -> $to', () => expect(relativeM3uPath(from, to), want));
  }
}
