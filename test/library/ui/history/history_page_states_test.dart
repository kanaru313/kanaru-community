import 'dart:async';
import 'dart:ui' show SemanticsFlag;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/ui/history/history_hero.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../history/state/fake_history_store.dart';
import '../../../support/icon_button_finders.dart';
import 'history_page_harness.dart';

/// Labels of the chips the page marks selected.
List<String> _selectedChips(WidgetTester tester) => [
  for (final n in find.semantics.byFlag(SemanticsFlag.isSelected).evaluate())
    if (n.getSemanticsData().label == '2026' ||
        n.getSemanticsData().label == '2025')
      n.getSemanticsData().label,
];

void main() {
  group('data', () {
    testWidgets('the hero says what the history holds', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3, 2]),
          2025: [playAt(50, DateTime(2025, 12, 31, 10), uid: 'p50')],
        },
      );
      expect(find.text('6 lượt nghe'), findsOneWidget);
      expect(find.text('6 bài · từ 31/12/2025'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Phát'), findsOneWidget);
    });

    testWidgets('the bar counts the shown year, chips list the years, the '
        'newest is selected', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3, 2]),
          2025: [playAt(50, DateTime(2025, 12, 31, 10), uid: 'p50')],
        },
      );
      expect(find.text('2026 · 5 lượt nghe'), findsOneWidget);
      expect(find.widgetWithText(KChip, '2026'), findsOneWidget);
      expect(find.widgetWithText(KChip, '2025'), findsOneWidget);
      expect(_selectedChips(tester), ['2026']);
      semantics.dispose();
    });

    testWidgets('a single year still shows its chip', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
      );
      expect(find.widgetWithText(KChip, '2026'), findsOneWidget);
    });

    testWidgets('a chip switches the year; the older year has no footer, the '
        'newer one offers it', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([3, 2]),
          2025: [playAt(50, DateTime(2025, 12, 31, 10), uid: 'p50')],
        },
        height: 4000,
      );
      expect(find.text('Xem năm 2025'), findsOneWidget);
      await tester.tap(find.widgetWithText(KChip, '2025'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(h.store.yearReads, contains(2025));
      expect(find.text('2025 · 1 lượt nghe'), findsOneWidget);
      expect(find.text('Song 50'), findsOneWidget);
      expect(find.text('Song 1'), findsNothing);
      expect(find.text('Xem năm 2025'), findsNothing);
      expect(_selectedChips(tester), ['2025']);
      semantics.dispose();
    });

    testWidgets('the footer line opens the next older year', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
          2025: [playAt(50, DateTime(2025, 12, 31, 10), uid: 'p50')],
        },
        height: 4000,
      );
      await tester.tap(find.text('Xem năm 2025'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Song 50'), findsOneWidget);
    });

    testWidgets('the hero shows before the year is read', (tester) async {
      final store = FakeHistoryStore()..yearGate = Completer<void>();
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        store: store,
        settle: false,
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump();
      expect(find.text('2 lượt nghe'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Song 1'), findsNothing);
      store.yearGate = null;
      h.store.hashCode;
    });

    testWidgets('a failed overview shows the load error', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([1]),
        },
        overrides: [
          historyOverviewProvider.overrideWith(
            (ref) => Future<Never>.error(StateError('boom')),
          ),
        ],
      );
      expect(find.text('Không tải được danh sách'), findsOneWidget);
    });
  });

  group('empty and recording off', () {
    testWidgets('no plays: the empty state, no hero, no bar', (tester) async {
      await pumpHistoryPage(tester, byYear: {});
      expect(find.text('Bài hát bạn đã phát sẽ hiện ở đây.'), findsOneWidget);
      expect(find.byType(HistoryHero), findsNothing);
      expect(find.byType(KChip), findsNothing);
    });

    testWidgets('recording off: the strip sits above the page; Bật turns it '
        'on, folds the strip and toasts', (tester) async {
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        recording: false,
      );
      const message = 'Đang tắt ghi lịch sử nghe. Những gì đã ghi vẫn còn.';
      expect(find.text(message), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(message)).dy,
        lessThan(tester.getTopLeft(find.byType(HistoryHero)).dy),
      );
      await tester.tap(find.text('Bật'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(h.container.read(historyRecordingProvider), isTrue);
      expect(find.text('Đã bật ghi lịch sử nghe'), findsOneWidget);
      // Folding takes a moment, then nothing is left.
      expect(find.text(message), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text(message), findsNothing);
    });

    testWidgets('with animations off the strip is gone at once', (
      tester,
    ) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        recording: false,
        animations: false,
      );
      await tester.tap(find.text('Bật'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Đang tắt ghi lịch sử nghe'), findsNothing);
    });

    testWidgets('empty and recording off shows the strip over the empty '
        'state', (tester) async {
      await pumpHistoryPage(tester, byYear: {}, recording: false);
      expect(find.textContaining('Đang tắt ghi lịch sử nghe'), findsOneWidget);
      expect(find.text('Bài hát bạn đã phát sẽ hiện ở đây.'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('only the newest play of the playing song is marked', (
      tester,
    ) async {
      final song = info(5, title: 'Five');
      final plays = [
        playAt(1, DateTime(2026, 11, 20, 20), track: song, uid: 'a'),
        playAt(2, DateTime(2026, 11, 20, 19), uid: 'b'),
        playAt(3, DateTime(2026, 11, 20, 18), track: song, uid: 'c'),
        playAt(4, DateTime(2026, 11, 19, 18), track: song, uid: 'd'),
      ];
      final h = await pumpHistoryPage(tester, byYear: {2026: plays});
      h.setNowPlaying(NowPlaying(entryId: 1, trackId: song.id, playing: true));
      await tester.pump();
      await tester.pump();
      final cards = tester
          .widgetList<KMediaCard>(
            find.ancestor(
              of: find.text('Five'),
              matching: find.byType(KMediaCard),
            ),
          )
          .toList();
      expect(cards.map((c) => c.current), [true, false, false]);
    });

    testWidgets('a play whose file is gone says so and answers a tap with a '
        'toast', (tester) async {
      final gone = info(7, title: 'Gone', status: TrackAvailability.missing);
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: [playAt(1, DateTime(2026, 11, 20, 21, 42), track: gone)],
        },
      );
      expect(find.text('21:42 · không phát được'), findsOneWidget);
      final card = tester.widget<KMediaCard>(find.byType(KMediaCard));
      expect(card.missing, isTrue);
      await tester.tap(find.text('Gone'));
      await tester.pump();
      expect(find.text('Không phát được bài này'), findsOneWidget);
      expect(h.playback.calls, isEmpty);
    });

    testWidgets('a hidden song is treated like a missing one', (tester) async {
      final hidden = info(8, title: 'Hid', status: TrackAvailability.hidden);
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: [playAt(1, DateTime(2026, 11, 20, 9, 5), track: hidden)],
        },
      );
      expect(find.text('9:05 · không phát được'), findsOneWidget);
    });
  });

  group('hero buttons', () {
    testWidgets('Play plays every played song as History', (tester) async {
      final infos = [info(1), info(2)];
      final store = FakeHistoryStore()
        ..playedTracks = [infos[1].id, infos[0].id];
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        store: store,
        overrides: [
          trackRowLoaderProvider.overrideWithValue(
            (ids) async => [
              for (final id in ids) infos.firstWhere((i) => i.id == id),
            ],
          ),
        ],
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Phát'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      final call = h.playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((t) => t.value), [2, 1]);
      expect(call.context.kind, PlayContextKind.history);
    });

    testWidgets('nothing playable shows a toast', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        overrides: [
          trackRowLoaderProvider.overrideWithValue((ids) async => const []),
        ],
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Phát'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.text('Không phát được lịch sử'), findsOneWidget);
    });
  });

  group('frame', () {
    testWidgets('two columns from 840 dp of page width', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        width: 900,
      );
      final hero = tester.element(find.byType(HistoryHero));
      expect(KDetailLayout.isWide(hero), isTrue);
      expect(
        tester.getSize(find.byType(HistoryHero)).width,
        KDetailLayout.columnWidth,
      );
    });

    testWidgets('one column below 840 dp', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        width: 700,
      );
      expect(
        KDetailLayout.isWide(tester.element(find.byType(HistoryHero))),
        isFalse,
      );
    });

    testWidgets('the mobile shell has a back button', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        width: 400,
      );
      final back = MaterialLocalizations.of(
        tester.element(find.byType(HistoryPage)),
      ).backButtonTooltip;
      expect(byIconButton(back), findsOneWidget);
    });

    testWidgets('desktop (a sidebar page) has none', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        width: 1300,
      );
      final back = MaterialLocalizations.of(
        tester.element(find.byType(HistoryPage)),
      ).backButtonTooltip;
      expect(byIconButton(back), findsNothing);
    });

    testWidgets('large text with long titles lays out without overflow', (
      tester,
    ) async {
      final long = info(
        1,
        title: 'Một bài hát có cái tên dài dài dài dài dài dài dài dài',
        artist: 'Một nghệ sĩ có tên cũng rất dài dài dài dài dài',
      );
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: [
            playAt(1, DateTime(2026, 11, 20, 9), track: long),
            playAt(2, DateTime(2026, 11, 19, 9), track: long),
          ],
        },
        textScale: 2,
        width: 360,
        height: 1600,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(HistoryPage), findsOneWidget);
    });
  });
}
