import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_menu.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import '../menus/menu_pump.dart';
import 'support/fake_saved_queue_store.dart';
import 'support/saved_queue_harness.dart';

final _saved = DateTime(2026, 11, 21, 21, 17).millisecondsSinceEpoch;

PlaylistDetail _q({
  String uid = 'a',
  List<int> ids = const [1, 2, 3, 4],
  Set<int> missing = const {},
}) => savedQueue(
  uid,
  savedAt: _saved,
  ids: ids,
  missing: missing,
  kind: 'playlist',
  ref: 'pl1',
  label: 'Chạy bộ',
);

class _Favorites implements FavoritesController {
  final List<List<TrackId>> set = [];
  bool fail = false;

  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) async {
    if (fail) throw StateError('no');
    set.add(tracks);
  }

  @override
  Future<void> toggle(TrackId track) async {}
}

/// The list page with the menu of its only queue open.
Future<SavedQueueHarness> _openMenu(
  WidgetTester t, {
  PlaylistDetail? queue,
  FakeSavedQueueStore? store,
  FakePlaybackCommands? playback,
  double width = 400,
  bool onPage = false,
  List<Override> overrides = const [],
}) async {
  final s = store ?? FakeSavedQueueStore([queue ?? _q()]);
  final uid = s.queues.first.summary.uid;
  final h = await pumpSavedQueues(
    t,
    store: s,
    playback: playback,
    width: width,
    start: onPage ? '/playlists/queues/$uid' : '/playlists/queues',
    overrides: overrides,
  );
  await t.tap(byIconButton(l10nOf(t).libraryMenuMore).first);
  await pumpMenu(t);
  return h;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
  });

  group('play', () {
    testWidgets('Play: present songs in order, saved source, moved up, toast', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      final h = await _openMenu(
        t,
        queue: _q(missing: {2}),
        playback: playback,
      );
      await t.tap(find.text(l10nOf(t).savedQueueMenuPlay));
      await settle(t);
      final call = playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((i) => i.value), [1, 3, 4]);
      expect(call.shuffle, isFalse);
      expect(
        call.context,
        const PlayContext(
          PlayContextKind.playlist,
          ref: 'pl1',
          label: 'Chạy bộ',
        ),
      );
      expect(h.store.touched, ['a']);
      expect(find.textContaining('Đang phát hàng đợi'), findsOneWidget);
    });

    testWidgets('Shuffle plays shuffled', (t) async {
      final playback = FakePlaybackCommands();
      await _openMenu(t, playback: playback);
      await t.tap(find.text(l10nOf(t).libraryShuffle));
      await settle(t);
      expect((playback.calls.single as PlayTracksCall).shuffle, isTrue);
    });

    testWidgets('nothing can play by the time it is chosen: toast, no play', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      final store = FakeSavedQueueStore([_q()]);
      await _openMenu(t, store: store, playback: playback);
      // Every song went missing while the menu was open.
      store.set([
        _q(missing: {1, 2, 3, 4}),
      ]);
      await settle(t);
      await t.tap(find.text(l10nOf(t).savedQueueMenuPlay));
      await settle(t);
      expect(find.text(l10nOf(t).libraryNothingToPlay), findsOneWidget);
      expect(playback.calls, isEmpty);
      expect(store.touched, isEmpty);
    });

    testWidgets('the queue is gone by the time it is chosen: toast', (t) async {
      final playback = FakePlaybackCommands();
      final store = FakeSavedQueueStore([_q()]);
      await _openMenu(t, store: store, playback: playback);
      store.set(const []);
      await settle(t);
      await t.tap(find.text(l10nOf(t).savedQueueMenuPlay));
      await settle(t);
      expect(find.text(l10nOf(t).savedQueueNotFoundTitle), findsWidgets);
      expect(playback.calls, isEmpty);
    });
  });

  group('queue and playlists', () {
    testWidgets('Add to the end of the queue enqueues the present songs', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      await _openMenu(
        t,
        queue: _q(missing: {4}),
        playback: playback,
      );
      await t.tap(find.text(l10nOf(t).savedQueueMenuAppend));
      await settle(t);
      final call = playback.calls.single as EnqueueCall;
      expect(call.tracks.map((i) => i.value), [1, 2, 3]);
      expect(find.text(l10nOf(t).libraryMenuQueued), findsOneWidget);
    });

    testWidgets('Save as playlist opens the picker', (t) async {
      await _openMenu(t);
      await t.tap(find.text(l10nOf(t).savedQueueMenuSaveAsPlaylist));
      await settle(t);
      expect(find.text(l10nOf(t).playlistPickerTitle), findsOneWidget);
    });
  });

  group('favorites', () {
    testWidgets('adds each present song once and says how many were new', (
      t,
    ) async {
      final favorites = _Favorites();
      await _openMenu(
        t,
        queue: _q(ids: [1, 2, 2, 3], missing: {3}),
        overrides: [
          favoritesControllerProvider.overrideWithValue(favorites),
          favoriteTrackIdsProvider.overrideWith(
            (ref) => Stream.value({TrackId(1)}),
          ),
        ],
      );
      await t.tap(find.text(l10nOf(t).libraryMenuFavoriteAll));
      await pumpMenu(t);
      expect(favorites.set.single.map((i) => i.value), [1, 2]);
      expect(find.text(l10nOf(t).playlistFavoritedAll(1, 1)), findsOneWidget);
    });

    testWidgets('a failure is a toast', (t) async {
      final favorites = _Favorites()..fail = true;
      await _openMenu(
        t,
        overrides: [
          favoritesControllerProvider.overrideWithValue(favorites),
          favoriteTrackIdsProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      await t.tap(find.text(l10nOf(t).libraryMenuFavoriteAll));
      await pumpMenu(t);
      expect(find.text(l10nOf(t).libraryFavoriteFailed), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('remove missing', () {
    testWidgets('reads what is missing when chosen, not when the menu opened', (
      t,
    ) async {
      final store = FakeSavedQueueStore([
        _q(missing: {1, 2}),
      ]);
      await _openMenu(t, store: store);
      // One of them came back before the tap: the menu said two.
      store.set([
        _q(missing: {1}),
      ]);
      await settle(t);
      await t.tap(find.text(l10nOf(t).savedQueueMenuRemoveMissing));
      await settle(t);
      expect(store.prunedMissing, ['a']);
      expect(find.text(l10nOf(t).savedQueueRemovedMissing(1)), findsOneWidget);
    });

    testWidgets('a failure is a toast', (t) async {
      final store = FakeSavedQueueStore([
        _q(missing: {1}),
      ]);
      await _openMenu(t, store: store);
      store.failWrites = true;
      await t.tap(find.text(l10nOf(t).savedQueueMenuRemoveMissing));
      await settle(t);
      expect(find.text(l10nOf(t).savedQueueRemoveFailed), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('Cancel keeps the queue and the menu closes', (t) async {
      final h = await _openMenu(t);
      await t.tap(find.text(l10nOf(t).savedQueueMenuDelete));
      await settle(t);
      expect(find.text(l10nOf(t).savedQueueDeleteTitle), findsOneWidget);
      expect(find.text(l10nOf(t).savedQueueDeleteBody), findsOneWidget);
      await t.tap(find.text('Huỷ'));
      await settle(t);
      expect(h.store.deleted, isEmpty);
      expect(find.byType(SavedQueueTile), findsOneWidget);
    });

    testWidgets('from the list: deletes and says so', (t) async {
      final h = await _openMenu(t);
      await t.tap(find.text(l10nOf(t).savedQueueMenuDelete));
      await settle(t);
      await t.tap(find.text(l10nOf(t).playlistDeleteConfirm));
      await settle(t);
      expect(h.store.deleted, ['a']);
      expect(find.byType(SavedQueueTile), findsNothing);
      expect(find.text(l10nOf(t).savedQueueDeleted), findsOneWidget);
    });

    testWidgets('on its own page: back to the list first, then delete', (
      t,
    ) async {
      final store = FakeSavedQueueStore([_q()]);
      // Opened from the list so the page has somewhere to pop to.
      final h = await pumpSavedQueues(t, store: store);
      await t.tap(find.byType(SavedQueueTile));
      await settle(t);
      expect(h.location, '/playlists/queues/a');
      String? whereWhenDeleted;
      store.beforeDelete = () => whereWhenDeleted = h.location;
      await t.tap(byIconButton(l10nOf(t).libraryMenuMore).first);
      await pumpMenu(t);
      await t.tap(find.text(l10nOf(t).savedQueueMenuDelete));
      await settle(t);
      await t.tap(find.text(l10nOf(t).playlistDeleteConfirm));
      await settle(t);
      expect(whereWhenDeleted, '/playlists/queues');
      expect(store.deleted, ['a']);
      expect(h.location, '/playlists/queues');
      expect(find.text(l10nOf(t).savedQueueDeleted), findsOneWidget);
      // The page never showed "not found" on its way out.
      expect(find.text(l10nOf(t).savedQueueNotFoundMessage), findsNothing);
    });

    testWidgets('a page opened from outside goes to the list', (t) async {
      final store = FakeSavedQueueStore([_q()]);
      final h = await pumpSavedQueues(
        t,
        store: store,
        start: '/playlists/queues/a',
      );
      await t.tap(byIconButton(l10nOf(t).libraryMenuMore).first);
      await pumpMenu(t);
      await t.tap(find.text(l10nOf(t).savedQueueMenuDelete));
      await settle(t);
      await t.tap(find.text(l10nOf(t).playlistDeleteConfirm));
      await settle(t);
      expect(h.location, '/playlists/queues');
      expect(store.deleted, ['a']);
    });

    testWidgets('a failing delete: toast, queue stays, no crash', (t) async {
      final store = FakeSavedQueueStore([_q()]);
      await _openMenu(t, store: store);
      store.failWrites = true;
      await t.tap(find.text(l10nOf(t).savedQueueMenuDelete));
      await settle(t);
      await t.tap(find.text(l10nOf(t).playlistDeleteConfirm));
      await settle(t);
      expect(find.text(l10nOf(t).savedQueueDeleteFailed), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('menu', () {
    testWidgets('rows in the drawn order on screen', (t) async {
      await _openMenu(t, queue: _q(missing: {4}));
      final l10n = l10nOf(t);
      final titles = [
        l10n.savedQueueMenuPlay,
        l10n.libraryShuffle,
        l10n.savedQueueMenuAppend,
        l10n.savedQueueMenuSaveAsPlaylist,
        l10n.libraryMenuFavoriteAll,
        l10n.historyMenuExportM3u,
        l10n.savedQueueMenuRemoveMissing,
        l10n.savedQueueMenuDelete,
      ];
      final tops = [for (final s in titles) t.getTopLeft(find.text(s)).dy];
      expect([...tops]..sort(), tops);
    });

    testWidgets('desktop: Esc closes the menu', (t) async {
      await _openMenu(t, width: 1400);
      expect(find.text(l10nOf(t).savedQueueMenuPlay), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(t);
      expect(find.text(l10nOf(t).savedQueueMenuPlay), findsNothing);
    });

    testWidgets('a queue that is gone opens no menu', (t) async {
      final store = FakeSavedQueueStore([_q()]);
      await pumpSavedQueues(t, store: store);
      final context = t.element(find.byType(SavedQueueTile));
      store.set(const []);
      await openSavedQueueMenu(context, 'a');
      await settle(t);
      expect(find.text(l10nOf(t).savedQueueMenuPlay), findsNothing);
      expect(find.text(l10nOf(t).libraryNotFoundMessage), findsOneWidget);
    });
  });
}
