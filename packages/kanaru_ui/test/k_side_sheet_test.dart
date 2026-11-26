import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _contentKey = ValueKey('side-sheet-content');

Widget _content() => const SizedBox.expand(
  key: _contentKey,
  child: Column(children: [TextField(), TextField()]),
);

/// An opener that sits in a nested navigator narrower than the window, so a
/// sheet on the root navigator is seen reaching beyond it.
Widget _opener({
  double width = 400,
  FocusNode? returnFocus,
  bool adaptive = false,
}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: 300,
    height: 300,
    child: Navigator(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => Center(
          child: Focus(
            focusNode: returnFocus,
            child: TextButton(
              onPressed: () => adaptive
                  ? showKAdaptiveSheet<void>(
                      context,
                      builder: (_) => _content(),
                      returnFocus: returnFocus,
                    )
                  : showKSideSheet<void>(
                      context,
                      width: width,
                      builder: (_) => _content(),
                      returnFocus: returnFocus,
                    ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('short content still gets the full window height, at the edge', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showKSideSheet<void>(
              context,
              width: 400,
              builder: (_) => const Text('short', key: _contentKey),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await _open(tester);
    final sheet = tester.getRect(
      find
          .ancestor(
            of: find.byKey(_contentKey),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(sheet.top, 0);
    expect(sheet.bottom, 800);
    expect(sheet.right, 1300);
    expect(sheet.width, 400);
  });

  testWidgets('takes the width it is given', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_opener(width: 420)));
    await _open(tester);
    expect(tester.getSize(find.byKey(_contentKey)).width, 420);
    expect(tester.getSize(find.byKey(_contentKey)).height, 800);
  });

  testWidgets('docks to the window edge above a nested navigator', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_opener()));
    await _open(tester);
    final rect = tester.getRect(find.byKey(_contentKey));
    expect(rect.right, 1300, reason: 'not inside the 300 wide navigator');
    expect(rect.top, 0);
    expect(rect.bottom, 800);
  });

  testWidgets('Esc closes it', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_opener()));
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(_contentKey), findsNothing);
  });

  testWidgets('a tap on the scrim closes it, a tap inside does not', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_opener()));
    await _open(tester);
    await tester.tapAt(const Offset(1200, 400));
    await tester.pumpAndSettle();
    expect(find.byKey(_contentKey), findsOneWidget);
    await tester.tapAt(const Offset(100, 400));
    await tester.pumpAndSettle();
    expect(find.byKey(_contentKey), findsNothing);
  });

  testWidgets('focus goes back to the given node after it closes', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 800));
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(host(_opener(returnFocus: node)));
    await _open(tester);
    expect(node.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(node.hasFocus, isTrue);
  });

  testWidgets('Tab stays inside the sheet', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_opener()));
    await _open(tester);
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      var inside = false;
      FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
        if (e.widget.key == _contentKey) inside = true;
        return !inside;
      });
      expect(inside, isTrue, reason: 'Tab press ${i + 1}');
    }
  });

  testWidgets('slides in, and with animations off just appears', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      tester.getRect(find.byKey(_contentKey)).left,
      greaterThan(1300 - 400),
      reason: 'still sliding',
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_contentKey)).left, 1300 - 400);
  });

  testWidgets('reduced motion: no slide', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_opener(), reduceMotion: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    expect(tester.getRect(find.byKey(_contentKey)).left, 1300 - 400);
  });

  group('showKAdaptiveSheet', () {
    testWidgets('mobile shell: bottom sheet, also on a wide phone', (
      tester,
    ) async {
      for (final width in [400.0, 900.0]) {
        useWindow(tester, Size(width, 800));
        await tester.pumpWidget(host(_opener(adaptive: true)));
        await _open(tester);
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.byType(Dialog), findsNothing);
        expect(
          tester.getSize(find.byKey(_contentKey)).height,
          lessThanOrEqualTo(800 * 0.82),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('desktop shell: 400 wide side sheet', (tester) async {
      useWindow(tester, const Size(1300, 800));
      await tester.pumpWidget(host(_opener(adaptive: true)));
      await _open(tester);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.getSize(find.byKey(_contentKey)).width, 400);
    });

    testWidgets('swipe down closes the bottom sheet', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_opener(adaptive: true)));
      await _open(tester);
      await tester.drag(find.byType(BottomSheet), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(find.byKey(_contentKey), findsNothing);
    });
  });
}
