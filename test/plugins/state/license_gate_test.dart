import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/domain/license.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/platform/state/document_picker_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_services_provider.dart';

import '../../database/support/test_db.dart';
import '../data/services_test_support.dart';
import '../domain/plugin_test_support.dart';
import '../fixtures/zip_builders.dart';
import 'state_test_support.dart';

class _License implements LicenseService {
  LicenseStatus status = LicenseStatus.locked;

  @override
  LicenseStatus statusOf(ProFeature feature) =>
      feature == multiStreamingFeature ? status : LicenseStatus.locked;
}

/// The real mapping, license service to Free rule, through the providers; the
/// status changes while the container lives.
void main() {
  test('the license is asked at every check', () async {
    final db = openTestDb();
    final dir = tempDir();
    final license = _License();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(TestPaths(dir)),
        licenseServiceProvider.overrideWithValue(license),
        scriptCheckerProvider.overrideWithValue(FakeChecker()),
        pluginFetcherProvider.overrideWithValue(
          FakeFetcher((_) async => throw StateError('offline')),
        ),
        documentPickerProvider.overrideWithValue(
          FakePicker(
            (doc, _) async =>
                Ok(validZipBytes(doc.name.replaceAll('.zip', ''))),
          ),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
      dir.deleteSync(recursive: true);
    });
    final held = container.read(pluginServicesProvider).held;
    final actions = container.read(pluginActionsProvider);

    Future<InstallResult> install(String name) async {
      final prepared = await held
          .prepareFromFile(pickedZip('$name.zip'))
          .result;
      final token = switch (prepared) {
        Ok(:final value) => value.token,
        Err(:final error) => fail('prepare refused: $error'),
      };
      return actions.installer.install(token);
    }

    expect(await install('One'), isA<Installed>());
    final locked = await install('Two');
    expect((locked as InstallRefused).failure, InstallFailure.proRequired);

    license.status = LicenseStatus.granted;
    expect(await install('Two'), isA<Installed>());
  });
}

/// A streaming zip whose plugin name is the file name.
Uint8List validZipBytes(String name) => validZip(
  manifest: {
    'metadata': {
      ...(streamingManifest()['metadata']! as Map<String, Object?>),
      'name': name,
    },
    'script': streamingManifest()['script'],
  },
  extra: {'src/stream.js': 'x'},
);
