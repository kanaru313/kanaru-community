import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../menus/menu_pump.dart';
import '../support/detail_fixture.dart';
import '../support/ui_harness.dart';
import 'selection_support.dart';

Finder _tile(int i) => find.byType(SongTile).at(i);

bool _tinted(WidgetTester tester, int i) => tester
    .widget<KMediaCard>(
      find.descendant(of: _tile(i), matching: find.byType(KMediaCard)),
    )
    .selected;

Future<void> _modifiedTap(
  WidgetTester tester,
  Finder target,
  LogicalKeyboardKey modifier,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.tap(target);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

void main() {
  testWidgets('a long press selects the song with a tick and tints it', (
    tester,
  ) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final playback = FakePlaybackCommands();
    final h = await pumpSelection(tester, playback: playback);
    await tester.longPress(_tile(1));
    await tester.pump();
    expect(h.selected.ids, hasLength(1));
    // The framework's own long-press feedback is a plain vibrate; ours is the
    // light selection tick.
    expect(haptics, contains('HapticFeedbackType.selectionClick'));
    expect(_tinted(tester, 1), isTrue);
    expect(_tinted(tester, 0), isFalse);
    expect(playback.calls, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('while something is selected a tap toggles and never plays', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await pumpSelection(tester, playback: playback);
    await tester.longPress(_tile(0));
    await tester.pump();
    await tester.tap(_tile(2));
    await tester.pump();
    expect(h.selected.ids, hasLength(2));
    await tester.tap(_tile(2));
    await tester.pump();
    expect(h.selected.ids, hasLength(1));
    expect(playback.calls, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('Ctrl+click toggles without playing', (tester) async {
    final playback = FakePlaybackCommands();
    final h = await pumpSelection(tester, width: 1280, playback: playback);
    await _modifiedTap(tester, _tile(1), LogicalKeyboardKey.controlLeft);
    expect(h.selected.ids, hasLength(1));
    expect(_tinted(tester, 1), isTrue);
    await _modifiedTap(tester, _tile(1), LogicalKeyboardKey.controlLeft);
    expect(h.selected.isEmpty, isTrue);
    expect(playback.calls, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('Shift+click selects the rows between the last click and this', (
    tester,
  ) async {
    final h = await pumpSelection(tester, width: 1280);
    final order = [
      for (final t in tester.widgetList<SongTile>(find.byType(SongTile)))
        t.info.id,
    ];
    await _modifiedTap(tester, _tile(1), LogicalKeyboardKey.controlLeft);
    await _modifiedTap(tester, _tile(4), LogicalKeyboardKey.shiftLeft);
    expect(h.selected.ids.toSet(), order.sublist(1, 5).toSet());
    // The next range grows from the row just clicked.
    await _modifiedTap(tester, _tile(2), LogicalKeyboardKey.shiftLeft);
    expect(h.selected.ids.toSet(), order.sublist(1, 5).toSet());
    await unmountApp(tester);
  });

  testWidgets('Shift+click follows the order on screen, not the id order', (
    tester,
  ) async {
    final h = await pumpSelection(tester, width: 1280);
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setSort(
          BrowseList.songs,
          const SortSpec(SortCriterion.title, descending: true),
        );
    await h.settle(tester);
    final order = [
      for (final t in tester.widgetList<SongTile>(find.byType(SongTile)))
        t.info.id,
    ];
    await _modifiedTap(tester, _tile(0), LogicalKeyboardKey.controlLeft);
    await _modifiedTap(tester, _tile(2), LogicalKeyboardKey.shiftLeft);
    expect(h.selected.ids.toSet(), order.sublist(0, 3).toSet());
    await unmountApp(tester);
  });

  testWidgets('Ctrl+A selects the songs of the page with nothing focused', (
    tester,
  ) async {
    final h = await pumpSelection(tester, width: 1280);
    final ids = await allIds(h);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(h.selected.ids.toSet(), ids.toSet());
    await unmountApp(tester);
  });

  testWidgets('Ctrl+A is quiet under a dialog and in a text field', (
    tester,
  ) async {
    final h = await pumpSelection(tester, width: 1280);
    // In the filter field Ctrl+A selects its text.
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(h.selected.isEmpty, isTrue);
    await tester.tap(find.byTooltip('Close filter'));
    await tester.pumpAndSettle();

    // Under a menu dialog the page is not the target either.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(_tile(0)));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(
      find.descendant(of: _tile(0), matching: find.byIcon(KIcons.moreVert)),
    );
    await pumpMenu(tester);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(h.selected.isEmpty, isTrue);
    await unmountApp(tester);
  });

  testWidgets('the selection survives going to an album; a tap there toggles', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await pumpSelection(tester, playback: playback);
    await tester.longPress(_tile(0));
    await tester.pump();
    h.router.push('/library/albums/${albumId('Album 1', 'Artist 1')}');
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(h.selected.ids, hasLength(1));
    // The panel is still there, and a tap on a song of the page selects it.
    expect(find.text('1 song'), findsOneWidget);
    await tester.tap(find.text('Album 1 2'));
    await tester.pump();
    expect(h.selected.ids, hasLength(2));
    expect(playback.calls, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('right click on a selected song opens the selection menu', (
    tester,
  ) async {
    final h = await pumpSelection(tester, width: 1280);
    final ids = await allIds(h);
    h.selection.addRange(ids.take(3));
    await tester.pump();
    Future<void> rightClick(Finder target) async {
      final gesture = await tester.startGesture(
        tester.getCenter(target),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await gesture.up();
      await pumpMenu(tester);
    }

    // A song that is not selected keeps its own menu, the selection stays.
    await rightClick(_tile(5));
    expect(find.text('3 songs selected'), findsNothing);
    expect(find.text('Go to artist'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMenu(tester);

    await rightClick(_tile(1));
    expect(find.text('3 songs selected'), findsOneWidget);
    await unmountApp(tester);
  });
}
