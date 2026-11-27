import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/prepare_result.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/package_reader.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_package.dart';
import 'package:kanaru/src/plugins/domain/package/seekbar_assets.dart';

import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';
import 'services_test_support.dart';

const _zips = 'test/plugins/fixtures/seekbar/zips';

/// The sample zips of the plugins repository (see fixtures/seekbar/README.md).
List<File> _samples() =>
    Directory(_zips).listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

String _slug(File f) => f.uri.pathSegments.last.replaceAll('.zip', '');

void main() {
  late InstallHarness h;
  setUp(() => h = InstallHarness());
  tearDown(() => h.dispose());

  final samples = _samples().where((f) => _slug(f) != 'vinyl').toList();

  test('there are 21 installable samples and the Lottie one', () {
    expect(samples, hasLength(21));
    expect(_samples().map(_slug), contains('vinyl'));
  });

  for (final file in samples) {
    test(
      '${_slug(file)} installs and its assets read back byte for byte',
      () async {
        final zip = file.readAsBytesSync();
        final expected = switch (readPackage(zip)) {
          Ok(:final value) => value,
          Err(:final error) => fail('refused: $error'),
        };
        final held = await h.prepareFile(zip, '${_slug(file)}.zip');
        final result = await h.actions.installer.install(held.token);
        expect(result, isA<Installed>());

        final row = (await h.rows.liveById(held.installId))!;
        expect(row.kind, 'seekbar');
        expect(row.consentedHosts, isEmpty);
        for (final MapEntry(:key, :value) in expected.assets.entries) {
          expect(await h.files.readAsset(row, key), value, reason: key);
        }
        // Only the files the block names are stored; a skin without images
        // has no assets folder.
        final stored = Directory(
          '${h.dir.path}/plugins/${row.installId}/${row.packageDir}/assets',
        );
        final onDisk = stored.existsSync()
            ? stored.listSync().map((e) => e.uri.pathSegments.last).toSet()
            : <String>{};
        expect(onDisk, expected.assets.keys.toSet());
      },
    );
  }

  test('most samples carry images', () {
    final withAssets = samples.where((f) {
      final p = readPackage(f.readAsBytesSync());
      return p is Ok<PluginPackage, PackageProblem> &&
          p.value.assets.isNotEmpty;
    });
    expect(withAssets.length, greaterThan(15));
  });

  test('every asset a sample names exists in its zip', () {
    for (final file in samples) {
      final package = switch (readPackage(file.readAsBytesSync())) {
        Ok(:final value) => value,
        Err(:final error) => fail('${_slug(file)} refused: $error'),
      };
      final names = referencedAssets(package.manifest.seekbar!)
          .map(assetNameOf)
          .toSet();
      expect(package.assets.keys.toSet(), names, reason: _slug(file));
    }
  });

  test('the Lottie sample is refused as a feature this app cannot run', () {
    final zip = File('$_zips/vinyl.zip').readAsBytesSync();
    final problem = switch (readPackage(zip)) {
      Ok() => fail('accepted'),
      Err(:final error) => error,
    };
    expect(problem, isA<UnsupportedFeature>());
    expect(problem.detail, 'seekbar.thumb.lottie');
  });

  test('a sample with code added is not installed', () async {
    final zip = File('$_zips/cat.zip').readAsBytesSync();
    final withCode = buildZip({
      ..._entriesOf(zip),
      'src/search.js': 'function execute() {}',
    });
    h.pickedBytes = withCode;
    final result = await h.held.prepareFromFile(pickedZip('cat.zip')).result;
    expect(result, isA<Err>());
    expect(
      ((result as Err).error as PackageUnreadable).problem,
      isA<UnsafeEntry>(),
    );
  });
}

/// The files of [zip] by name, ready for [buildZip].
Map<String, Object> _entriesOf(Uint8List zip) {
  final archive = ZipDecoder().decodeBytes(zip);
  return {
    for (final f in archive)
      if (f.isFile) f.name: f.readBytes()!,
  };
}
