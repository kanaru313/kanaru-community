import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/history/history_row.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../history/state/fake_history_store.dart';
import 'history_page_harness.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  testWidgets('the third line is when the play began and which time it was', (
    tester,
  ) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: [
          playAt(1, DateTime(2026, 11, 20, 21, 42), ordinal: 6),
          playAt(2, DateTime(2026, 11, 20, 9, 5), ordinal: 1),
        ],
      },
    );
    expect(find.text('21:42 · lần thứ 6'), findsOneWidget);
    expect(find.text('9:05 · lần thứ 1'), findsOneWidget);
  });

  testWidgets('English words the same line', (tester) async {
    await pumpHistoryPage(
      tester,
      byYear: {
        2026: [playAt(1, DateTime(2026, 11, 20, 21, 42), ordinal: 6)],
      },
      locale: const Locale('en'),
    );
    expect(find.text('21:42 · play #6'), findsOneWidget);
  });

  group('tap', () {
    testWidgets('plays the songs of that day from the tapped one, each once, '
        'without the ones that cannot play', (tester) async {
      final gone = info(2, title: 'Gone', status: TrackAvailability.missing);
      final again = info(1, title: 'One');
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: [
            playAt(1, DateTime(2026, 11, 20, 20), track: again, uid: 'a'),
            playAt(2, DateTime(2026, 11, 20, 19), track: gone, uid: 'b'),
            playAt(3, DateTime(2026, 11, 20, 18), uid: 'c'),
            playAt(4, DateTime(2026, 11, 20, 17), track: again, uid: 'd'),
            // Another day: not in the queue.
            playAt(5, DateTime(2026, 11, 19, 17), uid: 'e'),
          ],
        },
      );
      await tester.tap(find.text('Song 3'));
      await _settle(tester);
      final call = h.playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((t) => t.value), [1, 3]);
      expect(call.startIndex, 1);
      expect(call.context.kind, PlayContextKind.history);
      expect(call.context.label, 'Lịch sử');
    });
  });

  group('Delete key', () {
    testWidgets('removes the focused play', (tester) async {
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
        width: 1400,
      );
      await focusRow(tester, 'Song 2');
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await _settle(tester);
      expect(h.store.removed, [
        ['p2'],
      ]);
    });

    testWidgets('removes a play whose file is gone as well', (tester) async {
      final gone = info(7, title: 'Gone', status: TrackAvailability.missing);
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: [playAt(1, DateTime(2026, 11, 20, 9), track: gone)],
        },
        width: 1400,
      );
      await focusRow(tester, 'Gone');
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await _settle(tester);
      expect(h.store.removed, [
        ['p1'],
      ]);
    });
  });

  group('day queue', () {
    test('keeps each song at its first play and drops the unplayable', () {
      final q = HistoryDayQueue([
        playAt(1, DateTime(2026, 11, 20, 20), track: info(1), uid: 'a'),
        playAt(
          2,
          DateTime(2026, 11, 20, 19),
          track: info(2, status: TrackAvailability.hidden),
          uid: 'b',
        ),
        playAt(3, DateTime(2026, 11, 20, 18), track: info(3), uid: 'c'),
        playAt(4, DateTime(2026, 11, 20, 17), track: info(1), uid: 'd'),
      ]);
      expect(q.ids.map((t) => t.value), [1, 3]);
      expect(q.indexOf(const TrackId(3)), 1);
      expect(q.indexOf(const TrackId(1)), 0);
      expect(q.indexOf(const TrackId(2)), 0);
    });

    test('an all-missing day queues nothing', () {
      final q = HistoryDayQueue([
        playAt(
          1,
          DateTime(2026, 11, 20, 20),
          track: info(1, status: TrackAvailability.missing),
        ),
      ]);
      expect(q.ids, isEmpty);
    });
  });

  testWidgets('selection by track: every row of a selected song shows it', (
    tester,
  ) async {
    final song = info(5, title: 'Five');
    final h = await pumpHistoryPage(
      tester,
      byYear: {
        2026: [
          playAt(1, DateTime(2026, 11, 20, 20), track: song, uid: 'a'),
          playAt(2, DateTime(2026, 11, 20, 19), track: song, uid: 'b'),
          playAt(3, DateTime(2026, 11, 20, 18), uid: 'c'),
        ],
      },
    );
    await tester.longPress(find.text('Five').first);
    await tester.pump();
    final cards = tester
        .widgetList<KMediaCard>(
          find.ancestor(
            of: find.text('Five'),
            matching: find.byType(KMediaCard),
          ),
        )
        .toList();
    expect(cards.map((c) => c.selected), [true, true]);
    h.store.hashCode;
  });
}
