import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/selection/selection_bar.dart';
import 'package:kanaru/src/library/ui/selection/selection_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../browse/support/library_fixture.dart';
import '../menus/menu_pump.dart';
import '../support/library_harness.dart';
import '../support/ui_harness.dart';
import 'selection_support.dart';

/// Songs page with three songs selected and the panel open, one page pushed
/// on top of it so there is a page for the last Back to pop.
Future<LibraryHarness> _open(WidgetTester tester, {double width = 390}) async {
  final h = await pumpSelection(tester, width: width);
  final ids = await allIds(h);
  h.selection.addRange(ids.take(3));
  h.selection.setExpanded(true);
  h.router.push('/probe');
  await tester.pump(const Duration(milliseconds: 400));
  await h.settle(tester, rounds: 3);
  return h;
}

Future<void> _back(WidgetTester tester) async {
  expect(await tester.binding.handlePopRoute(), isTrue);
  await pumpMenu(tester);
}

void main() {
  testWidgets(
    'Back: the menu from the panel first, then the panel, then the page',
    (tester) async {
      final h = await _open(tester);
      await tester.tap(find.byTooltip('Options for the selection'));
      await pumpMenu(tester);
      expect(find.byType(BottomSheet), findsOneWidget);

      await _back(tester);
      expect(find.byType(BottomSheet), findsNothing);
      expect(h.selected.expanded, isTrue);
      expect(h.location, '/probe');

      await _back(tester);
      expect(h.selected.expanded, isFalse);
      expect(find.byType(SelectedSongRow), findsNothing);
      expect(h.location, '/probe');

      await _back(tester);
      expect(h.location, '/library/songs');
      // Back never clears the selection.
      expect(h.selected.ids, hasLength(3));
      expect(find.byType(KSelectionPanel), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('Back closes the sheet of a panel row before the panel', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(SelectedSongRow).first,
        matching: find.byIcon(KIcons.moreVert),
      ),
    );
    await pumpMenu(tester);
    expect(find.byType(BottomSheet), findsOneWidget);
    await _back(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(h.selected.expanded, isTrue);
    expect(find.byType(SelectedSongRow), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('Back closes a sort popover over the open panel first', (
    tester,
  ) async {
    final h = await pumpSelection(tester);
    h.selection.addRange((await allIds(h)).take(2));
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 3);
    await tester.tap(find.byTooltip('Sort'));
    await tester.pumpAndSettle();
    expect(find.text('Artist'), findsWidgets);
    final before = find.byType(ModalBarrier).evaluate().length;
    await _back(tester);
    expect(find.byType(ModalBarrier).evaluate().length, lessThan(before));
    expect(h.selected.expanded, isTrue);
    await _back(tester);
    expect(h.selected.expanded, isFalse);
    expect(h.selected.ids, hasLength(2));
    await unmountApp(tester);
  });

  testWidgets('Back with the panel closed leaves it to the page', (
    tester,
  ) async {
    final h = await _open(tester);
    h.selection.setExpanded(false);
    await tester.pump();
    await _back(tester);
    expect(h.location, '/library/songs');
    expect(h.selected.ids, hasLength(3));
    await unmountApp(tester);
  });

  testWidgets('Esc on desktop: dialog first, then the panel, never clear', (
    tester,
  ) async {
    final h = await _open(tester, width: 1280);
    await tester.tap(find.byTooltip('Options for the selection'));
    await pumpMenu(tester);
    expect(find.byType(Dialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMenu(tester);
    expect(find.byType(Dialog), findsNothing);
    expect(h.selected.expanded, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(h.selected.expanded, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(h.selected.ids, hasLength(3));
    expect(find.byType(KSelectionPanel), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Esc in a text field is the field\'s, not the panel\'s', (
    tester,
  ) async {
    final h = await pumpSelection(tester, width: 1280);
    h.selection.addRange((await allIds(h)).take(2));
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 3);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(h.selected.expanded, isTrue);
    await unmountApp(tester);
  });

  /// A single music folder `Music` with songs in `Album A` and a loose one,
  /// the Folders tab open, and the selection slot under it.
  Future<LibraryHarness> folders(WidgetTester tester) async {
    final h = await pumpLibrary(
      tester,
      initial: '/library/folders',
      selectionBar: const LibrarySelectionBar(),
    );
    final music = await h.addFolder('Music');
    for (final locator in [
      'Album A/01.flac',
      'Album A/02.flac',
      'loose.flac',
    ]) {
      await addLibraryTrack(
        h.db,
        source: music.sourceId,
        locator: locator,
        title: locator.split('/').last,
      );
    }
    await h.settle(tester, rounds: 4);
    return h;
  }

  testWidgets('Back: the open panel first, then up one folder level', (
    tester,
  ) async {
    final h = await folders(tester);
    await tester.tap(find.text('Album A'));
    await h.settle(tester, rounds: 4);
    final level = h.location;
    expect(level, contains('at='));
    await tester.longPress(find.text('01.flac'));
    await tester.tap(find.text('02.flac'));
    h.selection.setExpanded(true);
    await h.settle(tester, rounds: 3);
    expect(h.selected.ids, hasLength(2));

    await _back(tester);
    expect(h.selected.expanded, isFalse);
    expect(h.location, level);
    await h.settle(tester, rounds: 3);

    await _back(tester);
    await h.settle(tester, rounds: 3);
    expect(h.location, isNot(level));
    expect(h.selected.ids, hasLength(2));
    await unmountApp(tester);
  });

  testWidgets('Back: the open panel first, then the page filter field', (
    tester,
  ) async {
    final h = await folders(tester);
    h.selection.addRange((await allIds(h)).take(2));
    h.selection.setExpanded(true);
    await tester.tap(find.byTooltip('Filter'));
    await h.settle(tester, rounds: 3);
    expect(find.byType(TextField), findsOneWidget);

    await _back(tester);
    expect(h.selected.expanded, isFalse);
    expect(find.byType(TextField), findsOneWidget);

    await _back(tester);
    expect(find.byType(TextField), findsNothing);
    expect(h.selected.ids, hasLength(2));
    await unmountApp(tester);
  });
}
