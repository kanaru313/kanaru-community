import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/custom_font_store.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/domain/custom_font.dart';
import 'package:kanaru/src/fonts/domain/font_label.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';

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

Uint8List _named(String name) => ttf([(platform: 3, id: 1, text: name)]);

void main() {
  late Directory tmp;
  late CustomFontStore store;
  late Directory custom;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('custom_font_store');
    final storage = FontStorage(_Paths(tmp));
    store = CustomFontStore(storage);
    custom = storage.customDir;
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Matcher refusedWith(CustomFontError e) =>
      throwsA(isA<CustomFontException>().having((x) => x.error, 'error', e));

  List<String> entries() => custom.existsSync()
      ? [for (final e in custom.listSync()) e.path.split('/').last]
      : [];

  test('imports a font under custom_<slug>_<hash> and lists it', () async {
    final font = await store.importBytes('x.ttf', nunitoBytes());
    expect(font.label, 'Nunito');
    expect(font.id, matches(RegExp(r'^custom_nunito_[0-9a-f]{8}$')));
    expect(store.list().map((f) => f.id), [font.id]);
    expect(
      File('${custom.path}/${font.id}/${font.id}.ttf').existsSync(),
      isTrue,
    );
    final manifest = jsonDecode(
      File('${custom.path}/custom_fonts.json').readAsStringSync(),
    );
    expect(manifest, {font.id: 'Nunito'});
  });

  test('a long name is cut to 24 characters of slug', () async {
    final font = await store.importBytes(
      'x.ttf',
      _named('A Very Long Family Name That Keeps Going'),
    );
    expect(
      font.id,
      matches(RegExp(r'^custom_a_very_long_family_name_[0-9a-f]{8}$')),
    );
  });

  test('OpenType CFF is stored as .otf', () async {
    final font = await store.importBytes(
      'f.otf',
      otf([(platform: 3, id: 1, text: 'Cff')]),
    );
    expect(
      File('${custom.path}/${font.id}/${font.id}.otf').existsSync(),
      isTrue,
    );
  });

  test('the same bytes again reuse the existing font', () async {
    final first = await store.importBytes('a.ttf', nunitoBytes());
    final second = await store.importBytes('copy of a.ttf', nunitoBytes());
    expect(second.id, first.id);
    expect(store.list(), hasLength(1));
  });

  test('a file without a readable name takes its file name', () async {
    final font = await store.importBytes(
      'My Face.ttf',
      ttf([(platform: 3, id: 2, text: 'Regular')]),
    );
    expect(font.label, 'My Face');
    expect(font.id, startsWith('custom_my_face_'));
  });

  test('refuses too large and invalid files and keeps nothing', () async {
    await expectLater(
      store.importBytes('big.ttf', Uint8List(maxCustomFontBytes + 1)),
      refusedWith(CustomFontError.tooLarge),
    );
    await expectLater(
      store.importBytes('x.ttf', Uint8List.fromList(List.filled(64, 1))),
      refusedWith(CustomFontError.invalid),
    );
    expect(entries(), isEmpty);
    expect(store.list(), isEmpty);
  });

  test('a failure while storing leaves no folder and no entry', () async {
    // The manifest path is a folder, so writing the manifest fails after the
    // font folder was moved into place.
    Directory('${custom.path}/custom_fonts.json').createSync(recursive: true);
    await expectLater(
      store.importBytes('x.ttf', nunitoBytes()),
      refusedWith(CustomFontError.unwritable),
    );
    expect(entries(), ['custom_fonts.json']);
  });

  test('list is sorted by label ignoring case', () async {
    await store.importBytes('b.ttf', _named('beta'));
    await store.importBytes('a.ttf', _named('Alpha'));
    await store.importBytes('c.ttf', _named('Charlie'));
    expect(store.list().map((f) => f.label), ['Alpha', 'beta', 'Charlie']);
  });

  test('delete removes the folder and the manifest entry', () async {
    final font = await store.importBytes('x.ttf', nunitoBytes());
    await store.delete(font.id);
    expect(store.list(), isEmpty);
    expect(Directory('${custom.path}/${font.id}').existsSync(), isFalse);
    expect(
      jsonDecode(File('${custom.path}/custom_fonts.json').readAsStringSync()),
      isEmpty,
    );
    await store.delete(font.id); // missing is fine
  });

  test('delete refuses an id that is not a safe folder name', () async {
    await expectLater(store.delete('../x'), throwsArgumentError);
  });

  test(
    'a corrupt manifest is moved aside and labels come from folders',
    () async {
      final font = await store.importBytes('x.ttf', nunitoBytes());
      File('${custom.path}/custom_fonts.json').writeAsStringSync('{ not json');
      final listed = store.list();
      expect(listed.map((f) => f.id), [font.id]);
      expect(listed.single.label, 'nunito');
      expect(
        entries().where((n) => n.startsWith('custom_fonts.json.corrupt.')),
        hasLength(1),
      );
      // The next import writes a healthy manifest again.
      final other = await store.importBytes('y.ttf', _named('Other'));
      expect(
        jsonDecode(File('${custom.path}/custom_fonts.json').readAsStringSync()),
        {other.id: 'Other'},
      );
    },
  );

  test('imports in a row do not lose manifest entries', () async {
    final results = await Future.wait([
      store.importBytes('a.ttf', _named('One')),
      store.importBytes('b.ttf', _named('Two')),
    ]);
    final manifest = jsonDecode(
      File('${custom.path}/custom_fonts.json').readAsStringSync(),
    ) as Map;
    expect(manifest.keys, containsAll(results.map((f) => f.id)));
  });
}
