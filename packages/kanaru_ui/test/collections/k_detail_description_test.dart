import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/collections/k_detail_line.dart'
    show KVerticalHitExtension;
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';
import '../support/scaled_host.dart';

final _long = List.generate(60, (i) => 'word$i').join(' ');
final _medium = List.generate(8, (i) => 'word$i').join(' ');

Widget _desc(
  String text, {
  bool expanded = false,
  ValueChanged<bool>? onChanged,
}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: 360,
    child: KDetailDescription(
      text: text,
      expanded: expanded,
      onExpandedChanged: onChanged ?? (_) {},
      moreLabel: 'More',
      lessLabel: 'Less',
    ),
  ),
);

/// Height of one line of the description text.
Future<double> _oneLine(WidgetTester tester) async {
  await tester.pumpWidget(host(_desc('One line.')));
  final h = tester.getSize(find.text('One line.')).height;
  await tester.pumpWidget(const SizedBox());
  return h;
}

void main() {
  testWidgets('short text has no button', (tester) async {
    await tester.pumpWidget(host(_desc('Just a line.')));
    expect(find.text('More'), findsNothing);
    expect(find.text('Less'), findsNothing);
  });

  testWidgets('long text clamps to three lines with a More button', (
    tester,
  ) async {
    bool? changed;
    final oneLine = await _oneLine(tester);
    await tester.pumpWidget(host(_desc(_long, onChanged: (v) => changed = v)));
    final text = tester.getSize(find.text(_long));
    expect(text.height, closeTo(oneLine * 3, 1));
    await tester.tap(find.text('More'));
    expect(changed, isTrue);
  });

  testWidgets('expanded shows all text and Less', (tester) async {
    bool? changed;
    final oneLine = await _oneLine(tester);
    await tester.pumpWidget(
      host(_desc(_long, expanded: true, onChanged: (v) => changed = v)),
    );
    expect(tester.getSize(find.text(_long)).height, greaterThan(oneLine * 3));
    expect(find.text('More'), findsNothing);
    await tester.tap(find.text('Less'));
    expect(changed, isFalse);
  });

  testWidgets('breaks become spaces while clamped, stay when expanded', (
    tester,
  ) async {
    const text = 'first paragraph\n\nsecond paragraph';
    await tester.pumpWidget(host(_desc(text)));
    expect(find.text('first paragraph second paragraph'), findsOneWidget);
    await tester.pumpWidget(host(_desc(text, expanded: true)));
    expect(find.text(text), findsOneWidget);
  });

  testWidgets('the button reaches up to 48 dp without adding height', (
    tester,
  ) async {
    var changed = 0;
    await tester.pumpWidget(host(_desc(_long, onChanged: (_) => changed++)));
    final r = tester.getRect(find.text('More'));
    expect(
      tester.getSize(find.byType(KVerticalHitExtension)).height,
      lessThan(48),
    );
    await tester.tapAt(Offset(r.left + 4, r.top - 20));
    expect(changed, 1);
    await tester.tapAt(Offset(r.left + 4, r.top - 40));
    expect(changed, 1, reason: 'beyond 48 dp the text is just text');
  });

  testWidgets('text scale 200% measures the overflow again', (tester) async {
    await tester.pumpWidget(scaledHost(_desc(_medium)));
    expect(find.text('More'), findsNothing);
    await tester.pumpWidget(scaledHost(_desc(_medium), textScale: 2));
    expect(find.text('More'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
