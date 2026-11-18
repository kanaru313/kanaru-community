import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_labels.dart';
import 'package:kanaru/src/library/ui/playlists/page/playlist_hero.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/library/ui/songs/song_tile_edit.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import 'support/playlist_page_support.dart';
import 'support/playlist_ui_harness.dart'
    show PlaylistUiHarness, canTap, eventually, toggled;
import 'support/reorder_support.dart';

const _titles = ['Alpha', 'Bravo', 'Cello'];

Future<void> _setStored(PlaylistUiHarness h, String uid, SortOrder sort) =>
    h.container.read(playlistTrackSortsProvider.notifier).set(uid, sort);

SortOrder _stored(PlaylistUiHarness h, String uid) =>
    h.container.read(playlistTrackSortProvider(uid));

void main() {
  group('header toggle', () {
    pageTest('an empty playlist has no toggle', (t) async {
      final (_, _) = await openSeededPlaylist(t, const []);
      final l10n = pageL10n(t);
      expect(byAnyIconButton(l10n.plScreensEditList), findsNothing);
    });

    pageTest('[✏] enters ("Done", toggled on); [✓] leaves', (t) async {
      final semantics = t.ensureSemantics();
      await openSeededPlaylist(t, _titles);
      final l10n = pageL10n(t);
      expect(toggled(t, byAnyIconButton(l10n.plScreensEditList)), isFalse);
      String labelOf(String tooltip) =>
          t.getSemantics(byAnyIconButton(tooltip)).getSemanticsData().label;
      expect(labelOf(l10n.plScreensEditList), 'Edit list');
      expect(anyHandle(l10n.playlistDragHandle), findsNothing);

      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(byAnyIconButton(l10n.plScreensEditList), findsNothing);
      expect(toggled(t, byAnyIconButton(l10n.plScreensEditDone)), isTrue);
      expect(labelOf(l10n.plScreensEditDone), 'Done');
      expect(anyHandle(l10n.playlistDragHandle), findsNWidgets(3));

      await t.tap(byAnyIconButton(l10n.plScreensEditDone));
      await settlePlaylistPage(t);
      expect(byAnyIconButton(l10n.plScreensEditDone), findsNothing);
      expect(anyHandle(l10n.playlistDragHandle), findsNothing);
      semantics.dispose();
    });

    pageTest('Esc and Back leave edit mode', (t) async {
      final (h, uid) = await openSeededPlaylist(t, _titles);
      // The page as the only route: a route above the first counts as a
      // modal and silences Esc.
      h.router.go('/playlists/$uid');
      await settlePlaylistPage(t);
      final l10n = pageL10n(t);
      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settlePlaylistPage(t);
      expect(byAnyIconButton(l10n.plScreensEditList), findsOneWidget);

      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(await t.binding.handlePopRoute(), isTrue);
      await settlePlaylistPage(t);
      expect(byAnyIconButton(l10n.plScreensEditList), findsOneWidget);
      // The page itself is still there.
      expect(find.text('Alpha'), findsOneWidget);
    });

    pageTest('another page above ends edit mode', (t) async {
      final (h, _) = await openSeededPlaylist(t, _titles);
      final l10n = pageL10n(t);
      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      unawaited(h.router.push<void>('/playlists/other'));
      await settlePlaylistPage(t);
      h.router.pop();
      await settlePlaylistPage(t);
      expect(byAnyIconButton(l10n.plScreensEditList), findsOneWidget);
    });

    pageTest('removing the last entry leaves edit mode', (t) async {
      final (h, uid) = await openSeededPlaylist(t, ['Alpha']);
      final l10n = pageL10n(t);
      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      await t.runAsync(
        () => h.store.removeEntries(uid, [entryUids(h, uid).single]),
      );
      await eventually(
        t,
        () => (shownDetail(h, uid)?.entries.isEmpty ?? false),
        what: 'the playlist to empty',
      );
      await settlePlaylistPage(t);
      expect(byAnyIconButton(l10n.plScreensEditDone), findsNothing);
      expect(byAnyIconButton(l10n.plScreensEditList), findsNothing);
    });
  });

  group('what edit mode changes', () {
    pageTest('shows playlist order and puts the stored sort back untouched', (
      t,
    ) async {
      final (h, uid) = await openSeededPlaylist(t, ['Cello', 'Alpha', 'Bravo']);
      final l10n = pageL10n(t);
      final byTitleDesc = SortOrder.by(SortCriterion.title, descending: true);
      await t.runAsync(() => _setStored(h, uid, byTitleDesc));
      await settlePlaylistPage(t);
      expect(rowOrder(t, ['Cello', 'Alpha', 'Bravo']), [
        'Cello',
        'Bravo',
        'Alpha',
      ]);

      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(rowOrder(t, ['Cello', 'Alpha', 'Bravo']), [
        'Cello',
        'Alpha',
        'Bravo',
      ]);
      expect(_stored(h, uid), byTitleDesc, reason: 'never written');
      // The bar is the count and the fixed order; no sort, reverse, filter.
      expect(find.text(l10n.plScreensEditBarLead(3)), findsOneWidget);
      expect(find.text(sortOrderLabel(l10n, byTitleDesc)), findsNothing);
      expect(byIconButton(l10n.libraryOrderReverse), findsNothing);
      expect(byIconButton(l10n.libraryFilter), findsNothing);

      await t.tap(byAnyIconButton(l10n.plScreensEditDone));
      await settlePlaylistPage(t);
      expect(rowOrder(t, ['Cello', 'Alpha', 'Bravo']), [
        'Cello',
        'Bravo',
        'Alpha',
      ]);
      expect(_stored(h, uid), byTitleDesc);
      expect(find.text(sortOrderLabel(l10n, byTitleDesc)), findsOneWidget);
    });

    pageTest('the filter is closed and cleared, and comes back as it was', (
      t,
    ) async {
      final (_, _) = await openSeededPlaylist(t, ['Café', 'Rock', 'Jazz']);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryFilter));
      await t.pump();
      await t.enterText(find.byType(TextField), 'caf');
      await t.pump(const Duration(milliseconds: 500));
      await settlePlaylistPage(t);
      expect(find.text('Rock'), findsNothing);

      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Jazz'), findsOneWidget);

      await t.tap(byAnyIconButton(l10n.plScreensEditDone));
      await settlePlaylistPage(t);
      expect(find.byType(TextField), findsOneWidget);
      expect(
        t.widget<TextField>(find.byType(TextField)).controller?.text,
        'caf',
      );
      expect(find.text('Rock'), findsNothing);
      expect(find.text('Café'), findsOneWidget);
    });

    pageTest('a closed filter stays closed after edit mode', (t) async {
      await openSeededPlaylist(t, _titles);
      final l10n = pageL10n(t);
      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      await t.tap(byAnyIconButton(l10n.plScreensEditDone));
      await settlePlaylistPage(t);
      expect(find.byType(TextField), findsNothing);
    });

    pageTest('the missing note is hidden; Play, shuffle and ⋮ are off', (
      t,
    ) async {
      final semantics = t.ensureSemantics();
      final playback = FakePlaybackCommands();
      await openSeededPlaylist(t, [..._titles, 'Gone*'], playback: playback);
      final l10n = pageL10n(t);
      expect(find.text(l10n.playlistUnavailableNote(1)), findsOneWidget);
      final more = find.descendant(
        of: find.byType(Scaffold),
        matching: byIconButton(l10n.libraryMenuMore),
      );
      expect(canTap(t, more.first), isTrue);

      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistUnavailableNote(1)), findsNothing);
      expect(canTap(t, byIconButton(l10n.libraryMenuMore)), isFalse);
      await t.tap(find.text(l10n.libraryPlay), warnIfMissed: false);
      await t.pump();
      expect(playback.calls, isEmpty);

      await t.tap(byAnyIconButton(l10n.plScreensEditDone));
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistUnavailableNote(1)), findsOneWidget);
      semantics.dispose();
    });

    pageTest('rows keep no ♥ / ⋮ and ignore tap and long press; the app '
        'selection is left alone', (t) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await openSeededPlaylist(t, _titles, playback: playback);
      final l10n = pageL10n(t);
      final ids = {
        for (final e in shownDetail(h, uid)!.entries) e.info.title: e.info.id,
      };
      // One song selected before: edit mode leaves it.
      await t.longPress(find.text('Bravo'));
      await t.pump();
      expect(h.container.read(librarySelectionProvider).set, {ids['Bravo']});

      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(byIconButton(l10n.libraryFavoriteAdd), findsNothing);
      final rowMore = find.descendant(
        of: find.byType(SongTile),
        matching: byIconButton(l10n.libraryMenuMore),
      );
      expect(rowMore, findsNothing);
      await t.tap(find.text('Alpha'), buttons: kSecondaryButton);
      await settlePlaylistPage(t);
      expect(find.text(l10n.playlistMenuRemoveEntry), findsNothing);
      await t.tap(find.text('Alpha'));
      await t.longPress(find.text('Cello'));
      await t.pump();
      expect(playback.calls, isEmpty);
      expect(h.container.read(librarySelectionProvider).set, {ids['Bravo']});

      await t.tap(byAnyIconButton(l10n.plScreensEditDone));
      await settlePlaylistPage(t);
      expect(rowMore, findsWidgets);
    });

    pageTest('the hero ⋮ keeps its size in both modes', (t) async {
      await openSeededPlaylist(t, _titles);
      final l10n = pageL10n(t);
      final heroMore = find.descendant(
        of: find.byType(PlaylistHero),
        matching: byIconButton(l10n.libraryMenuMore),
      );
      final before = t.getSize(heroMore);
      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(t.getSize(heroMore), before);
    });

    pageTest('Ctrl+A is ignored while editing and works again after', (
      t,
    ) async {
      final (h, uid) = await openSeededPlaylist(t, _titles);
      h.router.go('/playlists/$uid');
      await settlePlaylistPage(t);
      final l10n = pageL10n(t);
      Future<void> selectAll() async {
        await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await t.sendKeyEvent(LogicalKeyboardKey.keyA);
        await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await t.pump();
      }

      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(h.container.read(activeTrackListProvider), isNull);
      await selectAll();
      expect(h.container.read(librarySelectionProvider).set, isEmpty);

      await t.tap(byAnyIconButton(l10n.plScreensEditDone));
      await settlePlaylistPage(t);
      await selectAll();
      expect(h.container.read(librarySelectionProvider).set, hasLength(3));
    });

    pageTest('toggling remounts no row', (t) async {
      final (h, uid) = await openSeededPlaylist(t, _titles);
      final l10n = pageL10n(t);
      final first = entryUids(h, uid).first;
      final before = t.element(find.byKey(ValueKey(first)));
      final tileBefore = t.state(
        find.descendant(
          of: find.byKey(ValueKey(first)),
          matching: find.byType(SongTileRemovalScope),
        ),
      );
      await t.tap(byAnyIconButton(l10n.plScreensEditList));
      await settlePlaylistPage(t);
      expect(identical(t.element(find.byKey(ValueKey(first))), before), isTrue);
      expect(
        identical(
          t.state(
            find.descendant(
              of: find.byKey(ValueKey(first)),
              matching: find.byType(SongTileRemovalScope),
            ),
          ),
          tileBefore,
        ),
        isTrue,
      );
    });
  });

  group('no handle outside edit mode', () {
    pageTest('none in any sort', (t) async {
      final (h, uid) = await openSeededPlaylist(t, _titles);
      final l10n = pageL10n(t);
      for (final sort in [
        SortOrder.by(SortCriterion.playlistOrder),
        SortOrder.by(SortCriterion.playlistOrder, descending: true),
        SortOrder.by(SortCriterion.title),
        SortOrder.by(SortCriterion.title, descending: true),
      ]) {
        await t.runAsync(() => _setStored(h, uid, sort));
        await settlePlaylistPage(t);
        expect(
          anyHandle(l10n.playlistDragHandle),
          findsNothing,
          reason: '$sort',
        );
      }
    });
  });
}
