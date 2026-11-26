import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/media/flat_effects_painter.dart';
import 'package:kanaru_ui/src/widgets/media/flat_geometry.dart';
import 'package:kanaru_ui/src/widgets/media/seek_clock.dart';
import 'package:kanaru_ui/src/widgets/media/spark_pool.dart';
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
  KFlatLook look = const KFlatLook(),
  bool playing = false,
  Duration position = const Duration(seconds: 50),
  List<Duration>? seeks,
}) => SizedBox(
  width: 212,
  child: KFlatStyledSeekBar(
    position: position,
    duration: _total,
    look: look,
    playing: playing,
    onSeek: (d) => seeks?.add(d),
    semanticLabel: 'Position',
    semanticValue: '0:50 of 1:40',
  ),
);

FlatSeekPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(KFlatSeekTrack),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((c) => c.painter)
    .whereType<FlatSeekPainter>()
    .single;

const _shine = KFlatLook(effect: KFlatEffect.shine);

void main() {
  group('track thickness', () {
    for (final (thickness, dp) in [
      (KFlatThickness.thin, 2.0),
      (KFlatThickness.mid, 4.0),
      (KFlatThickness.thick, 8.0),
    ]) {
      testWidgets('${thickness.name} is $dp dp, +2 under the mouse', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            Center(
              child: _bar(look: KFlatLook(thickness: thickness)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(_painter(tester).thickness, dp);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(
          location: tester.getCenter(find.byType(KFlatStyledSeekBar)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(_painter(tester).thickness, dp + 2);
        await mouse.removePointer();
      });
    }
  });

  group('picture', () {
    const size = Size(200, 24);
    const red = Color(0xFFFF0000);
    const blue = Color(0xFF0000FF);

    Future<PaintProbe> draw(
      WidgetTester tester, {
      KFlatLook look = const KFlatLook(),
      double progress = 0.5,
      double thickness = 8,
      double energy = 0,
      double time = 0,
      FlatPaintCache? cache,
    }) async {
      final clock = SeekClock(tester)
        ..configure(target: energy, usesTime: false, instant: true)
        ..time = time;
      addTearDown(clock.dispose);
      return PaintProbe.of(
        tester,
        FlatSeekPainter(
          progress: progress,
          thickness: thickness,
          look: look,
          primary: red,
          tertiary: blue,
          surface: const Color(0xFFFFFFFF),
          showThumb: true,
          cache: cache ?? FlatPaintCache(),
          clock: clock,
        ),
        size,
      );
    }

    testWidgets('single colour: played in primary, rest at 24 %', (
      tester,
    ) async {
      final p = await draw(
        tester,
        look: const KFlatLook(thumb: KSeekThumb.none),
      );
      expect(p.red(20, 12), 255);
      expect(p.blue(20, 12), 0);
      expect(p.alpha(150, 12), closeTo(0.24 * 255, 2));
      expect(p.alpha(150, 5), 0, reason: 'track is 8 thick, not more');
    });

    testWidgets('gradient: blends to the tertiary colour along the track', (
      tester,
    ) async {
      final p = await draw(
        tester,
        progress: 1,
        look: const KFlatLook(
          played: KFlatPlayed.gradient,
          thumb: KSeekThumb.none,
        ),
      );
      expect(p.red(5, 12), greaterThan(230));
      expect(p.blue(195, 12), greaterThan(230));
    });

    testWidgets('thumb bar is 4 x 16 (taller on a thick track)', (
      tester,
    ) async {
      final p = await draw(tester, thickness: 4);
      expect(p.alpha(100, 5), 255);
      expect(p.alpha(100, 3), 0);
      expect(p.alpha(97, 5), 0);
      final none = await draw(
        tester,
        thickness: 4,
        look: const KFlatLook(thumb: KSeekThumb.none),
      );
      expect(none.alpha(100, 5), 0);
    });

    testWidgets('shine: a white band over the played part, scaled by energy', (
      tester,
    ) async {
      // Played 100 wide: the band centre is at u * 160 - 30 = 50 at u = 0.5.
      final full = await draw(
        tester,
        look: const KFlatLook(
          effect: KFlatEffect.shine,
          thumb: KSeekThumb.none,
        ),
        energy: 1,
        time: 1.2,
      );
      final half = await draw(
        tester,
        look: const KFlatLook(
          effect: KFlatEffect.shine,
          thumb: KSeekThumb.none,
        ),
        energy: 0.5,
        time: 1.2,
      );
      final off = await draw(
        tester,
        look: const KFlatLook(
          effect: KFlatEffect.shine,
          thumb: KSeekThumb.none,
        ),
        energy: 0,
        time: 1.2,
      );
      expect(off.green(50, 12), 0);
      expect(full.green(50, 12), closeTo(0.65 * 255, 8));
      expect(half.green(50, 12), closeTo(0.325 * 255, 8));
      expect(full.green(5, 12), lessThan(10), reason: 'band is away from x=5');
    });

    testWidgets('comet: the played part fades in from the start', (
      tester,
    ) async {
      final p = await draw(
        tester,
        look: const KFlatLook(
          effect: KFlatEffect.comet,
          thumb: KSeekThumb.none,
        ),
        energy: 1,
      );
      // Gradient 0.2 to 1 over the played 100, over the 24 % rest track.
      expect(p.alpha(50, 12), closeTo((0.24 + 0.6 * 0.76) * 255, 6));
      expect(p.alpha(3, 12), closeTo((0.24 + 0.224 * 0.76) * 255, 6));
      expect(p.alpha(3, 12), lessThan(p.alpha(60, 12)));
      // The glow reaches past the head.
      expect(p.alpha(108, 12), greaterThan(60));
      final off = await draw(
        tester,
        look: const KFlatLook(
          effect: KFlatEffect.comet,
          thumb: KSeekThumb.none,
        ),
      );
      expect(off.alpha(3, 12), 255);
      expect(off.alpha(108, 12), closeTo(0.24 * 255, 2));
    });

    testWidgets('comet: no pop when the fade ends', (tester) async {
      const look = KFlatLook(effect: KFlatEffect.comet, thumb: KSeekThumb.none);
      final last = await draw(tester, look: look, energy: 1 / 32);
      final done = await draw(tester, look: look);
      expect(done.alpha(50, 12), 255);
      expect(last.alpha(50, 12), closeTo(255, 6));
      expect(last.alpha(3, 12), closeTo(255, 8));
    });

    testWidgets('comet glow scales with energy', (tester) async {
      const look = KFlatLook(effect: KFlatEffect.comet, thumb: KSeekThumb.none);
      final full = await draw(tester, look: look, energy: 1);
      final half = await draw(tester, look: look, energy: 0.5);
      final off = await draw(tester, look: look);
      expect(full.alpha(108, 12), greaterThan(half.alpha(108, 12)));
      expect(half.alpha(108, 12), greaterThan(off.alpha(108, 12)));
    });

    testWidgets('sparks leave no particle without energy', (tester) async {
      final cache = FlatPaintCache();
      await draw(
        tester,
        look: const KFlatLook(effect: KFlatEffect.sparks),
        cache: cache,
      );
      expect(cache.particles, 0);
    });
  });

  group('spark pool', () {
    test('never holds more than the pool size', () {
      final pool = SparkPool();
      for (var i = 0; i < 20000; i++) {
        pool.step(i % 7 == 0 ? 0.002 : 0.016, headX: 50, headY: 12, emit: 1);
        expect(pool.count, lessThanOrEqualTo(sparkPoolSize));
      }
      expect(sparkPoolSize, lessThanOrEqualTo(60));
      expect(pool.count, greaterThan(5), reason: 'it does emit');
    });

    test(
      'a particle dies by the end of its life, without energy none are born',
      () {
        final pool = SparkPool();
        for (var i = 0; i < 200; i++) {
          pool.step(0.016, headX: 0, headY: 0, emit: 1);
        }
        expect(pool.count, greaterThan(0));
        for (var i = 0; i < 100; i++) {
          pool.step(0.016, headX: 0, headY: 0, emit: 0);
        }
        expect(pool.count, 0, reason: '1.6 s is past every life');
      },
    );
  });

  group('frames', () {
    testWidgets('no effect: never a frame of its own while playing', (
      tester,
    ) async {
      await tester.pumpWidget(host(Center(child: _bar(playing: true))));
      await _advance(tester, const Duration(milliseconds: 500));
      expect(_idle(tester), isTrue);
    });

    testWidgets('an effect runs while playing', (tester) async {
      await tester.pumpWidget(
        host(Center(child: _bar(look: _shine, playing: true))),
      );
      await _advance(tester, const Duration(milliseconds: 500));
      expect(_idle(tester), isFalse);
      expect(_painter(tester).clock!.time, greaterThan(0.3));
    });

    testWidgets('mounted paused: no frames', (tester) async {
      await tester.pumpWidget(host(Center(child: _bar(look: _shine))));
      expect(_idle(tester), isTrue);
    });

    testWidgets('pausing fades the effect out over 300 ms, then no frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(Center(child: _bar(look: _shine, playing: true))),
      );
      await _advance(tester, const Duration(milliseconds: 100));
      await tester.pumpWidget(host(Center(child: _bar(look: _shine))));
      await _advance(tester, const Duration(milliseconds: 100));
      expect(_idle(tester), isFalse);
      expect(_painter(tester).clock!.energy, inExclusiveRange(0, 1));
      await _advance(tester, const Duration(milliseconds: 300));
      expect(_painter(tester).clock!.energy, 0);
      expect(_idle(tester), isTrue);
    });

    testWidgets('reduced motion: no effect, no frames', (tester) async {
      await tester.pumpWidget(
        host(
          Center(child: _bar(look: _shine, playing: true)),
          reduceMotion: true,
        ),
      );
      await _advance(tester, const Duration(milliseconds: 500));
      expect(_idle(tester), isTrue);
      expect(_painter(tester).clock!.energy, 0);
    });

    testWidgets('a muted ticker (TickerMode off) schedules no frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Center(
            child: TickerMode(
              enabled: false,
              child: _bar(look: _shine, playing: true),
            ),
          ),
        ),
      );
      await _advance(tester, const Duration(milliseconds: 500));
      expect(_idle(tester), isTrue);
    });

    testWidgets('sparks while playing make particles, pause removes them', (
      tester,
    ) async {
      const sparks = KFlatLook(effect: KFlatEffect.sparks);
      await tester.pumpWidget(
        host(Center(child: _bar(look: sparks, playing: true))),
      );
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final cache = _painter(tester).cache;
      expect(cache.particles, inInclusiveRange(1, sparkPoolSize));
      await tester.pumpWidget(host(Center(child: _bar(look: sparks))));
      await _advance(tester, const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_painter(tester).clock!.energy, 0);
      expect(_painter(tester).cache.particles, 0);
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
              look: const KFlatLook(thumb: KSeekThumb.none),
              seeks: seeks,
            ),
          ),
        ),
      );
      expect(
        find.semantics.byLabel('Position').evaluate().single,
        isSemantics(isSlider: true, hasEnabledState: true, isEnabled: true),
      );
      final box = tester.getRect(find.byType(KFlatStyledSeekBar));
      await tester.tapAt(Offset(box.left + 106, box.center.dy));
      expect(seeks.single.inMilliseconds, closeTo(50000, 1));
      handle.dispose();
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
              child: KFlatStyledSeekBar(
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
      final box = tester.getRect(find.byType(KFlatStyledSeekBar));
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

    testWidgets('band is 56 tall with 6 dp insets', (tester) async {
      await tester.pumpWidget(host(Center(child: _bar())));
      expect(tester.getSize(find.byType(KFlatStyledSeekBar)).height, 56);
      final box = tester.getRect(find.byType(KFlatStyledSeekBar));
      final track = tester.getRect(find.byType(KFlatSeekTrack));
      expect(track.left - box.left, 6);
      expect(box.right - track.right, 6);
    });
  });
}
