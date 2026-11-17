import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

/// A text column like the hero's: name, line 2, line 3 and a button.
Widget _column({
  String text = 'Artist',
  String? trailing,
  double width = 300,
  VoidCallback? onTap,
  VoidCallback? onPlay,
}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Name'),
        KDetailLine(text: text, onTap: onTap, trailing: trailing),
        const IgnorePointer(child: Text('3 songs')),
        const SizedBox(height: 8),
        GestureDetector(onTap: onPlay, child: const Text('Play')),
      ],
    ),
  ),
);

void main() {
  testWidgets('a tap on the link calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_column(onTap: () => taps++)));
    await tester.tap(find.text('Artist'));
    expect(taps, 1);
  });

  testWidgets('the touch area reaches above and below the line', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(host(_column(onTap: () => taps++)));
    final r = tester.getRect(find.text('Artist'));
    await tester.tapAt(Offset(r.left + 5, r.top - 10));
    await tester.tapAt(Offset(r.left + 5, r.bottom + 10));
    expect(taps, 2);
  });

  testWidgets('the extra touch area adds no height', (tester) async {
    await tester.pumpWidget(host(_column(onTap: () {})));
    final link = tester.getSize(find.byType(KDetailLine)).height;
    await tester.pumpWidget(host(_column()));
    expect(tester.getSize(find.byType(KDetailLine)).height, link);
  });

  testWidgets('a tap on the button below does not open the link', (
    tester,
  ) async {
    var taps = 0;
    var plays = 0;
    await tester.pumpWidget(
      host(_column(onTap: () => taps++, onPlay: () => plays++)),
    );
    await tester.tap(find.text('Play'));
    expect(plays, 1);
    expect(taps, 0);
  });

  testWidgets('a tap on the trailing text does not open the link', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(_column(onTap: () => taps++, trailing: '2020')),
    );
    await tester.tap(find.text(' · 2020'));
    expect(taps, 0);
  });

  testWidgets('Tab reaches the link and Enter opens it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(_column(onTap: () => taps++)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('the link is a focusable link in semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_column(onTap: () {})));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Artist')),
      isSemantics(
        label: 'Artist',
        isLink: true,
        isButton: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('without onTap it is plain text, not a link', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_column()));
    expect(
      tester.getSemantics(find.text('Artist')),
      isSemantics(label: 'Artist'),
    );
    handle.dispose();
  });

  testWidgets('a long name is cut before the year', (tester) async {
    await tester.pumpWidget(
      host(
        _column(
          text: 'A very long artist name that cannot fit in this width at all',
          trailing: '2020',
          width: 200,
          onTap: () {},
        ),
      ),
    );
    final link = tester.getRect(find.textContaining('A very long'));
    final year = tester.getRect(find.text(' · 2020'));
    expect(link.right, lessThanOrEqualTo(year.left + 0.5));
    expect(year.right, lessThanOrEqualTo(200.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a very long trailing text is cut, never overflows', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        _column(
          trailing: 'a trailing text that is far too long for the line',
          width: 200,
          onTap: () {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getRect(find.byType(KDetailLine)).right,
      lessThanOrEqualTo(200.5),
    );
  });
}
