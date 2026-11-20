import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/sleep_timer_state.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_number_field.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sleep_timer_modal_host.dart';

const _desktop = Size(1300, 800);

Finder _button(String label) => holding(KModalButton, label);

/// The round −5 / +5 / −1 / +1 button by its text.
Finder _side(String text) => holding(KStepButton, text);

bool _sideEnabled(WidgetTester tester, String text) =>
    tester.widget<KStepButton>(_side(text)).onPressed != null;

/// A quick-add chip by its text ("+10 ph").
Finder _chip(String text) => holding(KChip, text);

bool _chipEnabled(WidgetTester tester, String text) =>
    tester.widget<KChip>(_chip(text)).onTap != null;

void main() {
  testWidgets('opens on the running screen when a timer runs', (tester) async {
    await pumpSleepModal(tester, initial: runningMinutes());
    await openSleepModal(tester);
    expect(find.text('Tắt hẹn giờ'), findsOneWidget);
    expect(find.text('Chạm một mục là bắt đầu ngay.'), findsNothing);
  });

  group('minutes', () {
    testWidgets('label, clock, row and the buttons', (tester) async {
      await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      expect(find.text('Ngủ sau'), findsOneWidget);
      expect(find.text('23:41'), findsOneWidget);
      expect(find.text('Đặt 45 phút'), findsNothing);
      expect(find.textContaining('Dừng lúc'), findsOneWidget);
      expect(_side('−5'), findsOneWidget);
      expect(_side('+5'), findsOneWidget);
      // One line: −5, the clock and +5 share a row.
      expect(
        tester.getCenter(_side('−5')).dy,
        closeTo(tester.getCenter(find.text('23:41')).dy, 1),
      );
      expect(
        tester.getCenter(_side('+5')).dy,
        closeTo(tester.getCenter(find.text('23:41')).dy, 1),
      );
      expect(find.text('Tạm dừng đếm'), findsOneWidget);
      expect(find.text('Tắt hẹn giờ'), findsOneWidget);
      expect(find.text('Đổi…'), findsOneWidget);
    });

    testWidgets('from an hour the clock shows hours', (tester) async {
      await pumpSleepModal(
        tester,
        initial: runningMinutes(
          remaining: const Duration(hours: 2, minutes: 5, seconds: 9),
        ),
      );
      await openSleepModal(tester);
      expect(find.text('2:05:09'), findsOneWidget);
    });

    testWidgets('the status for a screen reader is minute precise, not live', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      final status = find.bySemanticsLabel('Ngủ sau 24 phút');
      expect(status, findsOneWidget);
      expect(tester.getSemantics(status), isSemantics(isLiveRegion: false));
      semantics.dispose();
    });

    testWidgets('−5 and +5 change the time; the labels are the long ones', (
      tester,
    ) async {
      final host = await pumpSleepModal(
        tester,
        initial: runningMinutes(remaining: const Duration(minutes: 20)),
      );
      await openSleepModal(tester);
      await tapVisible(tester, _side('+5'));
      await tapVisible(tester, _side('−5'));
      await tapVisible(tester, _side('−5'));
      expect(host.timer.calls, [
        'addMinutes:5',
        'addMinutes:-5',
        'addMinutes:-5',
      ]);
      expect(find.text('15:00'), findsOneWidget);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Thêm 5 phút'), findsOneWidget);
      expect(find.bySemanticsLabel('Bớt 5 phút'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      '−5 above 5 minutes, −1 at 5 or less, off at 1; +5 off at 720',
      (tester) async {
        final host = await pumpSleepModal(
          tester,
          initial: runningMinutes(remaining: const Duration(minutes: 6)),
        );
        await openSleepModal(tester);
        expect(_side('−5'), findsOneWidget);
        expect(_sideEnabled(tester, '−5'), isTrue);
        host.timer.set(runningMinutes(remaining: const Duration(minutes: 5)));
        await tester.pump();
        expect(_side('−5'), findsNothing);
        expect(_sideEnabled(tester, '−1'), isTrue);
        expect(_sideEnabled(tester, '+5'), isTrue);
        host.timer.set(runningMinutes(remaining: const Duration(minutes: 1)));
        await tester.pump();
        expect(_sideEnabled(tester, '−1'), isFalse);
        host.timer.set(runningMinutes(remaining: const Duration(minutes: 720)));
        await tester.pump();
        expect(_sideEnabled(tester, '−5'), isTrue);
        expect(_sideEnabled(tester, '+5'), isFalse);
      },
    );

    testWidgets('−1 takes one minute off and says so', (tester) async {
      final host = await pumpSleepModal(
        tester,
        initial: runningMinutes(remaining: const Duration(minutes: 3)),
      );
      await openSleepModal(tester);
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Bớt 1 phút'), findsOneWidget);
      semantics.dispose();
      await tapVisible(tester, _side('−1'));
      expect(host.timer.calls.last, 'addMinutes:-1');
      expect(find.text('2:00'), findsOneWidget);
    });

    testWidgets('quick-add chips: one line under the bar, each adds its '
        'minutes and is off past 720', (tester) async {
      final host = await pumpSleepModal(
        tester,
        initial: runningMinutes(remaining: const Duration(minutes: 20)),
      );
      await openSleepModal(tester);
      final row = tester.getRect(find.textContaining('Dừng lúc'));
      final pause = tester.getRect(_button('Tạm dừng đếm'));
      final tops = {
        for (final c in ['+10 ph', '+15 ph', '+30 ph', '+1 giờ'])
          tester.getTopLeft(_chip(c)).dy,
      };
      expect(tops, hasLength(1), reason: 'chips share one line');
      // Under the bar and its text row, above the pause button.
      expect(tops.single, greaterThan(row.bottom));
      expect(tester.getRect(_chip('+1 giờ')).bottom, lessThan(pause.top));
      expect(tester.getSize(_chip('+10 ph')).height, 40);
      await tapVisible(tester, _chip('+10 ph'));
      await tapVisible(tester, _chip('+1 giờ'));
      await tapVisible(tester, _chip('+30 ph'));
      await tapVisible(tester, _chip('+15 ph'));
      expect(host.timer.calls, [
        'addMinutes:10',
        'addMinutes:60',
        'addMinutes:30',
        'addMinutes:15',
      ]);
      final semantics = tester.ensureSemantics();
      for (final label in [
        'Thêm 10 phút',
        'Thêm 15 phút',
        'Thêm 30 phút',
        'Thêm 1 giờ',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      expect(find.bySemanticsLabel('+10 ph'), findsNothing);
      semantics.dispose();
      // 700 left: +10 fits (710), +30 and +1 giờ pass 720.
      host.timer.set(runningMinutes(remaining: const Duration(minutes: 700)));
      await tester.pump();
      expect(_chipEnabled(tester, '+10 ph'), isTrue);
      expect(_chipEnabled(tester, '+15 ph'), isTrue);
      expect(_chipEnabled(tester, '+30 ph'), isFalse);
      expect(_chipEnabled(tester, '+1 giờ'), isFalse);
      host.timer.set(runningMinutes(remaining: const Duration(minutes: 720)));
      await tester.pump();
      expect(_chipEnabled(tester, '+10 ph'), isFalse);
    });

    testWidgets('the old row of two wide −5 / +5 buttons is gone', (
      tester,
    ) async {
      await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      expect(find.text('−5 phút'), findsNothing);
      expect(find.text('+5 phút'), findsNothing);
      expect(tester.getSize(_side('−5')), const Size(48, 48));
    });

    testWidgets('pause counting holds the clock and says so once', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      await tapVisible(tester, find.text('Tạm dừng đếm'));
      expect(host.timer.calls, ['pauseCounting']);
      expect(host.announced, ['Đã tạm dừng đếm']);
      // The label of the clock and the button now both say what is next.
      expect(find.text('Tạm dừng đếm'), findsOneWidget);
      expect(find.text('Tiếp tục đếm'), findsOneWidget);
      expect(find.text('Đã tạm dừng đếm'), findsOneWidget);
      await tapVisible(tester, find.text('Tiếp tục đếm'));
      expect(host.timer.calls, ['pauseCounting', 'resumeCounting']);
      expect(host.announced, ['Đã tạm dừng đếm', 'Đã tiếp tục đếm']);
      expect(find.text('Tạm dừng đếm'), findsOneWidget);
      expect(find.text('Tiếp tục đếm'), findsNothing);
    });

    testWidgets('held: the clock is labelled, the row says so', (tester) async {
      await pumpSleepModal(tester, initial: runningMinutes(held: true));
      await openSleepModal(tester);
      expect(find.text('Tạm dừng đếm'), findsNWidgets(1));
      expect(find.text('Đã tạm dừng đếm'), findsOneWidget);
      expect(find.text('Tiếp tục đếm'), findsOneWidget);
      expect(find.text('Ngủ sau'), findsNothing);
      expect(find.textContaining('Dừng lúc'), findsNothing);
    });

    testWidgets('Đổi… opens the custom screen filled with the minutes left', (
      tester,
    ) async {
      await pumpSleepModal(
        tester,
        initial: runningMinutes(
          remaining: const Duration(minutes: 9, seconds: 1),
        ),
      );
      await openSleepModal(tester);
      await tapVisible(tester, find.text('Đổi…'));
      expect(find.text('Tuỳ chỉnh'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '10',
      );
    });
  });

  group('tracks', () {
    testWidgets('label, count, row and the buttons', (tester) async {
      await pumpSleepModal(tester, initial: runningTracks());
      await openSleepModal(tester);
      expect(find.text('Tạm dừng sau'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Bài đang phát tính là một'), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
      expect(_side('−1'), findsOneWidget);
      expect(_side('+1'), findsOneWidget);
      expect(find.text('Tạm dừng đếm'), findsNothing);
      expect(find.text('+10 ph'), findsNothing);
    });

    testWidgets('−1 and +1 call the timer; off at 1 and at 20', (tester) async {
      final host = await pumpSleepModal(tester, initial: runningTracks());
      await openSleepModal(tester);
      await tapVisible(tester, _side('+1'));
      await tapVisible(tester, _side('−1'));
      expect(host.timer.calls, ['addTracks:1', 'addTracks:-1']);
      host.timer.set(runningTracks(left: 1, total: 3));
      await tester.pump();
      expect(_sideEnabled(tester, '−1'), isFalse);
      expect(find.textContaining('bài này là bài cuối'), findsOneWidget);
      host.timer.set(runningTracks(left: 20, total: 20));
      await tester.pump();
      expect(_sideEnabled(tester, '+1'), isFalse);
      expect(_sideEnabled(tester, '−1'), isTrue);
    });

    testWidgets('Đổi… opens the custom screen on Số bài', (tester) async {
      await pumpSleepModal(tester, initial: runningTracks(left: 4));
      await openSleepModal(tester);
      await tapVisible(tester, find.text('Đổi…'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '4',
      );
      expect(find.text('bài'), findsOneWidget);
    });
  });

  group('end of', () {
    for (final (mode, word, left) in [
      (SleepTimerMode.endOfTrack, 'bài này', 'còn 2:48'),
      (SleepTimerMode.endOfAlbum, 'album này', 'còn 4 bài · 14 phút'),
      (SleepTimerMode.endOfQueue, 'hàng đợi', 'còn 7 bài · 29 phút'),
    ]) {
      testWidgets('$mode: word, what is left, queue kept, no buttons', (
        tester,
      ) async {
        await pumpSleepModal(tester, initial: runningEndOf(mode));
        await openSleepModal(tester);
        expect(find.text('Tạm dừng khi hết'), findsOneWidget);
        expect(find.text(word), findsOneWidget);
        expect(find.text(left), findsOneWidget);
        expect(find.text('hàng đợi vẫn giữ'), findsOneWidget);
        expect(find.text('Tắt hẹn giờ'), findsOneWidget);
        expect(find.byType(KStepButton), findsNothing);
        expect(find.byType(KChip), findsNothing);
      });
    }

    testWidgets('end of album under repeat one: stops after this one', (
      tester,
    ) async {
      await pumpSleepModal(
        tester,
        initial: runningEndOf(SleepTimerMode.endOfAlbum),
        repeatsOne: true,
      );
      await openSleepModal(tester);
      expect(find.text('album này'), findsOneWidget);
      expect(find.text('Đang lặp một bài · dừng sau bài này'), findsOneWidget);
      expect(find.textContaining('còn 4 bài'), findsNothing);
    });

    testWidgets('Đổi… shows the tiles with the running card', (tester) async {
      await pumpSleepModal(
        tester,
        initial: runningEndOf(SleepTimerMode.endOfQueue),
      );
      await openSleepModal(tester);
      await tapVisible(tester, find.text('Đổi…'));
      expect(find.text('Chạm một mục là bắt đầu ngay.'), findsOneWidget);
      expect(
        find.text('Đang chạy · Tạm dừng khi hết hàng đợi'),
        findsOneWidget,
      );
    });
  });

  testWidgets('Tắt hẹn giờ cancels, closes once and says so once', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester, initial: runningMinutes());
    await openSleepModal(tester);
    await tapVisible(tester, find.text('Tắt hẹn giờ'));
    expect(host.timer.calls, ['cancel']);
    expect(host.announced, ['Đã tắt hẹn giờ ngủ']);
    expect(host.pops.pops, 1);
    expect(modalOpen, findsNothing);
  });

  group('desktop focus', () {
    testWidgets('first focus is the first enabled control', (tester) async {
      final host = await pumpSleepModal(
        tester,
        size: _desktop,
        initial: runningMinutes(),
      );
      await openSleepModal(tester);
      expect(focusedWithin(tester, _side('−5')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      // −1 is off at 1 minute: +5 is first.
      host.timer.set(runningMinutes(remaining: const Duration(minutes: 1)));
      await openSleepModal(tester);
      expect(focusedWithin(tester, _side('+5')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      // End-of modes have no adjust buttons: Tắt hẹn giờ is first.
      host.timer.set(runningEndOf(SleepTimerMode.endOfAlbum));
      await openSleepModal(tester);
      expect(focusedWithin(tester, _button('Tắt hẹn giờ')), isTrue);
    });

    testWidgets('a focused − keeps focus from −5 to −1, then hands it to +5', (
      tester,
    ) async {
      await pumpSleepModal(
        tester,
        size: _desktop,
        initial: runningMinutes(remaining: const Duration(minutes: 10)),
      );
      await openSleepModal(tester);
      expect(focusedWithin(tester, _side('−5')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // 5:00: the same button is now −1 and still focused.
      expect(find.text('5:00'), findsOneWidget);
      expect(_sideEnabled(tester, '−1'), isTrue);
      expect(focusedWithin(tester, _side('−1')), isTrue);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
      }
      expect(find.text('1:00'), findsOneWidget);
      expect(_sideEnabled(tester, '−1'), isFalse);
      expect(focusedWithin(tester, _side('+5')), isTrue);
    });

    testWidgets(
      'a focused quick-add chip that turns off hands focus to pause',
      (tester) async {
        final host = await pumpSleepModal(
          tester,
          size: _desktop,
          initial: runningMinutes(remaining: const Duration(minutes: 20)),
        );
        await openSleepModal(tester);
        final chip = find.ancestor(
          of: find.text('+1 giờ'),
          matching: find.byType(KChip),
        );
        Focus.of(tester.element(find.text('+1 giờ'))).requestFocus();
        await tester.pump();
        host.timer.set(runningMinutes(remaining: const Duration(minutes: 700)));
        await tester.pump();
        expect(tester.widget<KChip>(chip).enabled, isFalse);
        expect(focusedWithin(tester, _button('Tạm dừng đếm')), isTrue);
      },
    );

    testWidgets('pause and resume keep focus on the same button', (
      tester,
    ) async {
      await pumpSleepModal(tester, size: _desktop, initial: runningMinutes());
      await openSleepModal(tester);
      tester
          .widget<KModalButton>(_button('Tạm dừng đếm'))
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(focusedWithin(tester, _button('Tiếp tục đếm')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(focusedWithin(tester, _button('Tạm dừng đếm')), isTrue);
    });

    testWidgets('Đổi… moves focus to the number of the new screen', (
      tester,
    ) async {
      await pumpSleepModal(tester, size: _desktop, initial: runningMinutes());
      await openSleepModal(tester);
      await tester.tap(find.text('Đổi…'));
      await tester.pumpAndSettle();
      expect(focusedWithin(tester, find.byType(SleepTimerNumberField)), isTrue);
    });

    testWidgets(
      'from the custom screen the Đang chạy chip moves focus to the first running control',
      (tester) async {
        await pumpSleepModal(tester, size: _desktop, initial: runningMinutes());
        await openSleepModal(tester);
        await tester.tap(find.text('Đổi…'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Đang chạy'));
        await tester.pumpAndSettle();
        expect(focusedWithin(tester, _side('−5')), isTrue);
      },
    );
  });
}
