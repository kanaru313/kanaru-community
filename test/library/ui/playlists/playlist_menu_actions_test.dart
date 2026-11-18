import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';
import 'package:kanaru/src/database/database.dart' show TrackStatus;
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/playlists/menu/favorites_menu_spec.dart';
import 'package:kanaru/src/library/ui/playlists/menu/playlist_menu_actions.dart';
import 'package:kanaru/src/library/ui/playlists/menu/playlist_menu_spec.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:material_ui/material_ui.dart';

import 'support/playlist_menu_support.dart';
import 'support/playlist_ui_harness.dart';

typedef _Seed = ({String uid, List<TrackId> tracks});

/// A playlist [name] with [songs] songs; [repeatFirst] adds the first song
/// again, [missing] adds songs whose file is gone.
Future<_Seed> _seed(
  WidgetTester t,
  PlaylistUiHarness h,
  String name, {
  int songs = 3,
  bool repeatFirst = false,
  int missing = 0,
}) async {
  final tracks = (await t.runAsync(
    () async => [
      for (var i = 0; i < songs; i++) await h.fixture.track('$name-$i'),
      for (var i = 0; i < missing; i++)
        await h.fixture.track('$name-gone$i', status: TrackStatus.missing),
    ],
  ))!;
  final all = [...tracks, if (repeatFirst) tracks.first];
  final uid = (await t.runAsync(
    () => h.fixture.repo.createPlaylist(name: name, tracks: all),
  ))!;
  return (uid: uid, tracks: tracks);
}

Future<PlaylistDetail> _detail(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid,
) async => (await t.runAsync(() => h.fixture.repo.loadPlaylist(uid)))!;

Future<void> _toast(WidgetTester t, String text) => eventually(
  t,
  () => find.text(text).evaluate().isNotEmpty,
  what: 'toast "$text"',
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('favoriteAllOf', () {
    uiTest('says how many were added and how many were already there', (
      t,
    ) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      await t.runAsync(
        () => h.fixture.repo.addToPlaylists(
          tracks: [src.tracks.first],
          playlistUids: [PlaylistUids.favorites],
        ),
      );
      unawaited(h.launch(t, (c) => favoriteAllOf(c, src.uid)));
      await _toast(t, l10n.playlistFavoritedAll(2, 1));
      expect(
        await t.runAsync(() => h.fixture.liveTracks(PlaylistUids.favorites)),
        hasLength(3),
      );
    });

    uiTest('a playlist deleted meanwhile: not-found toast, nothing written', (
      t,
    ) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      await t.runAsync(() => h.fixture.repo.deletePlaylist(src.uid));
      unawaited(h.launch(t, (c) => favoriteAllOf(c, src.uid)));
      await _toast(t, l10n.libraryNotFoundMessage);
      expect(
        await t.runAsync(() => h.fixture.liveTracks(PlaylistUids.favorites)),
        isEmpty,
      );
    });

    uiTest('a write failure toasts', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      h.store.addAllError = StateError('locked');
      unawaited(h.launch(t, (c) => favoriteAllOf(c, src.uid)));
      await _toast(t, l10n.playlistSaveFailed);
    });
  });

  group('saveFavoritesAsPlaylist', () {
    uiTest('copies Favorites at once and names the copy', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', songs: 2);
      await t.runAsync(
        () => h.fixture.repo.addToPlaylists(
          tracks: src.tracks,
          playlistUids: [PlaylistUids.favorites],
        ),
      );
      unawaited(
        h.launch(
          t,
          (c) => saveFavoritesAsPlaylist(
            c,
            PlaylistUids.favorites,
            'Favorites (1/2)',
          ),
        ),
      );
      await _toast(t, l10n.playlistDuplicated('Favorites (1/2)'));
      final copy = (await storedPlaylists(
        t,
        h,
      )).singleWhere((p) => p.name == 'Favorites (1/2)');
      expect(
        await t.runAsync(() => h.fixture.liveTracks(copy.uid)),
        src.tracks.map((e) => e.value).toList(),
      );
    });

    uiTest('a failure toasts and creates nothing', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      h.store.duplicateError = StateError('locked');
      unawaited(
        h.launch(
          t,
          (c) => saveFavoritesAsPlaylist(c, PlaylistUids.favorites, 'Copy'),
        ),
      );
      await _toast(t, l10n.playlistSaveFailed);
      expect(await storedPlaylists(t, h), isEmpty);
    });

    uiTest('a source that is gone says so', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      unawaited(
        h.launch(t, (c) => saveFavoritesAsPlaylist(c, 'no-such-uid', 'Copy')),
      );
      await _toast(t, l10n.libraryNotFoundMessage);
      expect(await storedPlaylists(t, h), isEmpty);
    });
  });

  group('removing entries', () {
    uiTest('duplicates: first of each stays, toast counts, Undo restores', (
      t,
    ) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', repeatFirst: true);
      final before = await t.runAsync(() => h.fixture.liveTracks(src.uid));
      unawaited(h.launch(t, (c) => removeDuplicateEntries(c, src.uid)));
      await _toast(t, l10n.playlistRemovedDuplicates(1));
      await eventuallyLive(t, h, src.uid, (x) => x.length == 3);

      await tapUndo(t, l10n);
      final after = await eventuallyLive(t, h, src.uid, (x) => x.length == 4);
      expect(after, before);
    });

    uiTest('missing songs: only the entries captured at open go', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', missing: 1);
      final detail = await _detail(t, h, src.uid);
      final captured = [
        for (final e in detail.entries)
          if (!e.available) e.uid,
      ];
      expect(captured, hasLength(1));
      // A scan marks another song missing after the menu opened.
      await t.runAsync(
        () => h.fixture.db.customStatement(
          'UPDATE tracks SET status = ?, missing_since = ? WHERE id = ?',
          [TrackStatus.missing, 1, src.tracks.first.value],
        ),
      );
      unawaited(h.launch(t, (c) => removeMissingEntries(c, src.uid, captured)));
      await _toast(t, l10n.playlistRemovedUnavailable(1));
      final live = await eventuallyLive(t, h, src.uid, (x) => x.length == 3);
      expect(live, contains(src.tracks.first.value));
    });

    uiTest('missing songs with the page open: captured entries only', (
      t,
    ) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', missing: 1);
      final page = playlistPageProvider(src.uid);
      final sub = h.container.listen(page, (_, _) {});
      await eventually(
        t,
        () => h.container.read(page).detail.value?.entries.length == 4,
        what: 'page loaded',
      );
      final captured = [
        for (final e in h.container.read(page).detail.value!.entries)
          if (!e.available) e.uid,
      ];
      expect(captured, hasLength(1));
      // A scan marks another song missing after the menu opened.
      await t.runAsync(
        () => h.fixture.db.customStatement(
          'UPDATE tracks SET status = ?, missing_since = ? WHERE id = ?',
          [TrackStatus.missing, 1, src.tracks.first.value],
        ),
      );
      unawaited(h.launch(t, (c) => removeMissingEntries(c, src.uid, captured)));
      await _toast(t, l10n.playlistRemovedUnavailable(1));
      final live = await eventuallyLive(t, h, src.uid, (x) => x.length == 3);
      expect(live, contains(src.tracks.first.value));
      sub.close();
      await t.pump(const Duration(seconds: 2));
    });

    uiTest('page open, nothing left to remove: quiet, store not asked', (
      t,
    ) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      final page = playlistPageProvider(src.uid);
      final sub = h.container.listen(page, (_, _) {});
      await eventually(
        t,
        () => h.container.read(page).detail.value?.entries.length == 3,
        what: 'page loaded',
      );
      // Captured uids the page no longer shows, and no duplicates.
      h.store.removeError = StateError('must not be called');
      await h.launch(
        t,
        (c) => removeMissingEntries(c, src.uid, ['gone-entry']),
      );
      await h.launch(t, (c) => removeDuplicateEntries(c, src.uid));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text(l10n.playlistSaveFailed), findsNothing);
      sub.close();
      await t.pump(const Duration(seconds: 2));
    });

    uiTest('page open, the store fails to remove: a real failure toasts', (
      t,
    ) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', missing: 1);
      final page = playlistPageProvider(src.uid);
      final sub = h.container.listen(page, (_, _) {});
      await eventually(
        t,
        () => h.container.read(page).detail.value?.entries.length == 4,
        what: 'page loaded',
      );
      final captured = [
        for (final e in h.container.read(page).detail.value!.entries)
          if (!e.available) e.uid,
      ];
      h.store.removeNothing = true;
      unawaited(h.launch(t, (c) => removeMissingEntries(c, src.uid, captured)));
      await _toast(t, l10n.playlistSaveFailed);
      sub.close();
      await t.pump(const Duration(seconds: 2));
    });

    uiTest('a playlist deleted meanwhile: not-found toast', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', repeatFirst: true);
      await t.runAsync(() => h.fixture.repo.deletePlaylist(src.uid));
      unawaited(h.launch(t, (c) => removeDuplicateEntries(c, src.uid)));
      await _toast(t, l10n.libraryNotFoundMessage);
    });

    uiTest('nothing left to remove stays quiet', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      await h.launch(t, (c) => removeDuplicateEntries(c, src.uid));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text(l10n.playlistRemovedDuplicates(0)), findsNothing);
      expect(find.text(l10n.libraryNotFoundMessage), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    uiTest('a write failure toasts and leaves the playlist alone', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', missing: 1);
      final detail = await _detail(t, h, src.uid);
      final captured = [
        for (final e in detail.entries)
          if (!e.available) e.uid,
      ];
      h.store.removeError = StateError('locked');
      unawaited(h.launch(t, (c) => removeMissingEntries(c, src.uid, captured)));
      await _toast(t, l10n.playlistSaveFailed);
      expect(
        await t.runAsync(() => h.fixture.liveTracks(src.uid)),
        hasLength(4),
      );
    });

    uiTest('with the page open the removal waits for the write before it', (
      t,
    ) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      // [a, b, b]: removing the first entry is held back by the store.
      final src = await _seed(t, h, 'Src', songs: 2);
      await t.runAsync(
        () => h.fixture.repo.addToPlaylists(
          tracks: [src.tracks.last],
          playlistUids: [src.uid],
          policy: DuplicatePolicy.addAll,
        ),
      );
      final page = playlistPageProvider(src.uid);
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

      unawaited(h.launch(t, (c) => removeDuplicateEntries(c, src.uid)));
      await t.pump(const Duration(milliseconds: 100));
      // Queued behind the held write: nothing else is written yet.
      expect(
        await t.runAsync(() => h.fixture.liveTracks(src.uid)),
        hasLength(3),
      );
      h.store.removeGate!.complete();
      await eventuallyLive(
        t,
        h,
        src.uid,
        (x) => x.length == 1 && x.single == src.tracks.last.value,
        what: 'both removals',
      );
      await _toast(t, l10n.playlistRemovedDuplicates(1));
      sub.close();
      await t.pump(const Duration(seconds: 2));
    });

    uiTest('a write cancelled behind a failing one stays silent: one '
        'save-failed toast in all', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', songs: 2, missing: 2);
      final missing = (await _detail(
        t,
        h,
        src.uid,
      )).entries.where((e) => !e.available).map((e) => e.uid).toList();
      final page = playlistPageProvider(src.uid);
      final sub = h.container.listen(page, (_, _) {});
      await eventually(
        t,
        () => h.container.read(page).detail.value?.entries.length == 4,
        what: 'page loaded',
      );
      // Each failure that is not silent logs once (a snackbar of the same text
      // would hide a second toast).
      final failures = <LogRecord>[];
      final logSub = Logger.root.onRecord.listen((r) {
        if (r.message.startsWith('Removing entries of')) failures.add(r);
      });
      addTearDown(logSub.cancel);
      final gate = h.store.removeGate = Completer<void>();
      h.store.removeError = StateError('disk');
      unawaited(
        h.launch(t, (c) => removeMissingEntries(c, src.uid, [missing.first])),
      );
      await t.pump(const Duration(milliseconds: 100));
      // Queued behind the held (and soon failing) write: cancelled with it.
      unawaited(
        h.launch(t, (c) => removeMissingEntries(c, src.uid, [missing.last])),
      );
      await t.pump(const Duration(milliseconds: 100));
      gate.complete();
      await _toast(t, l10n.playlistSaveFailed);
      await t.pump(const Duration(seconds: 1));
      expect(find.text(l10n.playlistSaveFailed), findsOneWidget);
      expect(failures, hasLength(1));
      sub.close();
      await t.pump(const Duration(seconds: 2));
    });
  });

  group('rows that open a flow', () {
    Future<MenuSpec> specOf(
      WidgetTester t,
      PlaylistUiHarness h,
      String uid,
    ) async => buildPlaylistMenu(
      await _detail(t, h, uid),
      menuEnv(),
      onOwnPage: false,
      desktop: false,
    );

    Future<void> runRow(
      WidgetTester t,
      PlaylistUiHarness h,
      MenuSpec spec,
      MenuItemId id,
    ) => h.launch(t, (c) => (rowOf(spec, id).action! as RunAction).run(c));

    uiTest('Duplicate opens the dialog with the name of the copy', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      final spec = await specOf(t, h, src.uid);
      unawaited(runRow(t, h, spec, MenuItemId.playlistDuplicate));
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        l10n.playlistCopyName('Src'),
      );
    });

    uiTest('Edit opens the dialog with the playlist', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final src = await _seed(t, h, 'Src');
      final spec = await specOf(t, h, src.uid);
      unawaited(runRow(t, h, spec, MenuItemId.playlistEdit));
      await t.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Src'), findsOneWidget);
    });

    uiTest('Delete asks first and deletes nothing yet', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      final spec = await specOf(t, h, src.uid);
      unawaited(runRow(t, h, spec, MenuItemId.playlistDelete));
      await t.pumpAndSettle();
      expect(find.text(l10n.playlistDeleteTitle('Src')), findsOneWidget);
      expect(await storedPlaylists(t, h), hasLength(1));
      await t.tap(find.text('Cancel'));
    });

    uiTest('both M3U rows call the export entry point', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      final spec = await specOf(t, h, src.uid);
      await runRow(t, h, spec, MenuItemId.playlistExportM3u);
      await t.pump();
      expect(find.text(l10n.appComingSoon), findsOneWidget);
      await t.pump(const Duration(seconds: 6));
      await runRow(t, h, spec, MenuItemId.playlistExportM3uRelative);
      await t.pump();
      expect(find.text(l10n.appComingSoon), findsOneWidget);
    });

    uiTest('the head cover button is still soft and Add to playlist opens the '
        'picker without this playlist', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src');
      await t.runAsync(
        () => h.fixture.repo.createPlaylist(name: 'Other', tracks: const []),
      );
      final spec = await specOf(t, h, src.uid);
      final cover = spec.header.action!.action as RunAction;
      await h.launch(t, (c) => cover.run(c));
      await t.pump();
      expect(find.text(l10n.appComingSoon), findsOneWidget);
      await t.pump(const Duration(seconds: 6));

      unawaited(runRow(t, h, spec, MenuItemId.playlist));
      for (var i = 0; i < 40; i++) {
        if (find.text(l10n.playlistPickerTitle).evaluate().isNotEmpty) break;
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(l10n.playlistPickerTitle), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      expect(find.text('Src'), findsNothing);
    });

    uiTest('Favorites: Remove all asks, Save as copies at once', (t) async {
      final h = await PlaylistUiHarness.pump(t);
      final l10n = h.l10n(t);
      final src = await _seed(t, h, 'Src', songs: 2);
      await t.runAsync(
        () => h.fixture.repo.addToPlaylists(
          tracks: src.tracks,
          playlistUids: [PlaylistUids.favorites],
        ),
      );
      final spec = buildFavoritesMenu(
        await _detail(t, h, PlaylistUids.favorites),
        menuEnv(),
        onOwnPage: false,
        desktop: false,
        today: DateTime(2026, 11, 18),
      );
      unawaited(runRow(t, h, spec, MenuItemId.playlistClearFavorites));
      await t.pumpAndSettle();
      expect(find.text(l10n.playlistClearFavoritesTitle), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      unawaited(runRow(t, h, spec, MenuItemId.playlistSaveAs));
      await _toast(
        t,
        l10n.playlistDuplicated(
          rowOf(spec, MenuItemId.playlistSaveAs).subtitle!,
        ),
      );
    });
  });
}
