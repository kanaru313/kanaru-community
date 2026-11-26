import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/package_reader.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_package.dart';

import '../fixtures/zip_builders.dart';
import 'plugin_test_support.dart';

const _fixtures = 'test/plugins/fixtures/manifests';

/// The package for [zip], failing the test when it is refused.
PluginPackage readOk(Uint8List zip) => switch (readPackage(zip)) {
  Ok(:final value) => value,
  Err(:final error) => fail('refused: $error'),
};

/// The problem [zip] is refused with.
PackageProblem problemOfZip(Uint8List zip) => switch (readPackage(zip)) {
  Ok() => fail('the package was accepted'),
  Err(:final error) => error,
};

/// A zip of the manifest [bytes] with a stub for every script it names.
Uint8List zipOfManifest(
  Uint8List bytes, {
  Map<String, Object> extra = const {},
}) {
  final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
  final script = json['script']! as Map<String, Object?>;
  return buildZip({
    'plugin.json': bytes,
    for (final file in script.values.toSet())
      'src/$file': '// $file\nfunction execute() {}',
    ...extra,
  });
}

void main() {
  test('a streaming package keeps all 10 scripts and the manifest bytes', () {
    final bytes = File('$_fixtures/streaming__youtube.json').readAsBytesSync();
    final zip = zipOfManifest(bytes);
    final package = readOk(zip);
    expect(package.manifest.kind, PluginKind.streaming);
    expect(package.scripts.keys, hasLength(10));
    expect(
      package.scripts.keys,
      unorderedEquals([for (final f in package.manifest.scripts.values) f]),
    );
    expect(package.manifestBytes, bytes);
    expect(package.manifestText, utf8.decode(bytes));
    expect(package.manifest.regexp, isNotNull);
    expect(package.sha256, sha256.convert(zip).toString());
    expect(package.sha256, hasLength(64));
    expect(package.size, zip.length);
  });

  test('every shipped manifest reads as a package with its scripts', () {
    final files = Directory(_fixtures)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));
    expect(files, hasLength(44));
    for (final file in files) {
      final bytes = file.readAsBytesSync();
      final package = readOk(zipOfManifest(bytes));
      expect(package.manifestBytes, bytes, reason: file.path);
      expect(
        package.scripts.keys.toSet(),
        package.manifest.scriptFiles,
        reason: file.path,
      );
    }
  });

  test('a script the manifest does not name is kept for load()', () {
    final package = readOk(
      validZip(extra: {'src/helper.js': 'var helper = 1;'}),
    );
    expect(package.scripts.keys, containsAll(['search.js', 'lyrics.js']));
    expect(package.scripts['helper.js'], 'var helper = 1;');
  });

  test('a script named by the manifest but missing is refused', () {
    final manifest = validManifest()
      ..['script'] = {'search': 'search.js', 'lyrics': 'gone.js'};
    final problem = problemOfZip(validZip(manifest: manifest));
    expect(problem, isA<MissingScript>());
    expect(problem.detail, 'gone.js');
  });

  test('a manifest problem is returned as is', () {
    final manifest = withMeta((m) => m['type'] = 'podcast');
    expect(problemOfZip(validZip(manifest: manifest)), isA<UnsupportedKind>());
    final secret = withConfig({
      'key': {'title': 'Key', 'mode': 'input', 'format': 'secret'},
    });
    expect(
      problemOfZip(validZip(manifest: secret)),
      isA<UnknownConfigFormat>(),
    );
  });

  test('a zip problem is returned as is', () {
    expect(problemOfZip(Uint8List.fromList([1, 2, 3])), isA<NotAZip>());
    expect(
      problemOfZip(buildZip({'src/search.js': 'x'})),
      isA<MissingManifest>(),
    );
  });

  test('a manifest that is not UTF-8 is refused', () {
    final zip = buildZip({
      'plugin.json': Uint8List.fromList([0x7b, 0xff, 0xfe, 0x7d]),
    });
    final problem = problemOfZip(zip);
    expect(problem, isA<InvalidManifest>());
    expect(problem.detail, 'plugin.json');
  });

  test('a script that is not UTF-8 is refused, a BOM is stripped', () {
    final bad = problemOfZip(
      validZip(
        extra: {
          'src/bad.js': Uint8List.fromList([0xff, 0xfe, 0x41]),
        },
      ),
    );
    expect(bad, isA<ScriptNotUtf8>());
    expect(bad.detail, 'bad.js');
    final withBom = readOk(
      validZip(
        extra: {
          'src/bom.js': Uint8List.fromList([0xef, 0xbb, 0xbf, 0x41]),
        },
      ),
    );
    expect(withBom.scripts['bom.js'], 'A');
  });

  test('only one leading BOM of a script goes; a second one is content', () {
    final twice = readOk(
      validZip(
        extra: {
          'src/bom.js': Uint8List.fromList([
            0xef, 0xbb, 0xbf, 0xef, 0xbb, 0xbf, 0x41, //
          ]),
        },
      ),
    );
    expect(twice.scripts['bom.js'], '\u{feff}A');
  });

  test('a manifest with a BOM keeps its bytes and reads', () {
    final text = jsonEncode(validManifest());
    final bytes = Uint8List.fromList([0xef, 0xbb, 0xbf, ...utf8.encode(text)]);
    final package = readOk(zipOfManifest(bytes));
    expect(package.manifestBytes, bytes);
    expect(package.manifestText, text);
  });

  test(
    'a valid icon is kept; a bad one is dropped and the install goes on',
    () {
      final icon = pngHeader(64, 64);
      expect(readOk(validZip(extra: {'icon.png': icon})).icon, icon);
      final dropped = readOk(
        validZip(extra: {'icon.png': pngHeader(900, 900)}),
      );
      expect(dropped.icon, isNull);
      expect(dropped.scripts, hasLength(2));
      expect(readOk(validZip()).icon, isNull);
    },
  );

  test('one top-level folder is stripped', () {
    final package = readOk(validZip(prefix: 'demo/'));
    expect(package.scripts.keys, unorderedEquals(['search.js', 'lyrics.js']));
  });

  test('a stray nested plugin.zip does not change the result', () {
    final plain = readOk(validZip());
    final stray = readOk(
      validZip(
        extra: {
          'plugin.zip': Uint8List.fromList([1, 2, 3]),
        },
      ),
    );
    expect(stray.scripts, plain.scripts);
    expect(stray.manifestBytes, plain.manifestBytes);
  });

  test('the scripts map cannot be changed by the caller', () {
    final package = readOk(validZip());
    expect(() => package.scripts['x.js'] = 'y', throwsUnsupportedError);
  });
}
