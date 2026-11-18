import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/ui/playlists/playlist_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../support/detail_fixture.dart' show headerNodes, inPageHeader;
import 'support/playlist_page_support.dart';
import 'support/playlist_ui_harness.dart'
    show PlaylistUiHarness, canTap, eventually;

const _unknownUid = '01HZZZZZZZZZZZZZZZZZZZZZZZ';

void main() {
  group('back button', () {
    pageTest('mobile: Favorites has Back, which returns to the tab', (t) async {
      final h = await pumpPlaylistPage(t, uid: PlaylistUids.favorites);
      expect(
        FormFactor.of(t.element(find.byType(PlaylistPage))),
        FormFactor.mobile,
      );
      expect(byIconButton('Back'), findsOneWidget);
      await t.tap(byIconButton('Back'));
      await settlePlaylistPage(t);
      expect(find.byType(PlaylistPage), findsNothing);
      expect(h.router.state.uri.path, '/');
    });

    pageTest('desktop: Favorites has no Back in any state', (t) async {
      final h = await pumpPlaylistPage(
        t,
        uid: PlaylistUids.favorites,
        width: 1280,
      );
      expect(
        FormFactor.of(t.element(find.byType(PlaylistPage))),
        FormFactor.desktop,
      );
      expect(byIconButton('Back'), findsNothing);
      await seedFavorites(t, h, ['One']);
      await eventually(
        t,
        () => find.text('One').evaluate().isNotEmpty,
        what: 'the favorite',
      );
      expect(byIconButton('Back'), findsNothing);
    });

    pageTest('desktop: an ordinary playlist keeps Back', (t) async {
      await pumpPlaylistPage(t, uid: _unknownUid, width: 1280);
      expect(byIconButton('Back'), findsOneWidget);
    });

    pageTest('mobile: an ordinary playlist has Back, which returns', (t) async {
      final h = await pumpPlaylistPage(t, uid: _unknownUid);
      expect(byIconButton('Back'), findsOneWidget);
      await t.tap(byIconButton('Back'));
      await settlePlaylistPage(t);
      expect(h.router.state.uri.path, '/');
    });
  });

  group('states', () {
    pageTest('not found: header says so, body says why', (t) async {
      final handle = t.ensureSemantics();
      await pumpPlaylistPage(t, uid: _unknownUid);
      final l10n = pageL10n(t);
      expect(inPageHeader(l10n.libraryNotFoundTitle), findsOneWidget);
      expect(find.text(l10n.playlistNotFoundTitle), findsOneWidget);
      expect(find.text(l10n.playlistNotFoundMessage), findsOneWidget);
      handle.dispose();
    });

    pageTest('loading: an empty header; Favorites on desktop has no Back', (
      t,
    ) async {
      final never = StreamController<PlaylistDetail?>();
      addTearDown(never.close);
      await pumpPlaylistPage(
        t,
        uid: PlaylistUids.favorites,
        width: 1280,
        overrides: [
          playlistDetailProvider(PlaylistUids.favorites)
              .overrideWith((ref) => never.stream),
        ],
      );
      expect(find.byType(PlaylistPage), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PageHeader),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(byIconButton('Back'), findsNothing);
    });

    pageTest('failed: the error line; Back kept on mobile', (t) async {
      await pumpPlaylistPage(
        t,
        uid: _unknownUid,
        overrides: [
          playlistDetailProvider(_unknownUid)
              .overrideWith((ref) => Stream.error(StateError('no'))),
        ],
      );
      expect(find.text(pageL10n(t).libraryLoadFailed), findsOneWidget);
      expect(byIconButton('Back'), findsOneWidget);
    });

    pageTest('failed: Favorites on desktop has no Back', (t) async {
      await pumpPlaylistPage(
        t,
        uid: PlaylistUids.favorites,
        width: 1280,
        overrides: [
          playlistDetailProvider(PlaylistUids.favorites)
              .overrideWith((ref) => Stream.error(StateError('no'))),
        ],
      );
      expect(find.text(pageL10n(t).libraryLoadFailed), findsOneWidget);
      expect(byIconButton('Back'), findsNothing);
    });

    pageTest('an empty playlist: empty state, no bar, no edit toggle', (
      t,
    ) async {
      final h = await pumpPlaylistPage(t, uid: _unknownUid);
      final uid = await seedTracks(t, h, const []);
      h.router.go('/');
      await settlePlaylistPage(t);
      unawaited(h.router.push<void>('/playlists/$uid'));
      await settlePlaylistPage(t);
      final l10n = pageL10n(t);
      expect(find.text(l10n.playlistEmptyTitle), findsOneWidget);
      expect(find.text(l10n.playlistEmptyMessage), findsOneWidget);
      expect(find.byType(KListSortFilterBar), findsNothing);
      expect(byIconButton(l10n.libraryFilter), findsNothing);
      // Hero is there; Play is disabled (nothing to play).
      expect(find.text('Mix'), findsWidgets);
      expect(canTap(t, find.text(l10n.libraryPlay)), isFalse);
    });

    pageTest('Favorites empty: its own empty state', (t) async {
      final handle = t.ensureSemantics();
      await pumpPlaylistPage(t, uid: PlaylistUids.favorites);
      final l10n = pageL10n(t);
      expect(find.text(l10n.playlistFavoritesEmptyTitle), findsOneWidget);
      final spoken = l10n.playlistFavoritesEmptyMessage.replaceFirst(
        KEmpty.iconToken,
        l10n.playlistFavoritesEmptyIconLabel,
      );
      expect(find.bySemanticsLabel(spoken), findsOneWidget);
      expect(find.textContaining(KEmpty.iconToken), findsNothing);
      expect(find.byType(KListSortFilterBar), findsNothing);
      handle.dispose();
    });
  });

  group('header title', () {
    Future<PlaylistUiHarness> manyRows(
      WidgetTester t, {
      double width = 360,
      double? pageWidth,
    }) async {
      final h = await pumpPlaylistPage(
        t,
        uid: _unknownUid,
        width: width,
        pageWidth: pageWidth,
      );
      final uid = await seedTracks(t, h, [
        for (var i = 0; i < 40; i++) 'Song $i',
      ]);
      h.router.go('/');
      await settlePlaylistPage(t);
      unawaited(h.router.push<void>('/playlists/$uid'));
      await settlePlaylistPage(t);
      return h;
    }

    pageTest('mobile: hidden at rest, shown once the name scrolls away', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      await manyRows(t);
      expect(inPageHeader('Mix'), findsNothing);
      expect(headerNodes(t, 'Mix'), 1);
      final list = find.byType(CustomScrollView).last;
      await t.drag(list, const Offset(0, -700));
      await t.pumpAndSettle();
      expect(inPageHeader('Mix'), findsOneWidget);
      await t.drag(list, const Offset(0, 2000));
      await t.pumpAndSettle();
      expect(inPageHeader('Mix'), findsNothing);
      handle.dispose();
    });

    pageTest('a page under 840 inside a 1280 window collapses the same', (
      t,
    ) async {
      await manyRows(t, width: 1280, pageWidth: 700);
      expect(inPageHeader('Mix'), findsNothing);
      await t.drag(find.byType(CustomScrollView).last, const Offset(0, -700));
      await t.pumpAndSettle();
      expect(inPageHeader('Mix'), findsOneWidget);
    });

    pageTest('wide column: the name never moves into the header', (t) async {
      await manyRows(t, width: 1280);
      expect(inPageHeader('Mix'), findsNothing);
      await t.drag(find.byType(CustomScrollView).last, const Offset(0, -900));
      await t.pumpAndSettle();
      expect(inPageHeader('Mix'), findsNothing);
      expect(find.text('Mix'), findsOneWidget);
    });
  });
}
