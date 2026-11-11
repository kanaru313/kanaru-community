import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/now_playing_auto_hide.dart';
import 'package:material_ui/material_ui.dart';

Future<AutoHideController> _pump(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  final chrome = AutoHideController();
  addTearDown(chrome.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: AutoHideRegion(
            controller: chrome,
            child: Column(
              children: [
                AutoHide(
                  controller: chrome,
                  child: const SizedBox(
                    height: 64,
                    child: Center(child: Text('header')),
                  ),
                ),
                const Expanded(child: SizedBox(key: ValueKey('body'))),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return chrome;
}

double _opacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

void main() {
  testWidgets('hides after 3 seconds without movement', (tester) async {
    final chrome = await _pump(tester);
    chrome.poke();
    await tester.pump(const Duration(milliseconds: 2900));
    expect(chrome.visible.value, isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    expect(chrome.visible.value, isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_opacity(tester), 0);
  });

  testWidgets('a pointer move shows it again and restarts the countdown', (
    tester,
  ) async {
    final chrome = await _pump(tester);
    chrome.poke();
    await tester.pump(const Duration(seconds: 4));
    expect(chrome.visible.value, isFalse);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(300, 300));
    await mouse.moveTo(const Offset(320, 320));
    await tester.pump();
    expect(chrome.visible.value, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(chrome.visible.value, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(chrome.visible.value, isFalse);
    await mouse.removePointer();
  });

  testWidgets('pointer moves closer than 300 ms count as one', (tester) async {
    final chrome = await _pump(tester);
    chrome.poke();
    await tester.pump(const Duration(milliseconds: 2500));
    chrome.poke(throttled: true);
    await tester.pump(const Duration(milliseconds: 100));
    chrome.poke(throttled: true);
    await tester.pump(const Duration(milliseconds: 100));
    // The second move was ignored: only the first restarted the countdown.
    await tester.pump(const Duration(milliseconds: 2800));
    expect(chrome.visible.value, isFalse);
  });

  testWidgets('pinned: it stays until the pin is given back', (tester) async {
    final chrome = await _pump(tester);
    chrome.pin();
    await tester.pump(const Duration(seconds: 10));
    expect(chrome.visible.value, isTrue);
    chrome.unpin();
    await tester.pump(const Duration(milliseconds: 3100));
    expect(chrome.visible.value, isFalse);
  });

  testWidgets('the pointer resting on the header pins it', (tester) async {
    final chrome = await _pump(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(400, 30));
    await tester.pump();
    await mouse.moveTo(const Offset(402, 30));
    await tester.pump(const Duration(seconds: 6));
    expect(chrome.visible.value, isTrue);
    await mouse.removePointer();
  });

  testWidgets('a hidden header ignores the pointer but keeps its place', (
    tester,
  ) async {
    final chrome = await _pump(tester);
    final before = tester.getTopLeft(find.byKey(const ValueKey('body')));
    chrome.poke();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.byKey(const ValueKey('body'))), before);
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .descendant(
                  of: find.byType(AutoHide),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );
  });

  testWidgets('leaving the window hides it at once, unless pinned', (
    tester,
  ) async {
    final chrome = await _pump(tester);
    chrome.hideNow();
    expect(chrome.visible.value, isFalse);
    chrome.poke();
    chrome.pin();
    chrome.hideNow();
    expect(chrome.visible.value, isTrue);
  });

  testWidgets('reduced motion: no fade', (tester) async {
    final chrome = await _pump(tester, reduceMotion: true);
    chrome.poke();
    await tester.pump(const Duration(seconds: 4));
    expect(chrome.visible.value, isFalse);
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration,
      Duration.zero,
    );
    expect(_opacity(tester), 0);
  });
}
