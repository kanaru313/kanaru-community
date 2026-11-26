import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

const _short = 'Kanaru scans these folders and every subfolder.';
final _long = List.filled(30, 'Một câu giải thích khá dài.').join(' ');

Widget _icon(String message, {String? title}) => Center(
  child: KHelpIcon(message: message, tooltip: 'Giải thích', title: title),
);

void main() {
  testWidgets('a short message opens a popover on tap and closes on Esc', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_icon(_short)));
    expect(find.text(_short), findsNothing);
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    expect(find.text(_short), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(_short), findsNothing);
  });

  testWidgets('a tap outside closes the popover', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_icon(_short)));
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 700));
    await tester.pumpAndSettle();
    expect(find.text(_short), findsNothing);
  });

  testWidgets('a long message opens a sheet with a close button on mobile', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_icon(_long, title: 'Thư mục nhạc')));
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Thư mục nhạc'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('desktop: a long message opens an anchored panel, no sheet', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_icon(_long, title: 'Thư mục nhạc')));
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Thư mục nhạc'), findsOneWidget);
    expect(find.text(_long), findsOneWidget);
    expect(
      tester.getSize(find.byType(Material).last).width,
      lessThanOrEqualTo(KHelpIcon.panelWidth),
    );
  });

  testWidgets('desktop: hover opens, leaving closes, click pins', (
    tester,
  ) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_icon(_short)));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(5, 5));
    await mouse.moveTo(tester.getCenter(byIconButton('Giải thích')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text(_short), findsOneWidget);
    await mouse.moveTo(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text(_short), findsNothing);
    // Click pins: it survives the pointer leaving.
    await mouse.moveTo(tester.getCenter(byIconButton('Giải thích')));
    await mouse.down(tester.getCenter(byIconButton('Giải thích')));
    await mouse.up();
    await mouse.moveTo(const Offset(5, 5));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text(_short), findsOneWidget);
  });

  testWidgets('keyboard focus + Enter opens it', (tester) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_icon(_short)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(_short), findsOneWidget);
  });

  testWidgets('animations off: the popover is there at once', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_icon(_short), reduceMotion: true));
    await tester.tap(byIconButton('Giải thích'));
    await tester.pump();
    expect(find.text(_short), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity).last).opacity, 1);
  });

  testWidgets('200 % text: a long Vietnamese popover does not overflow', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 640));
    await tester.pumpWidget(host(_icon(_long.substring(0, 130)), textScale: 2));
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Esc reaches other handlers while closed; an open popover consumes it',
    (tester) async {
      useWindow(tester, const Size(1300, 800));
      var seen = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          Focus(
            focusNode: node,
            autofocus: true,
            onKeyEvent: (_, e) {
              if (e is KeyDownEvent &&
                  e.logicalKey == LogicalKeyboardKey.escape) {
                seen++;
              }
              return KeyEventResult.ignored;
            },
            child: _icon(_short),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(seen, 1);
      await tester.tap(byIconButton('Giải thích'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(_short), findsNothing);
      expect(seen, 1, reason: 'Esc that closes the popover is consumed');
    },
  );

  testWidgets('scrolling the page closes the popover', (tester) async {
    useWindow(tester, const Size(400, 800));
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      host(
        ListView(
          controller: scroll,
          children: [_icon(_short), const SizedBox(height: 2000)],
        ),
      ),
    );
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    expect(find.text(_short), findsOneWidget);
    scroll.jumpTo(100);
    await tester.pumpAndSettle();
    expect(find.text(_short), findsNothing);
  });

  testWidgets('resizing the window closes the popover', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_icon(_short)));
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(500, 800);
    await tester.pumpAndSettle();
    expect(find.text(_short), findsNothing);
  });

  testWidgets('an open popover whose page goes away disposes cleanly', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      host(
        ListView(
          controller: scroll,
          children: [_icon(_short), const SizedBox(height: 2000)],
        ),
      ),
    );
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(const SizedBox()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(scroll.hasClients, isFalse);
  });

  testWidgets('after closing, scrolling no longer touches the icon', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      host(
        ListView(
          controller: scroll,
          children: [_icon(_short), const SizedBox(height: 2000)],
        ),
      ),
    );
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    scroll.jumpTo(100);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(_short), findsNothing);
  });

  testWidgets('mobile: a pinned popover leaves a focused field alone', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final field = FocusNode();
    addTearDown(field.dispose);
    await tester.pumpWidget(
      host(
        Column(
          children: [
            TextField(focusNode: field, autofocus: true),
            _icon(_short),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    expect(find.text(_short), findsOneWidget);
    expect(field.hasFocus, isTrue);
  });

  testWidgets('desktop: Tab out of a pinned panel closes it', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(
      host(Column(children: [_icon(_short), const TextField()])),
    );
    await tester.tap(byIconButton('Giải thích'));
    await tester.pumpAndSettle();
    expect(find.text(_short), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text(_short), findsNothing);
  });

  testWidgets('desktop: Esc after keyboard open returns focus to the icon', (
    tester,
  ) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_icon(_short)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final icon = FocusManager.instance.primaryFocus;
    expect(icon, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(_short), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, isNot(icon));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(_short), findsNothing);
    expect(FocusManager.instance.primaryFocus, icon);
  });
}
