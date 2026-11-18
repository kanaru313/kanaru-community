import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_labels.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import 'support/playlist_page_support.dart';
import 'support/playlist_ui_harness.dart'
    show PlaylistUiHarness, eventually, eventuallyLive, tapUndo;

const _titles = ['Cello', 'Alpha', 'Bravo'];

Future<(PlaylistUiHarness, String)> _open(
  WidgetTester t,
  List<String> titles, {
  FakePlaybackCommands? playback,
  String name = 'Mix',
}) async {
  final h = await pumpPlaylistPage(t, uid: 'x', playback: playback);
  final uid = await seedTracks(t, h, titles, name: name);
  await _go(t, h, uid);
  return (h, uid);
}

Future<void> _go(WidgetTester t, PlaylistUiHarness h, String uid) async {
  h.router.go('/');
  await settlePlaylistPage(t);
  unawaited(h.router.push<void>('/playlists/$uid'));
  await settlePlaylistPage(t);
}

SortOrder _sortOf(PlaylistUiHarness h, String uid) =>
    h.container.read(playlistTrackSortProvider(uid));

void main() {
  group('sort', () {
    pageTest('the dropdown picks a criterion and the page remembers it per '
        'playlist', (t) async {
      final (h, uid) = await _open(t, _titles);
      final l10n = pageL10n(t);
      expect(rowOrder(t, _titles), _titles, reason: 'playlist order first');

      await t.tap(find.text(sortOrderLabel(l10n, _sortOf(h, uid))));
      await settlePlaylistPage(t);
      await t.tap(find.text(sortCriterionLabel(l10n, SortCriterion.title)));
      await settlePlaylistPage(t);
      expect(_sortOf(h, uid).primary.criterion, SortCriterion.title);
      expect(rowOrder(t, _titles), ['Alpha', 'Bravo', 'Cello']);

      final other = await seedTracks(t, h, ['Zed'], name: 'Other');
      expect(_sortOf(h, other).primary.criterion, SortCriterion.playlistOrder);
    });

    pageTest('"Advanced…" opens the sort box and leaving the page closes it', (
      t,
    ) async {
      final (h, uid) = await _open(t, _titles);
      final l10n = pageL10n(t);
      await t.tap(find.text(sortOrderLabel(l10n, _sortOf(h, uid))));
      await settlePlaylistPage(t);
      await t.tap(find.text(l10n.librarySortAdvanced));
      await settlePlaylistPage(t);
      expect(find.text(l10n.librarySortDialogTitle), findsWidgets);

      h.router.go('/');
      await settlePlaylistPage(t);
      expect(find.text(l10n.librarySortDialogTitle), findsNothing);
    });

    pageTest('reverse flips the order; two taps in one frame flip twice', (
      t,
    ) async {
      final (h, uid) = await _open(t, _titles);
      final l10n = pageL10n(t);
      final reverse = byIconButton(l10n.libraryOrderReverse);
      await t.tap(reverse);
      await settlePlaylistPage(t);
      expect(rowOrder(t, _titles), _titles.reversed.toList());

      await t.tap(reverse);
      await t.tap(reverse);
      await settlePlaylistPage(t);
      expect(rowOrder(t, _titles), _titles.reversed.toList());
      expect(_sortOf(h, uid).primary.descending, isTrue);
    });
  });

  group('rows', () {
    pageTest('tap plays the list from that row; long press selects; ♥ and ⋮ '
        'are there; no drag handle', (t) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await _open(t, [
        ..._titles,
        'Gone*',
      ], playback: playback);
      final l10n = pageL10n(t);
      final ids = {
        for (final e in shownDetail(h, uid)!.entries) e.info.title: e.info.id,
      };
      expect(byIconButton(l10n.libraryFavoriteAdd), findsWidgets);
      expect(byIconButton(l10n.libraryMenuMore), findsWidgets);
      expect(find.byTooltip(l10n.playlistDragHandle), findsNothing);

      await t.tap(find.text('Alpha'));
      await eventually(
        t,
        () => playback.calls.isNotEmpty,
        what: 'the row tap to play',
      );
      final call = playback.calls.single as PlayTracksCall;
      expect(call.tracks, [ids['Cello'], ids['Alpha'], ids['Bravo']]);
      expect(call.startIndex, 1);

      await t.longPress(find.text('Bravo'));
      await t.pump();
      expect(h.container.read(librarySelectionProvider).set, {ids['Bravo']});
    });

    pageTest('Ctrl+A selects the playable shown tracks, never a missing one; '
        'leaving clears the claim', (t) async {
      final (h, uid) = await _open(t, [..._titles, 'Gone*']);
      // The page as the only route: a route above the first counts as a
      // modal and silences the shortcut.
      h.router.go('/playlists/$uid');
      await settlePlaylistPage(t);
      final ids = {
        for (final e in shownDetail(h, uid)!.entries) e.info.title: e.info.id,
      };
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyA);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      expect(h.container.read(librarySelectionProvider).set, {
        ids['Cello'],
        ids['Alpha'],
        ids['Bravo'],
      });
      expect(h.container.read(activeTrackListProvider), isNotNull);

      h.router.go('/');
      await settlePlaylistPage(t);
      expect(h.container.read(activeTrackListProvider), isNull);
    });

    pageTest('the Ctrl+A claim survives a resize across 840 both ways', (
      t,
    ) async {
      final (h, uid) = await _open(t, [..._titles, 'Gone*']);
      h.router.go('/playlists/$uid');
      t.view.physicalSize = const Size(1280, 800);
      await settlePlaylistPage(t);
      Future<void> expectClaim() async {
        await t.pump();
        await t.pump();
        expect(h.container.read(activeTrackListProvider), hasLength(3));
        await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await t.sendKeyEvent(LogicalKeyboardKey.keyA);
        await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await t.pump();
        expect(h.container.read(librarySelectionProvider).ids, hasLength(3));
        h.container.read(librarySelectionProvider.notifier).clear();
      }

      await expectClaim();
      t.view.physicalSize = const Size(700, 800);
      await settlePlaylistPage(t);
      await expectClaim();
      t.view.physicalSize = const Size(1280, 800);
      await settlePlaylistPage(t);
      await expectClaim();
    });

    pageTest('only the first row of a repeated track counts as current', (
      t,
    ) async {
      final h = await pumpPlaylistPage(t, uid: 'x');
      final uid = (await t.runAsync(() async {
        final a = await h.fixture.track('Alpha');
        final b = await h.fixture.track('Bravo');
        return h.fixture.repo.createPlaylist(name: 'Rep', tracks: [a, b, a]);
      }))!;
      await _go(t, h, uid);
      final tiles = t.widgetList<SongTile>(find.byType(SongTile)).toList();
      expect([for (final s in tiles) s.markCurrent], [true, true, false]);
      expect(tiles.every((s) => s.ids.length == 3), isTrue);
    });
    pageTest('with a selection the last row ends above the selection panel', (
      t,
    ) async {
      final h = await pumpPlaylistPage(t, uid: 'x', width: 1280);
      final uid = await seedTracks(t, h, [
        for (var i = 0; i < 30; i++) 'Song ${i.toString().padLeft(2, '0')}',
      ]);
      await _go(t, h, uid);
      await t.longPress(find.text('Song 00'));
      await t.pump();
      final list = find.byType(CustomScrollView).last;
      await t.drag(list, const Offset(0, -5000));
      await t.pumpAndSettle();
      final bottom = t.getBottomLeft(list).dy;
      final last = t.getBottomLeft(find.text('Song 29')).dy;
      expect(bottom - last, greaterThan(60));
    });
  });

  group('missing songs', () {
    pageTest('the note and "Remove N" with undo', (t) async {
      final (h, uid) = await _open(t, ['Alpha', 'Gone1*', 'Gone2*']);
      final l10n = pageL10n(t);
      expect(find.text(l10n.playlistUnavailableNote(2)), findsOneWidget);
      expect(find.text('Gone1'), findsOneWidget);

      await t.tap(find.text(l10n.playlistRemoveUnavailableAction(2)));
      await settlePlaylistPage(t);
      expect(find.text('Gone1'), findsNothing);
      expect(find.text(l10n.playlistUnavailableNote(2)), findsNothing);
      expect(find.text(l10n.playlistRemovedUnavailable(2)), findsOneWidget);

      await tapUndo(t, l10n);
      await eventuallyLive(
        t,
        h,
        uid,
        (tracks) => tracks.length == 3,
        what: 'the undo',
      );
      await settlePlaylistPage(t);
      expect(find.text('Gone1'), findsOneWidget);
      expect(find.text(l10n.playlistUnavailableNote(2)), findsOneWidget);
    });

    pageTest('the ✕ of a missing row removes only that row', (t) async {
      final (h, uid) = await _open(t, ['Alpha', 'Gone1*', 'Gone2*']);
      final l10n = pageL10n(t);
      final x = find.descendant(
        of: find.ancestor(
          of: find.text('Gone1'),
          matching: find.byType(SongTile),
        ),
        matching: byIconButton(l10n.playlistMenuRemoveEntry),
      );
      await t.tap(x);
      await settlePlaylistPage(t);
      expect(find.text('Gone1'), findsNothing);
      expect(find.text('Gone2'), findsOneWidget);
      expect(find.text(l10n.playlistRemovedEntry('Gone1')), findsOneWidget);
      await eventuallyLive(t, h, uid, (tracks) => tracks.length == 2);
    });

    pageTest('a burst of failing writes says so once; the cancelled ones '
        'stay silent', (t) async {
      final (h, _) = await _open(t, ['Alpha', 'Gone1*', 'Gone2*', 'Gone3*']);
      final l10n = pageL10n(t);
      final failures = <String>[];
      Logger.root.level = Level.ALL;
      final sub = Logger.root.onRecord.listen((r) {
        if (r.message == 'A playlist removal failed') failures.add(r.message);
      });
      addTearDown(sub.cancel);
      final gate = Completer<void>();
      h.store.removeGate = gate;
      h.store.removeError = StateError('disk');
      Finder crossOf(String title) => find.descendant(
        of: find.ancestor(
          of: find.text(title),
          matching: find.byType(SongTile),
        ),
        matching: byIconButton(l10n.playlistMenuRemoveEntry),
      );
      await t.tap(crossOf('Gone1'));
      await t.pump();
      await t.tap(crossOf('Gone2'));
      await t.pump();
      await t.tap(crossOf('Gone3'));
      await t.pump();
      gate.complete();
      await settlePlaylistPage(t);
      expect(failures, hasLength(1));
      expect(find.text(l10n.playlistSaveFailed), findsOneWidget);
    });
  });

  group('filter', () {
    pageTest('narrows rows, counts, plays the filtered list from the tapped '
        'row, and is gone after leaving', (t) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await _open(t, [
        'Café one',
        'Rock',
        'Cafe two',
      ], playback: playback);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryFilter));
      await t.pump();
      await t.enterText(find.byType(TextField), 'cafe');
      await t.pump(const Duration(milliseconds: 500));
      await settlePlaylistPage(t);
      expect(find.text('Rock'), findsNothing);
      expect(find.text('2 / 3 ${l10n.libraryUnitSongs}'), findsOneWidget);

      await t.tap(find.text('Cafe two'));
      await eventually(t, () => playback.calls.isNotEmpty, what: 'play');
      final call = playback.calls.single as PlayTracksCall;
      expect(call.tracks, hasLength(2));
      expect(call.startIndex, 1);

      await t.enterText(find.byType(TextField), 'zzz');
      await t.pump(const Duration(milliseconds: 500));
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistFilterSongsNoMatch), findsOneWidget);

      // Back closes the field first and keeps the page.
      expect(await t.binding.handlePopRoute(), isTrue);
      await settlePlaylistPage(t);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Rock'), findsOneWidget);

      await t.tap(byIconButton(l10n.libraryFilter));
      await t.pump();
      await t.enterText(find.byType(TextField), 'rock');
      await t.pump(const Duration(milliseconds: 500));
      await _go(t, h, uid);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Cello'), findsNothing);
      expect(find.text('Café one'), findsOneWidget);
    });
  });

  group('filter count', () {
    pageTest('counts distinct songs on both sides of "x / N"', (t) async {
      final h = await pumpPlaylistPage(t, uid: 'x');
      final uid = (await t.runAsync(() async {
        final a = await h.fixture.track('Alpha');
        final b = await h.fixture.track('Bravo');
        return h.fixture.repo.createPlaylist(name: 'Rep', tracks: [a, b, a]);
      }))!;
      await _go(t, h, uid);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryFilter));
      await t.pump();
      await t.enterText(find.byType(TextField), 'alpha');
      await t.pump(const Duration(milliseconds: 500));
      await settlePlaylistPage(t);
      expect(find.text('1 / 2 ${l10n.libraryUnitSongs}'), findsOneWidget);
    });
  });

  group('Favorites', () {
    pageTest('a ♥ toggled elsewhere updates the open page live', (t) async {
      final h = await pumpPlaylistPage(t, uid: PlaylistUids.favorites);
      final tracks = (await t.runAsync(
        () async => [
          await h.fixture.track('Alpha'),
          await h.fixture.track('Bravo'),
        ],
      ))!;
      final favorites = h.container.read(favoritesControllerProvider);
      await t.runAsync(() => favorites.toggle(tracks[0]));
      await eventually(
        t,
        () => find.text('Alpha').evaluate().isNotEmpty,
        what: 'the new favorite',
      );
      await t.runAsync(() => favorites.toggle(tracks[1]));
      await eventually(
        t,
        () => find.text('Bravo').evaluate().isNotEmpty,
        what: 'the second favorite',
      );
      await t.runAsync(() => favorites.toggle(tracks[0]));
      await eventually(
        t,
        () => find.text('Alpha').evaluate().isEmpty,
        what: 'the removed favorite',
      );
      expect(find.text('Bravo'), findsOneWidget);
    });
  });
}
