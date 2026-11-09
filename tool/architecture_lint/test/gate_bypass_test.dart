import 'dart:io';

import 'package:kanaru_architecture/src/architecture_core.dart';
import 'package:kanaru_architecture/src/cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _yaml = '''
package: app
special: [rust]
domain_forbidden: [go_router]
modules:
  foundation: []
  media: [foundation]
  library: [media]
  screens: [library]
  shell: [screens]
''';

void main() {
  test('isArchitectureIgnore flags blanket type=lint ignores', () {
    expect(isArchitectureIgnore('// ignore_for_file: type=lint'), isTrue);
    expect(isArchitectureIgnore('// ignore: type=lint'), isTrue);
    expect(isArchitectureIgnore('// ignore_for_file: unused_import'), isFalse);
  });

  group('CLI bypass attempts', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('arch_bypass_');
      File(p.join(root.path, 'architecture.yaml')).writeAsStringSync(_yaml);
    });
    tearDown(() => root.deleteSync(recursive: true));

    void write(String rel, String content) {
      File(p.join(root.path, rel))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    String check({int expectCode = 1}) {
      final out = StringBuffer();
      expect(run([root.path], out: out, err: out), expectCode, reason: '$out');
      return out.toString();
    }

    test('a module importing the composition root is reported', () {
      write('lib/kanaru.dart', '');
      write('lib/src/media/a.dart', "import 'package:app/kanaru.dart';\n");
      write('lib/src/screens/b.dart', "import '../../kanaru.dart';\n");
      final out = check();
      expect(out, contains('lib/src/media/a.dart'));
      expect(out, contains('lib/src/screens/b.dart'));
      expect(out, contains('composition root'));
    });

    test('the composition root may import modules', () {
      write('lib/kanaru.dart', "import 'src/media/m.dart';\n");
      write('lib/src/media/m.dart', '');
      check(expectCode: 0);
    });

    test('a file directly in lib/src is reported, with or without imports', () {
      write('lib/src/loose.dart', '');
      write('lib/src/media/m.dart', "import '../loose.dart';\n");
      final out = check();
      expect(out, contains('lib/src/loose.dart:1:1'));
      expect(out, contains('outside any module'));
      expect(out, contains('lib/src/media/m.dart'));
    });

    test('domain may not import dart:ui, flutter_*, listed packages', () {
      write('lib/src/media/domain/a.dart', "import 'dart:ui';\n");
      write('lib/src/media/domain/b.dart', "import 'package:flutter_riverpod/flutter_riverpod.dart';\n");
      write('lib/src/media/domain/c.dart', "import 'package:go_router/go_router.dart';\n");
      write('lib/src/media/domain/d.dart', "import 'package:kanaru_ui/kanaru_ui.dart';\n");
      write('lib/src/media/domain/e.dart', "import 'dart:io';\nimport 'package:drift/drift.dart';\n");
      final out = check();
      for (final f in ['a', 'b', 'c', 'd']) {
        expect(out, contains('media/domain/$f.dart'), reason: f);
      }
      expect(out, isNot(contains('media/domain/e.dart')));
    });

    test('domain may not import data, state or ui, even of its own module', () {
      write('lib/src/media/ui/u.dart', '');
      write('lib/src/media/state/s.dart', '');
      write('lib/src/media/data/d.dart', '');
      write('lib/src/media/domain/a.dart', "import '../ui/u.dart';\n");
      write('lib/src/media/domain/b.dart', "import '../state/s.dart';\n");
      write('lib/src/media/domain/c.dart', "import '../data/d.dart';\n");
      write('lib/src/media/domain/ok.dart', "import 'a.dart';\n");
      final out = check();
      expect(RegExp('domain_layer').allMatches(out), hasLength(3));
      expect(out, isNot(contains('domain/ok.dart')));
    });

    test('kanaru_ui importing the app is reported', () {
      write('packages/kanaru_ui/lib/x.dart', "import 'package:app/kanaru.dart';\n");
      write('packages/kanaru_ui/lib/y.dart', "import 'package:flutter/widgets.dart';\n");
      write('packages/kanaru_extensions/lib/z.dart', "import 'package:app/kanaru.dart';\n");
      final out = check();
      expect(out, contains('packages/kanaru_ui/lib/x.dart'));
      expect(out, isNot(contains('kanaru_extensions')));
      expect(out, contains('[package_imports_app]'));
      expect(out, isNot(contains('packages/kanaru_ui/lib/y.dart')));
    });

    test('width idioms are reported, also import-prefixed', () {
      write('lib/src/library/ui/u.dart', '''
void f(c) {
  MediaQuery.of(c).size.width;
  MediaQuery.maybeOf(c)?.size;
  MediaQuery.widthOf(c);
  MediaQuery.heightOf(c);
  MediaQuery.maybeSizeOf(c);
  w.MediaQuery.sizeOf(c);
  w.LayoutBuilder(builder: null);
  MediaQuery.of(c).padding;
  MediaQuery.platformBrightnessOf(c);
}
''');
      final out = check();
      expect(RegExp(r'library/ui/u\.dart.*layout_api_outside_shell').allMatches(out), hasLength(7));
    });

    test('type=lint ignore in a hand-written file fails the gate', () {
      write('lib/src/media/m.dart', '// ignore_for_file: type=lint\nvoid f() {}\n');
      expect(check(), contains('[architecture_ignore]'));
    });
  });
}
