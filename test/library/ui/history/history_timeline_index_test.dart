import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/history/history_line_metrics.dart';
import 'package:kanaru/src/library/ui/history/history_timeline_index.dart';

/// Round numbers: a row is 100, a day bar 60.
const _m = HistoryLineMetrics(row: 100, dayBar: 60);

HistoryTimelineIndex _index(List<int> counts, {bool older = false}) =>
    HistoryTimelineIndex(counts, _m, hasOlderYear: older);

void main() {
  group('lines', () {
    // Day 0: 2 plays (no header line), day 1: 3 plays, day 2: 1 play.
    final i = _index([2, 3, 1], older: true);

    test('the first day has no header line, the others have one', () {
      expect(i.lineCount, 2 + (1 + 3) + (1 + 1) + 1);
      expect(i.lineInfo(0), (kind: HistoryLineKind.row, day: 0, row: 0));
      expect(i.lineInfo(1), (kind: HistoryLineKind.row, day: 0, row: 1));
      expect(i.lineInfo(2), (kind: HistoryLineKind.header, day: 1, row: -1));
      expect(i.lineInfo(3), (kind: HistoryLineKind.row, day: 1, row: 0));
      expect(i.lineInfo(6), (kind: HistoryLineKind.header, day: 2, row: -1));
      expect(i.lineInfo(8), (kind: HistoryLineKind.footer, day: 3, row: -1));
    });

    test('extents sum into offsets', () {
      expect(i.topOf(2), 200);
      expect(i.extentOf(2), 60);
      expect(i.topOf(3), 260);
      expect(i.totalExtent, 6 * 100 + 2 * 60 + 100);
    });

    test('a year without an older one has no footer line', () {
      expect(_index([2, 3, 1]).lineCount, 8);
    });

    test('an empty year has no line, no day', () {
      final e = _index([]);
      expect(e.lineCount, 0);
      expect(e.lineAt(10), -1);
      expect(e.dayAt(10), -1);
      expect(e.pushUp(10), 0);
    });
  });

  group('lineAt', () {
    final i = _index([2, 3]);
    test('finds the line under an offset, edges go to the later line', () {
      expect(i.lineAt(0), 0);
      expect(i.lineAt(99.9), 0);
      expect(i.lineAt(100), 1);
      expect(i.lineAt(200), 2);
      expect(i.lineAt(259), 2);
      expect(i.lineAt(260), 3);
    });
    test('clamps before the start and past the end', () {
      expect(i.lineAt(-50), 0);
      expect(i.lineAt(1e9), i.lineCount - 1);
    });
  });

  group('days', () {
    final i = _index([2, 3, 1]);
    test('dayOffset is the top of the header line, 0 for the first day', () {
      expect(i.dayOffset(0), 0);
      expect(i.dayOffset(1), 200);
      expect(i.dayOffset(2), 200 + 60 + 300);
    });
    test('dayLine is the header line, the first row for day 0', () {
      expect(i.dayLine(0), 0);
      expect(i.dayLine(1), 2);
      expect(i.dayLine(2), 6);
    });
    test('dayAt follows the header reaching the bar', () {
      expect(i.dayAt(-20), 0);
      expect(i.dayAt(199.9), 0);
      expect(i.dayAt(200), 1);
      expect(i.dayAt(559.9), 1);
      expect(i.dayAt(560), 2);
      expect(i.dayAt(1e6), 2);
    });
  });

  group('pushUp', () {
    final i = _index([2, 3]);
    // The next header (day 1) is at 200 and the bar is 60 tall: the bar
    // starts to move at offset 140 and is gone at 200.
    test('0 while the next header is below the bar', () {
      expect(i.pushUp(0), 0);
      expect(i.pushUp(140), 0);
    });
    test('grows to minus the bar height as the header arrives', () {
      expect(i.pushUp(170), -30);
      expect(i.pushUp(199), -59);
    });
    test('the bar is then the next day at rest', () {
      expect(i.pushUp(200), 0);
      expect(i.dayAt(200), 1);
    });
    test('the last day is never pushed', () {
      expect(i.pushUp(400), 0);
    });
    test('continuous across the swap: push stays within the bar height', () {
      for (var o = 0.0; o < 700; o += 7) {
        final dy = i.pushUp(o);
        expect(dy, inInclusiveRange(-60, 0));
      }
    });
  });

  group('plays', () {
    final i = _index([2, 3]);
    test('a play offset skips the header lines before it', () {
      expect(i.playOffset(0), 0);
      expect(i.playOffset(1), 100);
      expect(i.playOffset(2), 260);
      expect(i.lineOfPlay(2), 3);
      expect(i.playPlace(2), (day: 1, row: 0));
      expect(i.playCount, 5);
    });
  });

  group('text scale', () {
    test('the header line and the pinned bar are the same height', () {
      for (final scale in [1.0, 2.0]) {
        final m = HistoryLineMetrics(row: 80 * scale, dayBar: 56 * scale);
        final i = HistoryTimelineIndex([1, 1], m);
        expect(i.extentOf(1), m.dayBar);
      }
    });
  });
}
