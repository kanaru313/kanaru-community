import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import 'support/fake_saved_queue_store.dart';
import 'support/saved_queue_harness.dart';

int _at(int d, [int h = 21, int m = 17]) =>
    DateTime(2026, 11, d, h, m).millisecondsSinceEpoch;

PlaylistDetail _q(
  String uid,
  int savedAt, {
  int songs = 4,
  Set<int> missing = const {},
  String? kind = 'album',
  String? label = 'm-tp M-TP',
}) => savedQueue(
  uid,
  savedAt: savedAt,
  ids: [for (var i = 1; i <= songs; i++) i],
  missing: missing,
  kind: kind,
  label: label,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi');
  });

  group('states', () {
    testWidgets('empty: the message alone, no explanation line', (t) async {
      await pumpSavedQueues(t);
      final l10n = l10nOf(t);
      expect(find.text(l10n.savedQueueEmpty), findsOneWidget);
      expect(find.text(l10n.savedQueueExplain), findsNothing);
      expect(find.byType(SavedQueueTile), findsNothing);
    });

    testWidgets('one queue: row lines and the explanation line', (t) async {
      await pumpSavedQueues(
        t,
        store: FakeSavedQueueStore([_q('a', _at(21), songs: 24)]),
      );
      final l10n = l10nOf(t);
      expect(find.text(l10n.savedQueueExplain), findsOneWidget);
      expect(find.text('Hôm nay · 21:17'), findsOneWidget);
      expect(find.text('24 bài · 24 phút'), findsOneWidget);
      expect(find.text('Từ album m-tp M-TP'), findsOneWidget);
    });

    testWidgets('missing songs add to line 2; no source gives no line 3', (
      t,
    ) async {
      await pumpSavedQueues(
        t,
        store: FakeSavedQueueStore([
          _q('a', _at(20, 9, 5), songs: 9, missing: {8, 9}, kind: null),
        ]),
      );
      expect(find.text('Hôm qua · 9:05'), findsOneWidget);
      expect(find.text('9 bài · 9 phút · 2 bài không còn'), findsOneWidget);
      expect(find.textContaining('Từ '), findsNothing);
    });

    testWidgets('a missing song listed twice counts once', (t) async {
      await pumpSavedQueues(
        t,
        store: FakeSavedQueueStore([
          savedQueue('a', savedAt: _at(20), ids: [1, 1, 2], missing: {1}),
        ]),
      );
      expect(find.textContaining('1 bài không còn'), findsOneWidget);
    });

    testWidgets('20 queues: newest first, the list scrolls', (t) async {
      final queues = [
        // Newest first: 20 distinct days back from the 21st, 8 to 1 Nov then
        // October, so every name differs.
        for (var i = 0; i < 20; i++)
          _q(
            'q$i',
            DateTime(2026, 11, 21 - i, 12, 0).millisecondsSinceEpoch,
            songs: 2 + i,
          ),
      ];
      await pumpSavedQueues(t, store: FakeSavedQueueStore(queues), height: 600);
      final tiles = find.byType(SavedQueueTile);
      expect(t.widget<SavedQueueTile>(tiles.first).row.summary.uid, 'q0');
      expect(find.text('Hôm nay · 12:00'), findsOneWidget);
      // Not all 20 are built: the last is below the fold.
      expect(find.text('02/11 · 12:00'), findsNothing);
      await t.dragUntilVisible(
        find.text('02/11 · 12:00'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      expect(find.text('02/11 · 12:00'), findsOneWidget);
    });

    testWidgets('a long source and 200 % text do not overflow', (t) async {
      await pumpSavedQueues(
        t,
        textScale: 2,
        store: FakeSavedQueueStore([
          _q(
            'a',
            _at(21),
            kind: 'playlist',
            label: 'Những bài hát cho chuyến xe đêm từ Sài Gòn ra Vũng Tàu cuối tuần',
          ),
        ]),
      );
      expect(t.takeException(), isNull);
      expect(find.textContaining('Từ playlist Những bài'), findsOneWidget);
    });

    testWidgets('a failed read says so; the page stays', (t) async {
      final store = FakeSavedQueueStore()..failReads = true;
      await pumpSavedQueues(t, store: store);
      expect(find.text(l10nOf(t).libraryLoadFailed), findsOneWidget);
    });

    testWidgets('a change in the store updates the list', (t) async {
      final store = FakeSavedQueueStore([_q('a', _at(21))]);
      await pumpSavedQueues(t, store: store);
      expect(find.byType(SavedQueueTile), findsOneWidget);
      store.set([_q('b', _at(21, 22, 0)), _q('a', _at(21))]);
      await settle(t);
      expect(find.byType(SavedQueueTile), findsNWidgets(2));
      store.set(const []);
      await settle(t);
      expect(find.text(l10nOf(t).savedQueueEmpty), findsOneWidget);
    });
  });

  group('play button', () {
    testWidgets('mobile: always there; plays the saved queue', (t) async {
      final playback = FakePlaybackCommands();
      final h = await pumpSavedQueues(
        t,
        playback: playback,
        store: FakeSavedQueueStore([
          _q('a', _at(21), songs: 3, kind: 'genre', label: 'Indie'),
        ]),
      );
      final l10n = l10nOf(t);
      final play = byIconButton(l10n.savedQueuePlayRow);
      expect(t.widget<KIconButton>(play).onPressed, isNotNull);
      await t.tap(play);
      await settle(t);
      final call = playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((i) => i.value), [1, 2, 3]);
      expect(
        call.context,
        const PlayContext(PlayContextKind.genre, label: 'Indie'),
      );
      expect(h.store.touched, ['a']);
    });

    testWidgets('mobile: off when nothing in the queue can play', (t) async {
      await pumpSavedQueues(
        t,
        store: FakeSavedQueueStore([
          _q('a', _at(21), songs: 2, missing: {1, 2}),
        ]),
      );
      final play = byIconButton(l10nOf(t).savedQueuePlayRow);
      expect(t.widget<KIconButton>(play).onPressed, isNull);
    });

    testWidgets('desktop: shows on hover only', (t) async {
      final handle = t.ensureSemantics();
      await pumpSavedQueues(
        t,
        width: 1400,
        store: FakeSavedQueueStore([_q('a', _at(21))]),
      );
      final label = l10nOf(t).savedQueuePlayRow;
      expect(find.bySemanticsLabel(label), findsNothing);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(find.byType(SavedQueueTile)));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel(label), findsOneWidget);
      handle.dispose();
    });
  });

  group('open', () {
    testWidgets('a tap opens the queue page', (t) async {
      final h = await pumpSavedQueues(
        t,
        store: FakeSavedQueueStore([_q('abc', _at(21))]),
      );
      await t.tap(find.text('Hôm nay · 21:17'));
      await settle(t);
      expect(h.location, '/playlists/queues/abc');
    });

    testWidgets('⋮, long press and right click open the menu', (t) async {
      await pumpSavedQueues(t, store: FakeSavedQueueStore([_q('a', _at(21))]));
      final l10n = l10nOf(t);
      Future<void> opened(Future<void> Function() open) async {
        await open();
        await settle(t);
        expect(find.text(l10n.savedQueueMenuPlay), findsOneWidget);
        await t.tapAt(const Offset(200, 20));
        await settle(t);
        expect(find.text(l10n.savedQueueMenuPlay), findsNothing);
      }

      await opened(() => t.tap(byIconButton(l10n.libraryMenuMore)));
      await opened(() => t.longPress(find.byType(SavedQueueTile)));
      await opened(() async {
        final mouse = await t.startGesture(
          t.getCenter(find.byType(SavedQueueTile)),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await mouse.up();
      });
    });
  });

  group('themes', () {
    for (final dark in [false, true]) {
      for (final animations in [true, false]) {
        testWidgets('dark: $dark, animations: $animations: builds', (t) async {
          await pumpSavedQueues(
            t,
            animations: animations,
            brightness: dark ? Brightness.dark : Brightness.light,
            store: FakeSavedQueueStore([_q('a', _at(21))]),
          );
          expect(t.takeException(), isNull);
          expect(find.byType(SavedQueueTile), findsOneWidget);
        });
      }
    }
  });
}
