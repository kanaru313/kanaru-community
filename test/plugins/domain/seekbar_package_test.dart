import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/package/image_header.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/package_reader.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_package.dart';

import '../fixtures/image_bytes.dart';
import '../fixtures/zip_builders.dart';

/// A seekbar manifest whose block is [seekbar] (default: a flat track).
String _manifest([Map<String, Object?>? seekbar]) => jsonEncode({
  'metadata': {
    'apiVersion': 1,
    'type': 'seekbar',
    'name': 'Demo bar',
    'version': 1,
    'license': 'CC0-1.0',
  },
  'seekbar':
      seekbar ??
      {
        'track': {'kind': 'flat'},
      },
});

Map<String, Object?> _thumb({int frames = 1, String image = 'assets/t.png'}) =>
    {
      'track': {'kind': 'flat'},
      'thumb': {
        'image': image,
        'frames': frames,
        'size': [16, 16],
      },
    };

Map<String, Object?> _both() => {
  ..._thumb(),
  'emitter': {
    'image': 'assets/p.webp',
    'size': [8, 8],
    'rate': 2,
    'life': [1, 2],
    'velocity': {
      'x': [0, 1],
      'y': [-5, 0],
    },
  },
};

/// [bytes] padded with zeros to [length] (they deflate to almost nothing).
Uint8List _padded(Uint8List bytes, int length) =>
    Uint8List(length)..setAll(0, bytes);

PluginPackage _ok(Uint8List zip) => switch (readPackage(zip)) {
  Ok(:final value) => value,
  Err(:final error) => fail('refused: $error'),
};

PackageProblem _refused(Uint8List zip) => switch (readPackage(zip)) {
  Ok() => fail('the package was accepted'),
  Err(:final error) => error,
};

void main() {
  final png = pngBytes(16, 16);

  group('a valid package', () {
    test('keeps only the assets the block names, by file name', () {
      final zip = buildZip({
        'plugin.json': _manifest(_both()),
        'assets/t.png': png,
        'assets/p.webp': webpLossy(8, 8),
        'assets/unused.png': pngBytes(4, 4),
        'assets/unused.json': '{}',
        'notes/readme.txt': 'hi',
      });
      final package = _ok(zip);
      expect(package.assets.keys, unorderedEquals(['t.png', 'p.webp']));
      expect(package.assets['t.png'], png);
      expect(package.scripts, isEmpty);
      expect(() => package.assets['x'] = png, throwsUnsupportedError);
    });

    test('a package under one folder reads the same', () {
      final zip = buildZip({
        'demo/plugin.json': _manifest(_thumb()),
        'demo/assets/t.png': png,
      });
      expect(_ok(zip).assets.keys, ['t.png']);
    });

    test('a sprite whose width divides by its frames is accepted', () {
      final zip = buildZip({
        'plugin.json': _manifest(_thumb(frames: 4)),
        'assets/t.png': pngBytes(64, 16),
      });
      expect(_ok(zip).assets, hasLength(1));
    });

    test('a block without images keeps no assets', () {
      final zip = buildZip({
        'plugin.json': _manifest(),
        'assets/unused.png': 'junk',
      });
      expect(_ok(zip).assets, isEmpty);
    });
  });

  group('refusals name the asset', () {
    Uint8List zipWith(Object image, {String name = 'assets/t.png'}) =>
        buildZip({'plugin.json': _manifest(_thumb()), name: image});

    test('a file the block names is missing', () {
      final problem = _refused(buildZip({'plugin.json': _manifest(_thumb())}));
      expect(problem, isA<MissingAsset>());
      expect(problem.detail, 'assets/t.png');
    });

    test('the name is in a folder the reader does not list', () {
      final problem = _refused(zipWith(png, name: 'assets/sub/t.png'));
      expect(problem, isA<MissingAsset>());
    });

    test('not an image', () {
      final problem = _refused(zipWith('GIF89a'));
      expect(problem, isA<InvalidAsset>());
      expect(problem.detail, 'assets/t.png');
      expect((problem as InvalidAsset).reason, ImageProblem.format);
    });

    test('an animated PNG', () {
      final problem = _refused(zipWith(pngBytes(16, 16, animated: true)));
      expect((problem as InvalidAsset).reason, ImageProblem.animated);
    });

    test('a side over 2048 px', () {
      final problem = _refused(zipWith(pngBytes(2049, 16)));
      expect((problem as InvalidAsset).reason, ImageProblem.size);
    });

    test('an extension that lies', () {
      final problem = _refused(zipWith(webpLossy(16, 16)));
      expect((problem as InvalidAsset).reason, ImageProblem.extension);
    });

    test('a width that does not divide by the frames', () {
      final zip = buildZip({
        'plugin.json': _manifest(_thumb(frames: 3)),
        'assets/t.png': pngBytes(16, 16),
      });
      final problem = _refused(zip);
      expect(problem, isA<InvalidAsset>());
      expect(problem.detail, 'assets/t.png');
      expect((problem as InvalidAsset).reason, 'frames');
    });

    test('an image over 512 KiB', () {
      final big = _padded(png, 512 * 1024 + 1);
      final problem = _refused(zipWith(big));
      expect(problem, isA<PackageTooLarge>());
      expect(problem.detail, 'assets/t.png');
    });

    test('an image of exactly 512 KiB is accepted', () {
      expect(_ok(zipWith(_padded(png, 512 * 1024))).assets, hasLength(1));
    });

    test('the unpacked total over 1 MiB', () {
      final zip = buildZip({
        'plugin.json': _manifest(_both()),
        'assets/t.png': _padded(png, 512 * 1024),
        'assets/p.webp': _padded(webpLossy(8, 8), 512 * 1024),
      });
      final problem = _refused(zip);
      expect(problem, isA<PackageTooLarge>());
      expect(problem.detail, isEmpty);
    });

    test('a zip file over 1 MiB', () {
      final random = Random(7);
      final noise = Uint8List.fromList(
        List.generate(1100 * 1024, (_) => random.nextInt(256)),
      );
      final zip = buildZip({
        'plugin.json': _manifest(_thumb()),
        'assets/t.png': png,
        'other/noise.bin': noise,
      });
      expect(zip.length, greaterThan(1024 * 1024));
      final problem = _refused(zip);
      expect(problem, isA<PackageTooLarge>());
      expect(problem.detail, isEmpty);
    });

    test('a seekbar package with a script is refused before it is read', () {
      final zip = buildZip({
        'plugin.json': _manifest(_thumb()),
        'assets/t.png': png,
        'src/a.js': 'function execute() {}',
      });
      final problem = _refused(zip);
      expect(problem, isA<UnsafeEntry>());
      expect(problem.detail, 'src/a.js');
    });

    test('a script that is not UTF-8 is still the code refusal', () {
      final zip = buildZip({
        'plugin.json': _manifest(),
        'src/a.js': Uint8List.fromList([0xff, 0xfe, 0xfd]),
      });
      expect(_refused(zip), isA<UnsafeEntry>());
    });
  });

  group('hostile zips', () {
    Uint8List base() => buildZip({
      'plugin.json': _manifest(_thumb()),
      'assets/t.png': _padded(png, 3000),
    });

    test('an asset declaring less than it inflates', () {
      final problem = _refused(patchEntry(base(), 'assets/t.png', size: 100));
      expect(problem, isA<PackageTooLarge>());
      expect(problem.detail, 'assets/t.png');
    });

    test('an asset declaring more than the cap', () {
      final problem = _refused(
        patchEntry(base(), 'assets/t.png', size: 600 * 1024),
      );
      expect(problem, isA<PackageTooLarge>());
      expect(problem.detail, 'assets/t.png');
    });

    test('an asset declaring more than the data holds', () {
      final problem = _refused(patchEntry(base(), 'assets/t.png', size: 4000));
      expect(problem, isA<NotAZip>());
      expect(problem.detail, contains('assets/t.png'));
    });

    test('a wrong checksum', () {
      final problem = _refused(patchEntry(base(), 'assets/t.png', crc: 1));
      expect(problem, isA<NotAZip>());
      expect(problem.detail, contains('assets/t.png'));
    });

    test('an encrypted or unknown-method asset', () {
      expect(
        _refused(patchEntry(base(), 'assets/t.png', flags: 1)),
        isA<NotAZip>(),
      );
      expect(
        _refused(patchEntry(base(), 'assets/t.png', method: 12)),
        isA<NotAZip>(),
      );
    });

    test('51 entries', () {
      final zip = buildZip({
        'plugin.json': _manifest(_thumb()),
        'assets/t.png': png,
        for (var i = 0; i < 49; i++) 'other/$i.txt': 'x',
      });
      expect(_refused(zip), isA<TooManyEntries>());
    });

    test('50 entries are fine', () {
      final zip = buildZip({
        'plugin.json': _manifest(_thumb()),
        'assets/t.png': png,
        for (var i = 0; i < 48; i++) 'other/$i.txt': 'x',
      });
      expect(_ok(zip).assets, hasLength(1));
    });

    test('duplicate names', () {
      final data = Uint8List.fromList(utf8.encode('x'));
      final crc = getCrc32(data);
      final zip = handZip([
        HandEntry('plugin.json', Uint8List.fromList(utf8.encode(_manifest()))),
        HandEntry('assets/t.png', data, crc: crc),
        HandEntry('assets/t.png', data, crc: crc),
      ]);
      expect(_refused(zip), isA<UnsafeEntry>());
    });

    test('assets/../x.png', () {
      final zip = buildZip({
        'plugin.json': _manifest(),
        'assets/../x.png': png,
      });
      final problem = _refused(zip);
      expect(problem, isA<UnsafeEntry>());
      expect(problem.detail, 'assets/../x.png');
    });

    test('a symlink asset', () {
      final zip = buildZip(
        {'plugin.json': _manifest(_thumb()), 'assets/t.png': 'x'},
        modes: {'assets/t.png': 0xa1ff},
      );
      expect(_refused(zip), isA<UnsafeEntry>());
    });
  });
}
