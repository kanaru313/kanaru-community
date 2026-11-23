import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/custom_font_store.dart';
import 'package:kanaru/src/fonts/data/font_registrar.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/data/startup_font.dart';
import 'package:kanaru/src/fonts/domain/app_font.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';

import '../support/memory_settings_store.dart';
import 'support/font_bytes.dart';

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
  const customId = 'custom_my_font_1a2b3c4d';

  Future<String> run({FontRegistrar? r, MemorySettingsStore? store}) =>
      prepareStartupFont(
        paths: paths,
        settings: store ?? settings,
        registrar: r ?? registrar,
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
    install(AppFontKind.catalog, 'lora');
    await settings.write('app.font', 'lora');
    expect(await run(), 'lora');
    install(AppFontKind.custom, customId);
    await settings.write('app.font', customId);
    expect(await run(), customId);
    expect(loaded, ['Lora', customId]);
  });

  test('an imported font is the startup font after a restart', () async {
    final font = await CustomFontStore(FontStorage(paths))
        .importBytes('x.ttf', nunitoBytes());
    await settings.write('app.font', font.id);
    expect(await run(), font.id);
    expect(loaded, [font.id]);
  });

  test('missing files fall back and rewrite the setting', () async {
    await settings.write('app.font', 'lora');
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
    install(AppFontKind.catalog, 'lora');
    await settings.write('app.font', 'lora');
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
    final leftover = Directory('${storage.catalogDir.path}/lora.tmp')
      ..createSync(recursive: true);
    await run();
    expect(leftover.existsSync(), isFalse);
  });

  test(
    'a leftover .tmp next to the installed font keeps the stored id',
    () async {
      install(AppFontKind.catalog, 'lora');
      Directory('${FontStorage(paths).catalogDir.path}/lora.tmp')
          .createSync(recursive: true);
      await settings.write('app.font', 'lora');
      expect(await run(), 'lora');
      expect(settings.read('app.font'), 'lora');
      expect(
        Directory('${FontStorage(paths).catalogDir.path}/lora.tmp')
            .existsSync(),
        isFalse,
      );
    },
  );

  test('a real catalog id resolves without passing the catalog', () async {
    install(AppFontKind.catalog, 'lora');
    await settings.write('app.font', 'lora');
    final id = await prepareStartupFont(
      paths: paths,
      settings: settings,
      registrar: registrar,
    );
    expect(id, 'lora');
    expect(loaded, ['Lora']);
  });
}
