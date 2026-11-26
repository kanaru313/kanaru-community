import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/media/seek_clock.dart';
import 'package:kanaru_ui/src/widgets/media/squiggle_painter.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';
import '../support/paint_probe.dart';

const _total = Duration(seconds: 100);

/// Pumps [total] in 16 ms frames: the clock caps one frame at 50 ms.
Future<void> _advance(WidgetTester tester, Duration total) async {
  for (var left = total.inMilliseconds; left > 0; left -= 16) {
    await tester.pump(Duration(milliseconds: left < 16 ? left : 16));
  }
}

bool _idle(WidgetTester tester) => tester.binding.transientCallbackCount == 0;

Widget _bar({
  KSquiggleLook look = const KSquiggleLook(),
  bool playing = false,
  Uint8List? levels,
  Duration position = const Duration(seconds: 50),
  List<Duration>? seeks,
}) => SizedBox(
  width: 212,
  child: KSquiggleSeekBar(
    position: position,
    duration: _total,
    look: look,
    playing: playing,
    levels: levels,
    onSeek: (d) => seeks?.add(d),
    semanticLabel: 'Position',
    semanticValue: '0:50 of 1:40',
  ),
);

SquigglePainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(KSquiggleTrack),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((c) => c.painter)
    .whereType<SquigglePainter>()
    .single;

void main() {
  group('geometry', () {
    test('the wave tapers to 0 over the last half wavelength', () {
      const lam = 28.0;
      double taper(double x) =>
          squiggleTaper(x, start: 0, end: 200, wavelength: lam);
      expect(taper(200), 0);
      expect(taper(200 - lam / 4), closeTo(0.5, 1e-9));
      expect(taper(200 - lam / 2), 1);
      expect(taper(100), 1);
      expect(taper(210), 0, reason: 'never negative');
    });

    test('the wave starts at 0.2 and is full a quarter wavelength in', () {
      const lam = 28.0;
      double taper(double x) =>
          squiggleTaper(x, start: 0, end: 200, wavelength: lam);
      expect(taper(0), closeTo(0.2, 1e-9));
      expect(taper(lam / 4), 1);
    });

    test('y follows a sine of the position, moved by the phase', () {
      double y(double x, {double phase = 0, double taper = 1}) => squiggleWaveY(
        x: x,
        cy: 28,
        amplitude: 4.5,
        taper: taper,
        wavelength: 28,
        phase: phase,
      );
      expect(y(0), 28);
      expect(y(7), closeTo(32.5, 1e-9));
      expect(y(21), closeTo(23.5, 1e-9));
      expect(y(7, taper: 0), 28);
      expect(y(7, phase: math.pi / 2), closeTo(28, 1e-9));
    });

    test('amplitude: flat at no energy, music scales it by the level', () {
      expect(squiggleAmplitude(base: 4.5, energy: 0), 0);
      expect(squiggleAmplitude(base: 4.5, energy: 1), 4.5);
      expect(squiggleAmplitude(base: 4.5, energy: 0.5), 2.25);
      // Silence still moves a little; a loud passage goes past the base.
      final quiet = squiggleAmplitude(base: 4.5, energy: 1, level: 0);
      final loud = squiggleAmplitude(base: 4.5, energy: 1, level: 1);
      expect(quiet, inInclusiveRange(4.5 * 0.35 * 0.7, 4.5 * 0.35 * 1.0));
      expect(loud, greaterThan(4.5));
    });

    test('the loudness is the mean of the level and its neighbours', () {
      final levels = Uint8List.fromList(
        List.generate(100, (i) => i < 50 ? 0 : 255),
      );
      double? at(int seconds) => squiggleLevelAt(
        levels,
        position: Duration(seconds: seconds),
        length: _total,
      );
      expect(at(10), 0);
      expect(at(90), 1);
      // Index 49 is quiet, 52 loud: one of three levels is loud.
      expect(at(49), closeTo(1 / 3, 1e-9));
      expect(at(500), 1, reason: 'past the end clamps to the last level');
      expect(squiggleLevelAt(null, position: _total, length: _total), isNull);
      expect(
        squiggleLevelAt(levels, position: _total, length: Duration.zero),
        isNull,
      );
    });
  });

  group('picture', () {
    const size = Size(200, 56);

    Future<PaintProbe> draw(
      WidgetTester tester, {
      double energy = 0,
      KSquiggleLook look = const KSquiggleLook(),
      double progress = 0.5,
    }) async {
      final clock = SeekClock(tester)
        ..configure(target: energy, usesTime: false, instant: true);
      addTearDown(clock.dispose);
      return PaintProbe.of(
        tester,
        SquigglePainter(
          progress: progress,
          look: look,
          primary: const Color(0xFF3355CC),
          surface: const Color(0xFFFFFFFF),
          cache: SquigglePaintCache(),
          clock: clock,
          showThumb: true,
        ),
        size,
      );
    }

    testWidgets('flat line when paused, waves when playing', (tester) async {
      final paused = await draw(tester);
      // The line is 4 thick around y = 28.
      expect(paused.alpha(50, 28), 255);
      expect(paused.alpha(7, 32), 0);
      final playing = await draw(tester, energy: 1);
      // A quarter wave in, the line is 4.5 below the centre.
      expect(playing.alpha(7, 32), 255);
      expect(playing.alpha(7, 28), 0, reason: 'the line left the centre');
    });

    testWidgets('rest line at 24 %, a gap around the thumb', (tester) async {
      final probe = await draw(tester);
      expect(probe.alpha(150, 28), closeTo(0.24 * 255, 2));
      expect(probe.red(150, 28), closeTo(0x33, 3));
      // Thumb bar at x = 100 (98..102), wave ends at 94 (+2 cap), rest at 106.
      expect(probe.alpha(100, 28), 255);
      expect(probe.alpha(104, 28), 0);
      expect(probe.alpha(100, 19), 255, reason: 'the bar is 20 tall');
    });

    testWidgets('no thumb: no gap and no marker', (tester) async {
      final probe = await draw(
        tester,
        look: const KSquiggleLook(thumb: KSeekThumb.none),
      );
      expect(probe.alpha(100, 19), 0);
      expect(probe.alpha(104, 28), closeTo(0.24 * 255, 2));
    });

    testWidgets('dot thumb: primary centre inside a surface ring', (
      tester,
    ) async {
      final probe = await draw(
        tester,
        look: const KSquiggleLook(thumb: KSeekThumb.dot),
      );
      expect(probe.red(100, 28), closeTo(0x33, 3));
      // Between the 6.5 dp dot and the 8 dp ring: the surface colour.
      expect(probe.red(107, 28), greaterThan(0xB0));
      expect(probe.alpha(107, 28), greaterThan(200));
    });
  });

  group('frames', () {
    testWidgets('playing runs the drift', (tester) async {
      await tester.pumpWidget(host(Center(child: _bar(playing: true))));
      await _advance(tester, const Duration(milliseconds: 500));
      expect(_idle(tester), isFalse);
      expect(_painter(tester).clock.time, greaterThan(0.3));
      expect(_painter(tester).clock.energy, 1);
    });

    testWidgets('mounted paused: flat and no frames at all', (tester) async {
      await tester.pumpWidget(host(Center(child: _bar())));
      expect(_idle(tester), isTrue);
      expect(_painter(tester).clock.energy, 0);
    });

    testWidgets('pausing flattens over 300 ms, then no frames', (tester) async {
      await tester.pumpWidget(host(Center(child: _bar(playing: true))));
      await _advance(tester, const Duration(milliseconds: 100));
      await tester.pumpWidget(host(Center(child: _bar())));
      await _advance(tester, const Duration(milliseconds: 100));
      expect(_idle(tester), isFalse);
      final mid = _painter(tester).clock.energy;
      expect(mid, inExclusiveRange(0, 1));
      await _advance(tester, const Duration(milliseconds: 300));
      expect(_painter(tester).clock.energy, 0);
      expect(_idle(tester), isTrue);
      // Playing again grows it back.
      await tester.pumpWidget(host(Center(child: _bar(playing: true))));
      await _advance(tester, const Duration(milliseconds: 400));
      expect(_painter(tester).clock.energy, 1);
    });

    testWidgets('reduced motion: still full wave, no frames', (tester) async {
      await tester.pumpWidget(
        host(Center(child: _bar(playing: true)), reduceMotion: true),
      );
      await _advance(tester, const Duration(milliseconds: 100));
      expect(_idle(tester), isTrue);
      expect(_painter(tester).clock.energy, 1);
      expect(_painter(tester).clock.time, 0);
      await tester.pumpWidget(host(Center(child: _bar()), reduceMotion: true));
      expect(_painter(tester).clock.energy, 1, reason: 'no flatten either');
      expect(_idle(tester), isTrue);
    });

    testWidgets('still motion: full wave, no frames while playing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Center(
            child: _bar(
              playing: true,
              look: const KSquiggleLook(motion: KSquiggleMotion.still),
            ),
          ),
        ),
      );
      await _advance(tester, const Duration(milliseconds: 100));
      expect(_idle(tester), isTrue);
      expect(_painter(tester).clock.energy, 1);
    });

    testWidgets('a muted ticker (TickerMode off) schedules no frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Center(child: TickerMode(enabled: false, child: _bar(playing: true))),
        ),
      );
      await _advance(tester, const Duration(milliseconds: 100));
      expect(_idle(tester), isTrue);
    });

    testWidgets('reduced motion: a music squiggle ignores the loudness', (
      tester,
    ) async {
      final levels = Uint8List.fromList(List.generate(100, (i) => i * 2));
      await tester.pumpWidget(
        host(
          Center(
            child: _bar(
              look: const KSquiggleLook(motion: KSquiggleMotion.music),
              playing: true,
              levels: levels,
            ),
          ),
          reduceMotion: true,
        ),
      );
      expect(_painter(tester).level, isNull);
    });

    testWidgets('after a muted spell the clock moves one capped frame', (
      tester,
    ) async {
      Widget at(bool enabled) => host(
        Center(
          child: TickerMode(enabled: enabled, child: _bar(playing: true)),
        ),
      );
      await tester.pumpWidget(at(false));
      await tester.pump(const Duration(seconds: 2));
      expect(_painter(tester).clock.time, 0);
      await tester.pumpWidget(at(true));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(_painter(tester).clock.time, lessThan(0.1));
    });

    testWidgets('a drag up past the cancel distance does not seek', (
      tester,
    ) async {
      final seeks = <Duration>[];
      final scrubs = <Duration?>[];
      await tester.pumpWidget(
        host(
          Center(
            child: SizedBox(
              width: 212,
              child: KSquiggleSeekBar(
                position: Duration.zero,
                duration: _total,
                onSeek: seeks.add,
                bubbleLabel: (d) => 'T${d.inSeconds}',
                cancelLabel: 'Cancel',
                onScrub: scrubs.add,
              ),
            ),
          ),
        ),
      );
      final box = tester.getRect(find.byType(KSquiggleSeekBar));
      final g = await tester.startGesture(
        Offset(box.left + 40, box.center.dy),
        kind: PointerDeviceKind.touch,
      );
      await g.moveBy(const Offset(40, 0));
      await g.moveBy(const Offset(0, -seekCancelUpDistance - 10));
      await tester.pump();
      expect(find.text('Cancel'), findsOneWidget);
      await g.up();
      await tester.pumpAndSettle();
      expect(seeks, isEmpty);
      expect(scrubs.last, isNull);
    });

    testWidgets('music without levels drifts, with levels follows them', (
      tester,
    ) async {
      const music = KSquiggleLook(motion: KSquiggleMotion.music);
      await tester.pumpWidget(
        host(Center(child: _bar(look: music, playing: true))),
      );
      expect(_painter(tester).level, isNull);
      expect(_painter(tester).clock.running, isTrue, reason: 'drifts');
      final levels = Uint8List.fromList(List.generate(100, (i) => i * 2));
      await tester.pumpWidget(
        host(
          Center(
            child: _bar(look: music, playing: true, levels: levels),
          ),
        ),
      );
      expect(_painter(tester).level, isNotNull);
      // Drift look ignores levels.
      await tester.pumpWidget(
        host(Center(child: _bar(playing: true, levels: levels))),
      );
      expect(_painter(tester).level, isNull);
    });
  });

  group('input', () {
    testWidgets('thumb none is still a slider that seeks', (tester) async {
      final handle = tester.ensureSemantics();
      final seeks = <Duration>[];
      await tester.pumpWidget(
        host(
          Center(
            child: _bar(
              look: const KSquiggleLook(thumb: KSeekThumb.none),
              seeks: seeks,
            ),
          ),
        ),
      );
      expect(
        find.semantics.byLabel('Position').evaluate().single,
        isSemantics(isSlider: true, hasEnabledState: true, isEnabled: true),
      );
      final box = tester.getRect(find.byType(KSquiggleSeekBar));
      await tester.tapAt(Offset(box.left + 106, box.center.dy));
      expect(seeks.single.inMilliseconds, closeTo(50000, 1));
      handle.dispose();
    });

    testWidgets('band is 56 tall and the time axis has 6 dp insets', (
      tester,
    ) async {
      await tester.pumpWidget(host(Center(child: _bar())));
      expect(tester.getSize(find.byType(KSquiggleSeekBar)).height, 56);
      final box = tester.getRect(find.byType(KSquiggleSeekBar));
      final track = tester.getRect(find.byType(KSquiggleTrack));
      expect(track.left - box.left, 6);
      expect(box.right - track.right, 6);
    });

    testWidgets('hold shows the bubble', (tester) async {
      await tester.pumpWidget(
        host(
          Center(
            child: SizedBox(
              width: 212,
              child: KSquiggleSeekBar(
                position: Duration.zero,
                duration: _total,
                onSeek: (_) {},
                bubbleLabel: (d) => 'T${d.inSeconds}',
                cancelLabel: 'Cancel',
              ),
            ),
          ),
        ),
      );
      final box = tester.getRect(find.byType(KSquiggleSeekBar));
      final g = await tester.startGesture(
        Offset(box.center.dx, box.center.dy),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(seekHoldDelay + const Duration(milliseconds: 50));
      expect(find.text('T50'), findsOneWidget);
      await g.up();
      await tester.pumpAndSettle();
    });
  });
}
