import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart'
    show CustomSemanticsAction, SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/ui/browse/play_actions.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_entry_points.dart';
import 'package:kanaru/src/library/ui/playlists/list/playlist_card.dart';
import 'package:kanaru/src/library/ui/playlists/list/playlist_tile.dart';
import 'package:kanaru/src/library/ui/playlists/playlists_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru/src/library/ui/playlists/list/playlists_hub.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../../../support/fake_playback_commands.dart';
import 'support/playlist_page_support.dart' show shownDetail;
import 'support/playlist_ui_harness.dart';
import 'support/playlists_page_support.dart';

const _names = ['Banana', 'Apple', 'Cherry'];

Finder _fabOpen(WidgetTester t) => find.byTooltip(pageL10n(t).playlistFabOpen);

void main() {
  group('sort criteria', () {
    pageTest('"Nâng cao…" adds a second criterion; reverse flips them all', (
      t,
    ) async {
      final h = await pumpPlaylistsPage(t);
      await seedPlaylists(t, h, _names);
      final notifier = h.container.read(libraryListViewsProvider.notifier);
      await notifier.setSort(
        BrowseList.playlists,
        SortOrder.by(
          SortCriterion.dateModified,
          descending: true,
        ).add(SortCriterion.name),
      );
      await settlePage(t);
      SortOrder sort() => h.container
          .read(libraryListViewsProvider)
          .of(BrowseList.playlists)
          .sort;
      final before = sort().specs.map((s) => s.descending).toList();
      expect(before.length, 2);

      await t.tap(byIconButton(pageL10n(t).libraryOrderReverse));
      await settlePage(t);
      expect(sort().specs.map((s) => s.descending).toList(), [
        for (final d in before) !d,
      ]);
    });
  });

  group('card and row menus', () {
    pageTest('card: no ⋮, menu by semantics action, long press, right click', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      final h = await pumpPlaylistsPage(t);
      await seedPlaylists(t, h, ['Banana']);
      final l10n = pageL10n(t);
      final card = find.byType(PlaylistCard);
      expect(byIconButton(l10n.libraryMenuMore), findsNothing);

      // Screen readers: the card's custom action.
      final node = t.getSemantics(find.text('Banana').first);
      final labels = {
        for (final id
            in node.getSemanticsData().customSemanticsActionIds ?? <int>[])
          CustomSemanticsAction.getAction(id)!.label,
      };
      expect(labels, contains(l10n.libraryMenuMore));
      t.semantics.performAction(
        find.semantics.byPredicate((n) => n.id == node.id),
        SemanticsAction.customAction,
        args: CustomSemanticsAction.getIdentifier(
          CustomSemanticsAction(label: l10n.libraryMenuMore),
        ),
      );
      await settlePage(t);
      expect(find.text(l10n.libraryPlay), findsOneWidget);
      await t.tapAt(const Offset(200, 20));
      await settlePage(t);
      expect(find.text(l10n.libraryPlay), findsNothing);

      await t.longPress(card);
      await settlePage(t);
      expect(find.text(l10n.libraryPlay), findsOneWidget);
      await t.tapAt(const Offset(200, 20));
      await settlePage(t);

      final mouse = await t.startGesture(
        t.getCenter(card),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await mouse.up();
      await settlePage(t);
      expect(find.text(l10n.libraryPlay), findsOneWidget);
      handle.dispose();
    });

    pageTest('row: ⋮ and long press open the menu; ▶ is off when empty', (
      t,
    ) async {
      final h = await pumpPlaylistsPage(t);
      await seedPlaylists(t, h, ['Banana']);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryViewList));
      await settlePage(t);
      expect(find.byType(PlaylistTile), findsOneWidget);
      await t.tap(byIconButton(l10n.libraryMenuMore));
      await settlePage(t);
      expect(find.text(l10n.libraryPlay), findsOneWidget);
    });
  });

  group('play', () {
    pageTest('▶ on a row plays the playlist in its saved order', (t) async {
      final playback = FakePlaybackCommands();
      final h = await pumpPlaylistsPage(t, playback: playback);
      final uid = await t.runAsync(() async {
        final tracks = await h.fixture.tracks(3);
        return h.fixture.repo.createPlaylist(name: 'Mix', tracks: tracks);
      });
      await settlePage(t);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryViewList));
      await settlePage(t);
      await t.tap(byIconButton(l10n.plScreensPlay));
      await settlePage(t);
      final call = playback.calls.single as PlayTracksCall;
      expect(call.tracks.length, 3);
      expect(call.context.ref, uid);
    });

    pageTest('▶ of an older request is dropped when a newer one started', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      final h = await pumpPlaylistsPage(t, playback: playback);
      await seedPlaylists(t, h, ['Mix']);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryViewList));
      await settlePage(t);
      final gate = h.store.loadGate = Completer<void>();
      await t.tap(byIconButton(l10n.plScreensPlay));
      await t.pump();
      h.container.read(playRequestsProvider.notifier).begin();
      gate.complete();
      await settlePage(t);
      expect(playback.calls, isEmpty);
    });

    /// Opens the page controller of a 3-song playlist (kept alive by a
    /// listener) and queues a held write on it: removing its first entry.
    Future<(PlaylistUiHarness, FakePlaybackCommands, Completer<void>)> held(
      WidgetTester t,
    ) async {
      final playback = FakePlaybackCommands();
      final h = await pumpPlaylistsPage(t, playback: playback);
      final uid = (await t.runAsync(() async {
        final tracks = await h.fixture.tracks(3);
        return h.fixture.repo.createPlaylist(name: 'Mix', tracks: tracks);
      }))!;
      await settlePage(t);
      final page = playlistPageProvider(uid);
      final sub = h.container.listen(page, (_, _) {});
      addTearDown(sub.close);
      await eventually(
        t,
        () => h.container.read(page).detail.value?.entries.length == 3,
        what: 'page loaded',
      );
      final gate = h.store.removeGate = Completer<void>();
      final first = shownDetail(h, uid)!.entries.first.uid;
      unawaited(
        h.container.read(page.notifier).remove([first]).catchError((_) => null),
      );
      await t.pump();
      await t.tap(byIconButton(pageL10n(t).libraryViewList));
      await settlePage(t);
      return (h, playback, gate);
    }

    pageTest('▶ waits for the open page\'s queued write, then plays the new '
        'order', (t) async {
      final (_, playback, gate) = await held(t);
      await t.tap(byIconButton(pageL10n(t).plScreensPlay));
      await t.pump(const Duration(milliseconds: 200));
      expect(playback.calls, isEmpty);

      gate.complete();
      await eventually(t, () => playback.calls.isNotEmpty, what: 'play');
      expect((playback.calls.single as PlayTracksCall).tracks, hasLength(2));
      await settlePage(t);
    });

    pageTest('▶ gives up on a write that never lands: save-failed toast, '
        'nothing played', (t) async {
      final (_, playback, gate) = await held(t);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.plScreensPlay));
      await t.pump(const Duration(seconds: 6));
      expect(find.text(l10n.playlistSaveFailed), findsOneWidget);
      expect(playback.calls, isEmpty);
      gate.complete();
      await settlePage(t);
      expect(playback.calls, isEmpty);
    });

    pageTest('▶ shows a message when the playlist is gone or fails to load', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      final h = await pumpPlaylistsPage(t, playback: playback);
      await seedPlaylists(t, h, ['Mix']);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryViewList));
      await settlePage(t);

      h.store.loadMissing = true;
      await t.tap(byIconButton(l10n.plScreensPlay));
      await settlePage(t);
      expect(find.text(l10n.libraryNotFoundMessage), findsOneWidget);
      await t.pump(const Duration(seconds: 6));
      await settlePage(t);

      h.store.loadMissing = false;
      h.store.loadError = StateError('disk');
      await t.tap(byIconButton(l10n.plScreensPlay));
      await settlePage(t);
      expect(find.text(l10n.libraryPlayFailed), findsOneWidget);
      expect(playback.calls, isEmpty);
      await t.pump(const Duration(seconds: 6));
      await settlePage(t);
    });

    pageTest('▶ is off for an empty playlist', (t) async {
      final h = await pumpPlaylistsPage(t);
      await t.runAsync(
        () => h.fixture.repo.createPlaylist(name: 'Empty', tracks: const []),
      );
      await settlePage(t);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryViewList));
      await settlePage(t);
      final play = t.widget<KIconButton>(byIconButton(l10n.plScreensPlay));
      expect(play.onPressed, isNull);
    });
  });

  group('hub', () {
    pageTest('first sliver is the import progress slot, with and without '
        'playlists', (t) async {
      final h = await pumpPlaylistsPage(t);
      Widget first() => t
          .widget<CustomScrollView>(find.byType(CustomScrollView).first)
          .slivers
          .first;
      expect(first(), isA<M3uImportProgressSliver>());
      await seedPlaylists(t, h, _names);
      expect(first(), isA<M3uImportProgressSliver>());
    });

    pageTest('Favorites count is live; Stats is dimmed and inert', (t) async {
      final h = await pumpPlaylistsPage(t);
      final l10n = pageL10n(t);
      expect(find.text(l10n.playlistTrackCount(0)), findsOneWidget);
      // The hub shortcut keeps its icon; it is not a playlist cover.
      expect(
        find.descendant(
          of: find.byType(PlaylistsHub),
          matching: find.byIcon(KIcons.favorites),
        ),
        findsOneWidget,
      );
      await t.runAsync(() async {
        final track = await h.fixture.track('fav');
        await h.fixture.repo.addToPlaylists(
          tracks: [track],
          playlistUids: [PlaylistUids.favorites],
        );
      });
      await settlePage(t);
      expect(find.text(l10n.playlistTrackCount(1)), findsOneWidget);

      final stats = find.bySemanticsLabel(RegExp(l10n.playlistHubStats));
      expect(stats, findsWidgets);
      expect(canTap(t, stats.first), isFalse);
      expect(find.text(l10n.appComingSoon), findsWidgets);
    });

    pageTest('tiles follow comingSoon; a live one opens its page', (t) async {
      final h = await pumpPlaylistsPage(
        t,
        registry: hubRegistry(historySoon: false),
      );
      final history = find.bySemanticsLabel('History');
      final queue = find.bySemanticsLabel(RegExp('Queue'));
      expect(canTap(t, history.first), isTrue);
      expect(canTap(t, queue.first), isTrue);
      expect(h.router.state.uri.path, '/playlists');

      await t.tap(find.text('History'));
      await settlePage(t);
      expect(h.router.state.uri.path, '/playlists/history');
    });

    pageTest('the Queue tile is live and opens the saved queues', (t) async {
      final h = await pumpPlaylistsPage(t);
      await t.tap(find.text('Queue'));
      await settlePage(t);
      expect(h.router.state.uri.path, '/playlists/queues');
    });

    pageTest('Favorites tile opens the Favorites page', (t) async {
      final h = await pumpPlaylistsPage(t);
      await t.tap(find.text(pageL10n(t).libraryNavFavorites));
      await settlePage(t);
      expect(h.router.state.uri.path, '/playlists/favorites');
    });
  });

  group('FAB and shortcut', () {
    pageTest('FAB: New playlist opens the create dialog and closes the menu', (
      t,
    ) async {
      await pumpPlaylistsPage(t);
      final l10n = pageL10n(t);
      await t.tap(_fabOpen(t));
      await settlePage(t);
      expect(find.text(l10n.playlistFabImport), findsOneWidget);
      await t.tap(find.text(l10n.playlistFabNew));
      await settlePage(t);
      expect(find.text(l10n.playlistCreateTitle), findsWidgets);
    });

    pageTest('import is tappable and Smart playlist is Pro-locked', (t) async {
      final handle = t.ensureSemantics();
      await pumpPlaylistsPage(t);
      final l10n = pageL10n(t);
      await t.tap(_fabOpen(t));
      await settlePage(t);
      expect(canTap(t, find.text(l10n.playlistFabImport)), isTrue);
      expect(canTap(t, find.text(l10n.playlistFabSmart)), isFalse);
      handle.dispose();
    });

    pageTest('Ctrl+N opens the create dialog; not again while it is open', (
      t,
    ) async {
      await pumpPlaylistsPage(t, width: 1400, asRoot: true);
      final l10n = pageL10n(t);
      await pressCtrlN(t);
      await settlePage(t);
      expect(find.text(l10n.playlistCreateTitle), findsWidgets);
      final dialogs = find.byType(Dialog).evaluate().length;
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyN);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settlePage(t);
      expect(find.byType(Dialog).evaluate().length, dialogs);
    });

    pageTest('Ctrl+N is ignored with a text field focused', (t) async {
      final h = await pumpPlaylistsPage(t, width: 1400, asRoot: true);
      await seedPlaylists(t, h, _names);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryFilter));
      await t.pump();
      await t.showKeyboard(find.byType(TextField));
      await pressCtrlN(t);
      await settlePage(t);
      expect(find.text(l10n.playlistCreateTitle), findsNothing);
    });

    pageTest('Ctrl+N is ignored when the page is not the current route', (
      t,
    ) async {
      final h = await pumpPlaylistsPage(t, width: 1400, asRoot: true);
      final l10n = pageL10n(t);
      h.router.push<void>('/playlists/somewhere');
      await settlePage(t);
      await pressCtrlN(t);
      await settlePage(t);
      expect(find.text(l10n.playlistCreateTitle), findsNothing);
    });

    pageTest('Back closes the FAB menu, then the filter, then leaves', (
      t,
    ) async {
      final h = await pumpPlaylistsPage(t, asRoot: true);
      await seedPlaylists(t, h, _names);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryFilter));
      await t.pump();
      await t.tap(_fabOpen(t));
      await settlePage(t);
      expect(find.text(l10n.playlistFabImport), findsOneWidget);

      expect(await t.binding.handlePopRoute(), isTrue);
      await settlePage(t);
      expect(find.text(l10n.playlistFabImport), findsNothing);
      expect(find.byType(TextField), findsOneWidget);

      expect(await t.binding.handlePopRoute(), isTrue);
      await settlePage(t);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(PlaylistsPage), findsOneWidget);

      // Nothing is left to close: Back goes on to the system.
      expect(await t.binding.handlePopRoute(), isFalse);
      expect(find.byType(PlaylistsPage), findsOneWidget);
    });

    pageTest('the last row ends above the FAB', (t) async {
      final h = await pumpPlaylistsPage(t);
      await seedPlaylists(t, h, [for (var i = 0; i < 12; i++) 'List $i']);
      final l10n = pageL10n(t);
      await t.tap(byIconButton(l10n.libraryViewList));
      await settlePage(t);
      await t.drag(find.byType(CustomScrollView).first, const Offset(0, -6000));
      await settlePage(t);
      final fab = t.getTopLeft(_fabOpen(t)).dy;
      final rows = find.byType(PlaylistTile);
      final bottom = t.getBottomLeft(rows.last).dy;
      expect(bottom, lessThanOrEqualTo(fab));
    });
  });
}
