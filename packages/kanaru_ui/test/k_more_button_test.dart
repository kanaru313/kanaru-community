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
    await tester.tap(find.byType(KRowIconAction));
    expect(calls, [false]);
    await tester.longPress(find.byType(KRowIconAction));
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
    await tester.tap(find.byType(KRowIconAction));
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

  testWidgets('draws a 24 dp ⋮ in onSurfaceVariant outside a row', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        IconTheme(
          data: const IconThemeData(color: Colors.red),
          child: KMoreButton(tooltip: 'More', onPressed: ({required viaKeyboard}) {}),
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(KIcons.moreVert));
    expect(icon.size, 24);
    expect(
      icon.color,
      buildKanaruTheme(brightness: Brightness.light).colorScheme
          .onSurfaceVariant,
    );
  });

  testWidgets('a tap that follows a key press reports viaKeyboard false', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final calls = <bool>[];
    await tester.pumpWidget(
      host(
        KMoreButton(
          tooltip: 'More',
          onPressed: ({required viaKeyboard}) => calls.add(viaKeyboard),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.tap(find.byType(KRowIconAction));
    expect(calls, [true, false]);
  });
}
