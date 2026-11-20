import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/sleep_timer_state.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sleep_timer_modal_host.dart';

const _desktop = Size(1300, 800);

void main() {
  group('open', () {
    testWidgets('on the tiles when no timer runs', (tester) async {
      await pumpSleepModal(tester);
      await openSleepModal(tester);
      expect(find.text('Chạm một mục là bắt đầu ngay.'), findsOneWidget);
    });

    testWidgets('on the running screen when a timer runs', (tester) async {
      await pumpSleepModal(tester, initial: runningTracks());
      await openSleepModal(tester);
      expect(find.text('Tắt hẹn giờ'), findsOneWidget);
    });

    testWidgets('a scrim tap closes without changing anything', (tester) async {
      final host = await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(modalOpen, findsNothing);
      expect(host.timer.calls, isEmpty);
      expect(host.announced, isEmpty);
      expect(host.timer.state.active, isTrue);
    });

    testWidgets('a phone gets a bottom sheet', (tester) async {
      await pumpSleepModal(tester);
      await openSleepModal(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('a wide window gets a dialog', (tester) async {
      await pumpSleepModal(tester, size: _desktop);
      await openSleepModal(tester);
      expect(find.byType(BottomSheet), findsNothing);
      expect(modalOpen, findsOneWidget);
    });
  });

  group('closing', () {
    testWidgets('the timer ending by itself closes the running screen once', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      host.timer.set(const SleepTimerState.off());
      await tester.pumpAndSettle();
      expect(modalOpen, findsNothing);
      expect(host.pops.pops, 1);
      expect(host.announced, ['Hẹn giờ ngủ đã hết, nhạc đã tạm dừng']);
    });

    testWidgets(
      'the timer ending does not close the tiles or the custom screen',
      (tester) async {
        final host = await pumpSleepModal(tester, initial: runningMinutes());
        await openSleepModal(tester);
        await tapVisible(tester, find.text('Đổi…'));
        host.timer.set(const SleepTimerState.off());
        await tester.pumpAndSettle();
        expect(find.text('Tuỳ chỉnh'), findsOneWidget);
        expect(find.textContaining('Đang chạy'), findsNothing);
        await tapVisible(tester, backButton);
        expect(find.text('Chạm một mục là bắt đầu ngay.'), findsOneWidget);
        expect(host.pops.pops, 0);
        expect(host.announced, isEmpty);
      },
    );

    testWidgets('a covered modal closes when it is current again, once', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      final context = tester.element(find.byKey(SleepModalHost.openKey));
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (_) => const AlertDialog(content: Text('over')),
      );
      await tester.pumpAndSettle();
      host.timer.set(const SleepTimerState.off());
      await tester.pumpAndSettle();
      // The dialog on top is untouched; the sleep timer is still beneath it.
      expect(find.text('over'), findsOneWidget);
      expect(host.pops.pops, 0);
      Navigator.of(context, rootNavigator: true).pop();
      await tester.pumpAndSettle();
      expect(find.text('over'), findsNothing);
      expect(modalOpen, findsNothing);
      // One for the dialog, one for the modal.
      expect(host.pops.pops, 2);
    });

    testWidgets('the track going away closes the modal', (tester) async {
      final host = await pumpSleepModal(tester);
      await openSleepModal(tester);
      await host.ui.run(tester, host.ui.h.c.clearQueue);
      await tester.pumpAndSettle();
      expect(modalOpen, findsNothing);
      expect(host.pops.pops, 1);
    });

    testWidgets('Tắt hẹn giờ pops once even though the timer turns off', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, initial: runningTracks());
      await openSleepModal(tester);
      await tapVisible(tester, find.text('Tắt hẹn giờ'));
      expect(host.pops.pops, 1);
      expect(host.announced, ['Đã tắt hẹn giờ ngủ']);
    });

    testWidgets('Tắt hẹn giờ keeps the running screen while the route leaves', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      await tester.tap(find.text('Tắt hẹn giờ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(host.timer.state.active, isFalse);
      // Still mid-animation: the clock and the controls are still built.
      expect(modalOpen, findsOneWidget);
      expect(find.text('Tạm dừng đếm'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(modalOpen, findsNothing);
    });

    testWidgets('closing hands focus back to the opener on desktop', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, size: _desktop);
      await openSleepModal(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(host.opener.hasFocus, isTrue);
    });
  });

  group('focus', () {
    testWidgets('mobile: nothing takes focus on open or on a switch', (
      tester,
    ) async {
      await pumpSleepModal(tester, initial: runningMinutes());
      await openSleepModal(tester);
      expect(focusedWithin(tester, holding(KStepButton, '−5')), isFalse);
      await tapVisible(tester, find.text('Đổi…'));
      expect(focusedWithin(tester, find.byType(TextField)), isFalse);
    });

    testWidgets('desktop: Esc closes from the tiles; the shell is not run', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, size: _desktop);
      await openSleepModal(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(modalOpen, findsNothing);
      expect(host.shellEscapes, 0);
    });
  });

  group('layout', () {
    for (final (name, size, scale) in [
      ('320 x 640', const Size(320, 640), 1.0),
      ('320 x 640 at 200 %', const Size(320, 640), 2.0),
      ('400 x 800 at 200 %', const Size(400, 800), 2.0),
      ('desktop at 200 %', _desktop, 2.0),
    ]) {
      testWidgets('every screen fits without overflow: $name', (tester) async {
        final host = await pumpSleepModal(tester, size: size, textScale: scale);
        await openSleepModal(tester);
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text('Tuỳ chỉnh…'));
        expect(tester.takeException(), isNull);
        await tapVisible(tester, find.text('Số bài'));
        expect(tester.takeException(), isNull);
        host.timer.set(
          runningMinutes(
            remaining: const Duration(hours: 2, minutes: 5, seconds: 9),
          ),
        );
        await tester.pumpAndSettle();
        await tapVisible(tester, find.textContaining('Đang chạy'));
        expect(tester.takeException(), isNull);
        host.timer.set(runningTracks());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        host.timer.set(runningEndOf(SleepTimerMode.endOfAlbum));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('dark theme: every screen builds', (tester) async {
      final host = await pumpSleepModal(
        tester,
        brightness: Brightness.dark,
        initial: runningMinutes(),
      );
      await openSleepModal(tester);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('Đổi…'));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, backButton);
      expect(tester.takeException(), isNull);
      host.timer.set(const SleepTimerState.off());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion: the modal is there after one frame', (
      tester,
    ) async {
      await pumpSleepModal(tester, reduceMotion: true);
      await tester.tap(find.byKey(SleepModalHost.openKey));
      await tester.pump();
      await tester.pump();
      expect(modalOpen, findsOneWidget);
      expect(find.text('Chạm một mục là bắt đầu ngay.'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump();
      expect(modalOpen, findsNothing);
    });
  });
}
