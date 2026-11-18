import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/ui/playlists/menu/playlist_menu.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import 'support/playlist_menu_support.dart';
import 'support/playlist_ui_harness.dart';

/// Lets the menu finish loading (the database answers in real time) and its
/// route animate in.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pumpAndSettle();
}

Future<PlaylistUiHarness> _pump(
  WidgetTester t, {
  double width = 400,
  FakePlaybackCommands? playback,
}) => PlaylistUiHarness.pump(
  t,
  width: width,
  overrides: [
    fileManagerProvider.overrideWithValue(NoFileManager()),
    if (playback != null) playbackCommandsProvider.overrideWithValue(playback),
  ],
);

Future<String> _seed(
  WidgetTester t,
  PlaylistUiHarness h, {
  String name = 'Chill',
  int songs = 3,
}) async => (await t.runAsync(() async {
  final tracks = [
    for (var i = 0; i < songs; i++) await h.fixture.track('$name-$i'),
  ];
  return h.fixture.repo.createPlaylist(
    name: name,
    description: 'Rainy days',
    tracks: tracks,
  );
}))!;

Future<void> _open(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid, {
  bool own = false,
}) async {
  unawaited(h.launch(t, (c) => openPlaylistMenu(c, uid, onOwnPage: own)));
  await _settle(t);
}

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  uiTest('a playlist that is gone: not-found toast, no menu', (t) async {
    final h = await _pump(t);
    final l10n = h.l10n(t);
    final uid = await _seed(t, h);
    await t.runAsync(() => h.fixture.repo.deletePlaylist(uid));
    await _open(t, h, uid);
    expect(find.text(l10n.libraryNotFoundMessage), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  uiTest('opens the sheet with the head and the rows; hints stay hidden', (
    t,
  ) async {
    final h = await _pump(t);
    final l10n = h.l10n(t);
    final uid = await _seed(t, h);
    await _open(t, h, uid);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Chill'), findsWidgets);
    expect(find.text('Rainy days'), findsOneWidget);
    for (final label in [
      l10n.playlistMenuGoTo,
      l10n.libraryPlay,
      l10n.libraryShuffle,
      l10n.playlistMenuCopyTo,
      l10n.libraryMenuFavoriteAll,
      l10n.playlistMenuEdit,
      l10n.libraryMenuAdvanced,
      l10n.libraryMenuPlayNext,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(l10n.playlistMenuEditHint), findsNothing);
    expect(find.text(l10n.playlistMenuCopyToHint(3)), findsNothing);
  });

  uiTest('Play starts the songs in saved order with the playlist as source', (
    t,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await _pump(t, playback: playback);
    final l10n = h.l10n(t);
    final uid = await _seed(t, h);
    // Saved order differs from title, id and insertion order: the last song
    // is moved to the top.
    final entries = (await t.runAsync(() => h.fixture.live(uid)))!;
    await t.runAsync(
      () =>
          h.fixture.repo.moveEntry(uid, entries.last.uid, afterEntryUid: null),
    );
    final expected = [
      entries.last.track,
      for (final e in entries.take(entries.length - 1)) e.track,
    ];
    await _open(t, h, uid);
    await t.tap(find.text(l10n.libraryPlay));
    await _settle(t);
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.map((e) => e.value).toList(), expected);
    expect(call.shuffle, isFalse);
    expect(call.context.kind, PlayContextKind.playlist);
    expect(call.context.ref, uid);
  });

  uiTest('Advanced of a playlist holds Duplicate, M3U and Delete', (t) async {
    final h = await _pump(t);
    final l10n = h.l10n(t);
    final uid = await _seed(t, h);
    await _open(t, h, uid);
    await t.tap(find.text(l10n.libraryMenuAdvanced));
    await _settle(t);
    for (final label in [
      l10n.playlistMenuDuplicate,
      l10n.playlistMenuExportM3u,
      l10n.playlistMenuExportM3uRelative,
      l10n.playlistMenuDelete,
      l10n.playlistMenuDeleteHint,
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(l10n.playlistMenuExportM3uRelativeHint), findsNothing);
  });

  uiTest('Favorites: no edit, no cover button; Advanced has its own rows', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    final h = await _pump(t);
    final l10n = h.l10n(t);
    await t.runAsync(
      () async => h.fixture.repo.addToPlaylists(
        tracks: [await h.fixture.track('f0')],
        playlistUids: [PlaylistUids.favorites],
      ),
    );
    await _open(t, h, PlaylistUids.favorites);
    expect(find.text(l10n.playlistMenuGoToFavorites), findsOneWidget);
    expect(find.text(l10n.playlistMenuEdit), findsNothing);
    expect(find.bySemanticsLabel(l10n.playlistMenuChangeCover), findsNothing);
    await t.tap(find.text(l10n.libraryMenuAdvanced));
    await _settle(t);
    expect(find.text(l10n.playlistMenuSaveAs), findsOneWidget);
    expect(find.text(l10n.playlistMenuClearFavorites), findsOneWidget);
    expect(find.text(l10n.playlistMenuDelete), findsNothing);
    semantics.dispose();
  });

  uiTest(
    'desktop: a dialog; a playlist without description shows its edit date',
    (t) async {
      final semantics = t.ensureSemantics();
      final h = await _pump(t, width: 1280);
      final l10n = h.l10n(t);
      final uid = (await t.runAsync(
        () => h.fixture.repo.createPlaylist(name: 'Bare'),
      ))!;
      await _open(t, h, uid);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.textContaining('Edited '), findsOneWidget);
      expect(
        find.bySemanticsLabel(l10n.playlistMenuChangeCover),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  group('on the playlist\'s own page', () {
    uiTest('no Go to, Play or Shuffle', (t) async {
      final h = await _pump(t);
      final l10n = h.l10n(t);
      final uid = await _seed(t, h);
      final sub = h.container.listen(playlistPageProvider(uid), (_, _) {});
      await _open(t, h, uid, own: true);
      expect(find.text(l10n.playlistMenuEdit), findsOneWidget);
      expect(find.text(l10n.playlistMenuGoTo), findsNothing);
      expect(find.text(l10n.libraryPlay), findsNothing);
      expect(find.text(l10n.libraryShuffle), findsNothing);
      sub.close();
      await t.pump(const Duration(seconds: 2));
    });

    uiTest(
      'waits for a held write inside the builder; a second tap opens nothing extra',
      (t) async {
        final h = await _pump(t);
        final l10n = h.l10n(t);
        final uid = await _seed(t, h);
        final page = playlistPageProvider(uid);
        final sub = h.container.listen(page, (_, _) {});
        await eventually(
          t,
          () => h.container.read(page).detail.value?.entries.length == 3,
          what: 'page loaded',
        );
        final first = h.container.read(page).detail.value!.entries.first.uid;
        h.store.removeGate = Completer<void>();
        unawaited(h.container.read(page.notifier).remove([first]));
        await t.pump();
        expect(h.container.read(page).busy, isTrue);

        await _open(t, h, uid, own: true);
        // Still waiting: no menu, no failure toast.
        expect(find.byType(BottomSheet), findsNothing);
        unawaited(
          h.launch(t, (c) => openPlaylistMenu(c, uid, onOwnPage: true)),
        );
        await _settle(t);
        expect(find.byType(BottomSheet), findsNothing);

        h.store.removeGate!.complete();
        await eventually(
          t,
          () => find.byType(BottomSheet).evaluate().isNotEmpty,
          what: 'menu after the write',
        );
        await _settle(t);
        expect(find.byType(BottomSheet), findsOneWidget);
        // The counts are those after the write.
        expect(find.textContaining('2 songs'), findsOneWidget);
        expect(find.text(l10n.libraryMenuLoadFailed), findsNothing);
        sub.close();
        await t.pump(const Duration(seconds: 2));
      },
    );
  });
}
