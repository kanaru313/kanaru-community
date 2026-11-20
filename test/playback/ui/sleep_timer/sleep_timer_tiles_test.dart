import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/sleep_timer_state.dart';
import 'package:kanaru/src/playback/state/sleep_estimates.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'sleep_timer_modal_host.dart';

const _desktop = Size(1300, 800);

void main() {
  testWidgets('shows the title, the hint, the sections and no running card', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await openSleepModal(tester);
    expect(modalOpen, findsOneWidget);
    expect(find.text('Chạm một mục là bắt đầu ngay.'), findsOneWidget);
    expect(find.text('Sau một khoảng'), findsOneWidget);
    expect(find.text('Theo bài'), findsOneWidget);
    for (final t in ['15 phút', '30 phút', '45 phút', '1 giờ', '1 giờ 30']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.textContaining('đến '), findsNWidgets(5));
    expect(find.text('Tuỳ chỉnh…'), findsOneWidget);
    expect(find.text('còn 2:48'), findsOneWidget);
    expect(find.text('còn 4 bài'), findsOneWidget);
    expect(find.text('còn 7 bài · 29 phút'), findsOneWidget);
    expect(find.text('Sau số bài…'), findsOneWidget);
    expect(find.textContaining('Đang chạy'), findsNothing);
    expect(find.text('Huỷ'), findsNothing);
    expect(find.bySemanticsLabel('Huỷ'), findsNothing);
  });

  group('end of album under repeat one', () {
    const repeatText = 'Đang lặp một bài · dừng sau bài này';

    testWidgets('the row says it stops after this one, no track count', (
      tester,
    ) async {
      await pumpSleepModal(tester, repeatsOne: true);
      await openSleepModal(tester);
      expect(find.text(repeatText), findsOneWidget);
      expect(find.text('còn 4 bài'), findsNothing);
      expect(find.text('Hết album này'), findsOneWidget);
    });

    testWidgets('follows repeat mode changes while open', (tester) async {
      final runs = StreamController<AlbumRun?>();
      addTearDown(runs.close);
      AlbumRun run({required bool one}) => AlbumRun(
        tracks: one ? 1 : 4,
        restDuration: Duration.zero,
        noAlbum: false,
        capped: false,
        repeatsOne: one,
      );
      await pumpSleepModal(tester, albumRuns: runs.stream);
      await openSleepModal(tester);
      runs.add(run(one: false));
      await tester.pump();
      await tester.pump();
      expect(find.text('còn 4 bài'), findsOneWidget);
      runs.add(run(one: true));
      await tester.pump();
      await tester.pump();
      expect(find.text(repeatText), findsOneWidget);
      expect(find.text('còn 4 bài'), findsNothing);
      runs.add(run(one: false));
      await tester.pump();
      await tester.pump();
      expect(find.text('còn 4 bài'), findsOneWidget);
      expect(find.text(repeatText), findsNothing);
    });
  });

  group('tile columns', () {
    int perRow(WidgetTester tester) {
      final top = tester.getTopLeft(find.byType(KStartTile).first).dy;
      return tester
          .widgetList<KStartTile>(find.byType(KStartTile))
          .map((t) => tester.getTopLeft(find.byWidget(t)).dy)
          .where((y) => y == top)
          .length;
    }

    testWidgets('phone: 3 columns, two rows, no icon on "Tuỳ chỉnh…"', (
      tester,
    ) async {
      await pumpSleepModal(tester);
      await openSleepModal(tester);
      expect(perRow(tester), 3);
      expect(find.byType(KStartTile), findsNWidgets(6));
      expect(
        find.descendant(
          of: find.byType(KStartTile),
          matching: find.byType(Icon),
        ),
        findsNothing,
      );
    });

    testWidgets('a 320 phone (tile area under 360): 2 columns', (tester) async {
      await pumpSleepModal(tester, size: const Size(320, 800));
      await openSleepModal(tester);
      expect(perRow(tester), 2);
    });

    testWidgets('a 393 phone: 3 columns', (tester) async {
      await pumpSleepModal(tester, size: const Size(393, 800));
      await openSleepModal(tester);
      expect(perRow(tester), 3);
    });

    testWidgets('200 % text: one column', (tester) async {
      await pumpSleepModal(tester, textScale: 2);
      await openSleepModal(tester);
      expect(perRow(tester), 1);
    });

    testWidgets('desktop: 3 columns', (tester) async {
      await pumpSleepModal(tester, size: _desktop);
      await openSleepModal(tester);
      expect(perRow(tester), 3);
    });
  });

  testWidgets('tiles say they start: label with the stop time', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSleepModal(tester);
    await openSleepModal(tester);
    expect(
      find.bySemanticsLabel(RegExp(r'^Bắt đầu 15 phút, dừng lúc \d\d:\d\d$')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('every tile and row starts its timer, closes and says it once', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester);
    final cases = <(String, String, String)>[
      ('15 phút', 'startMinutes:15', 'Đã hẹn giờ ngủ 15 phút, dừng lúc '),
      ('30 phút', 'startMinutes:30', 'Đã hẹn giờ ngủ 30 phút, dừng lúc '),
      ('45 phút', 'startMinutes:45', 'Đã hẹn giờ ngủ 45 phút, dừng lúc '),
      ('1 giờ', 'startMinutes:60', 'Đã hẹn giờ ngủ 1 giờ, dừng lúc '),
      (
        '1 giờ 30',
        'startMinutes:90',
        'Đã hẹn giờ ngủ 1 giờ 30 phút, dừng lúc ',
      ),
      (
        'Hết bài này',
        'startEndOfTrack',
        'Đã hẹn giờ ngủ, tạm dừng khi hết bài này',
      ),
      (
        'Hết album này',
        'startEndOfAlbum',
        'Đã hẹn giờ ngủ, tạm dừng khi hết album này',
      ),
      (
        'Hết hàng đợi',
        'startEndOfQueue',
        'Đã hẹn giờ ngủ, tạm dừng khi hết hàng đợi',
      ),
    ];
    for (final (title, call, said) in cases) {
      host.timer.calls.clear();
      host.announced.clear();
      final pops = host.pops.pops;
      await openSleepModal(tester);
      await tapVisible(tester, find.text(title));
      expect(host.timer.calls, [call], reason: title);
      expect(host.announced, hasLength(1), reason: title);
      expect(host.announced.single, startsWith(said), reason: title);
      expect(host.pops.pops, pops + 1, reason: title);
      expect(modalOpen, findsNothing, reason: title);
      host.timer.set(const SleepTimerState.off());
    }
  });

  testWidgets('a tile replaces a running timer', (tester) async {
    final host = await pumpSleepModal(tester, initial: runningTracks());
    await openSleepModal(tester);
    // Opens on running; go to the tiles through Đổi… of the end-of modes.
    host.timer.set(runningEndOf(SleepTimerMode.endOfQueue));
    await tester.pump();
    await tapVisible(tester, find.text('Đổi…'));
    await tapVisible(tester, find.text('30 phút'));
    expect(host.timer.calls, ['startMinutes:30']);
    expect(host.timer.state.mode, SleepTimerMode.minutes);
  });

  testWidgets('a start does not flash the running card while closing', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester);
    await openSleepModal(tester);
    await tester.tap(find.text('30 phút'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(host.timer.state.active, isTrue);
    expect(modalOpen, findsOneWidget);
    expect(find.textContaining('Đang chạy'), findsNothing);
    await tester.pumpAndSettle();
    expect(modalOpen, findsNothing);
  });

  testWidgets('the last row clears the sheet bottom gap, no footer', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await openSleepModal(tester);
    final last = tester.getRect(find.text('Sau số bài…'));
    final sheet = tester.getRect(find.byType(KStartArea));
    expect(find.byType(KModalButton), findsNothing);
    // Row text sits above the content's bottom edge; nothing is cut.
    expect(last.bottom, lessThanOrEqualTo(sheet.bottom));
    expect(
      tester.view.physicalSize.height / tester.view.devicePixelRatio,
      greaterThanOrEqualTo(last.bottom + KSpace.x6),
    );
  });

  testWidgets('Tuỳ chỉnh… and Sau số bài… open the custom screen', (
    tester,
  ) async {
    await pumpSleepModal(tester);
    await openSleepModal(tester);
    await tapVisible(tester, find.text('Tuỳ chỉnh…'));
    expect(find.text('Tuỳ chỉnh'), findsOneWidget);
    expect(find.text('Dừng lúc', skipOffstage: false), findsNothing);
    await tapVisible(tester, backButton);
    await tapVisible(tester, find.text('Sau số bài…'));
    expect(find.text('Tuỳ chỉnh'), findsOneWidget);
    expect(find.textContaining('Tạm dừng sau 3 bài'), findsOneWidget);
  });

  testWidgets('the running card shows whenever a timer runs and goes back', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester);
    for (final (state, text) in [
      (runningMinutes(), 'Đang chạy · Ngủ sau 23:41'),
      (runningMinutes(held: true), 'Đang chạy · Tạm dừng đếm · còn 23:41'),
      (runningTracks(), 'Đang chạy · Tạm dừng sau 3 bài'),
      (
        runningEndOf(SleepTimerMode.endOfAlbum),
        'Đang chạy · Tạm dừng khi hết album này',
      ),
    ]) {
      host.timer.set(state);
      await openSleepModal(tester);
      // Opens on the running screen; the card is on the tiles.
      expect(find.text('Tắt hẹn giờ'), findsOneWidget);
      await tapVisible(tester, find.text('Đổi…'));
      if (state.mode == SleepTimerMode.minutes ||
          state.mode == SleepTimerMode.tracks) {
        await tapVisible(tester, backButton);
      }
      expect(find.text(text), findsOneWidget, reason: text);
      await tapVisible(tester, find.text(text));
      expect(find.text('Tắt hẹn giờ'), findsOneWidget, reason: text);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('a track without an album: the row is disabled with its reason', (
    tester,
  ) async {
    final host = await pumpSleepModal(tester, noAlbum: true);
    await openSleepModal(tester);
    expect(find.text('Bài này không có album'), findsOneWidget);
    expect(find.text('còn 4 bài'), findsNothing);
    await tester.tap(find.text('Hết album này'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(host.timer.calls, isEmpty);
    expect(modalOpen, findsOneWidget);
  });

  group('desktop', () {
    testWidgets('first focus is the 45 minute tile; Enter starts it', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, size: _desktop);
      await openSleepModal(tester);
      expect(focusedWithin(tester, holding(KStartTile, '45 phút')), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(host.timer.calls, ['startMinutes:45']);
      expect(modalOpen, findsNothing);
    });

    testWidgets('with a timer running the running card has first focus', (
      tester,
    ) async {
      final host = await pumpSleepModal(tester, size: _desktop);
      host.timer.set(runningEndOf(SleepTimerMode.endOfAlbum));
      await openSleepModal(tester);
      await tapVisible(tester, find.text('Đổi…'));
      expect(
        focusedWithin(
          tester,
          holding(SelectionRow, 'Đang chạy · Tạm dừng khi hết album này'),
        ),
        isTrue,
      );
    });

    testWidgets('arrows skip the disabled album row', (tester) async {
      await pumpSleepModal(tester, size: _desktop, noAlbum: true);
      await openSleepModal(tester);
      // Down from the tile grid to the first row, then past the album row.
      var guard = 0;
      while (!focusedWithin(tester, holding(SelectionRow, 'Hết bài này')) &&
          guard++ < 6) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      expect(
        focusedWithin(tester, holding(SelectionRow, 'Hết bài này')),
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        focusedWithin(tester, holding(SelectionRow, 'Hết hàng đợi')),
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(
        focusedWithin(tester, holding(SelectionRow, 'Hết bài này')),
        isTrue,
      );
    });
  });
}
