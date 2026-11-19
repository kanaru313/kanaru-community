import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_labels.dart';
import 'package:kanaru/src/library/ui/playlists/list/playlist_card.dart';
import 'package:kanaru/src/library/ui/playlists/list/playlist_tile.dart';
import 'package:kanaru/src/library/ui/playlists/playlists_page.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../../../support/memory_settings_store.dart';
import 'support/playlists_page_support.dart';

const _names = ['Banana', 'Apple', 'Cherry'];

SortOrder _sortOf(ProviderContainer c) =>
    c.read(libraryListViewsProvider).of(BrowseList.playlists).sort;

void main() {
  group('layout and sort', () {
    pageTest('grid by default; the switch persists to a new container', (
      t,
    ) async {
      final settings = MemorySettingsStore();
      final h = await pumpPlaylistsPage(t, settings: settings);
      await seedPlaylists(t, h, _names);
      final l10n = pageL10n(t);
      expect(find.byType(PlaylistCard), findsNWidgets(3));
      expect(find.byType(PlaylistTile), findsNothing);

      await t.tap(byIconButton(l10n.libraryViewList));
      await settlePage(t);
      expect(find.byType(PlaylistTile), findsNWidgets(3));
      expect(find.byType(PlaylistCard), findsNothing);

      // A fresh container over the same store remembers the layout.
      final h2 = await pumpPlaylistsPage(t, settings: settings);
      await seedPlaylists(t, h2, _names);
      expect(
        h2.container
            .read(libraryListViewsProvider)
            .of(BrowseList.playlists)
            .view,
        CollectionView.list,
      );
      expect(find.byType(PlaylistTile), findsNWidgets(3));
    });

    pageTest('sort: modified desc by default, name pick keeps the direction, '
        'reverse flips it, all persisted', (t) async {
      final settings = MemorySettingsStore();
      final h = await pumpPlaylistsPage(t, settings: settings);
      await seedPlaylists(t, h, _names);
      final l10n = pageL10n(t);
      expect(onScreenOrder(t, _names), [
        'Cherry',
        'Apple',
        'Banana',
      ], reason: 'newest edit first');

      final chip = find.text(sortOrderLabel(l10n, _sortOf(h.container)));
      await t.tap(chip);
      await settlePage(t);
      await t.tap(find.text(sortCriterionLabel(l10n, SortCriterion.name)).last);
      await settlePage(t);
      expect(_sortOf(h.container).primary.criterion, SortCriterion.name);
      expect(_sortOf(h.container).primary.descending, isTrue);
      expect(onScreenOrder(t, _names), ['Cherry', 'Banana', 'Apple']);

      await t.tap(byIconButton(l10n.libraryOrderReverse));
      await settlePage(t);
      expect(onScreenOrder(t, _names), ['Apple', 'Banana', 'Cherry']);

      final h2 = await pumpPlaylistsPage(t, settings: settings);
      expect(_sortOf(h2.container).primary.criterion, SortCriterion.name);
      expect(_sortOf(h2.container).primary.descending, isFalse);
    });

    pageTest('"Nâng cao…" opens the sort box; leaving the page closes it', (
      t,
    ) async {
      final h = await pumpPlaylistsPage(t);
      await seedPlaylists(t, h, _names);
      final l10n = pageL10n(t);
      await t.tap(find.text(sortOrderLabel(l10n, _sortOf(h.container))));
      await settlePage(t);
      await t.tap(find.text(l10n.librarySortAdvanced));
      await settlePage(t);
      expect(find.text(l10n.librarySortDialogTitle), findsWidgets);

      h.router.go('/');
      await settlePage(t);
      expect(find.text(l10n.librarySortDialogTitle), findsNothing);
      expect(find.byType(PlaylistsPage), findsNothing);
    });
  });

  group('filter', () {
    pageTest('folds diacritics, counts, shows no-match, Back closes it first', (
      t,
    ) async {
      final h = await pumpPlaylistsPage(t);
      await seedPlaylists(t, h, ['Café', 'Rock', 'Jazz']);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryFilter));
      await t.pump();
      await t.enterText(find.byType(TextField), 'cafe');
      // The text reaches the list only after typing pauses.
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Rock'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 400));
      await settlePage(t);
      expect(find.text('Café'), findsOneWidget);
      expect(find.text('Rock'), findsNothing);
      expect(find.text('1 / 3 ${l10n.plScreensUnitPlaylists}'), findsOneWidget);

      await t.enterText(find.byType(TextField), 'zzz');
      await t.pump(const Duration(milliseconds: 400));
      await settlePage(t);
      expect(find.text(l10n.playlistFilterNoMatch), findsOneWidget);

      // Back closes the field and keeps the page; the list is whole again.
      expect(await t.binding.handlePopRoute(), isTrue);
      await settlePage(t);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(PlaylistsPage), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);

      // A second Back leaves the page.
      expect(await t.binding.handlePopRoute(), isTrue);
      await settlePage(t);
      expect(find.byType(PlaylistsPage), findsNothing);
    });
  });

  group('empty and loading', () {
    pageTest('no playlist: empty state with both actions, no bar', (t) async {
      final h = await pumpPlaylistsPage(t);
      final l10n = pageL10n(t);
      expect(find.text(l10n.playlistsEmptyTitle), findsOneWidget);
      expect(find.text(l10n.playlistsEmptyMessage), findsOneWidget);
      expect(find.text(l10n.playlistCreateAction), findsOneWidget);
      // M3U import works where a document picker exists: its button is live.
      final import = find.widgetWithText(
        OutlinedButton,
        l10n.playlistImportM3uAction,
      );
      expect(t.widget<OutlinedButton>(import).onPressed, isNotNull);
      expect(find.byTooltip(l10n.libraryFilter), findsNothing);
      expect(byIconButton(l10n.libraryFilter), findsNothing);
      expect(h.store.createCalls, 0);

      await t.tap(find.text(l10n.playlistCreateAction));
      await settlePage(t);
      expect(find.text(l10n.playlistCreateTitle), findsWidgets);
    });

    pageTest('the hub stays on mobile when there is no playlist', (t) async {
      await pumpPlaylistsPage(t);
      final l10n = pageL10n(t);
      expect(find.text(l10n.libraryNavFavorites), findsOneWidget);
      expect(find.text(l10n.playlistYours), findsNothing);
    });
  });

  group('form factors', () {
    pageTest('desktop: no hub, grid cards at 160 dp min', (t) async {
      final h = await pumpPlaylistsPage(t, width: 1400);
      await seedPlaylists(t, h, _names);
      final l10n = pageL10n(t);
      expect(find.text(l10n.playlistHubStats), findsNothing);
      expect(find.text(l10n.playlistYours), findsNothing);
      expect(find.byType(PlaylistCard), findsNWidgets(3));
      expect(
        t.getSize(find.byType(PlaylistCard).first).width,
        greaterThan(160),
      );
    });

    pageTest('200 % text: grid and rows lay out without overflow', (t) async {
      final h = await pumpPlaylistsPage(t, textScale: 2);
      await seedPlaylists(t, h, _names);
      expect(t.takeException(), isNull);
      await t.tap(byIconButton(pageL10n(t).libraryViewList));
      await settlePage(t);
      expect(find.byType(PlaylistTile), findsWidgets);
      expect(t.takeException(), isNull);
    });

    pageTest('animations off: page and FAB still work', (t) async {
      final h = await pumpPlaylistsPage(t, disableAnimations: true);
      await seedPlaylists(t, h, _names);
      final l10n = pageL10n(t);
      await t.tap(find.byTooltip(l10n.playlistFabOpen));
      await t.pump();
      expect(find.text(l10n.playlistFabNew), findsOneWidget);
      await t.tap(find.text(l10n.playlistFabNew));
      await settlePage(t);
      expect(find.text(l10n.playlistCreateTitle), findsWidgets);
      expect(t.takeException(), isNull);
    });
  });
}
