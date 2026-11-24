import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/state/folder_exclusion_providers.dart';
import 'package:kanaru/src/library/ui/add_to_playlist/add_to_playlist.dart';
import 'package:kanaru/src/library/ui/menus/menu_action_runner.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/domain/file_manager.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../playlists/support/playlist_fixtures.dart';
import '../support/ui_harness.dart';
import 'menu_fakes.dart';
import 'menu_fixtures.dart';

class _Favorites implements FavoritesController {
  final List<String> calls = [];
  Object? failWith;

  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) async {
    if (failWith != null) throw failWith!;
    calls.add('set ${tracks.map((t) => t.value)} $favorite');
  }

  @override
  Future<void> toggle(TrackId track) async {}
}

class _Rig {
  _Rig(
    this.container,
    this.runner,
    this.router,
    this.playback,
    this.exclusions,
    this.favorites,
    this.files,
  );

  final ProviderContainer container;
  final MenuActionRunner runner;
  final GoRouter router;
  final FakePlaybackCommands playback;
  final FakeFolderExclusions exclusions;
  final _Favorites favorites;
  final FakeFileManager files;
}

Future<_Rig> _pump(
  WidgetTester tester, {
  FileManagerError? revealError,
  List<Override> overrides = const [],
}) async {
  final playback = FakePlaybackCommands();
  final exclusions = FakeFolderExclusions();
  final favorites = _Favorites();
  final files = FakeFileManager(result: revealError);
  final container = ProviderContainer(
    overrides: [
      playbackCommandsProvider.overrideWithValue(playback),
      folderExclusionsProvider.overrideWithValue(exclusions),
      favoritesControllerProvider.overrideWithValue(favorites),
      fileManagerProvider.overrideWithValue(files),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  late BuildContext root;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) {
          root = Navigator.of(context, rootNavigator: true).context;
          return const Scaffold(body: Text('home'));
        },
      ),
      GoRoute(
        path: '/library/albums/x',
        builder: (_, _) => const Scaffold(body: Text('album page')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildKanaruTheme(brightness: Brightness.light),
        routerConfig: router,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
  return _Rig(
    container,
    MenuActionRunner(container, root),
    router,
    playback,
    exclusions,
    favorites,
    files,
  );
}

const _ctx = PlayContext(PlayContextKind.album, ref: 'k', label: 'Blue');

void main() {
  testWidgets('add to playlist opens the picker for the tracks', (
    tester,
  ) async {
    addTearDown(resetAddToPlaylistGuard);
    late PlaylistFixture fx;
    await tester.runAsync(() async => fx = await PlaylistFixture.open());
    final rig = await _pump(
      tester,
      overrides: [appDatabaseProvider.overrideWithValue(fx.db)],
    );
    final tracks = await tester.runAsync(() => fx.tracks(2)) ?? const [];
    unawaited(
      rig.runner.run(
        MenuAction.addToPlaylist(
          AddToPlaylistRequest(tracks: tracks, sourceLabel: 'from Blue'),
        ),
      ),
    );
    for (var i = 0; i < 200; i++) {
      if (find.text('2 songs · from Blue').evaluate().isNotEmpty) break;
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Add to playlist'), findsWidgets);
    expect(find.text('2 songs · from Blue'), findsOneWidget);
    expect(rig.playback.calls, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('favorites go through the controller; a failure is a toast', (
    tester,
  ) async {
    final rig = await _pump(tester);
    await rig.runner.run(
      MenuAction.favorite([TrackId(1), TrackId(2)], on: true),
    );
    expect(rig.favorites.calls, ['set (1, 2) true']);
    rig.favorites.failWith = ArgumentError('gone');
    await rig.runner.run(MenuAction.favorite([TrackId(3)], on: true));
    await tester.pump();
    expect(find.text('Could not change favorites'), findsOneWidget);
  });

  testWidgets('exclude acts at once and the toast undoes it', (tester) async {
    final rig = await _pump(tester);
    await rig.runner.run(
      MenuAction.exclude(
        musicFolder,
        'Jazz/Blue',
        displayPath: 'Music/Jazz/Blue',
      ),
    );
    await tester.pump();
    expect(rig.exclusions.calls, ['exclude 1 Jazz/Blue Music/Jazz/Blue']);
    expect(find.text('Excluded “Blue” from the library'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(rig.exclusions.calls.last, 'include 1 Jazz/Blue');
  });

  testWidgets('the undo still works once the page that excluded is gone', (
    tester,
  ) async {
    final rig = await _pump(tester);
    await rig.runner.run(
      MenuAction.exclude(musicFolder, 'Jazz', displayPath: 'Music/Jazz'),
    );
    await tester.pump();
    // The page that opened the menu closes.
    unawaited(rig.router.push('/library/albums/x'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(rig.exclusions.calls.last, 'include 1 Jazz');
  });

  testWidgets('a failed exclusion says so and offers no undo', (tester) async {
    final rig = await _pump(tester);
    rig.exclusions.failWith = StateError('db');
    await rig.runner.run(
      MenuAction.exclude(musicFolder, 'Jazz', displayPath: 'Music/Jazz'),
    );
    await tester.pump();
    expect(find.text('Could not exclude the folder'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('copy puts the text on the clipboard and says so', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final rig = await _pump(tester);
    await rig.runner.run(const MenuAction.copy('/home/u/Music'));
    await tester.pump();
    expect(copied, '/home/u/Music');
    expect(find.text('Path copied'), findsOneWidget);
  });

  testWidgets('reveal asks the file manager; an error is a toast', (
    tester,
  ) async {
    final ok = await _pump(tester);
    await ok.runner.run(const MenuAction.reveal('/a/b.flac'));
    expect(ok.files.revealed, ['/a/b.flac']);
    await tester.pump();
    expect(find.text('Could not open the file manager'), findsNothing);
  });

  testWidgets('a reveal that fails shows a toast', (tester) async {
    final rig = await _pump(tester, revealError: FileManagerError.notFound);
    await rig.runner.run(const MenuAction.reveal('/gone'));
    await tester.pump();
    expect(find.text('Could not open the file manager'), findsOneWidget);
  });

  testWidgets('play sends the ids, shuffled or not', (tester) async {
    final rig = await _pump(tester);
    await rig.runner.run(
      MenuAction.play(trackIds(3), shuffle: false, context: _ctx),
    );
    await rig.runner.run(
      MenuAction.play(trackIds(3), shuffle: true, context: _ctx),
    );
    final plain = rig.playback.calls[0] as PlayTracksCall;
    final shuffled = rig.playback.calls[1] as PlayTracksCall;
    expect(plain.startIndex, 0);
    expect(plain.shuffle, isFalse);
    expect(shuffled.shuffle, isTrue);
    expect(shuffled.tracks, trackIds(3));
    expect(shuffled.context, _ctx);
    // Nothing to play: no call, no error.
    await rig.runner.run(
      MenuAction.play(const [], shuffle: false, context: _ctx),
    );
    expect(rig.playback.calls, hasLength(2));
  });

  testWidgets('play next and enqueue insert, with a toast', (tester) async {
    final rig = await _pump(tester);
    await rig.runner.playNext(trackIds(2));
    await tester.pump();
    expect(rig.playback.calls.single, isA<PlayNextCall>());
    expect(find.text('Playing next'), findsOneWidget);
    await rig.runner.enqueue(trackIds(2));
    await tester.pump();
    expect(rig.playback.calls.last, isA<EnqueueCall>());
    expect(find.text('Added to queue'), findsOneWidget);
  });

  testWidgets('select adds and removes from the selection', (tester) async {
    final rig = await _pump(tester);
    await rig.runner.run(MenuAction.select(TrackId(5), on: true));
    await rig.runner.run(MenuAction.select(TrackId(5), on: true));
    expect(rig.container.read(librarySelectionProvider).ids, [TrackId(5)]);
    await rig.runner.run(MenuAction.select(TrackId(5), on: false));
    expect(rig.container.read(librarySelectionProvider).isEmpty, isTrue);
  });

  testWidgets('go pushes the page; Back returns', (tester) async {
    final rig = await _pump(tester);
    await rig.runner.run(const MenuAction.go('/library/albums/x'));
    await tester.pumpAndSettle();
    expect(find.text('album page'), findsOneWidget);
    rig.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('Go to the page that is already open pushes nothing', (
    tester,
  ) async {
    final rig = await _pump(tester);
    unawaited(rig.router.push('/library/albums/x'));
    await tester.pumpAndSettle();
    await rig.runner.run(const MenuAction.go('/library/albums/x'));
    await tester.pumpAndSettle();
    rig.router.pop();
    await tester.pumpAndSettle();
    // One pop returns to home: no duplicate of the page was pushed.
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('beforeNavigate runs first on every Go, also to the open page', (
    tester,
  ) async {
    final rig = await _pump(tester);
    var calls = 0;
    var pagesWhenCalled = -1;
    final runner = MenuActionRunner(
      rig.container,
      tester.element(find.text('home')),
      beforeNavigate: () {
        calls++;
        pagesWhenCalled = find.text('album page').evaluate().length;
      },
    );
    await runner.run(const MenuAction.go('/library/albums/x'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(pagesWhenCalled, 0); // before the page was pushed
    expect(find.text('album page'), findsOneWidget);
    // The page is open now: the host still gets to close what covers it.
    await runner.run(const MenuAction.go('/library/albums/x'));
    expect(calls, 2);
    rig.router.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('beforeNavigate is not called for actions that stay', (
    tester,
  ) async {
    final rig = await _pump(tester);
    var calls = 0;
    final runner = MenuActionRunner(
      rig.container,
      tester.element(find.text('home')),
      beforeNavigate: () => calls++,
    );
    await runner.run(MenuAction.favorite([TrackId(5)], on: true));
    await runner.run(MenuAction.select(TrackId(5), on: true));
    expect(calls, 0);
  });

  testWidgets('settled waits for a started caller action to finish', (
    tester,
  ) async {
    final rig = await _pump(tester);
    final gate = Completer<void>();
    var settled = false;
    unawaited(rig.runner.run(MenuAction.run((_) => gate.future)));
    unawaited(rig.runner.settled().then((_) => settled = true));
    await tester.pump();
    expect(settled, isFalse);
    gate.complete();
    await tester.pump();
    expect(settled, isTrue);
  });

  testWidgets('settled completes at once when nothing is running', (
    tester,
  ) async {
    final rig = await _pump(tester);
    await rig.runner.settled();
  });

  testWidgets('settled also completes when the caller action throws', (
    tester,
  ) async {
    final rig = await _pump(tester);
    final gate = Completer<void>();
    var settled = false;
    unawaited(rig.runner.run(MenuAction.run((_) => gate.future)));
    unawaited(rig.runner.settled().then((_) => settled = true));
    await tester.pump();
    expect(settled, isFalse);
    gate.completeError(StateError('x'));
    await tester.pump();
    await tester.pump();
    expect(settled, isTrue);
    expect(find.text(l10n.libraryActionFailed), findsOneWidget);
  });
}
