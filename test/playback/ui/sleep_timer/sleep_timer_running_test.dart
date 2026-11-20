import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/sleep_timer_state.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_number_field.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sleep_timer_modal_host.dart';

const _desktop = Size(1300, 800);

Finder _button(String label) => holding(KModalButton, label);

bool _enabled(WidgetTester tester, String label) =>
    tester.widget<KModalButton>(_button(label)).onPressed != null;

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
      expect(find.text('Đặt 45 phút'), findsOneWidget);
      expect(find.textContaining('Dừng lúc'), findsOneWidget);
      expect(find.text('−5 phút'), findsOneWidget);
      expect(find.text('+5 phút'), findsOneWidget);
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
      await tapVisible(tester, find.text('+5 phút'));
      await tapVisible(tester, find.text('−5 phút'));
      await tapVisible(tester, find.text('−5 phút'));
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

    testWidgets('−5 is off at 5 minutes or less, +5 at 720', (tester) async {
      final host = await pumpSleepModal(
        tester,
        initial: runningMinutes(remaining: const Duration(minutes: 5)),
      );
      await openSleepModal(tester);
      expect(_enabled(tester, '−5 phút'), isFalse);
      expect(_enabled(tester, '+5 phút'), isTrue);
      host.timer.set(runningMinutes(remaining: const Duration(minutes: 720)));
      await tester.pump();
      expect(_enabled(tester, '−5 phút'), isTrue);
      expect(_enabled(tester, '+5 phút'), isFalse);
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
      expect(find.text('−1 bài'), findsOneWidget);
      expect(find.text('+1 bài'), findsOneWidget);
      expect(find.text('Tạm dừng đếm'), findsNothing);
    });

    testWidgets('−1 and +1 call the timer; off at 1 and at 20', (tester) async {
      final host = await pumpSleepModal(tester, initial: runningTracks());
      await openSleepModal(tester);
      await tapVisible(tester, find.text('+1 bài'));
      await tapVisible(tester, find.text('−1 bài'));
      expect(host.timer.calls, ['addTracks:1', 'addTracks:-1']);
      host.timer.set(runningTracks(left: 1, total: 3));
      await tester.pump();
      expect(_enabled(tester, '−1 bài'), isFalse);
      expect(find.textContaining('bài này là bài cuối'), findsOneWidget);
      host.timer.set(runningTracks(left: 20, total: 20));
      await tester.pump();
      expect(_enabled(tester, '+1 bài'), isFalse);
      expect(_enabled(tester, '−1 bài'), isTrue);
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
      });
    }

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
      expect(focusedWithin(tester, _button('−5 phút')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      // −5 is off at 5 minutes: +5 is first.
      host.timer.set(runningMinutes(remaining: const Duration(minutes: 5)));
      await openSleepModal(tester);
      expect(focusedWithin(tester, _button('+5 phút')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      // End-of modes have no adjust buttons: Tắt hẹn giờ is first.
      host.timer.set(runningEndOf(SleepTimerMode.endOfAlbum));
      await openSleepModal(tester);
      expect(focusedWithin(tester, _button('Tắt hẹn giờ')), isTrue);
    });

    testWidgets('a focused −5 that turns off hands focus to +5', (
      tester,
    ) async {
      await pumpSleepModal(
        tester,
        size: _desktop,
        initial: runningMinutes(remaining: const Duration(minutes: 10)),
      );
      await openSleepModal(tester);
      expect(focusedWithin(tester, _button('−5 phút')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('5:00'), findsOneWidget);
      expect(_enabled(tester, '−5 phút'), isFalse);
      expect(focusedWithin(tester, _button('+5 phút')), isTrue);
    });

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
        expect(focusedWithin(tester, _button('−5 phút')), isTrue);
      },
    );
  });
}
