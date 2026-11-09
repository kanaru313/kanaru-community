import 'dart:io';

import 'package:kanaru_architecture/src/architecture_core.dart';
import 'package:kanaru_architecture/src/cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _yaml = '''
package: app
special: [rust]
modules:
  foundation: []
  media: [foundation]
  playback: [media]
  library: [playback]
  screens: [library]
  shell: [screens]
''';

void main() {
  group('ArchitectureConfig', () {
    test('allows the transitive closure', () {
      final cfg = ArchitectureConfig.parse(_yaml);
      expect(cfg.package, 'app');
      expect(cfg.allowed['library'], containsAll(['playback', 'media', 'foundation']));
      expect(cfg.allowed['media'], isNot(contains('library')));
    });

    test('package defaults to kanaru', () {
      expect(ArchitectureConfig.parse('modules:\n  a: []\n').package, 'kanaru');
    });

    test('detects a cycle', () {
      final cfg = ArchitectureConfig.parse('modules:\n  a: [b]\n  b: [a]\n');
      expect(cfg.findCycle(), isNotNull);
      expect(ArchitectureConfig.parse(_yaml).findCycle(), isNull);
    });
  });

  group('ignore and layout helpers', () {
    test('architecture ignore comments are recognised', () {
      expect(isArchitectureIgnore('// ignore: module_dependency'), isTrue);
      expect(isArchitectureIgnore('// ignore_for_file: kanaru_architecture'), isTrue);
      expect(isArchitectureIgnore('// ignore: unused_import, screens_no_data'), isTrue);
      expect(isArchitectureIgnore('// ignore: unused_import'), isFalse);
      expect(isArchitectureIgnore('// module_dependency is a rule'), isFalse);
    });

    test('layout API allowed only in kanaru_ui and shell', () {
      expect(layoutApiAllowed('/r/packages/kanaru_ui/lib/a.dart'), isTrue);
      expect(layoutApiAllowed('/r/lib/src/shell/a.dart'), isTrue);
      expect(layoutApiAllowed('/r/lib/src/library/ui/a.dart'), isFalse);
    });
  });

  group('CLI on a fixture app', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('arch_lint_');
      File(p.join(root.path, 'architecture.yaml')).writeAsStringSync(_yaml);
    });
    tearDown(() => root.deleteSync(recursive: true));

    void write(String rel, String content) {
      final f = File(p.join(root.path, rel))..createSync(recursive: true);
      f.writeAsStringSync(content);
    }

    (int, String) check() {
      final out = StringBuffer();
      final code = run([root.path], out: out, err: out);
      return (code, out.toString());
    }

    test('clean app exits 0', () {
      write('lib/src/media/m.dart', "import '../foundation/f.dart';\n");
      write('lib/src/foundation/f.dart', '');
      write('lib/src/library/ui/u.dart', "import 'package:app/src/playback/p.dart';\n");
      write('lib/src/playback/p.dart', '');
      expect(check().$1, 0);
    });

    test('upward relative import is reported', () {
      write('lib/src/media/m.dart', "import '../library/l.dart';\n");
      write('lib/src/library/l.dart', '');
      final (code, out) = check();
      expect(code, 1);
      expect(out, contains('lib/src/media/m.dart:1:8'));
      expect(out, contains('[module_dependency]'));
    });

    test('package import, export, part and conditional import are checked', () {
      write('lib/src/media/a.dart', "import 'package:app/src/library/l.dart';\n");
      write('lib/src/media/b.dart', "export 'package:app/src/library/l.dart';\n");
      write('lib/src/media/c.dart', "part '../library/l.dart';\n");
      write('lib/src/media/d.dart',
          "import 'x.dart' if (dart.library.io) '../library/l.dart';\n");
      write('lib/src/media/x.dart', '');
      write('lib/src/library/l.dart', '');
      final (code, out) = check();
      expect(code, 1);
      for (final f in ['a', 'b', 'c', 'd']) {
        expect(out, contains('lib/src/media/$f.dart'));
      }
    });

    test('domain may not import Flutter', () {
      write('lib/src/media/domain/t.dart', "import 'package:flutter/material.dart';\n");
      expect(check().$2, contains('[domain_no_flutter]'));
    });

    test('screens may not import data or database', () {
      write('lib/src/screens/s.dart', "import '../library/data/repo.dart';\n");
      write('lib/src/library/data/repo.dart', '');
      expect(check().$2, contains('[screens_no_data]'));
    });

    test('rust only from a data folder', () {
      write('lib/src/rust/api.dart', '');
      write('lib/src/library/ui/u.dart', "import '../../rust/api.dart';\n");
      write('lib/src/library/data/d.dart', "import '../../rust/api.dart';\n");
      final (_, out) = check();
      expect(out, contains('lib/src/library/ui/u.dart'));
      expect(out, isNot(contains('lib/src/library/data/d.dart')));
      expect(out, contains('[rust_only_from_data]'));
    });

    test('layout APIs outside shell are reported, inside shell are not', () {
      const body = 'void f(ctx) { MediaQuery.sizeOf(ctx); LayoutBuilder(builder: null); }\n';
      write('lib/src/library/ui/u.dart', body);
      write('lib/src/shell/s.dart', body);
      final (code, out) = check();
      expect(code, 1);
      expect(RegExp(r'library/ui/u\.dart.*layout_api_outside_shell').allMatches(out), hasLength(2));
      expect(out, isNot(contains('shell/s.dart')));
    });

    test('ignore comments for architecture rules fail the gate', () {
      write('lib/src/media/m.dart', '// ignore: module_dependency\nvoid f() {}\n');
      final (code, out) = check();
      expect(code, 1);
      expect(out, contains('[architecture_ignore]'));
    });

    test('unrelated ignore comments are fine', () {
      write('lib/src/media/m.dart', '// ignore: unused_element\nvoid f() {}\n');
      expect(check().$1, 0);
    });

    test('cyclic architecture.yaml exits 2', () {
      File(p.join(root.path, 'architecture.yaml'))
          .writeAsStringSync('modules:\n  a: [b]\n  b: [a]\n');
      write('lib/src/a/a.dart', '');
      expect(check().$1, 2);
    });

    test('missing architecture.yaml exits 2', () {
      File(p.join(root.path, 'architecture.yaml')).deleteSync();
      expect(check().$1, 2);
    });
  });
}
