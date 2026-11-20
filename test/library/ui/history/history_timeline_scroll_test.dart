import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/ui/history/history_line_metrics.dart';
import 'package:kanaru/src/library/ui/history/history_timeline_data.dart';
import 'package:kanaru/src/library/ui/history/history_timeline_scroll.dart';

import 'history_page_harness.dart';

const _metrics = HistoryLineMetrics(row: 72, dayBar: 56);

HistoryTimelineData _data(List<HistoryPlay> plays) =>
    HistoryTimelineData(plays, _metrics, hasOlderYear: false);

void main() {
  // The list's top is 400 dp down the page; the page is scrolled so the bar
  // pins at 400 - 56 + the depth into the list.
  const listTop = 400.0;
  double pixelsAt(double into) => listTop - _metrics.dayBar + into;

  group('anchor', () {
    test('is the play under the bar and its distance from the bar', () {
      final data = _data(playsOverDays([8, 8, 8, 8]));
      // 2000 dp into the list: row index 27 (top 27 * 72 + day headers).
      final anchor = historyAnchorAt(data, listTop, pixelsAt(2000))!;
      final line = data.lineOfPlay[anchor.uid]!;
      expect(
        data.index.topOf(line) - anchor.below,
        closeTo(2000, 0.01),
        reason: 'top of the play minus its distance is the bar\'s content top',
      );
    });

    test('is none while the page is above the list', () {
      final data = _data(playsOverDays([8, 8]));
      expect(historyAnchorAt(data, listTop, 0), isNull);
      expect(historyAnchorAt(data, listTop, pixelsAt(-10)), isNull);
    });

    test('puts the page back after plays arrived above, deep in the year', () {
      final plays = playsOverDays([8, 8, 8, 8, 8, 8, 8, 8]);
      final before = _data(plays);
      final depth = 3000.0;
      final anchor = historyAnchorAt(before, listTop, pixelsAt(depth))!;
      final arrived = [
        for (var i = 0; i < 5; i++)
          playAt(100 + i, DateTime(2026, 11, 21, 12 - i), uid: 'n$i'),
        ...plays,
      ];
      final after = _data(arrived);
      final pixels = historyRestorePixels(
        after,
        listTop,
        HistoryRestore(anchor: anchor, pixels: pixelsAt(depth)),
      )!;
      // The same play is under the bar at the same distance.
      final again = historyAnchorAt(after, listTop, pixels)!;
      expect(again.uid, anchor.uid);
      expect(again.below, closeTo(anchor.below, 0.01));
      expect(pixels, greaterThan(pixelsAt(depth)));
    });

    test('falls back to the pixels when the play is gone', () {
      final plays = playsOverDays([8, 8, 8]);
      final anchor = historyAnchorAt(_data(plays), listTop, pixelsAt(300))!;
      final gone = [
        for (final p in plays)
          if (p.uid != anchor.uid) p,
      ];
      final pixels = historyRestorePixels(
        _data(gone),
        listTop,
        HistoryRestore(anchor: anchor, pixels: 123),
      );
      expect(pixels, 123);
    });
  });
}
