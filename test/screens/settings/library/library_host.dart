import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/library_counts_provider.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:material_ui/material_ui.dart';

import '../../../database/support/test_db.dart';
import '../../first_run/support/first_run_host.dart';
import '../support/settings_host.dart';

/// Everything a Settings › Library test holds on to.
class LibraryHarness {
  LibraryHarness({
    required this.settings,
    required this.db,
    required this.catalog,
    required this.scanner,
    required this.status,
  });

  final SettingsHarness settings;
  final AppDatabase db;
  final FakeCatalog catalog;
  final FullCountingScanner scanner;
  final StreamController<ScanStatus> status;

  /// Publishes a scan status, as the scanner would.
  Future<void> emit(WidgetTester tester, ScanStatus value) async {
    status.add(value);
    await tester.pump();
    await tester.pump();
  }
}

/// A scanner that tells plain re-scans from full ones.
class FullCountingScanner extends CountingScanner {
  int fullRescans = 0;
  int plainRescans = 0;

  @override
  Future<void> rescan({bool full = false}) {
    if (full) {
      fullRescans++;
    } else {
      plainRescans++;
    }
    return super.rescan(full: full);
  }
}

/// Opens Settings › Library with in-memory data and fakes for the platform
/// and the scanner. Scan status starts idle.
Future<LibraryHarness> openLibrary(
  WidgetTester tester, {
  bool android = false,
  Size size = const Size(400, 2400),
  MediaPermissionState? permission,
  LibraryOverview counts = (tracks: 2418, albums: 186, artists: 142),
  String location = SettingsPaths.library,
  Widget home = const SizedBox.shrink(),
  bool reduceMotion = false,
}) async {
  final db = openTestDb();
  addTearDown(db.close);
  final catalog = FakeCatalog(android: android);
  final scanner = FullCountingScanner();
  final status = StreamController<ScanStatus>.broadcast();
  addTearDown(status.close);
  final perm =
      permission ??
      (android
          ? perms(MediaPermissionStatus.granted, MediaPermissionStatus.granted)
          : const MediaPermissionState.notApplicable());
  final settings = await pumpSettings(
    tester,
    location: location,
    size: size,
    fakePermissions: false,
    scaffold: true,
    home: home,
    reduceMotion: reduceMotion,
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      libraryScanCommandsProvider.overrideWithValue(scanner),
      scanStatusProvider.overrideWith((ref) => status.stream),
      libraryOverviewProvider.overrideWith((ref) async => counts),
      ...platformOverrides(
        catalog: catalog,
        permissions: FakePermissions(perm),
        android: android,
      ),
    ],
  );
  status.add(const ScanIdle());
  await tester.pumpAndSettle();
  return LibraryHarness(
    settings: settings,
    db: db,
    catalog: catalog,
    scanner: scanner,
    status: status,
  );
}
