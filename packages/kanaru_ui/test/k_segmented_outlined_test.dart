import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _segments = [
  KSegment(value: 'under', label: 'Dưới dòng'),
  KSegment(value: 'replace', label: 'Thay dòng'),
];

Widget _compact({
  String value = 'under',
  ValueChanged<String>? onChanged,
  bool disabled = false,
}) => Align(
  alignment: Alignment.topLeft,
  child: KSegmentedOutlined<String>(
    segments: _segments,
    value: value,
    onChanged: disabled ? null : (onChanged ?? (_) {}),
    semanticLabel: 'Hiển thị',
  ),
);

Color? _fill(WidgetTester tester, String label) {
  final box = tester.widget<AnimatedContainer>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return (box.decoration! as BoxDecoration).color;
}

void main() {
  regularTests();
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('chosen segment reports selected in one exclusive group '
        '($name)', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_compact(), brightness: brightness, textScale: scale),
      );
      expect(
        tester.getSemantics(find.text('Dưới dòng')),
        isSemantics(
          label: 'Dưới dòng',
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Thay dòng')),
        isSemantics(
          label: 'Thay dòng',
          isButton: true,
          isSelected: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('only the chosen segment is tinted, no check mark', (
    tester,
  ) async {
    await tester.pumpWidget(host(_compact()));
    final scheme = Theme.of(tester.element(find.text('Dưới dòng'))).colorScheme;
    expect(_fill(tester, 'Dưới dòng'), scheme.secondaryContainer);
    expect(_fill(tester, 'Thay dòng')!.a, 0);
    expect(find.byType(KCheckMark), findsNothing);
  });

  testWidgets('tap chooses and reports the value', (tester) async {
    String? chosen;
    await tester.pumpWidget(host(_compact(onChanged: (v) => chosen = v)));
    await tester.tap(find.text('Thay dòng'));
    expect(chosen, 'replace');
  });

  testWidgets('the pill is 24 dp, the tap area 48: a tap above it selects', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(host(_compact(onChanged: (v) => chosen = v)));
    final pill = tester.getRect(
      find
          .ancestor(
            of: find.text('Thay dòng'),
            matching: find.byType(AnimatedContainer),
          )
          .last,
    );
    expect(pill.height, kSegmentedCompactHeight);
    expect(
      tester.getSize(find.byType(KSegmentedOutlined<String>)).height,
      kSegmentedCompactHit,
    );
    await tester.tapAt(Offset(pill.center.dx, pill.top - 10));
    expect(chosen, 'replace');
    chosen = null;
    await tester.tapAt(Offset(pill.center.dx, pill.bottom + 10));
    expect(chosen, 'replace');
  });

  testWidgets('selecting does not change the label weight', (tester) async {
    await tester.pumpWidget(host(_compact()));
    FontWeight? weight(String t) =>
        tester.widget<Text>(find.text(t)).style?.fontWeight;
    expect(weight('Dưới dòng'), weight('Thay dòng'));
  });

  testWidgets('onChanged null: dimmed, inert, not focusable', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_compact(disabled: true)));
    expect(
      tester.widget<Opacity>(find.byType(Opacity).first).opacity,
      lessThan(1),
    );
    expect(
      tester.getSemantics(find.text('Thay dòng')),
      isSemantics(
        label: 'Thay dòng',
        isButton: true,
        isSelected: false,
        isInMutuallyExclusiveGroup: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('grows with the text scale', (tester) async {
    await tester.pumpWidget(host(_compact(), textScale: 2));
    expect(
      tester.getSize(find.byType(KSegmentedOutlined<String>)).height,
      greaterThanOrEqualTo(kSegmentedCompactHit),
    );
  });
}

Widget _regular({
  String value = 'a',
  ValueChanged<String>? onChanged,
  bool lockOthers = false,
}) => Align(
  alignment: Alignment.topLeft,
  child: KSegmentedOutlined<String>(
    size: KSegmentedOutlinedSize.regular,
    segments: [
      const KSegment(value: 'a', label: 'Bài này'),
      KSegment(value: 'b', label: 'Hàng đợi', enabled: !lockOthers),
      KSegment(value: 'c', label: 'Mọi bài', enabled: !lockOthers),
    ],
    value: value,
    onChanged: onChanged ?? (_) {},
  ),
);

void regularTests() {
  testWidgets('regular: 36 dp pill in a 48 dp tap area, full width, tinted '
      'chosen segment without a check', (tester) async {
    await tester.pumpWidget(host(_regular()));
    final pill = tester.getRect(
      find
          .ancestor(
            of: find.text('Bài này'),
            matching: find.byType(AnimatedContainer),
          )
          .last,
    );
    expect(pill.height, kSegmentedRegularHeight);
    final size = tester.getSize(find.byType(KSegmentedOutlined<String>));
    expect(size.height, kSegmentedCompactHit);
    expect(size.width, 800);
    final scheme = Theme.of(tester.element(find.text('Bài này'))).colorScheme;
    expect(_fill(tester, 'Bài này'), scheme.secondaryContainer);
    expect(_fill(tester, 'Hàng đợi')!.a, 0);
    expect(find.byType(KCheckMark), findsNothing);
    expect(find.byIcon(KIcons.check), findsNothing);
  });

  testWidgets('regular: a disabled segment is dimmed and inert', (
    tester,
  ) async {
    String? chosen;
    await tester.pumpWidget(
      host(_regular(lockOthers: true, onChanged: (v) => chosen = v)),
    );
    final dim = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('Mọi bài'), matching: find.byType(Opacity))
          .first,
    );
    expect(dim.opacity, lessThan(1));
    await tester.tap(find.text('Mọi bài'));
    expect(chosen, isNull);
    await tester.tap(find.text('Bài này'));
    expect(chosen, 'a');
  });
}
