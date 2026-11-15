import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  testWidgets('a tap reports viaKeyboard false and shows the tooltip', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final calls = <bool>[];
    await tester.pumpWidget(
      host(
        KMoreButton(
          tooltip: 'More',
          onPressed: ({required viaKeyboard}) {
            calls.add(viaKeyboard);
          },
        ),
      ),
    );
    await tester.tap(find.byType(KIconButton));
    expect(calls, [false]);
    await tester.longPress(find.byType(KIconButton));
    await tester.pumpAndSettle();
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('Enter on the focused button reports viaKeyboard true', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final calls = <bool>[];
    await tester.pumpWidget(
      host(
        KMoreButton(
          tooltip: 'More',
          onPressed: ({required viaKeyboard}) {
            calls.add(viaKeyboard);
          },
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls, [true]);
    // A later pointer press resets the answer.
    await tester.tap(find.byType(KIconButton));
    expect(calls, [true, false]);
  });

  for (final (name, key) in [
    ('Space', LogicalKeyboardKey.space),
    ('Select', LogicalKeyboardKey.select),
    ('numpad Enter', LogicalKeyboardKey.numpadEnter),
  ]) {
    testWidgets('$name on the focused button reports viaKeyboard true', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final calls = <bool>[];
      await tester.pumpWidget(
        host(
          KMoreButton(
            tooltip: 'More',
            onPressed: ({required viaKeyboard}) {
              calls.add(viaKeyboard);
            },
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pump();
      expect(calls, [true]);
    });
  }

  testWidgets('the button is a small icon with padding 8, no 48 dp box', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        Center(
          child: KMoreButton(
            tooltip: 'More',
            onPressed: ({required viaKeyboard}) {},
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(KIconButton)),
      const Size(KIconSize.sm + 16, KIconSize.sm + 16),
    );
    expect(
      tester.widget<KIconButton>(find.byType(KIconButton)).tooltip,
      'More',
    );
  });
}
