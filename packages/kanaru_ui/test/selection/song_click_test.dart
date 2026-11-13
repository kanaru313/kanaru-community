import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

void main() {
  Future<void> hold(WidgetTester tester, LogicalKeyboardKey key) async {
    await simulateKeyDownEvent(key);
    addTearDown(() => simulateKeyUpEvent(key));
  }

  testWidgets('a plain click plays, with or without a selection rule', (
    tester,
  ) async {
    expect(songClick(selecting: false), SongClick.play);
  });

  testWidgets('an existing selection makes a click toggle', (tester) async {
    expect(songClick(selecting: true), SongClick.toggle);
  });

  testWidgets('Ctrl toggles', (tester) async {
    await hold(tester, LogicalKeyboardKey.controlLeft);
    expect(songClick(selecting: false), SongClick.toggle);
  });

  testWidgets('Meta toggles', (tester) async {
    await hold(tester, LogicalKeyboardKey.metaLeft);
    expect(songClick(selecting: false), SongClick.toggle);
  });

  testWidgets('Shift selects a range and wins over Ctrl and a selection', (
    tester,
  ) async {
    await hold(tester, LogicalKeyboardKey.shiftLeft);
    expect(songClick(selecting: false), SongClick.range);
    await hold(tester, LogicalKeyboardKey.controlLeft);
    expect(songClick(selecting: true), SongClick.range);
  });
}
