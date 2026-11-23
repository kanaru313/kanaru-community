import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/domain/app_font.dart';
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

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('font_storage');
    storage = FontStorage(_Paths(tmp));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('fontDir rejects invalid ids and built-in kind', () {
    expect(
      () => storage.fontDir(AppFontKind.custom, '../x'),
      throwsArgumentError,
    );
    expect(
      () => storage.fontDir(AppFontKind.catalog, 'a/b'),
      throwsArgumentError,
    );
    expect(
      () => storage.fontDir(AppFontKind.builtIn, 'inter'),
      throwsArgumentError,
    );
  });

  test('fontFiles lists only font files, sorted; empty when missing', () {
    const font = AppFont(
      id: 'lato',
      label: 'Lato',
      family: 'Lato',
      kind: AppFontKind.catalog,
    );
    expect(storage.fontFiles(font), isEmpty);
    final dir = storage.fontDir(AppFontKind.catalog, 'lato')
      ..createSync(recursive: true);
    File('${dir.path}/b.ttf').writeAsBytesSync([1]);
    File('${dir.path}/a.OTF').writeAsBytesSync([1]);
    File('${dir.path}/LICENSE.txt').writeAsStringSync('x');
    expect(storage.fontFiles(font).map((f) => f.uri.pathSegments.last), [
      'a.OTF',
      'b.ttf',
    ]);
  });

  test('repairTmpLeftovers removes .tmp entries only', () {
    storage.catalogDir.createSync(recursive: true);
    storage.customDir.createSync(recursive: true);
    final tmpDir = Directory('${storage.catalogDir.path}/lato.tmp')
      ..createSync();
    File('${tmpDir.path}/x.ttf').writeAsBytesSync([1]);
    final tmpFile = File('${storage.customDir.path}/f.tmp')
      ..writeAsBytesSync([1]);
    final keep = Directory('${storage.catalogDir.path}/lato')..createSync();
    storage.repairTmpLeftovers();
    expect(tmpDir.existsSync(), isFalse);
    expect(tmpFile.existsSync(), isFalse);
    expect(keep.existsSync(), isTrue);
  });

  test('repairTmpLeftovers does nothing when folders are missing', () {
    expect(storage.repairTmpLeftovers, returnsNormally);
  });
}
