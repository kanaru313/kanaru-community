import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/state/playlists/playlist_page_controller.dart';
import 'package:kanaru/src/library/state/playlists/playlist_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/play_actions.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import 'support/playlist_page_support.dart';
import 'support/playlist_ui_harness.dart'
    show PlaylistUiHarness, canTap, eventually;

const _longDescription =
    'Một danh sách rất dài các bài hát cho những buổi chiều mưa, gồm nhạc '
    'không lời, nhạc acoustic và những bản thu cũ mà tôi nghe đi nghe lại '
    'nhiều năm nay. Dòng thứ hai nói thêm về cách sắp xếp, dòng thứ ba nói '
    'về những bài được thêm gần đây và dòng thứ tư là lời cảm ơn.';

/// Opens playlist [uid] over the host route again (a fresh page).
Future<void> _reopen(WidgetTester t, PlaylistUiHarness h, String uid) async {
  h.router.go('/');
  await settlePlaylistPage(t);
  unawaited(h.router.push<void>('/playlists/$uid'));
  await settlePlaylistPage(t);
}

/// Pumps the page for a playlist seeded with [titles].
Future<(PlaylistUiHarness, String)> _open(
  WidgetTester t,
  List<String> titles, {
  double width = 360,
  double textScale = 1,
  double? pageWidth,
  String name = 'Mix',
  String description = '',
  FakePlaybackCommands? playback,
}) async {
  final h = await pumpPlaylistPage(
    t,
    uid: 'x',
    width: width,
    textScale: textScale,
    pageWidth: pageWidth,
    playback: playback,
  );
  final uid = await seedTracks(
    t,
    h,
    titles,
    name: name,
    description: description,
  );
  await _reopen(t, h, uid);
  return (h, uid);
}

void main() {
  group('hero content', () {
    pageTest('name, counts and no description line when it is empty', (
      t,
    ) async {
      await _open(t, ['A', 'B']);
      final l10n = pageL10n(t);
      expect(find.text('Mix'), findsWidgets);
      expect(find.textContaining('2 songs'), findsWidgets);
      expect(find.text(l10n.libraryShowMore), findsNothing);
    });

    pageTest('Favorites: heart line under the counts, no description', (
      t,
    ) async {
      final h = await pumpPlaylistPage(t, uid: PlaylistUids.favorites);
      await seedFavorites(t, h, ['One']);
      await eventually(
        t,
        () => find.text('One').evaluate().isNotEmpty,
        what: 'the favorite',
      );
      final l10n = pageL10n(t);
      expect(find.text(l10n.playlistFavoritesName), findsWidgets);
      expect(find.text(l10n.playlistFavoritesSubtitle), findsOneWidget);
    });

    pageTest('description sits under the row; Show more survives leaving', (
      t,
    ) async {
      final (h, uid) = await _open(t, ['A'], description: _longDescription);
      final l10n = pageL10n(t);
      expect(find.textContaining('Một danh sách'), findsOneWidget);
      expect(find.text(l10n.libraryShowMore), findsOneWidget);
      await t.tap(find.text(l10n.libraryShowMore));
      await t.pumpAndSettle();
      expect(find.text(l10n.libraryShowLess), findsOneWidget);

      await _reopen(t, h, uid);
      expect(find.text(l10n.libraryShowLess), findsOneWidget);
      expect(find.text(l10n.libraryShowMore), findsNothing);
    });

    pageTest('200 % text with long Vietnamese text does not overflow', (
      t,
    ) async {
      await _open(
        t,
        ['A'],
        textScale: 2,
        name: 'Những bản tình ca bất hủ của nhiều thế hệ nghe nhạc Việt Nam',
        description: _longDescription,
      );
      expect(t.takeException(), isNull);
      expect(find.text(pageL10n(t).libraryShowMore), findsOneWidget);
    });
  });

  group('counts', () {
    pageTest('repeats count once; missing songs count; an optimistic removal '
        'shows at once', (t) async {
      final h = await pumpPlaylistPage(t, uid: 'x');
      final uid = (await t.runAsync(() async {
        final a = await h.fixture.track('Alpha');
        final b = await h.fixture.track('Bravo');
        final m = await h.fixture.track('Gone', status: TrackStatus.missing);
        return h.fixture.repo.createPlaylist(name: 'Rep', tracks: [a, b, a, m]);
      }))!;
      await _reopen(t, h, uid);
      final l10n = pageL10n(t);
      expect(find.textContaining(l10n.librarySongCount(3)), findsWidgets);

      final gate = Completer<void>();
      h.store.removeGate = gate;
      final gone = shownDetail(h, uid)!.entries.last;
      unawaited(
        h.container
            .read(playlistPageProvider(uid).notifier)
            .remove([gone.uid])
            .catchError((_) => null),
      );
      await t.pump();
      await t.pump();
      expect(find.textContaining(l10n.librarySongCount(2)), findsWidgets);
      expect(find.textContaining(l10n.librarySongCount(3)), findsNothing);
      gate.complete();
      await settlePlaylistPage(t);
    });

    pageTest('an all-missing playlist shows its count, not "empty"', (t) async {
      await _open(t, ['A*', 'B*']);
      final l10n = pageL10n(t);
      expect(find.textContaining(l10n.librarySongCount(2)), findsWidgets);
      expect(find.text(l10n.playlistTrackCount(0)), findsNothing);
    });
  });

  group('layout', () {
    pageTest('a wide page puts the hero in a 320 column, name on 2 lines', (
      t,
    ) async {
      await _open(
        t,
        ['A'],
        width: 1280,
        name:
            'Những bản tình ca bất hủ của nhiều thế hệ nghe nhạc Việt Nam '
            'được yêu thích nhất mọi thời đại và mọi miền',
      );
      expect(t.getSize(find.byType(KDetailHero)).width, 320);
      final title = t.widget<Text>(find.textContaining('Những bản'));
      expect(title.maxLines, 2);
      expect(t.takeException(), isNull);
    });

    pageTest('a page under 840 in a 1280 window uses the narrow hero', (
      t,
    ) async {
      await _open(t, ['A'], width: 1280, pageWidth: 700);
      expect(t.getSize(find.byType(KDetailHero)).width, 700);
    });
  });

  group('play', () {
    pageTest('plays the available entries in the page sort, never the missing '
        'ones', (t) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await _open(t, [
        'Bravo',
        'Missing*',
        'Alpha',
        'Charlie',
      ], playback: playback);
      await h.container
          .read(playlistTrackSortsProvider.notifier)
          .set(uid, SortOrder.by(SortCriterion.title));
      await t.pump();
      final detail = shownDetail(h, uid)!;
      final idOf = {for (final e in detail.entries) e.info.title: e.info.id};
      await t.tap(find.text(pageL10n(t).libraryPlay));
      await eventuallyCalls(t, playback, 1);
      final call = playback.calls.single as PlayTracksCall;
      expect(call.tracks, [idOf['Alpha'], idOf['Bravo'], idOf['Charlie']]);
      expect(call.shuffle, isFalse);
      expect(call.context.kind, PlayContextKind.playlist);
      expect(call.context.ref, uid);
      expect(call.context.label, 'Mix');
    });

    pageTest('shuffle plays shuffled', (t) async {
      final playback = FakePlaybackCommands();
      await _open(t, ['A', 'B'], playback: playback);
      await t.tap(find.byTooltip(pageL10n(t).libraryShuffle));
      await eventuallyCalls(t, playback, 1);
      expect((playback.calls.single as PlayTracksCall).shuffle, isTrue);
    });

    pageTest('disabled when every entry is missing', (t) async {
      await _open(t, ['A*', 'B*']);
      final l10n = pageL10n(t);
      expect(canTap(t, find.text(l10n.libraryPlay)), isFalse);
      expect(canTap(t, find.byTooltip(l10n.libraryShuffle)), isFalse);
    });

    pageTest('waits for queued writes; a double press begins one request', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await _open(t, ['A', 'B', 'C'], playback: playback);
      final gate = Completer<void>();
      h.store.removeGate = gate;
      final controller = h.container.read(playlistPageProvider(uid).notifier);
      final first = shownDetail(h, uid)!.entries.first;
      unawaited(controller.remove([first.uid]).catchError((_) => null));
      await t.pump();
      final before = h.container.read(playRequestsProvider);
      final play = find.text(pageL10n(t).libraryPlay);
      // Both presses land before the page rebuilds: only the guard stops
      // the second one.
      await t.tap(play);
      await t.tap(play, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(h.container.read(playRequestsProvider), before + 1);
      expect(playback.calls, isEmpty);

      gate.complete();
      await eventuallyCalls(t, playback, 1);
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      expect(playback.calls, hasLength(1));
      expect(playback.calls.single.tracks, hasLength(2));
      expect(
        playback.calls.single.tracks,
        isNot(contains(first.info.id)),
        reason: 'plays what the page shows after the write',
      );
    });

    pageTest('a resize across 840 keeps a waiting play and its guard', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await _open(
        t,
        ['A', 'B'],
        width: 1280,
        playback: playback,
      );
      final gate = Completer<void>();
      h.store.removeGate = gate;
      final controller = h.container.read(playlistPageProvider(uid).notifier);
      unawaited(
        controller
            .remove([shownDetail(h, uid)!.entries.first.uid])
            .catchError((_) => null),
      );
      await t.pump();
      final l10n = pageL10n(t);
      await t.tap(find.text(l10n.libraryPlay));
      await t.pump();
      t.view.physicalSize = const Size(700, 800);
      await t.pump();
      await t.pump();
      expect(canTap(t, find.text(l10n.libraryPlay)), isFalse);
      gate.complete();
      await eventuallyCalls(t, playback, 1);
      expect(playback.calls, hasLength(1));
    });

    pageTest('a newer play request wins over a waiting one', (t) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await _open(t, ['A', 'B'], playback: playback);
      final gate = Completer<void>();
      h.store.removeGate = gate;
      final controller = h.container.read(playlistPageProvider(uid).notifier);
      unawaited(
        controller
            .remove([shownDetail(h, uid)!.entries.first.uid])
            .catchError((_) => null),
      );
      await t.pump();
      await t.tap(find.text(pageL10n(t).libraryPlay));
      await t.pump();
      h.container.read(playRequestsProvider.notifier).begin();
      gate.complete();
      await settlePlaylistPage(t);
      expect(playback.calls, isEmpty);
    });

    pageTest('a write that never ends: toast after 5 s, nothing plays', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await _open(t, ['A', 'B'], playback: playback);
      final gate = Completer<void>();
      h.store.removeGate = gate;
      final controller = h.container.read(playlistPageProvider(uid).notifier);
      unawaited(
        controller
            .remove([shownDetail(h, uid)!.entries.first.uid])
            .catchError((_) => null),
      );
      await t.pump();
      final l10n = pageL10n(t);
      await t.tap(find.text(l10n.libraryPlay));
      await t.pump(const Duration(seconds: 4));
      expect(find.text(l10n.playlistSaveFailed), findsNothing);
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text(l10n.playlistSaveFailed), findsOneWidget);
      expect(playback.calls, isEmpty);
      gate.complete();
      await settlePlaylistPage(t);
      expect(playback.calls, isEmpty);
    });

    pageTest('leaving the page while waiting plays nothing', (t) async {
      final playback = FakePlaybackCommands();
      final (h, uid) = await _open(t, ['A', 'B'], playback: playback);
      final gate = Completer<void>();
      h.store.removeGate = gate;
      final controller = h.container.read(playlistPageProvider(uid).notifier);
      unawaited(
        controller
            .remove([shownDetail(h, uid)!.entries.first.uid])
            .catchError((_) => null),
      );
      await t.pump();
      await t.tap(find.text(pageL10n(t).libraryPlay));
      await t.pump();
      // A kept-alive controller (the removal toast holds one) still has its
      // detail: only the page's own check stops the play.
      final keep = h.container.listen(playlistPageProvider(uid), (_, _) {});
      addTearDown(keep.close);
      h.router.go('/');
      await settlePlaylistPage(t);
      gate.complete();
      await settlePlaylistPage(t);
      expect(playback.calls, isEmpty);
    });
  });
}

/// Waits (real time) until [playback] holds [count] calls.
Future<void> eventuallyCalls(
  WidgetTester t,
  FakePlaybackCommands playback,
  int count,
) => eventually(
  t,
  () => playback.calls.length >= count,
  what: '$count play calls',
);
