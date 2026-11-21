import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/domain/history/history_ranges.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/state/history/most_played_selection.dart';
import 'package:kanaru/src/library/ui/most_played/most_played_page.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../history/state/fake_history_store.dart';
import 'most_played_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  group('with data', () {
    testWidgets('the hero names the page, the range and the totals', (
      tester,
    ) async {
      await pumpMostPlayed(
        tester,
        top: topList([topEntry(1, count: 10), topEntry(2, count: 4)]),
      );
      expect(find.text('Phát nhiều nhất'), findsWidgets);
      expect(
        find.descendant(
          of: find.byType(KDetailHero),
          matching: find.text('22/10 – 20/11/2026'),
        ),
        findsOneWidget,
      );
      expect(find.text('2 bài · 14 lượt nghe'), findsOneWidget);
      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
    });

    testWidgets('the totals are the window\'s, not only the listed rows', (
      tester,
    ) async {
      await pumpMostPlayed(
        tester,
        top: topList([topEntry(1, count: 3)], songs: 40, plays: 210),
      );
      expect(find.text('40 bài · 210 lượt nghe'), findsOneWidget);
    });

    testWidgets('the third line is the play count, then album and year', (
      tester,
    ) async {
      await pumpMostPlayed(
        tester,
        top: topList([
          topEntry(1, count: 10, track: albumSong(1, 'Alpha', 'Disc', 2020)),
          topEntry(2, count: 1),
        ]),
      );
      expect(find.text('10 lượt · Disc • 2020'), findsOneWidget);
      // No album: the count alone.
      expect(find.text('1 lượt'), findsOneWidget);
    });

    testWidgets('a rank badge sits on every cover, in rank order', (
      tester,
    ) async {
      await pumpMostPlayed(
        tester,
        top: topList([for (var r = 1; r <= 5; r++) topEntry(r)]),
      );
      final badges = find.byKey(songTileBadgeKey);
      expect(badges, findsNWidgets(5));
      for (var r = 1; r <= 5; r++) {
        expect(
          find.descendant(of: badges, matching: find.text('$r')),
          findsOneWidget,
          reason: 'rank $r',
        );
      }
    });

    testWidgets('a tap plays the playable rows in rank order from the row', (
      tester,
    ) async {
      final h = await pumpMostPlayed(
        tester,
        top: topList([
          topEntry(1),
          topEntry(
            2,
            track: info(2, title: 'Gone', status: TrackAvailability.missing),
          ),
          topEntry(3),
          topEntry(4),
        ]),
      );
      await tester.tap(find.text('Song 3'));
      await _settle(tester);
      final call = h.playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((t) => t.value), [1, 3, 4]);
      expect(call.startIndex, 1);
      expect(call.context.kind, PlayContextKind.mostPlayed);
    });

    testWidgets('a song with its file gone says so, plays '
        'nothing and is left out of the queue', (tester) async {
      final h = await pumpMostPlayed(
        tester,
        top: topList([
          topEntry(
            1,
            count: 7,
            track: info(1, title: 'Gone', status: TrackAvailability.missing),
          ),
          topEntry(2),
        ]),
      );
      expect(find.text('7 lượt · không phát được'), findsOneWidget);
      // The missing row keeps its rank: 1 and 2.
      final badges = find.byKey(songTileBadgeKey);
      expect(badges, findsNWidgets(2));
      for (final r in [1, 2]) {
        expect(
          find.descendant(of: badges, matching: find.text('$r')),
          findsOneWidget,
          reason: 'rank $r',
        );
      }
      await tester.tap(find.text('Gone'));
      await _settle(tester);
      expect(h.playback.calls, isEmpty);
      expect(find.text('Không phát được bài này'), findsOneWidget);
    });

    testWidgets('the playing row is marked', (tester) async {
      final h = await pumpMostPlayed(
        tester,
        top: topList([topEntry(1), topEntry(2)]),
      );
      bool current(String title) => tester
          .widget<KMediaCard>(find.widgetWithText(KMediaCard, title))
          .current;
      expect(current('Song 2'), isFalse);
      h.setNowPlaying(
        NowPlaying(entryId: 1, trackId: TrackId(2), playing: true),
      );
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(current('Song 2'), isTrue);
      expect(current('Song 1'), isFalse);
    });

    testWidgets('a long press selects the song', (tester) async {
      final h = await pumpMostPlayed(
        tester,
        top: topList([topEntry(1), topEntry(2)]),
      );
      await tester.longPress(find.text('Song 2'));
      await _settle(tester);
      expect(h.container.read(librarySelectionProvider).ids.single.value, 2);
      expect(h.playback.calls, isEmpty);
    });

    testWidgets('long text at 2.0x on a narrow phone does not overflow', (
      tester,
    ) async {
      await pumpMostPlayed(
        tester,
        width: 320,
        textScale: 2,
        top: topList([
          topEntry(
            1,
            count: 12,
            track: albumSong(
              1,
              'Một bản thu trực tiếp rất dài tại Nhà hát Lớn Hà Nội đêm nhạc mùa thu',
              'Album có cái tên cũng rất dài để thử cắt chữ',
              2026,
            ),
          ),
        ]),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SongTile), findsOneWidget);
    });
  });

  group('empty', () {
    testWidgets('a range with no plays: the line, and the chips stay usable', (
      tester,
    ) async {
      await pumpMostPlayed(tester, top: topList(const []));
      expect(find.text('Không có lượt nghe trong khoảng này.'), findsOneWidget);
      expect(find.text('0 bài · 0 lượt nghe'), findsOneWidget);
      expect(find.byType(KChip), findsWidgets);
      final custom = tester.widget<KChip>(
        find.widgetWithText(KChip, 'Tuỳ chọn…'),
      );
      expect(custom.enabled, isTrue);
    });

    testWidgets('no plays at all: the same line, Tuỳ chọn… dimmed', (
      tester,
    ) async {
      await pumpMostPlayed(tester, top: topList(const []), hasPlays: false);
      expect(find.text('Không có lượt nghe trong khoảng này.'), findsOneWidget);
      expect(
        tester.widget<KChip>(find.widgetWithText(KChip, 'Tuỳ chọn…')).enabled,
        isFalse,
      );
      expect(
        tester.widget<KChip>(find.widgetWithText(KChip, '7 ngày')).enabled,
        isTrue,
      );
    });
  });

  group('stale', () {
    testWidgets('the previous list stays under a thin progress line', (
      tester,
    ) async {
      final store = FakeHistoryStore();
      final h = await pumpMostPlayed(
        tester,
        store: store,
        top: topList([topEntry(1)]),
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      final gate = Completer<void>();
      store.topGate = gate;
      h.container
          .read(mostPlayedRangeProvider.notifier)
          .set(
            h.container
                .read(mostPlayedRangeProvider)
                .withPreset(MostPlayedPreset.days7),
          );
      await _settle(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Song 1'), findsOneWidget);
      ButtonStyleButton play() => tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Phát'),
          matching: find.bySubtype<ButtonStyleButton>(),
        ),
      );
      expect(play().onPressed, isNull, reason: 'Play waits for the new list');
      gate.complete();
      await _settle(tester);
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(play().onPressed, isNotNull);
    });
  });

  testWidgets('a failed read says so and keeps the chips', (tester) async {
    final store = _FailingStore();
    await pumpMostPlayed(tester, store: store);
    expect(find.text('Không tải được danh sách'), findsOneWidget);
    expect(find.byType(KChip), findsWidgets);
  });

  testWidgets('a failed read states no totals', (tester) async {
    await pumpMostPlayed(tester, store: _FailingStore());
    expect(find.textContaining('lượt nghe'), findsNothing);
  });

  testWidgets('a retry after a failed read keeps the failed frame', (
    tester,
  ) async {
    final store = _FailingStore();
    final h = await pumpMostPlayed(tester, store: store);
    final gate = Completer<void>();
    store
      ..fail = false
      ..topGate = gate;
    h.container
        .read(mostPlayedRangeProvider.notifier)
        .set(
          h.container
              .read(mostPlayedRangeProvider)
              .withPreset(MostPlayedPreset.days7),
        );
    await tester.pump();
    await tester.pump();
    expect(find.text('Không tải được danh sách'), findsOneWidget);
    expect(find.byType(KChip), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Không tải được danh sách'), findsNothing);
  });

  testWidgets('a range that fails after data shows the error, not the old '
      'list', (tester) async {
    final store = _FailingStore()..fail = false;
    final h = await pumpMostPlayed(
      tester,
      store: store,
      top: topList([topEntry(1)]),
    );
    expect(find.text('Song 1'), findsOneWidget);
    store.fail = true;
    h.container
        .read(mostPlayedRangeProvider.notifier)
        .set(
          h.container
              .read(mostPlayedRangeProvider)
              .withPreset(MostPlayedPreset.days7),
        );
    await tester.pumpAndSettle();
    expect(find.text('Không tải được danh sách'), findsOneWidget);
    expect(find.text('Song 1'), findsNothing);
  });

  group('hero line and chips on a phone', () {
    testWidgets('the hero line is the dates alone, end year included', (
      tester,
    ) async {
      await pumpMostPlayed(tester, width: 360, top: topList([topEntry(1)]));
      final line = find.descendant(
        of: find.byType(KDetailHero),
        matching: find.text('22/10 – 20/11/2026'),
      );
      expect(line, findsOneWidget);
      // The preset name is the chosen chip's job: the line is the dates
      // alone, short enough for the end year to stay on a phone.
      expect(
        find.descendant(
          of: find.byType(KDetailHero),
          matching: find.textContaining('30 ngày'),
        ),
        findsNothing,
      );
    });

    testWidgets('the chosen chip scrolls into view when it changes', (
      tester,
    ) async {
      final h = await pumpMostPlayed(
        tester,
        width: 360,
        top: topList([topEntry(1)]),
      );
      final custom = find.widgetWithText(KChip, 'Tuỳ chọn…');
      expect(tester.getRect(custom).right, greaterThan(360));
      h.container
          .read(mostPlayedRangeProvider.notifier)
          .set(
            h.container
                .read(mostPlayedRangeProvider)
                .withCustom(DateTime(2026, 11, 1), DateTime(2026, 11, 5)),
          );
      await tester.pumpAndSettle();
      final rect = tester.getRect(custom);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
    });
  });

  group('layout', () {
    testWidgets('two columns from 840 dp of page width, one below', (
      tester,
    ) async {
      await pumpMostPlayed(
        tester,
        width: 1000,
        top: topList([topEntry(1), topEntry(2)]),
      );
      final wideHero = tester.getTopLeft(find.byType(KDetailHero));
      final wideList = tester.getTopLeft(find.text('Song 1'));
      expect(wideList.dx, greaterThan(wideHero.dx + 300));
      expect(find.byType(MostPlayedPage), findsOneWidget);
    });

    testWidgets('narrow: the list sits under the hero', (tester) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1)]));
      expect(
        tester.getTopLeft(find.text('Song 1')).dy,
        greaterThan(tester.getBottomLeft(find.byType(KDetailHero)).dy),
      );
    });
  });
}

class _FailingStore extends FakeHistoryStore {
  /// True: every read throws; false: reads answer like the fake.
  bool fail = true;

  @override
  Future<MostPlayed> top({
    ({int start, int end})? window,
    required int limit,
  }) async {
    if (fail) throw StateError('db');
    return super.top(window: window, limit: limit);
  }
}
