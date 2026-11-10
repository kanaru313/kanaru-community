import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/scan_controller.dart';
import 'package:kanaru/src/library/state/scan/scan_controller_provider.dart';
import 'package:kanaru/src/library/state/scan/scan_settings.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';

class _Paths implements AppPaths {
  _Paths(this.root);
  final Directory root;
  @override
  Directory get cacheDir => Directory('${root.path}/cache');
  @override
  Directory get configDir => Directory('${root.path}/config');
  @override
  Directory get dataDir => Directory('${root.path}/data');
}

void main() {
  late ProviderContainer container;
  late MemorySettingsStore store;

  setUp(() {
    final db = openTestDb();
    addTearDown(db.close);
    final dir = Directory.systemTemp.createTempSync('kanaru_scan_providers');
    addTearDown(() => dir.deleteSync(recursive: true));
    store = MemorySettingsStore();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(_Paths(dir)),
        settingsStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
  });

  test('the commands provider is the real scan controller', () {
    final commands = container.read(libraryScanCommandsProvider);
    expect(commands, isA<ScanController>());
    expect(commands, same(container.read(scanControllerProvider)));
  });

  test('the status starts idle', () async {
    final sub = container.listen(scanStatusProvider, (_, _) {});
    addTearDown(sub.close);
    final first = await container.read(scanStatusProvider.future);
    expect(first, isA<ScanIdle>());
  });

  testWidgets('creating both providers leaves no timer behind', (tester) async {
    container.read(libraryScanCommandsProvider);
    container.listen(scanStatusProvider, (_, _) {});
    await container.read(scanStatusProvider.future);
    container.dispose();
  });

  test('a rescan before setup is done is accepted and does nothing', () async {
    container.listen(scanStatusProvider, (_, _) {});
    await container.read(libraryScanCommandsProvider).rescan();
    final status = await container.read(scanStatusProvider.future);
    expect(status, isA<ScanIdle>());
  });

  test('changing settings keeps the same controller', () async {
    final before = container.read(scanControllerProvider);
    await container.read(setupDoneProvider.notifier).set(true);
    await container.read(skipShortTracksProvider.notifier).set(false);
    await container.read(setupDefaultsAppliedProvider.notifier).set(true);
    expect(container.read(scanControllerProvider), same(before));
  });

  test('the setting keys and defaults', () {
    expect(setupDoneSetting.key, 'library.setup_done');
    expect(setupDoneSetting.defaultValue, isFalse);
    expect(skipShortTracksSetting.key, 'library.skip_short_tracks');
    expect(skipShortTracksSetting.defaultValue, isTrue);
    expect(setupDefaultsAppliedSetting.key, 'library.setup_defaults_applied');
    expect(setupDefaultsAppliedSetting.defaultValue, isFalse);
    expect(() => setupDoneSetting.decode('yes'), throwsFormatException);
    expect(store.read('library.setup_done'), isNull);
  });
}
