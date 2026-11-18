import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/state/playlists/playlist_prefs_providers.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/playlists/page/playlist_entry_menu.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'support/playlist_menu_support.dart';
import 'support/playlist_page_support.dart';
import 'support/playlist_ui_harness.dart' show PlaylistUiHarness, canTap;
import 'support/reorder_support.dart';

const _all = ['Alpha', 'Bravo', 'Cello'];

List<MenuItemSpec> _group({
  bool favorites = false,
  bool canStep = true,
  bool first = false,
  bool last = false,
}) => playlistEntryMenuGroup(
  enL10n,
  isFavorites: favorites,
  canStep: canStep,
  isFirst: first,
  isLast: last,
  onStep: (_) {},
  onRemove: (_) async {},
);

/// Opens the song menu of [title] with its ⋮.
Future<void> _openMenu(WidgetTester t, String title) async {
  final more = find.descendant(
    of: tileOf(title),
    matching: byIconButton(pageL10n(t).libraryMenuMore),
  );
  await t.tap(more);
  await settlePlaylistPage(t);
}

void main() {
  group('the group', () {
    test('Up, Down and the removal; the ends are disabled', () {
      final mid = _group();
      expect(mid.map((r) => r.id), [
        MenuItemId.playlistMoveUp,
        MenuItemId.playlistMoveDown,
        MenuItemId.playlistRemove,
      ]);
      expect(mid.every((r) => r.enabled), isTrue);
      expect(_group(first: true).first.enabled, isFalse);
      expect(_group(first: true)[1].enabled, isTrue);
      expect(_group(last: true)[1].enabled, isFalse);
      expect(_group(last: true).first.enabled, isTrue);
    });

    test('no stepping rows when the order is not the playlist order', () {
      expect(_group(canStep: false).map((r) => r.id), [
        MenuItemId.playlistRemove,
      ]);
    });

    test('Favorites word the removal as "Remove from Favorites"', () {
      final remove = _group(favorites: true).last;
      expect(remove.title, enL10n.playlistMenuRemoveFavorite);
      expect(_group().last.title, enL10n.playlistMenuRemoveEntry);
    });
  });

  group('on the page', () {
    pageTest('Move up / Move down reorder the playlist, ends disabled', (
      t,
    ) async {
      final semantics = t.ensureSemantics();
      final (h, uid) = await openSeededPlaylist(t, _all);
      final l10n = pageL10n(t);
      await _openMenu(t, 'Alpha');
      expect(canTap(t, find.text(l10n.playlistMenuMoveUp)), isFalse);
      expect(canTap(t, find.text(l10n.playlistMenuMoveDown)), isTrue);
      await t.tapAt(const Offset(2, 2));
      await settlePlaylistPage(t);
      await _openMenu(t, 'Cello');
      expect(canTap(t, find.text(l10n.playlistMenuMoveUp)), isTrue);
      expect(canTap(t, find.text(l10n.playlistMenuMoveDown)), isFalse);
      await t.tapAt(const Offset(2, 2));
      await settlePlaylistPage(t);
      await _openMenu(t, 'Bravo');
      expect(find.text(l10n.playlistMenuMoveUp), findsOneWidget);
      expect(find.text(l10n.playlistMenuMoveDown), findsOneWidget);
      expect(find.text(l10n.playlistMenuRemoveEntry), findsOneWidget);
      await t.tap(find.text(l10n.playlistMenuMoveUp));
      await settlePlaylistPage(t);
      await expectStoredOrder(t, h, uid, ['Bravo', 'Alpha', 'Cello']);
      expect(rowOrder(t, _all), ['Bravo', 'Alpha', 'Cello']);

      // Bravo is now the first row: Up has nothing to do.
      await _openMenu(t, 'Bravo');
      await t.tap(find.text(l10n.playlistMenuMoveUp), warnIfMissed: false);
      await settlePlaylistPage(t);
      await expectStoredOrder(t, h, uid, ['Bravo', 'Alpha', 'Cello']);
      semantics.dispose();
    });

    pageTest('the add-to-playlist picker from a row leaves the open playlist '
        'out', (t) async {
      final (h, _) = await openSeededPlaylist(t, _all, name: 'Mix');
      await t.runAsync(
        () => h.fixture.repo.createPlaylist(name: 'Other', tracks: const []),
      );
      final l10n = pageL10n(t);
      await _openMenu(t, 'Alpha');
      await t.tap(find.text(l10n.libraryMenuAddToPlaylist));
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistPickerTitle), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
      // Only the page's own title: the picker has no "Mix" row.
      expect(find.text('Mix'), findsOneWidget);
    });

    pageTest('a menu opened before another move acts on the row where the '
        'entry is now', (t) async {
      final (h, uid) = await openSeededPlaylist(t, _all);
      final l10n = pageL10n(t);
      await _openMenu(t, 'Bravo');
      final entries = {
        for (final e in shownDetail(h, uid)!.entries) e.info.title: e.uid,
      };
      // Alpha goes behind Bravo while the menu is open: Bravo is first.
      await t.runAsync(
        () => h.store.moveEntry(
          uid,
          entries['Alpha']!,
          afterEntryUid: entries['Bravo'],
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.text(l10n.playlistMenuMoveDown));
      await settlePlaylistPage(t);
      // Down from first: behind Alpha, so Alpha, Bravo, Cello.
      await expectStoredOrder(t, h, uid, ['Alpha', 'Bravo', 'Cello']);
    });

    pageTest('an entry gone when the row is chosen: nothing happens', (
      t,
    ) async {
      final (h, uid) = await openSeededPlaylist(t, _all);
      final l10n = pageL10n(t);
      await _openMenu(t, 'Bravo');
      final bravo = shownDetail(
        h,
        uid,
      )!.entries.singleWhere((e) => e.info.title == 'Bravo').uid;
      await t.runAsync(() => h.store.removeEntries(uid, [bravo]));
      await eventuallyGone(t, h, uid, 'Bravo');
      await t.tap(find.text(l10n.playlistMenuMoveUp));
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistSaveFailed), findsNothing);
      await expectStoredOrder(t, h, uid, ['Alpha', 'Cello']);
    });

    pageTest('Remove takes the entry out', (t) async {
      final (h, uid) = await openSeededPlaylist(t, _all);
      final l10n = pageL10n(t);
      await _openMenu(t, 'Bravo');
      await t.tap(find.text(l10n.playlistMenuRemoveEntry));
      await settlePlaylistPage(t);
      expect(find.text('Bravo'), findsNothing);
      expect(find.text(l10n.playlistRemovedEntry('Bravo')), findsOneWidget);
      await expectStoredOrder(t, h, uid, ['Alpha', 'Cello']);
    });

    pageTest('another sort leaves only the removal', (t) async {
      final (h, uid) = await openSeededPlaylist(t, _all);
      final l10n = pageL10n(t);
      await t.runAsync(
        () => h.container
            .read(playlistTrackSortsProvider.notifier)
            .set(uid, SortOrder.by(SortCriterion.title, descending: true)),
      );
      await settlePlaylistPage(t);
      await _openMenu(t, 'Bravo');
      expect(find.text(l10n.playlistMenuMoveUp), findsNothing);
      expect(find.text(l10n.playlistMenuMoveDown), findsNothing);
      expect(find.text(l10n.playlistMenuRemoveEntry), findsOneWidget);
    });

    pageTest('a filter leaves only the removal', (t) async {
      await openSeededPlaylist(t, _all);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryFilter));
      await t.pump();
      await t.enterText(find.byType(TextField), 'ra');
      await t.pump(const Duration(milliseconds: 500));
      await settlePlaylistPage(t);
      await _openMenu(t, 'Bravo');
      expect(find.text(l10n.playlistMenuMoveUp), findsNothing);
      expect(find.text(l10n.playlistMenuRemoveEntry), findsOneWidget);
    });

    pageTest('the last row cannot go down', (t) async {
      final (h, uid) = await openSeededPlaylist(t, _all);
      final l10n = pageL10n(t);
      await _openMenu(t, 'Cello');
      await t.tap(find.text(l10n.playlistMenuMoveDown), warnIfMissed: false);
      await settlePlaylistPage(t);
      await expectStoredOrder(t, h, uid, _all);
    });

    pageTest('Favorites: no heart row, "Remove from Favorites" removes', (
      t,
    ) async {
      final h = await pumpPlaylistPage(t, uid: PlaylistUids.favorites);
      await seedFavorites(t, h, _all);
      await settlePlaylistPage(t);
      final l10n = pageL10n(t);
      await _openMenu(t, 'Bravo');
      expect(find.text(l10n.libraryFavoriteRemove), findsNothing);
      expect(find.text(l10n.libraryFavoriteAdd), findsNothing);
      expect(find.text(l10n.playlistMenuRemoveFavorite), findsOneWidget);
      await t.tap(find.text(l10n.playlistMenuRemoveFavorite));
      await settlePlaylistPage(t);
      expect(find.text('Bravo'), findsNothing);
      expect(find.text(l10n.playlistRemovedFavorite('Bravo')), findsOneWidget);
    });

    pageTest('a missing row opens a menu with only the removal', (t) async {
      final (h, uid) = await openSeededPlaylist(t, ['Alpha', 'Gone*']);
      final l10n = pageL10n(t);
      await t.tap(find.text('Gone'), buttons: kSecondaryButton);
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistMenuRemoveEntry), findsOneWidget);
      expect(find.textContaining(l10n.playlistNotInLibrary), findsWidgets);
      expect(find.text(l10n.playlistMenuMoveUp), findsNothing);
      expect(find.text(l10n.libraryFavoriteAdd), findsNothing);
      expect(find.text(l10n.libraryMenuSelect), findsNothing);
      await t.tap(find.text(l10n.playlistMenuRemoveEntry));
      await settlePlaylistPage(t);
      expect(find.text('Gone'), findsNothing);
      await expectStoredOrder(t, h, uid, ['Alpha']);
    });
  });
}

Future<void> eventuallyGone(
  WidgetTester t,
  PlaylistUiHarness h,
  String uid,
  String title,
) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (shownDetail(h, uid)!.entries.any((e) => e.info.title == title)) {
    if (DateTime.now().isAfter(end)) fail('$title never left the page');
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await t.pump(const Duration(milliseconds: 16));
  }
}
