import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_routes.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../database/support/test_db.dart';
import '../../../support/fake_playback_commands.dart';
import '../../../support/memory_settings_store.dart';

/// Reload interval of the lists in these tests (the app waits 1 s).
const testRefresh = Duration(milliseconds: 100);

class _TempPaths implements AppPaths {
  _TempPaths(Directory root)
    : dataDir = Directory('${root.path}/data')..createSync(),
      cacheDir = Directory('${root.path}/cache')..createSync(),
      configDir = Directory('${root.path}/config')..createSync();

  @override
  final Directory dataDir;
  @override
  final Directory cacheDir;
  @override
  final Directory configDir;
}

/// The library routes in a router of their own (no app shell), with a test
/// database, a recording player and short reload intervals.
class LibraryHarness {
  LibraryHarness._(
    this.container,
    this.router,
    this.db,
    this.playback,
    this.sourceId,
    this._folderFeed,
    this._nowFeed,
  );

  final ProviderContainer container;
  final GoRouter router;
  final AppDatabase db;
  final FakePlaybackCommands playback;
  final int sourceId;
  final StreamController<List<MusicFolder>> _folderFeed;
  final StreamController<NowPlaying> _nowFeed;
  final List<MusicFolder> _folders = [];
  int _folderSeq = 0;

  /// Adds a music folder (a source with its own tracks) to what
  /// `musicFoldersProvider` reports and returns it.
  Future<MusicFolder> addFolder(
    String name, {
    String? root,
    StorageVolume volume = const StorageVolume(
      root: '/home/u',
      kind: StorageVolumeKind.home,
    ),
  }) async {
    final uid = 'uid-${_folderSeq++}-$name';
    final id = await addSource(db, uid: uid, name: name);
    final folder = MusicFolder(
      sourceId: id,
      sourceUid: uid,
      root: root ?? '/home/u/$name',
      volume: volume,
      name: name,
    );
    _folders.add(folder);
    _folderFeed.add(List.of(_folders));
    return folder;
  }

  /// Changes what the player reports as loaded.
  void setNowPlaying(NowPlaying value) => _nowFeed.add(value);

  /// The titles of the song rows built, top to bottom.
  List<String> songTitles(WidgetTester tester) => [
    for (final t in tester.widgetList<SongTile>(find.byType(SongTile)))
      t.info.title,
  ];

  /// Location of the page on top (pushed pages included).
  String get location => router.state.uri.toString();

  /// Runs the pending reloads: past the throttle of the lists. The database
  /// answers in real time, the throttle waits in fake time, so each round
  /// lets real time pass and then the fake clock.
  Future<void> settle(WidgetTester tester, {int rounds = 5}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      // A reload waits as long as the last load took in real time (at most
      // 5 s), so the fake clock moves well past the interval.
      await tester.pump(const Duration(seconds: 2));
    }
  }
}

/// Pumps the library routes at [initial] on a window of [width] x [height].
///
/// [header] wraps the pages the way the app shell does (a header scope).
/// Write fixtures after this returns: the database is the harness's own.
Future<LibraryHarness> pumpLibrary(
  WidgetTester tester, {
  String initial = '/library',
  double width = 390,
  double height = 844,
  List<Override> overrides = const [],
  FakePlaybackCommands? playback,
  Widget Function(Widget child)? header,
  List<MusicFolder> folders = const [],
  ScanStatus scan = const ScanIdle(),
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  final root = Directory.systemTemp.createTempSync('kanaru_library_ui');
  addTearDown(() => root.deleteSync(recursive: true));
  final db = openTestDb();
  addTearDown(db.close);
  final player = playback ?? FakePlaybackCommands();
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      libraryRoute(),
      // Stand-ins for the detail pages, so a push has somewhere to go.
      for (final kind in ['albums', 'artists', 'genres', 'languages'])
        GoRoute(
          path: '/library/$kind/:key',
          builder: (_, state) =>
              Text('detail $kind ${state.pathParameters['key']}'),
        ),
      GoRoute(
        path: '/probe',
        builder: (context, _) => Column(
          children: [
            PageHeader(title: 'Probe', onBack: context.pop),
            const Text('probe page'),
          ],
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  final folderFeed = StreamController<List<MusicFolder>>();
  addTearDown(() => unawaited(folderFeed.close()));
  folderFeed.add(folders);
  final nowFeed = StreamController<NowPlaying>();
  addTearDown(() => unawaited(nowFeed.close()));
  nowFeed.add(NowPlaying.none);
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      appPathsProvider.overrideWithValue(_TempPaths(root)),
      playbackCommandsProvider.overrideWithValue(player),
      nowPlayingProvider.overrideWith((ref) => nowFeed.stream),
      scanStatusProvider.overrideWith((ref) => Stream.value(scan)),
      musicFoldersProvider.overrideWith((ref) => folderFeed.stream),
      browseRefreshIntervalProvider.overrideWithValue(testRefresh),
      folderRefreshIntervalProvider.overrideWithValue(testRefresh),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  final sourceId = await addSource(db);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildKanaruTheme(brightness: Brightness.light),
        locale: locale,
        routerConfig: router,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // The app shell supplies a Scaffold (Material) and the header scope.
        builder: (context, child) {
          final page = child ?? const SizedBox.shrink();
          return Scaffold(body: header == null ? page : header(page));
        },
      ),
    ),
  );
  final harness = LibraryHarness._(
    container,
    router,
    db,
    player,
    sourceId,
    folderFeed,
    nowFeed,
  );
  await harness.settle(tester);
  return harness;
}
