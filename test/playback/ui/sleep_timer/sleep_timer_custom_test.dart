import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_number_field.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sleep_timer_modal_host.dart';

const _desktop = Size(1300, 800);

// Air between the caret and the unit label: field padding + gap above the
// unit + the line box below the digits. Dropping any one of the three fix
// parts (caret height, field padding, gap) leaves 8 to 11 dp.
const _caretGap = KSpace.x3;

Finder get _field => find.byType(TextField);
String get _fieldText =>
    (find.byType(TextField).evaluate().single.widget as TextField)
        .controller!
        .text;

Finder _step(IconData icon) =>
    find.byWidgetPredicate((w) => w is KStepButton && w.icon == icon);

bool _disabled(WidgetTester tester, Finder step) =>
    tester.widget<KStepButton>(step).onPressed == null;

Future<void> _openCustom(
  WidgetTester tester, [
  String entry = 'Tuỳ chỉnh…',
]) async {
  await openSleepModal(tester);
  await tapVisible(tester, find.text(entry));
}

void main() {
  testWidgets('opens with 45 minutes: title, number, unit, stop time, chips', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    expect(find.text('Tuỳ chỉnh'), findsOneWidget);
    expect(_fieldText, '45');
    expect(find.text('phút'), findsOneWidget);
    expect(find.textContaining('Dừng lúc'), findsOneWidget);
    for (final c in ['15 ph', '30 ph', '45 ph', '1 giờ', '1 giờ 30']) {
      expect(find.text(c), findsOneWidget);
    }
    expect(
      tester.getSemantics(holding(KChip, '45 ph')),
      isSemantics(isSelected: true),
    );
    expect(find.text('Huỷ'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);
    // Not running: no "Đang chạy" chip.
    expect(find.textContaining('Đang chạy'), findsNothing);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('the caret of the number keeps a gap above the unit label '
        '(text x$scale)', (tester) async {
      await pumpSleepModal(tester, textScale: scale);
      await _openCustom(tester);
      await tester.tap(_field);
      await tester.pump();
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      final render = editable.renderEditable;
      final local = render.getLocalRectForCaret(
        TextPosition(offset: _fieldText.length),
      );
      final caret = Rect.fromPoints(
        render.localToGlobal(local.topLeft),
        render.localToGlobal(local.bottomRight),
      );
      final unit = tester.getRect(find.text('phút'));
      expect(unit.top - caret.bottom, greaterThanOrEqualTo(_caretGap));
      // The caret is as tall as the scaled digits (an unscaled one is shorter).
      final fontSize = Theme.of(tester.element(_field))
          .textTheme
          .displayLarge!
          .fontSize!;
      expect(caret.height, closeTo(scale * fontSize, 1));
    });
  }

  testWidgets('Bắt đầu starts 45 minutes, closes and says it once', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester);
    await _openCustom(tester);
    await tapVisible(tester, find.text('Bắt đầu'));
    expect(host.timer.calls, ['startMinutes:45']);
    expect(host.announced, hasLength(1));
    expect(
      host.announced.single,
      startsWith('Đã hẹn giờ ngủ 45 phút, dừng lúc'),
    );
    expect(modalOpen, findsNothing);
    expect(host.pops.pops, 1);
  });

  testWidgets('Số bài: 3 tracks, its unit and stop text, starts the tracks', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester);
    await _openCustom(tester, 'Sau số bài…');
    expect(_fieldText, '3');
    expect(find.text('bài'), findsOneWidget);
    expect(find.text('Tạm dừng sau 3 bài, tính cả bài này'), findsOneWidget);
    for (final c in ['1', '2', '3', '5', '10']) {
      expect(find.widgetWithText(KChip, c), findsOneWidget);
    }
    await tapVisible(tester, find.text('Bắt đầu'));
    expect(host.timer.calls, ['startTracks:3']);
    expect(host.announced.single, 'Đã hẹn giờ ngủ, tạm dừng sau 3 bài');
  });

  testWidgets('the Phút / Số bài segments keep each kind\'s own number', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    await tapVisible(tester, find.text('Số bài'));
    expect(_fieldText, '3');
    await tapVisible(tester, _step(KIcons.add));
    expect(_fieldText, '4');
    await tapVisible(tester, find.text('Phút'));
    expect(_fieldText, '45');
    await tapVisible(tester, find.text('Số bài'));
    expect(_fieldText, '4');
  });

  testWidgets('− / + step 5 minutes, from an off-step value too', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    await tapVisible(tester, _step(KIcons.add));
    expect(_fieldText, '50');
    await tapVisible(tester, _step(KIcons.remove));
    await tapVisible(tester, _step(KIcons.remove));
    expect(_fieldText, '40');
    expect(find.textContaining('Dừng lúc'), findsOneWidget);
    await tester.enterText(_field, '24');
    await tester.pump();
    await tapVisible(tester, _step(KIcons.add));
    expect(_fieldText, '29');
  });

  testWidgets('− and + turn off at the ends of the range', (tester) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    await tester.enterText(_field, '3');
    await tester.pump();
    await tester.enterText(_field, '1');
    await tester.pump();
    expect(_disabled(tester, _step(KIcons.remove)), isTrue);
    expect(_disabled(tester, _step(KIcons.add)), isFalse);
    await tester.enterText(_field, '5000');
    await tester.pump();
    expect(_fieldText, '720');
    expect(_disabled(tester, _step(KIcons.add)), isTrue);
    expect(_disabled(tester, _step(KIcons.remove)), isFalse);
  });

  testWidgets('a typed number above the ruler stays; unit shows hours', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    await tester.enterText(_field, '240');
    await tester.pump();
    expect(find.text('phút · 4 giờ'), findsOneWidget);
    expect(_fieldText, '240');
    expect(tester.widget<KRuler>(find.byType(KRuler)).value, 180);
  });

  testWidgets('chips set the value and the lit chip follows the number', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    await tapVisible(tester, find.text('30 ph'));
    expect(_fieldText, '30');
    expect(
      tester.getSemantics(holding(KChip, '30 ph')),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(holding(KChip, '45 ph')),
      isSemantics(isSelected: false),
    );
    await tester.enterText(_field, '31');
    await tester.pump();
    expect(
      tester.getSemantics(holding(KChip, '30 ph')),
      isSemantics(isSelected: false),
    );
  });

  testWidgets('the ruler moves the number', (tester) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    tester.widget<KRuler>(find.byType(KRuler)).onChanged(20);
    await tester.pump();
    expect(_fieldText, '20');
  });

  testWidgets('empty or 0 then Done restores the shown number and starts it', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester);
    await _openCustom(tester);
    await tester.enterText(_field, '0');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(host.timer.calls, ['startMinutes:45']);
    expect(modalOpen, findsNothing);
  });

  testWidgets('a pasted 1000 is 720 and starts 720', (tester) async {
    final host = await pumpSleepModal(tester);
    await _openCustom(tester);
    await tester.enterText(_field, '1000');
    await tester.pump();
    expect(_fieldText, '720');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(host.timer.calls, ['startMinutes:720']);
  });

  testWidgets('← goes back to the tiles; Huỷ closes without starting', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester);
    await _openCustom(tester);
    await tapVisible(tester, backButton);
    expect(find.text('Chạm một mục là bắt đầu ngay.'), findsOneWidget);
    await tapVisible(tester, find.text('Tuỳ chỉnh…'));
    await tapVisible(tester, find.text('Huỷ'));
    expect(modalOpen, findsNothing);
    expect(host.timer.calls, isEmpty);
  });

  testWidgets('a running timer shows the Đang chạy chip, which goes back', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester, initial: runningMinutes());
    await openSleepModal(tester);
    await tapVisible(tester, find.text('Đổi…'));
    // Đổi… of minutes: custom, filled with the minutes left rounded up.
    expect(find.text('Tuỳ chỉnh'), findsOneWidget);
    expect(_fieldText, '24');
    expect(find.text('Đang chạy · 23:41'), findsOneWidget);
    await tapVisible(tester, find.text('Đang chạy · 23:41'));
    expect(find.text('Tắt hẹn giờ'), findsOneWidget);
    // Starting here replaces the running timer.
    await tapVisible(tester, find.text('Đổi…'));
    await tapVisible(tester, find.text('Bắt đầu'));
    expect(host.timer.calls, ['startMinutes:24']);
  });

  group('desktop', () {
    testWidgets('first focus is the number with all of it selected', (
      tester,
    ) async {
      await pumpSleepModal(tester, size: _desktop);
      await _openCustom(tester);
      expect(focusedWithin(tester, find.byType(SleepTimerNumberField)), isTrue);
      final selection = tester.widget<TextField>(_field).controller!.selection;
      expect(selection.start, 0);
      expect(selection.end, 2);
    });

    testWidgets(
      'Esc closes from the custom screen; the shell handler is not run',
      (tester) async {
        final host = await pumpSleepModal(tester, size: _desktop);
        await _openCustom(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(modalOpen, findsNothing);
        expect(host.shellEscapes, 0);
        expect(host.timer.calls, isEmpty);
        // Focus goes back to the button that opened it.
        expect(host.opener.hasFocus, isTrue);
      },
    );

    testWidgets('a focused − that turns off hands focus to +', (tester) async {
      await pumpSleepModal(tester, size: _desktop);
      await _openCustom(tester);
      await tester.enterText(_field, '6');
      await tester.pump();
      final minus = tester.widget<KStepButton>(_step(KIcons.remove));
      minus.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_fieldText, '1');
      expect(_disabled(tester, _step(KIcons.remove)), isTrue);
      expect(focusedWithin(tester, _step(KIcons.add)), isTrue);
    });

    testWidgets('Enter on the ruler starts', (tester) async {
      final host = await pumpSleepModal(tester, size: _desktop);
      await _openCustom(tester);
      // The ruler makes its own focus node: reach it through Tab.
      var guard = 0;
      while (!focusedWithin(tester, find.byType(KRuler)) && guard++ < 12) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(focusedWithin(tester, find.byType(KRuler)), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(host.timer.calls, ['startMinutes:46']);
    });
  });

  testWidgets('mobile: the number is not focused when the screen opens', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    expect(focusedWithin(tester, find.byType(SleepTimerNumberField)), isFalse);
  });

  testWidgets('with the keyboard up the number and Bắt đầu stay reachable', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await _openCustom(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final visibleBottom = tester.view.physicalSize.height - 300;
    await tester.ensureVisible(find.text('Bắt đầu'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Bắt đầu')).bottom,
      lessThanOrEqualTo(visibleBottom),
    );
    await tester.ensureVisible(_field);
    await tester.pumpAndSettle();
    expect(tester.getRect(_field).bottom, lessThanOrEqualTo(visibleBottom));
    await tapVisible(tester, find.text('Bắt đầu'));
    expect(modalOpen, findsNothing);
  });

  testWidgets('tracks Đổi… keeps the tracks left', (tester) async {
    await pumpSleepModal(tester, initial: runningTracks(left: 2));
    await openSleepModal(tester);
    await tapVisible(tester, find.text('Đổi…'));
    expect(_fieldText, '2');
    expect(find.text('bài'), findsOneWidget);
    expect(find.text('Đang chạy · 2 bài'), findsOneWidget);
  });
}
