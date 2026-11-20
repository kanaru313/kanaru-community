import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/playback/domain/sleep_timer_state.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_announce.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_clock_builder.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_texts.dart';
import 'package:material_ui/material_ui.dart';

Future<SleepTimerTexts> texts(
  WidgetTester tester, {
  String locale = 'vi',
  bool use24 = true,
}) async {
  late SleepTimerTexts out;
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24),
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          out = SleepTimerTexts.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return out;
}

final _now = DateTime(2026, 11, 20, 23, 25);

void main() {
  testWidgets('durations in words', (tester) async {
    final t = await texts(tester);
    expect(t.minutesLabel(15), '15 phút');
    expect(t.minutesLabel(60), '1 giờ');
    expect(t.minutesLabel(90), '1 giờ 30');
    expect(t.chipLabel(15), '15 ph');
    expect(t.chipLabel(60), '1 giờ');
    expect(t.chipLabel(90), '1 giờ 30');
    expect(t.durationWords(90), '1 giờ 30 phút');
    expect(t.durationWords(120), '2 giờ');
    expect(t.unitMinutes(45), 'phút');
    expect(t.unitMinutes(90), 'phút · 1 giờ 30 phút');
  });

  testWidgets('stops-at texts follow the device 24 hour setting', (
    tester,
  ) async {
    var t = await texts(tester);
    expect(t.tileUntil(_now, 15), 'đến 23:40');
    expect(t.tileStartLabel(_now, 15), 'Bắt đầu 15 phút, dừng lúc 23:40');
    expect(t.stopsAt(_now, 45), 'Dừng lúc 00:10');
    expect(t.stopsAfterTracks(3), 'Tạm dừng sau 3 bài, tính cả bài này');
    t = await texts(tester, locale: 'en', use24: false);
    expect(t.tileUntil(_now, 15), allOf(contains('11:40'), contains('PM')));
  });

  testWidgets('end-of rows', (tester) async {
    final t = await texts(tester);
    expect(t.leftTime(const Duration(minutes: 2, seconds: 48)), 'còn 2:48');
    expect(t.leftTracks(4), 'còn 4 bài');
    expect(
      t.leftTracks(7, time: const Duration(minutes: 28, seconds: 20)),
      'còn 7 bài · 29 phút',
    );
    expect(t.leftTracks(100, capped: true), 'còn 100+ bài');
  });

  testWidgets('status counts seconds, the reader text counts minutes', (
    tester,
  ) async {
    final t = await texts(tester);
    const running = SleepTimerState(
      mode: SleepTimerMode.minutes,
      remaining: Duration(minutes: 23, seconds: 41),
    );
    expect(t.statusText(running), 'Ngủ sau 23:41');
    expect(t.statusText(running, minutePrecision: true), 'Ngủ sau 24 phút');
    expect(t.pillLabel(running), '23:41');
    expect(t.entryLabel(running), 'Hẹn giờ ngủ: còn 23:41');
    expect(
      t.entryLabel(running, minutePrecision: true),
      'Hẹn giờ ngủ: còn 24 phút',
    );
    expect(t.entryStatusTooltip(running), 'Hẹn giờ ngủ: Ngủ sau 23:41');
    expect(t.menuLabel(running), 'Hẹn giờ ngủ · còn 23:41');
    expect(
      t.menuLabel(running, minutePrecision: true),
      'Hẹn giờ ngủ · còn 24 phút',
    );

    final held = running.copyWith(countingPaused: true);
    expect(t.statusText(held), 'Tạm dừng đếm · còn 23:41');
    expect(
      t.entryLabel(held, minutePrecision: true),
      'Hẹn giờ ngủ: còn 24 phút (tạm dừng đếm)',
    );
  });

  testWidgets('tracks and end-of modes', (tester) async {
    final t = await texts(tester);
    const tracks = SleepTimerState(mode: SleepTimerMode.tracks, tracksLeft: 3);
    expect(t.pillLabel(tracks), '3 bài');
    expect(
      t.entryLabel(tracks, minutePrecision: true),
      'Hẹn giờ ngủ: còn 3 bài',
    );
    expect(t.statusText(tracks), 'Tạm dừng sau 3 bài');
    const album = SleepTimerState(mode: SleepTimerMode.endOfAlbum);
    expect(t.pillLabel(album), 'Album');
    expect(t.statusText(album), 'Tạm dừng khi hết album này');
    expect(t.entryLabel(album), 'Hẹn giờ ngủ: hết album này');
    expect(t.menuLabel(album), 'Hẹn giờ ngủ · hết album này');
    expect(t.entryLabel(const SleepTimerState.off()), 'Hẹn giờ ngủ');
    expect(t.menuLabel(const SleepTimerState.off()), 'Hẹn giờ ngủ');
  });

  testWidgets('announcements (vi and en)', (tester) async {
    var t = await texts(tester);
    final started = SleepTimerState(
      mode: SleepTimerMode.minutes,
      setLength: const Duration(minutes: 15),
      remaining: const Duration(minutes: 15),
      endsAt: DateTime(2026, 11, 20, 23, 40),
    );
    expect(
      t.announceStart(started, _now),
      'Đã hẹn giờ ngủ 15 phút, dừng lúc 23:40',
    );
    expect(
      t.announceStart(
        const SleepTimerState(
          mode: SleepTimerMode.tracks,
          tracksLeft: 3,
          tracksAtStart: 3,
        ),
        _now,
      ),
      'Đã hẹn giờ ngủ, tạm dừng sau 3 bài',
    );
    expect(
      t.announceStart(
        const SleepTimerState(mode: SleepTimerMode.endOfQueue),
        _now,
      ),
      'Đã hẹn giờ ngủ, tạm dừng khi hết hàng đợi',
    );
    expect(t.announceHeld, 'Đã tạm dừng đếm');
    expect(t.announceResumed, 'Đã tiếp tục đếm');
    expect(t.announceCancelled, 'Đã tắt hẹn giờ ngủ');
    expect(t.announceExpired, 'Hẹn giờ ngủ đã hết, nhạc đã tạm dừng');

    t = await texts(tester, locale: 'en');
    expect(
      t.announceStart(started, _now),
      'Sleep timer set for 15 minutes, stops at 23:40',
    );
    expect(t.announceCancelled, 'Sleep timer turned off');
  });

  testWidgets('the clock builder refreshes every 15 s and stops on dispose', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 20, 23, 25);
    var builds = 0;
    Widget host() => MaterialApp(
      home: SleepTimerClockBuilder(
        clock: () => now,
        builder: (context, at) {
          builds++;
          return Text('${at.hour}:${at.minute}');
        },
      ),
    );
    await tester.pumpWidget(host());
    expect(find.text('23:25'), findsOneWidget);
    expect(builds, 1);

    now = DateTime(2026, 11, 20, 23, 26);
    await tester.pump(const Duration(seconds: 14));
    expect(find.text('23:25'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('23:26'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    final after = builds;
    await tester.pump(const Duration(seconds: 60));
    expect(builds, after);
  });
}
