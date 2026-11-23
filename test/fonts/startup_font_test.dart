import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/font_registrar.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/data/startup_font.dart';
import 'package:kanaru/src/fonts/domain/app_font.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';

import '../support/memory_settings_store.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

class _ThrowingStore extends MemorySettingsStore {
  bool failWrites = false;

  @override
  Future<void> write(String key, Object? value) async {
    if (failWrites) throw const FileSystemException('disk full');
    await super.write(key, value);
  }
}

void main() {
  late Directory tmp;
  late _Paths paths;
  late MemorySettingsStore settings;
  late List<String> loaded;
  late FontRegistrar registrar;
  const lato = AppFont(
    id: 'lato',
    label: 'Lato',
    family: 'Lato',
    kind: AppFontKind.catalog,
  );
  const customId = 'custom_my_font_1a2b3c4d';

  Future<String> run({FontRegistrar? r, MemorySettingsStore? store}) =>
      prepareStartupFont(
        paths: paths,
        settings: store ?? settings,
        registrar: r ?? registrar,
        catalog: const [lato],
      );

  void install(AppFontKind kind, String id) {
    final dir = FontStorage(paths).fontDir(kind, id)
      ..createSync(recursive: true);
    File('${dir.path}/a.ttf').writeAsBytesSync([1]);
  }

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('startup_font');
    paths = _Paths(tmp);
    settings = MemorySettingsStore();
    loaded = [];
    registrar = FontRegistrar(registrar: (f, _) async => loaded.add(f));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('no stored value gives the default and writes nothing', () async {
    expect(await run(), 'nunito');
    expect(settings.read('app.font'), isNull);
  });

  test('built-in id is kept without loading', () async {
    await settings.write('app.font', 'inter');
    expect(await run(), 'inter');
    expect(loaded, isEmpty);
    expect(settings.read('app.font'), 'inter');
  });

  test('installed catalog and custom fonts load', () async {
    install(AppFontKind.catalog, 'lato');
    await settings.write('app.font', 'lato');
    expect(await run(), 'lato');
    install(AppFontKind.custom, customId);
    await settings.write('app.font', customId);
    expect(await run(), customId);
    expect(loaded, ['Lato', customId]);
  });

  test('missing files fall back and rewrite the setting', () async {
    await settings.write('app.font', 'lato');
    expect(await run(), 'nunito');
    expect(settings.read('app.font'), 'nunito');
  });

  test('unknown id falls back and rewrites', () async {
    await settings.write('app.font', 'mystery');
    expect(await run(), 'nunito');
    expect(settings.read('app.font'), 'nunito');
  });

  test('invalid or traversal value falls back and rewrites', () async {
    for (final bad in <Object>['../../etc', 42]) {
      await settings.write('app.font', bad);
      expect(await run(), 'nunito');
      expect(settings.read('app.font'), 'nunito');
    }
  });

  test('registrar failure falls back', () async {
    install(AppFontKind.catalog, 'lato');
    await settings.write('app.font', 'lato');
    final r = FontRegistrar(
      registrar: (_, _) async => throw StateError('bad font'),
    );
    expect(await run(r: r), 'nunito');
    expect(settings.read('app.font'), 'nunito');
  });

  test('a store that cannot write still returns the default', () async {
    final store = _ThrowingStore();
    await store.write('app.font', 'mystery');
    store.failWrites = true;
    expect(await run(store: store), 'nunito');
  });

  test('leftover .tmp folders are removed before resolving', () async {
    final storage = FontStorage(paths);
    final leftover = Directory('${storage.catalogDir.path}/lato.tmp')
      ..createSync(recursive: true);
    await run();
    expect(leftover.existsSync(), isFalse);
  });
}
