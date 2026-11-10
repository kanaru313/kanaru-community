import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/ui/queue/queue_list.dart';
import 'package:kanaru/src/playback/ui/queue/queue_locate_button.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row_hooks.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'queue_test_support.dart';

const _list = QueueList(size: QueueRowSize.mobile);
final _button = find.byType(IconButton);

Finder get _locate => find.descendant(
  of: find.byType(QueueLocateButton),
  matching: find.byType(IconButton),
);

void main() {
  testWidgets('hidden while the current row is in view', (tester) async {
    await pumpFakeQueue(tester, _list, view: fakeView(50, current: 25));
    expect(_locate, findsNothing);
  });

  testWidgets('appears after a jump scroll, pointing the way', (tester) async {
    await pumpFakeQueue(tester, _list, view: fakeView(50, current: 25));
    await tester.drag(find.byType(ReorderableListView), const Offset(0, 5000));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_locate, findsOneWidget);
    expect(find.byIcon(KIcons.arrowDown), findsOneWidget);
    expect(tester.getSize(_locate), const Size.square(48));

    await tester.drag(find.byType(ReorderableListView), const Offset(0, -9000));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(KIcons.arrowUp), findsOneWidget);
  });

  testWidgets('it sits at the bottom right and has a tooltip', (tester) async {
    await pumpFakeQueue(tester, _list, view: fakeView(50, current: 25));
    await tester.drag(find.byType(ReorderableListView), const Offset(0, 5000));
    await tester.pump(const Duration(milliseconds: 500));
    final box = tester.getRect(_locate);
    expect(box.right, 400 - KSpace.x4);
    expect(box.bottom, 800 - KSpace.x4);
    expect(find.byTooltip('Go to current track'), findsOneWidget);
  });

  testWidgets('a tap scrolls back and the button goes away', (tester) async {
    await pumpFakeQueue(tester, _list, view: fakeView(50, current: 25));
    await tester.drag(find.byType(ReorderableListView), const Offset(0, 5000));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(_locate);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(_locate, findsNothing);
    // The current row is the second one from the top.
    expect(tester.getTopLeft(find.text('Song 25')).dy, lessThan(120));
  });

  testWidgets('rechecked when the current row advances out of view', (
    tester,
  ) async {
    final views = StreamController<QueueView>();
    addTearDown(views.close);
    await pumpFakeQueue(
      tester,
      _list,
      view: fakeView(50, current: 25),
      views: views.stream,
    );
    expect(_locate, findsNothing);
    final next = fakeView(50, current: 45);
    views.add(next);
    await tester.pump();
    await tester.pump();
    expect(_locate, findsOneWidget);
    expect(find.byIcon(KIcons.arrowDown), findsOneWidget);
    expect(_button, findsWidgets);
  });

  testWidgets('rechecked when the window shrinks', (tester) async {
    await pumpFakeQueue(tester, _list, view: fakeView(50, current: 25));
    expect(_locate, findsNothing);
    tester.view.physicalSize = const Size(400, 50);
    await tester.pump();
    await tester.pump();
    expect(_locate, findsOneWidget);
  });
}
