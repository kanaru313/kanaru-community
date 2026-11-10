import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/folder_exclusion_providers.dart';
import 'package:kanaru/src/library/state/scan/music_folder_editor.dart';
import 'package:kanaru/src/library/state/scan/music_folder_editor_provider.dart';
import 'package:kanaru/src/library/state/scan/scan_settings.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';
import 'package:kanaru/src/platform/state/local_audio_catalog_provider.dart';
import 'package:kanaru/src/platform/state/media_permissions_provider.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/platform/state/storage_volumes_provider.dart';
import 'package:kanaru/src/screens/first_run/ui/first_run_page.dart';
import 'package:kanaru/src/screens/settings/state/appearance_settings.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../database/support/test_db.dart';
import '../../../support/memory_settings_store.dart';

/// A catalog the test scripts.
class FakeCatalog implements LocalAudioCatalog {
  FakeCatalog({this.android = false});

  final bool android;
  String? suggestion;
  List<AudioFolderSummary> folders = [];

  /// Answers of the system folder dialog, one per call.
  final List<String?> picks = [];
  final List<String?> pickStarts = [];

  @override
  Future<String> canonicalize(String path) async => path;
  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
  }) async => const AudioListing();
  int audioFolderReads = 0;

  @override
  Future<List<AudioFolderSummary>> audioFolders() async {
    audioFolderReads++;
    return folders;
  }

  @override
  Future<String?> suggestedMusicFolder() async => suggestion;
  @override
  FolderChoice get folderChoice =>
      android ? FolderChoice.mediaStoreSheet : FolderChoice.systemDialog;
  @override
  Future<String?> pickFolder({String? initialDirectory}) async {
    pickStarts.add(initialDirectory);
    return picks.isEmpty ? null : picks.removeAt(0);
  }
}

/// Permissions the test moves by hand.
class FakePermissions implements MediaPermissions {
  FakePermissions(this.state);

  MediaPermissionState state;
  int settingsOpened = 0;
  final List<String> requests = [];

  /// What a request turns the state into.
  MediaPermissionState Function(MediaPermissionState)? onAudio, onImages;

  @override
  Future<MediaPermissionState> status() async => state;
  @override
  Future<MediaPermissionState> requestAudio() async {
    requests.add('audio');
    return state = onAudio?.call(state) ?? state;
  }

  @override
  Future<MediaPermissionState> requestImages() async {
    requests.add('images');
    return state = onImages?.call(state) ?? state;
  }

  @override
  Future<bool> openSettings() async => ++settingsOpened > 0;
}

MediaPermissionState perms(
  MediaPermissionStatus audio,
  MediaPermissionStatus images,
) => MediaPermissionState(audio: audio, images: images);

class FakeVolumes implements StorageVolumes {
  FakeVolumes(this.volumes);

  final List<StorageVolume> volumes;
  @override
  Future<List<StorageVolume>> list() async => volumes;
  @override
  StorageVolume volumeOf(String path) => volumeForPath(volumes, path);
}

class CountingScanner implements LibraryScanCommands {
  int rescans = 0;

  /// When set, a request does not complete until it does.
  Completer<void>? gate;

  @override
  Future<void> rescan({bool full = false}) async {
    rescans++;
    await gate?.future;
  }
}

/// Everything a first-run test touches.
class FirstRunHarness {
  FirstRunHarness({
    required this.container,
    required this.db,
    required this.catalog,
    required this.permissions,
    required this.settings,
    required this.scanner,
  });

  final ProviderContainer container;
  final AppDatabase db;
  final FakeCatalog catalog;
  final MediaPermissions permissions;
  final MemorySettingsStore settings;
  final CountingScanner scanner;

  FakePermissions get fake => permissions as FakePermissions;

  MusicFolderEditor get editor => container.read(musicFolderEditorProvider);
}

const androidInternal = StorageVolume(
  root: '/storage/emulated/0',
  kind: StorageVolumeKind.internal,
);
const linuxHome = StorageVolume(root: '/home/u', kind: StorageVolumeKind.home);

/// The platform fakes and an editor that does not look at the disk, shared
/// by tests that build the page themselves and by tests that run the app.
List<Override> platformOverrides({
  required FakeCatalog catalog,
  required MediaPermissions permissions,
  required bool android,
}) => [
  localAudioCatalogProvider.overrideWithValue(catalog),
  mediaPermissionsProvider.overrideWithValue(permissions),
  storageVolumesProvider.overrideWithValue(
    FakeVolumes(android ? [androidInternal] : [linuxHome]),
  ),
  musicFolderEditorProvider.overrideWith(
    (ref) => MusicFolderEditor(
      db: ref.watch(appDatabaseProvider),
      catalog: catalog,
      permissions: permissions,
      volumes: ref.watch(storageVolumesProvider),
      exclusions: ref.watch(folderExclusionsProvider),
      defaultsApplied: () => ref.read(setupDefaultsAppliedProvider),
      markDefaultsApplied: () =>
          ref.read(setupDefaultsAppliedProvider.notifier).set(true),
      onChanged: () => ref.read(folderEditsProvider.notifier).bump(),
      // The paths of these tests are not on disk.
      isDirectory: (_) async => true,
    ),
  ),
];

/// Pumps [FirstRunPage] on a window of [width] with fakes for the platform.
Future<FirstRunHarness> pumpFirstRun(
  WidgetTester tester, {
  bool android = false,
  double? width,
  double height = 2600,
  MediaPermissionState? permission,
  FakeCatalog? catalog,
  MediaPermissions? permissions,
  MemorySettingsStore? settings,
  List<Override> overrides = const [],
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width ?? (android ? 400 : 1280), height);
  addTearDown(tester.view.reset);

  final db = openTestDb();
  addTearDown(db.close);
  final fakeCatalog = catalog ?? FakeCatalog(android: android);
  final fakePermissions =
      permissions ??
      FakePermissions(
        permission ??
            (android
                ? perms(
                    MediaPermissionStatus.denied,
                    MediaPermissionStatus.denied,
                  )
                : const MediaPermissionState.notApplicable()),
      );
  final store = settings ?? MemorySettingsStore();
  final scanner = CountingScanner();
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(store),
      libraryScanCommandsProvider.overrideWithValue(scanner),
      ...platformOverrides(
        catalog: fakeCatalog,
        permissions: fakePermissions,
        android: android,
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const _App(child: FirstRunPage()),
    ),
  );
  if (settle) await tester.pumpAndSettle();
  return FirstRunHarness(
    container: container,
    db: db,
    catalog: fakeCatalog,
    permissions: fakePermissions,
    settings: store,
    scanner: scanner,
  );
}

/// A localized app whose theme follows the theme setting, like the real one.
class _App extends ConsumerWidget {
  const _App({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeChoiceProvider);
    final language = ref.watch(appLanguageProvider);
    return MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      darkTheme: buildKanaruTheme(brightness: Brightness.dark),
      themeMode: theme.mode,
      locale: Locale(language.name),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}

extension FirstRunFinders on WidgetTester {
  ThemeMode get themeMode =>
      widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;
}

/// A Switch row's switch by the row title.
Finder switchOf(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(KSwitchRow)),
  matching: find.byType(Switch),
);
