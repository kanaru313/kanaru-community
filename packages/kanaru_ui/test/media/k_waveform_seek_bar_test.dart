import 'dart:ui' show SemanticsAction;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

const _total = Duration(seconds: 100);
final _levels = Uint8List.fromList(List.generate(100, (i) => i * 2));
const _computing = KWaveformStatus.computing;
const _ready = KWaveformStatus.ready;
const _none = KWaveformStatus.none;
const _unknown = KWaveformStatus.unknown;

Duration _ms(int v) => Duration(milliseconds: v);

Widget _bar({
  Uint8List? levels,
  KWaveformStatus status = _unknown,
  Duration position = const Duration(seconds: 20),
  Duration? duration = _total,
  Object? track,
  List<Duration>? seeks,
  Widget Function(BuildContext, KSeekState)? fallback,
  double width = 200,
}) => SizedBox(
  width: width,
  child: KWaveformSeekBar(
    position: position,
    duration: duration,
    track: track,
    levels: levels,
    status: status,
    fallback: fallback,
    onSeek: (d) => seeks?.add(d),
    semanticLabel: 'Position',
    semanticValue: '0:20 of 1:40',
  ),
);

Widget _hosted(Widget bar, {bool reduceMotion = false}) =>
    host(Center(child: bar), reduceMotion: reduceMotion);

/// The painter of the bars; null while the fallback has fully replaced them.
WaveformBandPainter? _painter(WidgetTester tester) {
  final found = find.byKey(waveformBandKey);
  if (found.evaluate().isEmpty) return null;
  return tester.widget<CustomPaint>(found).painter! as WaveformBandPainter;
}

bool _fallbackShown() => find.byKey(waveformFallbackKey).evaluate().isNotEmpty;

/// Steady bars: drawn from recorded pictures at their full height.
bool _isSteady(WidgetTester tester) => _painter(tester)?.pictures != null;

/// A dotted row: every bar at its minimum height.
bool _isDots(WidgetTester tester) {
  final heights = _painter(tester)?.heights;
  return heights != null &&
      heights.isNotEmpty &&
      heights.every((h) => h == waveformMinExtent);
}

double _tallest(WidgetTester tester) =>
    (_painter(tester)!.heights!).reduce((a, b) => a > b ? a : b);

bool _idle(WidgetTester tester) => tester.binding.transientCallbackCount == 0;

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    for (final status in KWaveformStatus.values) {
      testWidgets('is 56 dp tall in $name, status ${status.name}', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(
            Center(
              child: _bar(
                levels: status == _ready ? _levels : null,
                status: status,
              ),
            ),
            brightness: brightness,
            textScale: scale,
          ),
        );
        expect(
          tester.getSize(find.byType(KWaveformSeekBar)).height,
          seekBandHeight,
        );
        expect(seekBandHeight, 56);
      });
    }
  }

  group('mounting', () {
    testWidgets('a cached track shows its bars at once, nothing runs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, track: 1)),
      );
      expect(_isSteady(tester), isTrue);
      expect(_fallbackShown(), isFalse);
      expect(_idle(tester), isTrue);
    });

    testWidgets(
      'a status that arrives after one async gap also shows at once',
      (tester) async {
        await tester.pumpWidget(_hosted(_bar(track: 1)));
        expect(_isDots(tester), isTrue);
        expect(_idle(tester), isTrue);
        await tester.pumpWidget(
          _hosted(_bar(levels: _levels, status: _ready, track: 1)),
        );
        expect(_isSteady(tester), isTrue);
        expect(_idle(tester), isTrue);
      },
    );

    testWidgets('the first track after none is not a change: no gate', (
      tester,
    ) async {
      await tester.pumpWidget(_hosted(_bar()));
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, track: 1)),
      );
      expect(_isSteady(tester), isTrue);
      expect(_idle(tester), isTrue);
    });

    testWidgets('computing shows the dotted row, still', (tester) async {
      await tester.pumpWidget(_hosted(_bar(status: _computing, track: 1)));
      expect(_isDots(tester), isTrue);
      expect(_idle(tester), isTrue);
    });

    testWidgets('none shows the fallback at once, nothing runs', (
      tester,
    ) async {
      await tester.pumpWidget(_hosted(_bar(status: _none, track: 1)));
      expect(_fallbackShown(), isTrue);
      expect(_painter(tester), isNull);
      expect(_idle(tester), isTrue);
    });

    testWidgets('unknown duration with bars draws them and is not seekable', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _hosted(
          SizedBox(
            width: 200,
            child: KWaveformSeekBar(
              position: Duration.zero,
              duration: null,
              levels: _levels,
              levelsDuration: _total,
              status: _ready,
              onSeek: seeks.add,
            ),
          ),
        ),
      );
      expect(_isSteady(tester), isTrue);
      await tester.tapAt(tester.getCenter(find.byType(KWaveformSeekBar)));
      expect(seeks, isEmpty);
    });
  });

  group('transitions', () {
    testWidgets('computing then ready: the bars grow in place over 600 ms', (
      tester,
    ) async {
      await tester.pumpWidget(_hosted(_bar(status: _computing, track: 1)));
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, track: 1)),
      );
      await tester.pump();
      expect(_isDots(tester), isTrue);
      await tester.pump(_ms(300));
      expect(_isSteady(tester), isFalse);
      expect(_isDots(tester), isFalse);
      expect(_tallest(tester), lessThan(waveformMaxExtent));
      await tester.pump(_ms(400));
      await tester.pump();
      expect(_isSteady(tester), isTrue);
      expect(_idle(tester), isTrue);
    });

    testWidgets('computing then none: the dots fade into the fallback', (
      tester,
    ) async {
      await tester.pumpWidget(_hosted(_bar(status: _computing, track: 1)));
      await tester.pumpWidget(_hosted(_bar(status: _none, track: 1)));
      await tester.pump();
      await tester.pump(_ms(100));
      expect(_fallbackShown(), isTrue);
      expect(_painter(tester), isNotNull);
      await tester.pump(_ms(150));
      await tester.pump();
      expect(_painter(tester), isNull);
      expect(_fallbackShown(), isTrue);
      expect(_idle(tester), isTrue);
    });

    testWidgets(
      'a track change collapses the old bars, even when the duration goes '
      'to zero, then the cached new bars grow after 800 ms',
      (tester) async {
        await tester.pumpWidget(
          _hosted(_bar(levels: _levels, status: _ready, track: 1)),
        );
        // The next track: nothing known yet, no duration.
        await tester.pumpWidget(_hosted(_bar(duration: null, track: 2)));
        await tester.pump();
        expect(_painter(tester)!.pictures, isNull);
        final tall = _tallest(tester);
        expect(tall, greaterThan(waveformMaxExtent - 4));
        await tester.pump(_ms(300));
        expect(_tallest(tester), lessThan(tall));
        expect(_tallest(tester), greaterThan(waveformMinExtent));
        await tester.pump(_ms(350));
        expect(_isDots(tester), isTrue);
        // Cached: ready at once, but not before the gate.
        await tester.pumpWidget(
          _hosted(_bar(levels: _levels, status: _ready, track: 2)),
        );
        await tester.pump(_ms(100));
        expect(_isDots(tester), isTrue);
        await tester.pump(_ms(100));
        expect(_isDots(tester), isTrue);
        await tester.pump(_ms(100));
        await tester.pump(_ms(200));
        expect(_isDots(tester), isFalse);
        await tester.pump(_ms(800));
        await tester.pump();
        expect(_isSteady(tester), isTrue);
        expect(_idle(tester), isTrue);
      },
    );

    testWidgets('reduced motion: every change is instant', (tester) async {
      await tester.pumpWidget(
        _hosted(_bar(status: _computing, track: 1), reduceMotion: true),
      );
      await tester.pumpWidget(
        _hosted(
          _bar(levels: _levels, status: _ready, track: 1),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      expect(_isSteady(tester), isTrue);
      expect(_idle(tester), isTrue);
      await tester.pumpWidget(
        _hosted(
          _bar(track: 2, levels: _levels, status: _ready),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      expect(_isSteady(tester), isTrue);
      expect(_idle(tester), isTrue);
    });

    testWidgets('a muted ticker (TickerMode off) schedules no frames', (
      tester,
    ) async {
      Widget tree(KWaveformStatus s, Uint8List? l) => host(
        Center(
          child: TickerMode(
            enabled: false,
            child: _bar(levels: l, status: s, track: 1),
          ),
        ),
      );
      await tester.pumpWidget(tree(_computing, null));
      await tester.pumpWidget(tree(_ready, _levels));
      await tester.pump();
      expect(_idle(tester), isTrue);
    });

    testWidgets('leaving the tree mid-collapse is clean', (tester) async {
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, track: 1)),
      );
      await tester.pumpWidget(_hosted(_bar(track: 2)));
      await tester.pump(_ms(200));
      await tester.pumpWidget(host(const SizedBox()));
      expect(tester.takeException(), isNull);
      expect(_idle(tester), isTrue);
    });
  });

  group('drawing', () {
    testWidgets('a position tick does not record the bars again', (
      tester,
    ) async {
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, track: 1)),
      );
      final before = WaveformPictures.recordings;
      for (var i = 1; i <= 100; i++) {
        await tester.pumpWidget(
          _hosted(
            _bar(
              levels: _levels,
              status: _ready,
              track: 1,
              position: Duration(milliseconds: 20000 + i * 100),
            ),
          ),
        );
      }
      expect(WaveformPictures.recordings, before);
    });

    testWidgets('narrow widths draw without throwing', (tester) async {
      for (final width in [0.0, 1.0, 3.0, 12.0, 13.0, 20.0]) {
        await tester.pumpWidget(
          _hosted(
            _bar(levels: _levels, status: _ready, track: 1, width: width),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'width $width');
      }
    });

    group('focus line on a desktop', () {
      // The platform must be reset before the test ends (flutter_test checks
      // it right after the body), so not in a tearDown.
      void desktopTest(
        String name,
        Future<void> Function(WidgetTester tester) body,
      ) {
        testWidgets(name, (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.linux;
          try {
            await body(tester);
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }

      Future<Rect> pumpBar(WidgetTester tester) async {
        await tester.pumpWidget(
          _hosted(_bar(levels: _levels, status: _ready, track: 1)),
        );
        return tester.getRect(find.byType(KWaveformSeekBar));
      }

      Future<void> mouseClick(WidgetTester tester, Offset at) async {
        final mouse = await tester.startGesture(
          at,
          kind: PointerDeviceKind.mouse,
        );
        await mouse.up();
        await mouse.removePointer();
        await tester.pump();
      }

      desktopTest('a mouse click focuses the bar without a line', (
        tester,
      ) async {
        final box = await pumpBar(tester);
        await mouseClick(tester, Offset(box.left + 100, box.center.dy));
        expect(
          FocusManager.instance.highlightMode,
          FocusHighlightMode.traditional,
        );
        expect(_painter(tester)!.focusLine, isFalse);
        // The keyboard takes over: the line shows.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(_painter(tester)!.focusLine, isTrue);
        // A click again hides it.
        await mouseClick(tester, Offset(box.left + 60, box.center.dy));
        expect(_painter(tester)!.focusLine, isFalse);
      });

      desktopTest('Tab onto the bar draws the line, a drag hides it', (
        tester,
      ) async {
        final box = await pumpBar(tester);
        expect(_painter(tester)!.focusLine, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_painter(tester)!.focusLine, isTrue);
        final drag = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
          kind: PointerDeviceKind.mouse,
        );
        await drag.moveTo(Offset(box.left + 100, box.center.dy));
        await tester.pump();
        expect(_painter(tester)!.focusLine, isFalse);
        await drag.up();
        await drag.removePointer();
        await tester.pump();
        expect(_painter(tester)!.focusLine, isFalse);
      });

      desktopTest('a drag without focus leaves Tab its line', (tester) async {
        final box = await pumpBar(tester);
        final drag = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
          kind: PointerDeviceKind.mouse,
        );
        await drag.moveTo(Offset(box.left + 100, box.center.dy));
        await drag.up();
        await drag.removePointer();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_painter(tester)!.focusLine, isTrue);
      });

      desktopTest('a touch tap draws no line', (tester) async {
        final box = await pumpBar(tester);
        await tester.tapAt(Offset(box.left + 100, box.center.dy));
        await tester.pump();
        expect(_painter(tester)!.focusLine, isFalse);
      });
    });
  });

  group('input', () {
    testWidgets('a tap at x seeks to (x - 6) / (w - 12) of the duration', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, seeks: seeks)),
      );
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      await tester.tapAt(Offset(box.left + 106, box.center.dy));
      expect(seeks.single.inMilliseconds, (100000 * 100 / 188).round());
      seeks.clear();
      // Outside the time axis it clamps.
      await tester.tapAt(Offset(box.left + 2, box.center.dy));
      await tester.tapAt(Offset(box.right - 2, box.center.dy));
      expect(seeks, [Duration.zero, _total]);
    });

    testWidgets('the fallback gets the inner width and draws at the tap', (
      tester,
    ) async {
      final seeks = <Duration>[];
      KSeekState? seen;
      const probe = ValueKey('fallback probe');
      Widget at(Duration position) => _hosted(
        _bar(
          status: _none,
          position: position,
          seeks: seeks,
          fallback: (context, state) {
            seen = state;
            return const SizedBox.expand(key: probe);
          },
        ),
      );
      await tester.pumpWidget(at(Duration.zero));
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      await tester.tapAt(Offset(box.left + 106, box.center.dy));
      await tester.pumpWidget(at(seeks.single));
      expect(seen!.width, 188);
      expect(seen!.progress, closeTo(100 / 188, 1e-3));
      // The fallback box starts at the inset and is as wide as its state, so
      // the progress it draws lands under the tap.
      final probeBox = tester.getRect(find.byKey(probe));
      expect(probeBox.left - box.left, 6);
      expect(probeBox.width, seen!.width);
      expect(
        probeBox.left + seen!.width * seen!.progress - box.left,
        closeTo(106, 0.6),
      );
    });

    testWidgets('the default fallback sits inside the 6 dp insets', (
      tester,
    ) async {
      await tester.pumpWidget(_hosted(_bar(status: _none, track: 1)));
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      final flat = tester.getRect(find.byType(KFlatSeekTrack));
      expect(flat.left - box.left, 6);
      expect(box.right - flat.right, 6);
    });

    testWidgets('drag seeks once, on release', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, seeks: seeks)),
      );
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      final g = await tester.startGesture(Offset(box.left + 20, box.center.dy));
      await g.moveTo(Offset(box.left + 100, box.center.dy));
      expect(seeks, isEmpty);
      await g.up();
      expect(seeks.single.inMilliseconds, (100000 * 94 / 188).round());
    });

    testWidgets('a drag that outlives its track does not seek the next one', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _hosted(_bar(track: 1, levels: _levels, status: _ready, seeks: seeks)),
      );
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      final drag = await tester.startGesture(
        Offset(box.left + 20, box.center.dy),
      );
      await drag.moveTo(Offset(box.left + 100, box.center.dy));
      await tester.pump();
      await tester.pumpWidget(
        _hosted(
          _bar(
            track: 2,
            position: Duration.zero,
            duration: const Duration(seconds: 200),
            levels: _levels,
            status: _ready,
            seeks: seeks,
          ),
        ),
      );
      await drag.moveTo(Offset(box.left + 140, box.center.dy));
      await drag.up();
      await tester.pump();
      expect(seeks, isEmpty);
    });

    testWidgets('left and right seek 5 s while focused', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, seeks: seeks)),
      );
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      await tester.tapAt(Offset(box.left + 100, box.center.dy));
      seeks.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(seeks, [const Duration(seconds: 25), const Duration(seconds: 15)]);
    });

    testWidgets('no duration: taps and keys do nothing', (tester) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _hosted(
          _bar(levels: _levels, status: _ready, duration: null, seeks: seeks),
        ),
      );
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      await tester.tapAt(Offset(box.left + 100, box.center.dy));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(seeks, isEmpty);
    });

    testWidgets('announces itself as a slider with its value', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_hosted(_bar(levels: _levels, status: _ready)));
      final data = tester
          .getSemantics(find.byType(KWaveformSeekBar))
          .getSemanticsData();
      expect(data.label, 'Position');
      expect(data.value, '0:20 of 1:40');
      expect(data.flagsCollection.isSlider, isTrue);
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      handle.dispose();
    });
  });
}
