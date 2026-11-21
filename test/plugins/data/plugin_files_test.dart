import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/store/plugin_files.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_package.dart';

import '../fixtures/zip_builders.dart';
import 'store_test_support.dart';

/// The `plugin.json` text every default test package carries.
final _demoManifest = packageOf().manifestText;

PluginRow _rowAt(String id, String? dir) => PluginRow(
  installId: id,
  kind: 'lyrics',
  name: 'Demo',
  version: 3,
  apiVersion: 1,
  manifestJson: _demoManifest,
  packageDir: dir,
  packageSha256: 'a' * 64,
  origin: 'file',
  originLabel: 'demo.zip',
  consentedHostsJson: '[]',
  installedAt: 1,
  updatedAt: 1,
);

void main() {
  late Directory data;
  late PluginFiles files;
  final id = testInstallId();
  var now = 1000;

  setUp(() {
    data = Directory.systemTemp.createTempSync('plugin_files_test');
    now = 1000;
    files = PluginFiles(data, clock: () => now);
  });
  tearDown(() => data.deleteSync(recursive: true));

  Directory folder(String dir) => Directory('${data.path}/plugins/$id/$dir');

  group('write', () {
    test('writes plugin.json bytes, scripts and icon, named by time', () async {
      final icon = pngHeader(64, 64);
      final text = jsonEncode(manifestWith({}));
      // Extra spaces and a trailing newline must survive byte for byte.
      final raw = '$text  \n';
      final package = packageOf(null, {'plugin.json': raw, 'icon.png': icon});
      final dir = await files.write(id, package);
      expect(dir, 'v3-1000');
      expect(
        File('${folder(dir).path}/plugin.json').readAsBytesSync(),
        utf8.encode(raw),
      );
      expect(File('${folder(dir).path}/icon.png').readAsBytesSync(), icon);
      expect(
        File('${folder(dir).path}/src/search.js').readAsStringSync(),
        package.scripts['search.js'],
      );
      expect(File('${folder(dir).path}/src/lyrics.js').existsSync(), isTrue);
    });

    test('a name already taken moves the stamp forward', () async {
      final first = await files.write(id, packageOf());
      final second = await files.write(id, packageOf());
      expect(first, 'v3-1000');
      expect(second, 'v3-1001');
      expect(folder(first).existsSync(), isTrue);
    });

    test(
      'a failure half way deletes the new folder and keeps the old',
      () async {
        final old = await files.write(id, packageOf());
        var written = 0;
        final failing = PluginFiles(
          data,
          clock: () => 2000,
          writeFile: (file, bytes) async {
            if (++written == 2) throw const FileSystemException('disk full');
            await file.writeAsBytes(bytes, flush: true);
          },
        );
        await expectLater(
          failing.write(id, packageOf()),
          throwsA(isA<FileSystemException>()),
        );
        expect(folder('v3-2000').existsSync(), isFalse);
        expect(folder(old).existsSync(), isTrue);
      },
    );

    test('a failure of a first install leaves no plugin folder', () async {
      final failing = PluginFiles(
        data,
        writeFile: (_, _) async => throw const FileSystemException('nope'),
      );
      await expectLater(
        failing.write(id, packageOf()),
        throwsA(isA<FileSystemException>()),
      );
      expect(Directory('${data.path}/plugins/$id').existsSync(), isFalse);
    });

    test('bad ids are refused before any file system call', () async {
      var touched = 0;
      final spy = PluginFiles(data, writeFile: (_, _) async => touched++);
      for (final bad in [
        '../evil',
        'plugin-1',
        '$id/..',
        '',
        'plugin-${'G' * 32}',
      ]) {
        await expectLater(
          spy.write(bad, packageOf()),
          throwsArgumentError,
          reason: bad,
        );
      }
      expect(touched, 0);
      expect(Directory('${data.path}/plugins').existsSync(), isFalse);
    });

    test('a bad script name is refused before anything is created', () async {
      final package = packageOf();
      final bad = PluginPackage(
        manifestBytes: package.manifestBytes,
        manifestText: package.manifestText,
        manifest: package.manifest,
        scripts: {'../x.js': 'a', ...package.scripts},
        sha256: package.sha256,
        size: package.size,
      );
      await expectLater(files.write(id, bad), throwsArgumentError);
      expect(Directory('${data.path}/plugins').existsSync(), isFalse);
    });
  });

  group('read', () {
    test('readPackage gives the manifest and every script', () async {
      final dir = await files.write(id, packageOf());
      final stored = await files.readPackage(_rowAt(id, dir));
      expect(stored.manifest.name, 'Demo');
      expect(stored.scripts.keys, containsAll(['search.js', 'lyrics.js']));
    });

    test(
      'a row without a package, or with a bad folder name, is unreadable',
      () async {
        await expectLater(
          files.readPackage(_rowAt(id, null)),
          throwsA(isA<PluginPackageUnreadable>()),
        );
        await expectLater(
          files.readPackage(_rowAt(id, '../v1-1')),
          throwsA(isA<PluginPackageUnreadable>()),
        );
      },
    );

    test('is cached per folder; a failure is not cached', () async {
      final dir = await files.write(id, packageOf());
      final row = _rowAt(id, dir);
      final script = File('${folder(dir).path}/src/lyrics.js');
      final body = script.readAsStringSync();
      await files.readPackage(row);
      // A cached folder is not read again, so a vanished script is not seen.
      script.deleteSync();
      expect((await files.readPackage(row)).scripts, contains('lyrics.js'));
      // A fresh cache reads the damaged folder: unreadable, then fixed.
      final other = PluginFiles(data);
      await expectLater(
        other.readPackage(row),
        throwsA(isA<PluginPackageUnreadable>()),
      );
      script.writeAsStringSync(body);
      expect((await other.readPackage(row)).scripts, contains('lyrics.js'));
    });

    test('the cache holds its limit and drops the oldest folder', () async {
      final small = PluginFiles(data, cacheEntries: 2, clock: () => now++);
      final dirs = [
        for (var i = 0; i < 3; i++) await small.write(id, packageOf()),
      ];
      for (final d in dirs) {
        await small.readPackage(_rowAt(id, d));
      }
      for (final d in dirs) {
        File('${folder(d).path}/src/lyrics.js').deleteSync();
      }
      // The two newest are still cached; the oldest was dropped and is read
      // again from the damaged folder.
      expect(
        (await small.readPackage(_rowAt(id, dirs[2]))).scripts,
        contains('lyrics.js'),
      );
      expect(
        (await small.readPackage(_rowAt(id, dirs[1]))).scripts,
        contains('lyrics.js'),
      );
      await expectLater(
        small.readPackage(_rowAt(id, dirs[0])),
        throwsA(isA<PluginPackageUnreadable>()),
      );
    });

    test('a damaged package is unreadable with a reason, no path', () async {
      final dir = await files.write(id, packageOf());
      File('${folder(dir).path}/plugin.json').writeAsStringSync('{broken');
      final error = await files
          .readPackage(_rowAt(id, dir))
          .then<Object>((_) => 'read', onError: (Object e) => e);
      expect(error, isA<PluginPackageUnreadable>());
      expect(
        (error as PluginPackageUnreadable).reason,
        isNot(contains(data.path)),
      );
    });

    test(
      'a plugin.json that differs from the row is unreadable, not cached',
      () async {
        final dir = await files.write(id, packageOf());
        final row = _rowAt(
          id,
          dir,
        ).copyWith(manifestJson: jsonEncode(manifestWith({})));
        // The row's text is the one that was reviewed; the folder has another.
        final package = packageOf();
        final matching = _rowAt(
          id,
          dir,
        ).copyWith(manifestJson: package.manifestText);
        expect((await files.readPackage(matching)).manifest.name, 'Demo');
        await expectLater(
          files.readPackage(row),
          throwsA(
            isA<PluginPackageUnreadable>().having(
              (e) => e.reason,
              'reason',
              'plugin.json changed',
            ),
          ),
        );
        // The next read with the right row works again.
        expect((await files.readPackage(matching)).manifest.name, 'Demo');
      },
    );

    test('a script over its cap is unreadable', () async {
      final dir = await files.write(id, packageOf());
      File('${folder(dir).path}/src/search.js')
          .writeAsBytesSync(Uint8List(1024 * 1024 + 1));
      await expectLater(
        files.readPackage(_rowAt(id, dir)),
        throwsA(isA<PluginPackageUnreadable>()),
      );
    });

    test('readIcon and exists', () async {
      final dir = await files.write(
        id,
        packageOf(null, {'icon.png': pngHeader(32, 32)}),
      );
      final row = _rowAt(id, dir);
      expect(await files.readIcon(row), isNotNull);
      expect(await files.exists(row), isTrue);
      expect(await files.exists(_rowAt(id, 'v9-9')), isFalse);
      expect(await files.exists(_rowAt(id, null)), isFalse);
      expect(await files.exists(_rowAt(id, '../v1-1')), isFalse);
      File('${folder(dir).path}/icon.png').deleteSync();
      expect(await files.readIcon(row), isNull);
    });
  });

  group('sweep support', () {
    test('listFolders lists well-named folders only, never links', () async {
      final a = await files.write(id, packageOf());
      final other = testInstallId(2);
      now = 2000;
      final b = await files.write(other, packageOf());
      Directory('${data.path}/plugins/junk').createSync();
      Directory('${data.path}/plugins/$id/not-a-version').createSync();
      File('${data.path}/plugins/stray.txt').writeAsStringSync('x');
      final target = Directory('${data.path}/target')..createSync();
      Link('${data.path}/plugins/${testInstallId(3)}').createSync(target.path);
      final found = (await files.listFolders()).map((f) => f.key).toSet();
      expect(found, {'$id/$a', '$other/$b'});
    });

    test('listFolders is empty without a plugins folder', () async {
      expect(await files.listFolders(), isEmpty);
    });

    test(
      'deleteFolder removes the folder and an emptied plugin folder',
      () async {
        final a = await files.write(id, packageOf());
        now = 2000;
        final b = await files.write(id, packageOf());
        expect(await files.deleteFolder(id, a), isTrue);
        expect(folder(b).existsSync(), isTrue);
        expect(await files.deleteFolder(id, b), isTrue);
        expect(Directory('${data.path}/plugins/$id').existsSync(), isFalse);
        expect(await files.deleteFolder(id, b), isFalse);
      },
    );

    test('deleteFolder refuses a bad name and touches nothing', () async {
      final dir = await files.write(id, packageOf());
      expect(await files.deleteFolder(id, '../$id/$dir'), isFalse);
      expect(await files.deleteFolder('..', dir), isFalse);
      expect(folder(dir).existsSync(), isTrue);
    });

    test('deleting a folder drops it from the cache', () async {
      final dir = await files.write(id, packageOf());
      final row = _rowAt(id, dir);
      await files.readPackage(row);
      await files.deleteFolder(id, dir);
      await expectLater(
        files.readPackage(row),
        throwsA(isA<PluginPackageUnreadable>()),
      );
    });
  });
}
