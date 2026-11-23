import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/font_registrar.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/domain/app_font.dart';
import 'package:kanaru/src/fonts/domain/builtin_fonts.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

void main() {
  late Directory tmp;
  late FontStorage storage;
  const font = AppFont(
    id: 'lato',
    label: 'Lato',
    family: 'Lato',
    kind: AppFontKind.catalog,
  );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('font_registrar');
    storage = FontStorage(_Paths(tmp));
    final dir = storage.fontDir(AppFontKind.catalog, 'lato')
      ..createSync(recursive: true);
    File('${dir.path}/a.ttf').writeAsBytesSync([1, 2]);
    File('${dir.path}/b.ttf').writeAsBytesSync([3]);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('built-in fonts never reach the registrar', () async {
    var calls = 0;
    final r = FontRegistrar(registrar: (_, _) async => calls++);
    await r.ensureLoaded(nunitoFont, storage);
    expect(calls, 0);
  });

  test('registers all files of the family once', () async {
    final seen = <(String, List<Uint8List>)>[];
    final r = FontRegistrar(registrar: (f, b) async => seen.add((f, b)));
    await r.ensureLoaded(font, storage);
    await r.ensureLoaded(font, storage);
    expect(seen, hasLength(1));
    expect(seen.single.$1, 'Lato');
    expect(seen.single.$2, hasLength(2));
    expect(r.isFamilyLoaded('Lato'), isTrue);
  });

  test('concurrent calls share one load', () async {
    final gate = Completer<void>();
    var calls = 0;
    final r = FontRegistrar(
      registrar: (_, _) {
        calls++;
        return gate.future;
      },
    );
    final a = r.ensureLoaded(font, storage);
    final b = r.ensureLoaded(font, storage);
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await Future.wait([a, b]);
    expect(calls, 1);
  });

  test('a failed load can be retried', () async {
    var fail = true;
    final r = FontRegistrar(
      registrar: (_, _) async {
        if (fail) throw StateError('boom');
      },
    );
    await expectLater(r.ensureLoaded(font, storage), throwsStateError);
    expect(r.isFamilyLoaded('Lato'), isFalse);
    fail = false;
    await r.ensureLoaded(font, storage);
    expect(r.isFamilyLoaded('Lato'), isTrue);
  });

  test(
    'a font whose files are missing loads once they are installed',
    () async {
      const other = AppFont(
        id: 'gone',
        label: 'Gone',
        family: 'Gone',
        kind: AppFontKind.catalog,
      );
      var calls = 0;
      final r = FontRegistrar(registrar: (_, _) async => calls++);
      await expectLater(r.ensureLoaded(other, storage), throwsStateError);
      expect(calls, 0);
      final dir = storage.fontDir(AppFontKind.catalog, 'gone')
        ..createSync(recursive: true);
      File('${dir.path}/g.ttf').writeAsBytesSync([9]);
      await r.ensureLoaded(other, storage);
      expect(calls, 1);
      expect(r.isFamilyLoaded('Gone'), isTrue);
    },
  );
}
