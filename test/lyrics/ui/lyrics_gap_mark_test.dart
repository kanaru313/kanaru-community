import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_gap_mark.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'lyrics_ui_host.dart';

Widget _mark({required bool active}) =>
    LyricsGapMark(active: active, color: Colors.white);

int _tickers() => SchedulerBinding.instance.transientCallbackCount;

void main() {
  testWidgets('a gap that is not current stays still', (tester) async {
    await LyricsUiHost().pump(tester, _mark(active: false));
    expect(_tickers(), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(_tickers(), 0);
  });

  testWidgets('the current gap pulses, and stops when it is not current', (
    tester,
  ) async {
    final host = LyricsUiHost();
    await host.pump(tester, _mark(active: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_tickers(), greaterThan(0));
    await host.pump(tester, _mark(active: false));
    await tester.pump();
    expect(_tickers(), 0);
  });

  testWidgets('animations off: static notes', (tester) async {
    await LyricsUiHost().pump(
      tester,
      _mark(active: true),
      disableAnimations: true,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(_tickers(), 0);
  });

  testWidgets('three music notes of the small icon size, no dots', (
    tester,
  ) async {
    await LyricsUiHost().pump(tester, _mark(active: false));
    final notes = find.descendant(
      of: find.byType(LyricsGapMark),
      matching: find.byType(Icon),
    );
    expect(notes, findsNWidgets(3));
    for (final note in tester.widgetList<Icon>(notes)) {
      expect(note.size, KIconSize.sm);
      expect(note.color, Colors.white);
    }
    expect(find.byType(DecoratedBox), findsNothing);
  });
}
