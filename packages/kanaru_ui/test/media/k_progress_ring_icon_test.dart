import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/media/k_progress_ring_icon.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _ring({double? progress, bool held = false}) => Center(
  child: KProgressRingIcon(
    icon: KIcons.sleepTimerActive,
    progress: progress,
    held: held,
  ),
);

RingPainter? _painter(WidgetTester tester) {
  final paints = tester.widgetList<CustomPaint>(
    find.descendant(
      of: find.byType(KProgressRingIcon),
      matching: find.byType(CustomPaint),
    ),
  );
  for (final p in paints) {
    if (p.painter is RingPainter) return p.painter! as RingPainter;
  }
  return null;
}

void main() {
  testWidgets('progress value: ring 24 around icon 14, no dot', (tester) async {
    await tester.pumpWidget(host(_ring(progress: 0.5)));
    expect(tester.getSize(find.byType(KProgressRingIcon)), const Size(24, 24));
    expect(tester.widget<Icon>(find.byType(Icon)).size, 14);
    expect(_painter(tester)!.progress, 0.5);
    expect(find.byKey(const ValueKey('progress-ring-dot')), findsNothing);
  });

  testWidgets('progress is clamped and NaN is 0', (tester) async {
    await tester.pumpWidget(host(_ring(progress: 3)));
    expect(_painter(tester)!.progress, 1.0);
    await tester.pumpWidget(host(_ring(progress: double.nan)));
    expect(_painter(tester)!.progress, 0.0);
  });

  testWidgets('progress null: icon 24 and a 7 dot, no ring', (tester) async {
    await tester.pumpWidget(host(_ring()));
    expect(_painter(tester), isNull);
    expect(tester.widget<Icon>(find.byType(Icon)).size, 24);
    expect(
      tester.getSize(find.byKey(const ValueKey('progress-ring-dot'))),
      const Size(7, 7),
    );
  });

  testWidgets('held: ring and icon use onSurfaceVariant at 70 %', (
    tester,
  ) async {
    await tester.pumpWidget(host(_ring(progress: 0.5, held: true)));
    final scheme = Theme.of(tester.element(find.byType(KProgressRingIcon)))
        .colorScheme;
    final icon = tester.widget<Icon>(find.byType(Icon)).color!;
    expect(icon.a, closeTo(0.7, 0.01));
    expect(
      icon.withValues(alpha: 1),
      scheme.onSurfaceVariant.withValues(alpha: 1),
    );
    expect(_painter(tester)!.arc, icon);
  });

  testWidgets('decorative: no semantics node', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_ring(progress: 0.5)));
    expect(
      find.descendant(
        of: find.byType(KProgressRingIcon),
        matching: find.byType(Semantics),
      ),
      findsWidgets,
    );
    expect(tester.getSemantics(find.byType(KProgressRingIcon)).label, isEmpty);
    handle.dispose();
  });

  for (final v in hostVariants) {
    testWidgets('renders in ${v.$1}', (tester) async {
      await tester.pumpWidget(
        host(
          _ring(progress: 0.3),
          brightness: v.$2,
          textScale: v.$3,
          reduceMotion: true,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
