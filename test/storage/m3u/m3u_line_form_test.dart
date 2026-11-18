import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_line_form.dart';

void main() {
  M3uLineProblem? problem(String line) {
    final f = classifyM3uLine(line);
    return f is M3uRejected ? f.problem : null;
  }

  String? absolute(String line) {
    final f = classifyM3uLine(line);
    return f is M3uAbsolute ? f.path : null;
  }

  test('absolute path', () => expect(absolute('/m/a.mp3'), '/m/a.mp3'));

  test('relative path has no alternative', () {
    final f = classifyM3uLine('Rock/a.mp3') as M3uRelative;
    expect((f.path, f.backslashAlt), ('Rock/a.mp3', null));
  });

  test('file URI decodes percent escapes as UTF-8', () {
    expect(absolute('file:///a%20b%C3%A9.mp3'), '/a bé.mp3');
  });

  test('file URI with localhost is accepted', () {
    expect(absolute('file://localhost/x.mp3'), '/x.mp3');
  });

  group('rejected file URIs', () {
    for (final line in [
      'file://host/x',
      'file:///x?y',
      'file:///x#y',
      'file://user@/x',
      'file://localhost:80/x',
      'file:///%ZZ',
      'file:relative.mp3',
    ]) {
      test(line, () => expect(problem(line), M3uLineProblem.badFileUri));
    }

    test('encoded NUL', () {
      expect(problem('file:///a%00b'), M3uLineProblem.nul);
    });

    test('Windows drive inside a file URI', () {
      expect(problem('file:///C:/a.mp3'), M3uLineProblem.driveLetter);
    });
  });

  group('other schemes', () {
    for (final line in ['http://x/a.mp3', 'https://x/a', 'rtsp://x/a']) {
      test(line, () => expect(problem(line), M3uLineProblem.uri));
    }
  });

  group('Windows forms', () {
    for (final line in [r'C:\Music\a.mp3', 'c:/a.mp3']) {
      test(line, () => expect(problem(line), M3uLineProblem.driveLetter));
    }

    test('backslash relative gets an alternative', () {
      final f = classifyM3uLine(r'Rock\a.mp3') as M3uRelative;
      expect((f.path, f.backslashAlt), (r'Rock\a.mp3', 'Rock/a.mp3'));
    });

    test('mixed separators get no alternative', () {
      final f = classifyM3uLine(r'Rock\x/a.mp3') as M3uRelative;
      expect(f.backslashAlt, isNull);
    });
  });

  test('"Artist: Song.mp3" is a relative name, not a scheme', () {
    final f = classifyM3uLine('Artist: Song.mp3') as M3uRelative;
    expect(f.path, 'Artist: Song.mp3');
  });

  test('NUL is rejected', () {
    expect(problem('/a\u0000b'), M3uLineProblem.nul);
  });

  test('line over 4096 bytes is rejected', () {
    expect(problem('/${'a' * 4096}'), M3uLineProblem.tooLong);
    expect(problem('/${'a' * 4095}'), isNull);
  });

  group('file URI text', () {
    test('raw non-ASCII characters are accepted', () {
      expect(absolute('file:///home/me/Nhạc/a.mp3'), '/home/me/Nhạc/a.mp3');
    });

    test('escapes and raw characters mix', () {
      expect(absolute('file:///Nh%E1%BA%A1c/Việt.mp3'), '/Nhạc/Việt.mp3');
    });

    test('invalid UTF-8 after decoding is rejected', () {
      expect(problem('file:///a%E9.mp3'), M3uLineProblem.badFileUri);
    });

    test('a truncated escape is rejected', () {
      expect(problem('file:///a%2'), M3uLineProblem.badFileUri);
      expect(problem('file:///a%'), M3uLineProblem.badFileUri);
    });
  });

  test('the classifier does not apply the raw byte limit', () {
    // 3000 two-byte characters in UTF-8, but one byte each in cp1252: the
    // parser decides tooLong from raw bytes, so the classifier accepts it.
    expect(problem('/${'é' * 3000}'), isNull);
  });
}
