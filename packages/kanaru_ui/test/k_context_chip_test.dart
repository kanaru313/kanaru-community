import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

Widget _chip(
  KContextChipState state, {
  String label = 'Bài đang phát',
  VoidCallback? onTap,
  VoidCallback? onRemove,
}) => Align(
  alignment: Alignment.topLeft,
  child: KContextChip(
    label: label,
    icon: KIcons.info,
    state: state,
    onTap: onTap ?? () {},
    onRemove: onRemove ?? () {},
    removeLabel: 'Bỏ thẻ $label',
    struckHint: 'Công cụ đang tắt',
  ),
);

void main() {
  testWidgets('suggested tap calls onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(_chip(KContextChipState.suggested, onTap: () => taps++)),
    );
    await tester.tap(find.text('+ Bài đang phát'));
    expect(taps, 1);
    expect(byIconButton('Bỏ thẻ Bài đang phát'), findsNothing);
  });

  testWidgets('attached × calls onRemove', (tester) async {
    var removed = 0;
    var taps = 0;
    await tester.pumpWidget(
      host(
        _chip(
          KContextChipState.attached,
          onTap: () => taps++,
          onRemove: () => removed++,
        ),
      ),
    );
    await tester.tap(byIconButton('Bỏ thẻ Bài đang phát'));
    expect(removed, 1);
    expect(taps, 0);
  });

  testWidgets('struck exposes its state in semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_chip(KContextChipState.struck)));
    final data = tester
        .getSemantics(find.bySemanticsLabel('Bài đang phát'))
        .getSemanticsData();
    expect(data.hint, 'Công cụ đang tắt');
    expect(byToggledState('Bài đang phát'), findsOneWidget);
    // Struck is still removable.
    expect(byIconButton('Bỏ thẻ Bài đang phát'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('attached is toggled on, suggested toggled off', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_chip(KContextChipState.attached)));
    expect(byToggledState('Bài đang phát'), findsOneWidget);
    await tester.pumpWidget(host(_chip(KContextChipState.suggested)));
    expect(byToggledState('Bài đang phát', on: false), findsOneWidget);
    handle.dispose();
  });

  testWidgets('height 32 on mobile and 28 on desktop', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_chip(KContextChipState.attached)));
    expect(tester.getSize(find.byType(KContextChip)).height, 32);
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_chip(KContextChipState.attached)));
    expect(tester.getSize(find.byType(KContextChip)).height, 28);
  });

  testWidgets('a long label is cut and the chip fits its parent', (
    tester,
  ) async {
    useWindow(tester, const Size(200, 800));
    await tester.pumpWidget(
      host(
        _chip(KContextChipState.attached, label: 'Một cái tên rất dài ' * 6),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(KContextChip)).width,
      lessThanOrEqualTo(200),
    );
  });

  for (final state in KContextChipState.values) {
    testWidgets('${state.name} has no overflow at 200 % text', (tester) async {
      useWindow(tester, const Size(300, 800));
      await tester.pumpWidget(
        host(_chip(state, label: 'Bài đang phát'), textScale: 2.0),
      );
      expect(tester.takeException(), isNull);
      if (state != KContextChipState.suggested) {
        expect(tester.getSize(find.byIcon(KIcons.info)), const Size(16, 16));
      }
    });
  }
}
