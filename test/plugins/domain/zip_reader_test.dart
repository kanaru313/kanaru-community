import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/zip_reader.dart';

import '../fixtures/zip_builders.dart';
import '../fixtures/zip_expect.dart';

void main() {
  group('declared size lies', () {
    test('an entry declaring 1 KiB that inflates to 64 MiB is refused', () {
      final bomb = rawDeflate(Uint8List(64 * 1024 * 1024));
      final zip = handZip([
        HandEntry('plugin.json', Uint8List(0)),
        HandEntry('src/big.js', bomb, method: 8, declaredSize: 1024),
      ]);
      expect(zip.length, lessThan(1024 * 1024));
      final problem = problemOf(zip);
      expect(problem, isA<PackageTooLarge>());
      expect(problem.detail, 'src/big.js');
    });

    test('an entry whose header declares less than it inflates', () {
      // 3 MiB of zeros: about 3 KB zipped. Only this entry lies.
      final zip = patchEntry(
        validZip(extra: {'src/big.js': Uint8List(3 * 1024 * 1024)}),
        'src/big.js',
        size: 100,
      );
      final problem = problemOf(zip);
      expect(problem, isA<PackageTooLarge>());
      expect(problem.detail, 'src/big.js');
    });

    test('an ignored entry that declares a small size is never inflated', () {
      final zip = patchEntry(
        validZip(extra: {'big.bin': Uint8List(3 * 1024 * 1024)}),
        'big.bin',
        size: 100,
      );
      expect(readZip(zip).scripts, hasLength(2));
    });

    test('an entry that declares more than the data holds', () {
      expectProblem<NotAZip>(
        patchEntry(validZip(), 'src/search.js', size: 5000),
        'size or checksum',
      );
    });

    test('a stored entry longer than it declares', () {
      final data = Uint8List.fromList(List.filled(100, 0x61));
      final zip = handZip([
        HandEntry('plugin.json', data, declaredSize: 10, crc: getCrc32(data)),
      ]);
      expectProblem<PackageTooLarge>(zip);
    });
  });

  group('safe names', () {
    for (final name in [
      '../evil.js',
      'src/../../evil.js',
      '/etc/passwd',
      r'src\search.js',
      'C:/win.js',
      'c:evil',
      'src/a\u0000.js',
    ]) {
      test('rejects "${name.replaceAll('\u0000', r'\0')}"', () {
        expectProblem<UnsafeEntry>(validZip(extra: {name: 'x'}));
      });
    }

    test('rejects a symlink entry', () {
      final zip = validZip(extra: {'src/link.js': 'search.js'});
      final archive = ZipDecoder().decodeBytes(zip);
      final rebuilt = buildZip(
        {for (final f in archive) f.name: f.content as List<int>},
        modes: {'src/link.js': 0xa1ff},
      );
      expectProblem<UnsafeEntry>(rebuilt);
    });

    test('a symlink on an ignored entry still refuses the package', () {
      final zip = patchEntry(
        validZip(extra: {'notes.txt': 'x'}),
        'notes.txt',
        versionMadeBy: 0x031e,
        externalAttributes: 0xa1ff << 16,
      );
      expectProblem<UnsafeEntry>(zip, 'notes.txt');
    });

    test('rejects names equal ignoring case', () {
      expectProblem<UnsafeEntry>(
        validZip(extra: {'src/Search.JS': 'x', 'src/search.js': 'y'}),
      );
    });

    test('case duplicates among ignored entries count too', () {
      expectProblem<UnsafeEntry>(
        validZip(extra: {'README.md': 'x', 'readme.MD': 'y'}),
      );
    });

    test('names equal but for a trailing slash', () {
      expectProblem<UnsafeEntry>(validZip(extra: {'src/': '', 'src': 'x'}));
    });
  });

  group('limits', () {
    test('rejects a file over 5 MiB before reading it', () {
      expectProblem<PackageTooLarge>(Uint8List(5 * 1024 * 1024 + 1));
    });

    test('rejects bytes that are not a zip', () {
      expectProblem<NotAZip>(Uint8List.fromList([1, 2, 3, 4]));
      expectProblem<NotAZip>(Uint8List(0));
    });

    test('rejects 51 entries, accepts 50', () {
      Map<String, Object> many(int n) => {
        for (var i = 0; i < n; i++) 'other/$i.txt': 'x',
      };
      // 3 entries are the required ones.
      expectProblem<TooManyEntries>(validZip(extra: many(48)));
      expect(readZip(validZip(extra: many(47))).scripts, hasLength(2));
    });

    test('rejects a declared total over 5 MiB even for ignored entries', () {
      final zip = validZip(extra: {'big.bin': Uint8List(6 * 1024 * 1024)});
      expectProblem<PackageTooLarge>(zip);
    });

    test('a nested stray plugin.zip is ignored but its size counts', () {
      final stray = Uint8List.fromList(List.filled(4 * 1024 * 1024, 7));
      final alone = validZip(extra: {'plugin.zip': stray});
      expect(readZip(alone).scripts, hasLength(2));
      final withMore = validZip(
        extra: {'plugin.zip': stray, 'data.bin': Uint8List(2 * 1024 * 1024)},
      );
      expectProblem<PackageTooLarge>(withMore);
    });

    test('rejects a script over 1 MiB', () {
      expectProblem<PackageTooLarge>(
        validZip(extra: {'src/big.js': Uint8List(1024 * 1024 + 1)}),
        'src/big.js',
      );
      expect(
        readZip(validZip(extra: {'src/ok.js': Uint8List(1024 * 1024)})).scripts,
        hasLength(3),
      );
    });

    test('rejects a manifest over 64 KiB', () {
      expectProblem<PackageTooLarge>(
        buildZip({'plugin.json': Uint8List(64 * 1024 + 1)}),
      );
    });

    test('an icon over 64 KiB is dropped, not fatal', () {
      final contents = readZip(
        validZip(extra: {'icon.png': Uint8List(64 * 1024 + 1)}),
      );
      expect(contents.icon, isNull);
      expect(contents.iconProblem, isNotNull);
    });
  });

  group('entry kinds', () {
    test('an encrypted entry', () {
      expectProblem<NotAZip>(
        patchEntry(validZip(), 'src/search.js', flags: 1),
        'encrypted',
      );
    });

    test('unsupported compression methods', () {
      for (final method in [12, 14, 93, 98]) {
        expectProblem<NotAZip>(
          patchEntry(validZip(), 'src/search.js', method: method),
          'compression $method',
        );
      }
    });

    test('a checksum mismatch', () {
      expectProblem<NotAZip>(
        patchEntry(validZip(), 'src/search.js', crc: 1234),
        'checksum',
      );
    });

    test('a damaged deflate stream', () {
      final good = rawDeflate(Uint8List.fromList(List.filled(500, 0x61)));
      final broken = Uint8List.fromList(good)..fillRange(2, good.length, 0xff);
      final zip = handZip([
        HandEntry('plugin.json', broken, method: 8, declaredSize: 500),
      ]);
      expectProblem<NotAZip>(zip);
    });

    test('an entry with a data descriptor flag is still read', () {
      final zip = patchEntry(validZip(), 'src/search.js', flags: 8);
      expect(readZip(zip).scripts, hasLength(2));
    });

    test('reads stored (uncompressed) entries', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final zip = handZip([
        HandEntry('plugin.json', bytes, crc: getCrc32(bytes)),
      ]);
      expect(readZip(zip).manifest, [1, 2, 3]);
    });

    test('a bad icon (cannot be inflated, lying size) is dropped', () {
      final base = validZip(extra: {'icon.png': pngHeader(8, 8)});
      for (final zip in [
        patchEntry(base, 'icon.png', crc: 99),
        patchEntry(base, 'icon.png', size: 40000),
        patchEntry(base, 'icon.png', flags: 1),
      ]) {
        final contents = readZip(zip);
        expect(contents.icon, isNull);
        expect(contents.iconProblem, isNotNull);
      }
    });

    test('an icon without an IHDR chunk or over 256 px is dropped', () {
      final noHeader = pngHeader(8, 8)..[13] = 0x58;
      var contents = readZip(validZip(extra: {'icon.png': noHeader}));
      expect(contents.icon, isNull);
      expect(contents.iconProblem, 'IHDR chunk missing');
      contents = readZip(validZip(extra: {'icon.png': pngHeader(257, 8)}));
      expect(contents.icon, isNull);
      contents = readZip(validZip(extra: {'icon.png': pngHeader(256, 256)}));
      expect(contents.icon, isNotNull);
    });
  });

  group('layout', () {
    test('rejects a package without plugin.json', () {
      expectProblem<MissingManifest>(buildZip({'src/search.js': 'x'}));
    });

    test('strips one top-level folder', () {
      final contents = readZip(validZip(prefix: 'myplugin/'));
      expect(
        contents.scripts.keys,
        unorderedEquals(['search.js', 'lyrics.js']),
      );
    });

    test('does not strip when an entry is outside the folder', () {
      expectProblem<MissingManifest>(
        buildZip({'a/plugin.json': '{}', 'b/readme.txt': 'x'}),
      );
    });

    test('does not strip a nested folder', () {
      expectProblem<MissingManifest>(validZip(prefix: 'a/b/'));
    });

    test('keeps only whitelisted entries', () {
      final contents = readZip(
        validZip(
          extra: {
            'readme.md': 'hi',
            'src/sub/deep.js': 'x',
            'src/notes.txt': 'x',
            'src/bad name.js': 'x',
            'src/': '',
          },
        ),
      );
      expect(
        contents.scripts.keys,
        unorderedEquals(['search.js', 'lyrics.js']),
      );
    });

    test('Finder metadata does not hide the top folder or get read', () {
      final contents = readZip(
        buildZip({
          '__MACOSX/': '',
          '__MACOSX/myplugin/': '',
          '__MACOSX/myplugin/._plugin.json': 'junk',
          '.DS_Store': 'junk',
          'myplugin/': '',
          'myplugin/.DS_Store': 'junk',
          'myplugin/plugin.json': '{}',
          'myplugin/src/search.js': 'x',
        }),
      );
      expect(contents.manifest, utf8.encode('{}'));
      expect(contents.scripts.keys, ['search.js']);
    });

    test('Finder metadata still counts in the duplicate check', () {
      expectProblem<UnsafeEntry>(
        buildZip({'__MACOSX/a': 'x', '__macosx/A': 'y', 'plugin.json': '{}'}),
      );
    });
  });

  group('assets', () {
    test('headers are kept by file name and never inflated', () {
      final contents = readZip(
        validZip(
          extra: {
            'assets/t.png': 'png bytes',
            'assets/a.json': '{}',
            'assets/p.webp': 'webp bytes',
          },
        ),
      );
      expect(
        contents.assetHeaders.keys,
        unorderedEquals(['t.png', 'a.json', 'p.webp']),
      );
      final entry = contents.assetHeaders['t.png']!;
      expect(entry.path, 'assets/t.png');
      expect(entry.declaredSize, 9);
      expect(entry.inflate(1024), utf8.encode('png bytes'));
    });

    test('a corrupt asset does not stop the zip from being read', () {
      final zip = patchEntry(
        validZip(extra: {'assets/t.png': 'png bytes'}),
        'assets/t.png',
        crc: 1,
      );
      final entry = readZip(zip).assetHeaders['t.png']!;
      expect(() => entry.inflate(1024), throwsA(isA<PackageProblemError>()));
    });

    test('names outside the asset shape are ignored, not listed', () {
      final contents = readZip(
        validZip(
          extra: {
            'assets/sub/t.png': 'x',
            'assets/t.gif': 'x',
            'assets/.png': 'x',
            'assets/${'a' * 65}.png': 'x',
            'Assets/t.png': 'x',
          },
        ),
      );
      expect(contents.assetHeaders, isEmpty);
    });

    test('inflate refuses a declared size over its cap before reading', () {
      final zip = patchEntry(
        validZip(extra: {'assets/t.png': 'x'}),
        'assets/t.png',
        size: 2000,
      );
      final entry = readZip(zip).assetHeaders['t.png']!;
      expect(entry.declaredSize, 2000);
      try {
        entry.inflate(1000);
        fail('accepted');
      } on PackageProblemError catch (e) {
        expect(e.problem, isA<PackageTooLarge>());
        expect(e.problem.detail, 'assets/t.png');
      }
    });

    test('a path under the entry cap total is still refused as a whole', () {
      // The declared sizes of every entry count toward the unpacked cap.
      final zip = patchEntry(
        validZip(extra: {'assets/t.png': 'x'}),
        'assets/t.png',
        size: 6 * 1024 * 1024,
      );
      expectProblem<PackageTooLarge>(zip);
    });
  });
}
