import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/zip_reader.dart';

import '../fixtures/zip_builders.dart';
import '../fixtures/zip_expect.dart';

void main() {
  group('central directory', () {
    test('many records on one huge local header end fast', () {
      final watch = Stopwatch()..start();
      expectProblem<TooManyEntries>(amplifiedZip(records: 10000));
      expect(watch.elapsedMilliseconds, lessThan(500));
    });

    test('thousands of records with a lying end record are refused fast', () {
      final watch = Stopwatch()..start();
      expectProblem<TooManyEntries>(
        amplifiedZip(records: 5000, announced: 3, localNameLength: 10),
      );
      expect(watch.elapsedMilliseconds, lessThan(500));
    });

    test('records sharing one local header are refused', () {
      expectProblem<NotAZip>(
        amplifiedZip(records: 3, localNameLength: 10),
        'overlapping',
      );
    });

    test('an entry whose data runs into the next entry is refused', () {
      expectProblem<NotAZip>(
        patchEntry(validZip(), 'src/search.js', compressedSize: 100000),
        'overlapping',
      );
    });

    test('an over-long local name is refused', () {
      expectProblem<NotAZip>(amplifiedZip(records: 1), 'over-long');
    });

    test('over-long name, extra and comment in a central record', () {
      for (final at in [28, 30, 32]) {
        expectProblem<NotAZip>(
          patchCentralField(validZip(), 'src/search.js', at, 1025),
          'over-long',
        );
      }
    });

    test('an end record announcing fewer entries than the directory holds', () {
      expectProblem<NotAZip>(
        patchEndRecord(validZip(), totalEntries: 2, entriesOnDisk: 2),
      );
    });

    test('an end record announcing more entries than the directory holds', () {
      expectProblem<NotAZip>(
        patchEndRecord(validZip(), totalEntries: 4, entriesOnDisk: 4),
      );
    });

    test('an end record announcing more than 50 entries', () {
      expectProblem<TooManyEntries>(
        patchEndRecord(validZip(), totalEntries: 51, entriesOnDisk: 51),
      );
    });

    test('a directory size that does not match', () {
      final zip = validZip();
      final size = ByteData.sublistView(zip)
          .getUint32(zip.length - 10, Endian.little);
      expectProblem<NotAZip>(patchEndRecord(zip, directorySize: size - 1));
    });

    test('zip64 markers in the end record are refused', () {
      expectProblem<NotAZip>(
        patchEndRecord(validZip(), totalEntries: 0xffff, entriesOnDisk: 0xffff),
        'zip64',
      );
      expectProblem<NotAZip>(
        patchEndRecord(validZip(), directoryOffset: 0xffffffff),
        'zip64',
      );
    });

    test('a zip64 locator before the end record is refused', () {
      final zip = validZip();
      final end = zip.length - 22;
      final locator = Uint8List(20)..setAll(0, [0x50, 0x4b, 0x06, 0x07]);
      final withLocator = Uint8List.fromList([
        ...zip.sublist(0, end),
        ...locator,
        ...zip.sublist(end),
      ]);
      expectProblem<NotAZip>(withLocator, 'zip64');
    });

    test('a multi-disk archive is refused', () {
      expectProblem<NotAZip>(
        patchEndRecord(validZip(), thisDisk: 1),
        'multi-disk',
      );
      expectProblem<NotAZip>(
        patchEndRecord(validZip(), entriesOnDisk: 2),
        'multi-disk',
      );
    });

    test('a fake end record inside the real comment is refused fast', () {
      // Real end record with a comment holding a second end record that
      // points at thousands of hidden central records, plus one extra byte.
      final hidden = amplifiedZip(records: 10000, localNameLength: 10);
      final fake = hidden.sublist(hidden.length - 22);
      final real = validZip();
      final end = real.length - 22;
      final comment = Uint8List.fromList([...fake, 0]);
      final forged = Uint8List.fromList([
        ...real.sublist(0, end),
        ...real.sublist(end, end + 20),
        comment.length & 0xff,
        comment.length >> 8,
        ...comment,
      ]);
      final watch = Stopwatch()..start();
      expectProblem<NotAZip>(forged);
      expect(watch.elapsedMilliseconds, lessThan(500));
    });

    test('all-ones sizes or offsets in a central record are refused', () {
      for (final field in [20, 24, 42]) {
        final zip = validZip();
        final start = ByteData.sublistView(zip)
            .getUint32(zip.length - 6, Endian.little);
        ByteData.sublistView(zip)
            .setUint32(start + field, 0xffffffff, Endian.little);
        expectProblem<NotAZip>(zip, 'zip64');
      }
    });

    test('bytes after the end record are refused', () {
      expectProblem<NotAZip>(Uint8List.fromList([...validZip(), 0, 0]));
    });

    test('a stored nested zip inside the package reads fine', () {
      final manifest = Uint8List.fromList([1, 2, 3]);
      final nested = validZip();
      final zip = handZip([
        HandEntry('plugin.json', manifest, crc: getCrc32(manifest)),
        HandEntry('old/plugin.zip', nested, crc: getCrc32(nested)),
      ]);
      expect(readZip(zip).manifest, [1, 2, 3]);
    });

    test('a nested zip does not excuse trailing data', () {
      final nested = validZip();
      final zip = handZip([
        HandEntry('plugin.json', Uint8List(0)),
        HandEntry('old/plugin.zip', nested, crc: getCrc32(nested)),
      ]);
      expectProblem<NotAZip>(Uint8List.fromList([...zip, 0]));
    });

    group('local header against the central record', () {
      Uint8List patchCentral(int at, int value) =>
          patchCentralField(validZip(), 'src/search.js', at, value);

      test('another method is refused', () {
        expectProblem<NotAZip>(patchCentral(10, 0), 'local header differs');
      });

      test('another flag (encryption) is refused', () {
        expectProblem<NotAZip>(patchCentral(8, 1), 'local header differs');
      });

      test('another name is refused', () {
        final zip = validZip();
        final start = ByteData.sublistView(zip)
            .getUint32(zip.length - 6, Endian.little);
        // First central record is `plugin.json`: change a name byte.
        final other = Uint8List.fromList(zip)..[start + 46] ^= 0x01;
        expectProblem<NotAZip>(other, 'local header differs');
      });

      test('a data-descriptor flag on one side only is tolerated', () {
        final plain = patchEntry(validZip(), 'src/search.js', flags: 0);
        final zip = patchCentralField(plain, 'src/search.js', 8, 8);
        expect(readZip(zip).scripts, contains('search.js'));
      });
    });

    test('a bad central record fails the whole package', () {
      final zip = validZip();
      final start = ByteData.sublistView(zip)
          .getUint32(zip.length - 6, Endian.little);
      final broken = Uint8List.fromList(zip)..[start + 1] = 0;
      expectProblem<NotAZip>(broken);
    });
  });
}
