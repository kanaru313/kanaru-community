import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  testWidgets('is 52 x 32', (tester) async {
    await tester.pumpWidget(
      host(Center(child: KSwitch(value: false, onChanged: (_) {}))),
    );
    expect(tester.getSize(find.byType(KSwitch)), const Size(52, 32));
  });

  testWidgets('tap reports the opposite value', (tester) async {
    final seen = <bool>[];
    await tester.pumpWidget(
      host(Center(child: KSwitch(value: false, onChanged: seen.add))),
    );
    await tester.tap(find.byType(KSwitch));
    expect(seen, [true]);
  });

  testWidgets('locked ignores taps and is dimmed', (tester) async {
    await tester.pumpWidget(
      host(const Center(child: KSwitch(value: true, onChanged: null))),
    );
    await tester.tap(find.byType(KSwitch));
    final o = tester.widget<Opacity>(
      find.descendant(of: find.byType(KSwitch), matching: find.byType(Opacity)),
    );
    expect(o.opacity, 0.38);
  });

  testWidgets('Space and Enter toggle when focused', (tester) async {
    final seen = <bool>[];
    await tester.pumpWidget(
      host(Center(child: KSwitch(value: false, onChanged: seen.add))),
    );
    final focus = Focus.of(tester.element(find.byType(GestureDetector).first));
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(seen, [true, true]);
  });

  testWidgets('semantics are toggled and enabled', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Center(
          child: KSwitch(
            value: true,
            onChanged: (_) {},
            semanticLabel: 'Albums',
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(KSwitch)),
      matchesSemantics(
        label: 'Albums',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('value change animates, and is instant with reduced motion', (
    tester,
  ) async {
    Widget build(bool v, {bool reduce = false}) => host(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Center(
          child: KSwitch(value: v, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpWidget(build(false));
    await tester.pumpWidget(build(true));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    await tester.pumpWidget(build(false, reduce: true));
    await tester.pumpWidget(build(true, reduce: true));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
