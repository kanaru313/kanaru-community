import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_hero.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import 'support/fake_saved_queue_store.dart';
import 'support/saved_queue_harness.dart';

final _saved = DateTime(2026, 11, 21, 21, 17).millisecondsSinceEpoch;

PlaylistDetail _q({
  String uid = 'a',
  List<int> ids = const [1, 2, 3, 4, 5],
  Set<int> missing = const {},
  String? kind = 'album',
  String? label = 'm-tp M-TP',
}) => savedQueue(
  uid,
  savedAt: _saved,
  ids: ids,
  missing: missing,
  kind: kind,
  label: label,
);

Future<SavedQueueHarness> _pump(
  WidgetTester t,
  PlaylistDetail queue, {
  FakePlaybackCommands? playback,
  FakeSavedQueueStore? store,
  double width = 400,
  double textScale = 1,
  bool animations = true,
  Brightness brightness = Brightness.light,
}) => pumpSavedQueues(
  t,
  store: store ?? FakeSavedQueueStore([queue]),
  start: '/playlists/queues/${queue.summary.uid}',
  playback: playback,
  width: width,
  textScale: textScale,
  animations: animations,
  brightness: brightness,
);

FilledButton _play(WidgetTester t) => t.widget<FilledButton>(
  find.descendant(
    of: find.byType(SavedQueueHero),
    matching: find.byType(FilledButton),
  ),
);

IconButton _shuffle(WidgetTester t) => t.widget<IconButton>(
  find.descendant(
    of: find.byType(SavedQueueHero),
    matching: find.byType(IconButton),
  ),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
  });

  group('hero', () {
    testWidgets('name, songs and length, source', (t) async {
      await _pump(t, _q(ids: List.generate(24, (i) => i + 1)));
      final name = find.text('Hôm nay · 21:17');
      // The name is in the hero; the header shows it only once scrolled out.
      expect(name, findsOneWidget);
      expect(find.text('24 bài · 24 phút'), findsOneWidget);
      expect(find.text('Từ album m-tp M-TP'), findsOneWidget);
    });

    testWidgets('no source: no "From" line', (t) async {
      await _pump(t, _q(kind: null));
      expect(find.textContaining('Từ '), findsNothing);
    });

    testWidgets('a queue from a playlist says so; a plain queue says nothing', (
      t,
    ) async {
      await _pump(t, _q(kind: 'playlist', label: 'Chạy bộ'));
      expect(find.text('Từ playlist Chạy bộ'), findsOneWidget);
    });

    testWidgets('a long source at 200 % text does not overflow', (t) async {
      await _pump(
        t,
        textScale: 2,
        _q(
          kind: 'playlist',
          label: 'Những bài hát cho chuyến xe đêm từ Sài Gòn ra Vũng Tàu cuối tuần',
        ),
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('wide page: the hero is the left column', (t) async {
      await _pump(t, _q(), width: 1400);
      expect(t.takeException(), isNull);
      expect(find.byType(SavedQueueHero), findsOneWidget);
      expect(find.text('Từ album m-tp M-TP'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('the bar counts the songs and says the order', (t) async {
      await _pump(t, _q());
      expect(find.text(l10nOf(t).savedQueueBar(5)), findsOneWidget);
      expect(find.byType(SongTile), findsNWidgets(5));
    });

    testWidgets('songs that are gone are dimmed, answer a tap and have no ✕', (
      t,
    ) async {
      final playback = FakePlaybackCommands();
      await _pump(t, _q(missing: {2, 3}), playback: playback);
      final l10n = l10nOf(t);
      expect(find.text(l10n.playlistNotInLibrary), findsNWidgets(2));
      expect(byIconButton(l10n.playlistMenuRemoveEntry), findsNothing);
      await t.tap(find.text('Song 2'));
      await settle(t);
      expect(find.text(l10n.historyMissingTap), findsOneWidget);
      expect(playback.calls, isEmpty);
    });

    testWidgets('a tap starts the playable songs from that one', (t) async {
      final playback = FakePlaybackCommands();
      await _pump(
        t,
        _q(kind: 'genre', label: 'Indie', ids: [1, 2, 3, 4, 5], missing: {3}),
        playback: playback,
      );
      await t.tap(find.text('Song 4'));
      await settle(t);
      final call = playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((i) => i.value), [1, 2, 4, 5]);
      expect(call.startIndex, 2);
      expect(call.shuffle, isFalse);
      expect(
        call.context,
        const PlayContext(PlayContextKind.genre, label: 'Indie'),
      );
    });

    testWidgets('every song gone: Play and shuffle are off', (t) async {
      await _pump(t, _q(ids: [1, 2], missing: {1, 2}));
      expect(_play(t).onPressed, isNull);
      expect(_shuffle(t).onPressed, isNull);
    });
  });

  group('play', () {
    testWidgets('Play replaces the queue, moves it up and says so', (t) async {
      final playback = FakePlaybackCommands();
      final h = await _pump(
        t,
        _q(kind: 'album', label: 'X', missing: {3}),
        playback: playback,
      );
      _play(t).onPressed!();
      await settle(t);
      final call = playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((i) => i.value), [1, 2, 4, 5]);
      expect(call.startIndex, 0);
      expect(call.shuffle, isFalse);
      expect(
        call.context,
        const PlayContext(PlayContextKind.album, label: 'X'),
      );
      expect(h.store.touched, ['a']);
      expect(
        find.text(
          'Đang phát hàng đợi Hôm nay · 21:17 (4 bài). Hàng đợi cũ đã được lưu.',
        ),
        findsOneWidget,
      );
      // No Undo on the toast.
      expect(find.text(l10nOf(t).libraryMenuUndo), findsNothing);
    });

    testWidgets('shuffle plays shuffled', (t) async {
      final playback = FakePlaybackCommands();
      await _pump(t, _q(kind: null), playback: playback);
      _shuffle(t).onPressed!();
      await settle(t);
      final call = playback.calls.single as PlayTracksCall;
      expect(call.shuffle, isTrue);
      expect(call.context, const PlayContext(PlayContextKind.queue));
    });

    testWidgets('a failing write: toast, nothing played, no crash', (t) async {
      final playback = FakePlaybackCommands();
      final store = FakeSavedQueueStore([_q()])..failWrites = true;
      await _pump(t, _q(), playback: playback, store: store);
      _play(t).onPressed!();
      await settle(t);
      expect(find.text(l10nOf(t).libraryPlayFailed), findsOneWidget);
      expect(playback.calls, isEmpty);
      expect(t.takeException(), isNull);
    });
  });

  group('not found', () {
    testWidgets('a queue deleted elsewhere while open', (t) async {
      final h = await _pump(t, _q());
      expect(find.byType(SavedQueueHero), findsOneWidget);
      h.store.set(const []);
      await settle(t);
      expect(find.text(l10nOf(t).savedQueueNotFoundTitle), findsWidgets);
      expect(find.text(l10nOf(t).savedQueueNotFoundMessage), findsOneWidget);
      expect(find.byType(SavedQueueHero), findsNothing);
    });

    testWidgets('an uid that is not a saved queue', (t) async {
      await pumpSavedQueues(t, start: '/playlists/queues/nope');
      expect(find.text(l10nOf(t).savedQueueNotFoundMessage), findsOneWidget);
    });

    testWidgets('a playlist (no saved-queue info) is not shown as one', (
      t,
    ) async {
      final playlist = PlaylistDetail(
        summary: PlaylistSummary(
          id: 0,
          uid: 'p',
          name: 'Mix',
          description: '',
          isFavorites: false,
          trackCount: 1,
          durationMs: 0,
          createdAt: 0,
          updatedAt: 0,
          autoCoverKeys: const [],
        ),
        entries: const [],
      );
      await pumpSavedQueues(
        t,
        store: FakeSavedQueueStore([playlist]),
        start: '/playlists/queues/p',
      );
      expect(find.text(l10nOf(t).savedQueueNotFoundMessage), findsOneWidget);
    });

    testWidgets('a failed read shows the load error', (t) async {
      final store = FakeSavedQueueStore([_q()])..failReads = true;
      await _pump(t, _q(), store: store);
      expect(find.text(l10nOf(t).libraryLoadFailed), findsOneWidget);
    });
  });

  group('themes', () {
    for (final dark in [false, true]) {
      for (final animations in [true, false]) {
        testWidgets('dark: $dark, animations: $animations: builds', (t) async {
          await _pump(
            t,
            _q(),
            animations: animations,
            brightness: dark ? Brightness.dark : Brightness.light,
          );
          expect(t.takeException(), isNull);
          expect(find.byType(SavedQueueHero), findsOneWidget);
        });
      }
    }
  });
}
