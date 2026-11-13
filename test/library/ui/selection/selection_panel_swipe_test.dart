import 'dart:ui' show GestureSettings;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/selection/selection_row.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/library_harness.dart';
import '../support/ui_harness.dart';
import 'selection_support.dart';

Finder _row(int i) => find.byType(SelectedSongRow).at(i);

/// Selects the first [n] songs, in title order, and opens the panel.
Future<(LibraryHarness, List<TrackId>)> _openPanel(
  WidgetTester tester,
  int n,
) async {
  final h = await pumpSelection(tester);
  final ids = (await allIds(h)).take(n).toList();
  h.selection.addRange(ids);
  await tester.pump();
  await tester.tap(find.byTooltip('Show the selected songs'));
  await h.settle(tester, rounds: 3);
  return (h, ids);
}

/// Drags the row [i] by [fraction] of its width from its left third, then lets
/// the slide-out and the removal finish.
Future<void> _swipe(
  WidgetTester tester,
  int i,
  double fraction, {
  double slope = 0,
}) async {
  final box = tester.getRect(_row(i));
  final dx = box.width * fraction;
  await tester.dragFrom(
    Offset(box.left + box.width * 0.3, box.center.dy),
    Offset(dx, dx * slope),
  );
  await tester.pump();
  await tester.pump(KMotion.fast * 2);
  await tester.pump();
}

void main() {
  testWidgets('a swipe past 70 % deselects the song after the slide', (
    tester,
  ) async {
    final (h, ids) = await _openPanel(tester, 3);
    final box = tester.getRect(_row(1));
    final gesture = await tester.startGesture(
      Offset(box.left + box.width * 0.1, box.center.dy),
    );
    await gesture.moveBy(Offset(box.width * 0.72, 0));
    await gesture.up();
    await tester.pump();
    // The slide plays before the song leaves the selection.
    expect(h.selected.ids, hasLength(3));
    await tester.pump(KMotion.fast * 2);
    await tester.pump();
    expect(h.selected.ids, [ids[0], ids[2]]);
    expect(find.byType(SelectedSongRow), findsNWidgets(2));
    await unmountApp(tester);
  });

  testWidgets('a swipe of half the width brings the row back', (tester) async {
    final (h, ids) = await _openPanel(tester, 3);
    await _swipe(tester, 1, 0.5);
    await tester.pumpAndSettle();
    expect(h.selected.ids, ids);
    expect(find.byType(SelectedSongRow), findsNWidgets(3));
    await unmountApp(tester);
  });

  testWidgets('dragging the handle reorders and deselects nothing', (
    tester,
  ) async {
    final (h, ids) = await _openPanel(tester, 3);
    final handle = find.descendant(
      of: _row(0),
      matching: find.byType(KDragHandle),
    );
    final extent = tester.getRect(_row(0)).height;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    for (var k = 0; k < 8; k++) {
      await gesture.moveBy(Offset(0, extent * 0.25));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.selected.ids, hasLength(3));
    expect(h.selected.ids.first, isNot(ids.first));
    expect(h.selected.ids.toSet(), ids.toSet());
    await unmountApp(tester);
  });

  testWidgets('swiping away the last row closes the panel', (tester) async {
    final (h, _) = await _openPanel(tester, 1);
    await _swipe(tester, 0, 0.8);
    expect(h.selected.isEmpty, isTrue);
    expect(find.byType(KSelectionPanel), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a song deselected elsewhere mid-swipe is not selected again', (
    tester,
  ) async {
    final (h, ids) = await _openPanel(tester, 3);
    final box = tester.getRect(_row(1));
    final gesture = await tester.startGesture(
      Offset(box.left + box.width * 0.1, box.center.dy),
    );
    await gesture.moveBy(Offset(box.width * 0.8, 0));
    await gesture.up();
    await tester.pump();
    h.selection.remove(ids[1]);
    await tester.pump(KMotion.fast * 2);
    await tester.pump();
    expect(h.selected.ids, [ids[0], ids[2]]);
    await unmountApp(tester);
  });

  testWidgets('the row offers "Deselect" to assistive tech and it works', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (h, ids) = await _openPanel(tester, 2);
    final node = tester.getSemantics(
      find.descendant(of: _row(0), matching: find.byType(Semantics)).first,
    );
    // The node carrying the custom action sits on the swipe wrapper.
    SemanticsNode? holder;
    CustomSemanticsAction? action;
    void visit(SemanticsNode n) {
      final data = n.getSemanticsData();
      final actions = data.customSemanticsActionIds;
      for (final id in actions ?? const <int>[]) {
        final a = CustomSemanticsAction.getAction(id);
        if (a?.label == 'Deselect' && holder == null) {
          holder = n;
          action = a;
        }
      }
      n.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    var root = node;
    while (root.parent != null) {
      root = root.parent!;
    }
    visit(root);
    expect(holder, isNotNull);
    holder!.owner!.performAction(
      holder!.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(action!),
    );
    await tester.pump();
    await tester.pump(KMotion.fast * 2);
    await tester.pump();
    // The first row in tree order is the one that was asked to leave.
    expect(h.selected.ids, [ids[1]]);
    semantics.dispose();
    await unmountApp(tester);
  });

  testWidgets('a 30 degree swipe deselects instead of scrolling the list', (
    tester,
  ) async {
    tester.view.gestureSettings = const GestureSettings(physicalTouchSlop: 8);
    addTearDown(tester.view.resetGestureSettings);
    final (h, _) = await _openPanel(tester, 12);
    final list = find.byType(Scrollable).last;
    final before = tester.state<ScrollableState>(list).position.pixels;
    final count = h.selected.ids.length;
    await _swipe(tester, 0, 0.75, slope: 0.58);
    expect(h.selected.ids, hasLength(count - 1));
    expect(tester.state<ScrollableState>(list).position.pixels, before);
    await unmountApp(tester);
  });

  testWidgets('closing the panel during the slide still deselects the song', (
    tester,
  ) async {
    final (h, ids) = await _openPanel(tester, 3);
    final box = tester.getRect(_row(1));
    final gesture = await tester.startGesture(
      Offset(box.left + box.width * 0.1, box.center.dy),
    );
    await gesture.moveBy(Offset(box.width * 0.72, 0));
    await gesture.up();
    await tester.pump();
    h.selection.setExpanded(false);
    await tester.pump();
    expect(find.byType(SelectedSongRow), findsNothing);
    await tester.pump(KMotion.fast * 2);
    await tester.pump();
    expect(h.selected.ids, [ids[0], ids[2]]);
    await unmountApp(tester);
  });

  testWidgets('a sideways mouse drag on the handle deselects nothing', (
    tester,
  ) async {
    final (h, ids) = await _openPanel(tester, 3);
    final handle = find.descendant(
      of: _row(1),
      matching: find.byType(KDragHandle),
    );
    final width = tester.getRect(_row(1)).width;
    final gesture = await tester.startGesture(
      tester.getCenter(handle),
      kind: PointerDeviceKind.mouse,
    );
    for (var k = 0; k < 8; k++) {
      await gesture.moveBy(Offset(-width * 0.1, 0));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await gesture.up();
    await tester.pump(KMotion.fast * 2);
    await tester.pumpAndSettle();
    expect(h.selected.ids, ids);
    await unmountApp(tester);
  });
}
