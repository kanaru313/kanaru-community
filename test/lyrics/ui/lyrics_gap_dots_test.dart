import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_gap_dots.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';

Widget _dots({required bool active}) =>
    LyricsGapDots(active: active, color: Colors.white);

int _tickers() => SchedulerBinding.instance.transientCallbackCount;

void main() {
  testWidgets('a gap that is not current stays still', (tester) async {
    await LyricsUiHost().pump(tester, _dots(active: false));
    expect(_tickers(), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(_tickers(), 0);
  });

  testWidgets('the current gap pulses, and stops when it is not current', (
    tester,
  ) async {
    final host = LyricsUiHost();
    await host.pump(tester, _dots(active: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_tickers(), greaterThan(0));
    await host.pump(tester, _dots(active: false));
    await tester.pump();
    expect(_tickers(), 0);
  });

  testWidgets('animations off: static dots', (tester) async {
    await LyricsUiHost().pump(
      tester,
      _dots(active: true),
      disableAnimations: true,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(_tickers(), 0);
  });

  testWidgets('three dots of 10 dp with a gap of 8', (tester) async {
    await LyricsUiHost().pump(tester, _dots(active: false));
    final dots = find.byType(DecoratedBox).evaluate().length;
    expect(dots, greaterThanOrEqualTo(3));
    final boxes = find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == 10 && w.height == 10,
    );
    expect(boxes, findsNWidgets(3));
    expect(
      tester.getTopLeft(boxes.at(1)).dx - tester.getTopLeft(boxes.at(0)).dx,
      18,
    );
  });
}
