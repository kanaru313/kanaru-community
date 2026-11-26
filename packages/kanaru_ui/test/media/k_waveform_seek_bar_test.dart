import 'dart:async' show unawaited;
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

const _cancelText = 'Release to cancel';

String _clock(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

Widget _bar({
  Uint8List? levels,
  KWaveformStatus status = _unknown,
  Duration position = const Duration(seconds: 20),
  Duration? duration = _total,
  Object? track,
  List<Duration>? seeks,
  Widget Function(BuildContext, KSeekState)? fallback,
  double width = 200,
  bool bubble = false,
  VoidCallback? onSeekEnd,
  ValueChanged<Duration?>? onScrub,
  KSeekKind kind = KSeekKind.bars,
  KWaveLook look = const KWaveLook(),
}) => SizedBox(
  width: width,
  child: KWaveformSeekBar(
    position: position,
    duration: duration,
    track: track,
    levels: levels,
    status: status,
    kind: kind,
    look: look,
    fallback: fallback,
    onSeek: (d) => seeks?.add(d),
    onSeekEnd: onSeekEnd,
    onScrub: onScrub,
    bubbleLabel: bubble ? _clock : null,
    cancelLabel: bubble ? _cancelText : null,
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

      desktopTest('Tab draws the line, a touch elsewhere hides it', (
        tester,
      ) async {
        await pumpBar(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_painter(tester)!.focusLine, isTrue);
        // Touch outside the bar: focus stays, the highlight mode turns touch.
        await tester.tapAt(const Offset(5, 5));
        await tester.pump();
        expect(FocusManager.instance.highlightMode, FocusHighlightMode.touch);
        expect(_painter(tester)!.focusLine, isFalse);
      });

      desktopTest('focus back from a route opened and closed by mouse: no '
          'line', (tester) async {
        final box = await pumpBar(tester);
        await mouseClick(tester, Offset(box.left + 100, box.center.dy));
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        unawaited(
          navigator.push(
            MaterialPageRoute<void>(builder: (_) => const Text('page')),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('page'), findsOneWidget);
        navigator.pop();
        await tester.pumpAndSettle();
        expect(
          FocusManager.instance.highlightMode,
          FocusHighlightMode.traditional,
        );
        expect(_painter(tester)!.focusLine, isFalse);
        // Focus did come back to the bar: a key shows its line.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(_painter(tester)!.focusLine, isTrue);
      });

      desktopTest('focus back from a dialog closed with Esc: line', (
        tester,
      ) async {
        final box = await pumpBar(tester);
        await mouseClick(tester, Offset(box.left + 100, box.center.dy));
        unawaited(
          showDialog<void>(
            context: tester.element(find.byType(KWaveformSeekBar)),
            builder: (_) => const AlertDialog(content: Text('dialog')),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('dialog'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('dialog'), findsNothing);
        expect(_painter(tester)!.focusLine, isTrue);
      });

      desktopTest('Shift+Tab back after a mouse click elsewhere: line', (
        tester,
      ) async {
        await tester.pumpWidget(
          _hosted(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(levels: _levels, status: _ready, track: 1),
                const SizedBox(width: 200, child: TextField()),
              ],
            ),
          ),
        );
        final box = tester.getRect(find.byType(KWaveformSeekBar));
        await mouseClick(tester, Offset(box.left + 100, box.center.dy));
        await mouseClick(tester, tester.getCenter(find.byType(TextField)));
        expect(_painter(tester)!.focusLine, isFalse);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(_painter(tester)!.focusLine, isTrue);
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

  group('time bubble and drag-up cancel', () {
    /// x of [seconds] on a 200 dp bar of 100 s: (x - 6) / 188 of the length.
    double xAt(Rect box, double seconds) => box.left + 6 + 188 * seconds / 100;

    /// Pumps a bar with the bubble on; [states] gets every state it draws
    /// (through the fallback: status none).
    Future<Rect> pumpBubbleBar(
      WidgetTester tester, {
      List<Duration>? seeks,
      List<KSeekState>? states,
      VoidCallback? onSeekEnd,
      Object? track = 1,
      Duration? duration = _total,
      ValueChanged<Duration?>? onScrub,
    }) async {
      await tester.pumpWidget(
        _hosted(
          _bar(
            status: states == null ? _ready : _none,
            levels: states == null ? _levels : null,
            track: track,
            duration: duration,
            seeks: seeks,
            onSeekEnd: onSeekEnd,
            onScrub: onScrub,
            bubble: true,
            fallback: states == null
                ? null
                : (context, state) {
                    states.add(state);
                    return const SizedBox.expand();
                  },
          ),
        ),
      );
      return tester.getRect(find.byType(KWaveformSeekBar));
    }

    testWidgets('a drag shows the time at the finger above the band', (
      tester,
    ) async {
      final box = await pumpBubbleBar(tester);
      final g = await tester.startGesture(Offset(box.left + 20, box.center.dy));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
      await tester.pump();
      expect(find.text('1:05'), findsOneWidget);
      final bubble = tester.getRect(find.text('1:05'));
      expect(bubble.center.dx, moreOrLessEquals(xAt(box, 65.5), epsilon: 1));
      expect(bubble.bottom, lessThanOrEqualTo(box.top - seekBubbleGap));
      // The band keeps its height: the bubble is in the overlay.
      expect(tester.getSize(find.byType(KWaveformSeekBar)).height, 56);
      await g.up();
      await tester.pump();
      expect(find.text('1:05'), findsNothing);
    });

    testWidgets('the bubble stays off the ends of the bar', (tester) async {
      final box = await pumpBubbleBar(tester);
      final g = await tester.startGesture(Offset(box.left + 60, box.center.dy));
      await g.moveTo(Offset(box.left + 1, box.center.dy));
      await tester.pump();
      final left = tester.getRect(find.text('0:00'));
      expect(left.center.dx, greaterThanOrEqualTo(box.left + 32 - 0.5));
      await g.moveTo(Offset(box.right - 1, box.center.dy));
      await tester.pump();
      final right = tester.getRect(find.text('1:40'));
      expect(right.center.dx, lessThanOrEqualTo(box.right - 32 + 0.5));
      await g.up();
    });

    testWidgets('drag right then up 60: the real position, no seek', (
      tester,
    ) async {
      final seeks = <Duration>[];
      final states = <KSeekState>[];
      var ends = 0;
      final box = await pumpBubbleBar(
        tester,
        seeks: seeks,
        states: states,
        onSeekEnd: () => ends++,
      );
      final g = await tester.startGesture(Offset(box.left + 20, box.center.dy));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
      await tester.pump();
      expect(states.last.progress, moreOrLessEquals(0.655, epsilon: 0.001));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy - 60));
      await tester.pump();
      expect(find.text(_cancelText), findsOneWidget);
      expect(find.text('1:05'), findsNothing);
      expect(states.last.cancelling, isTrue);
      expect(states.last.dragging, isTrue);
      // The real position (20 s) shows while cancelling.
      expect(states.last.progress, 0.2);
      expect(
        states.last.pointerFraction,
        moreOrLessEquals(0.655, epsilon: 1e-3),
      );
      await g.up();
      await tester.pump();
      expect(seeks, isEmpty);
      expect(ends, 1);
      expect(find.text(_cancelText), findsNothing);
      expect(states.last.cancelling, isFalse);
      expect(states.last.dragging, isFalse);
    });

    testWidgets('up 60 then back down to 10: seeking resumes, one seek', (
      tester,
    ) async {
      final seeks = <Duration>[];
      var ends = 0;
      final box = await pumpBubbleBar(
        tester,
        seeks: seeks,
        onSeekEnd: () => ends++,
      );
      final g = await tester.startGesture(Offset(box.left + 20, box.center.dy));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy - 60));
      await tester.pump();
      expect(find.text(_cancelText), findsOneWidget);
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy - 10));
      await tester.pump();
      expect(find.text(_cancelText), findsNothing);
      expect(find.text('1:05'), findsOneWidget);
      await g.up();
      expect(seeks, hasLength(1));
      expect(seeks.single.inMilliseconds, 65500);
      expect(ends, 1);
    });

    testWidgets('the cancel is measured from the pointer down, not the '
        'drag start', (tester) async {
      final states = <KSeekState>[];
      final box = await pumpBubbleBar(tester, states: states);
      final g = await tester.startGesture(Offset(box.left + 20, box.center.dy));
      // Up 15 before the horizontal lock, then right: the drag starts 15 up.
      await g.moveBy(const Offset(0, -15));
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(states.last.dragging, isTrue);
      expect(states.last.cancelling, isFalse);
      // 50 above the down point, 35 above the drag start.
      await g.moveBy(const Offset(0, -35));
      await tester.pump();
      expect(states.last.cancelling, isTrue);
      expect(find.text(_cancelText), findsOneWidget);
      await g.up();
    });

    testWidgets('48 dp up is not yet cancelling, 49 is', (tester) async {
      final box = await pumpBubbleBar(tester);
      final g = await tester.startGesture(Offset(box.left + 20, box.center.dy));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy - 48));
      await tester.pump();
      expect(find.text(_cancelText), findsNothing);
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy - 49));
      await tester.pump();
      expect(find.text(_cancelText), findsOneWidget);
      await g.up();
    });

    group('haptic tick', () {
      Future<List<Object?>> recordHaptics(WidgetTester tester) async {
        final calls = <Object?>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add(call.arguments);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        return calls;
      }

      Future<void> crossTwice(WidgetTester tester, Rect box) async {
        final g = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
        );
        final x = xAt(box, 65.5);
        await g.moveTo(Offset(x, box.center.dy));
        await g.moveTo(Offset(x, box.center.dy - 60));
        await g.moveTo(Offset(x - 10, box.center.dy - 80));
        await g.moveTo(Offset(x, box.center.dy - 10));
        await g.moveTo(Offset(x, box.center.dy - 70));
        await g.up();
        await tester.pump();
      }

      testWidgets('mobile: once per upward crossing', (tester) async {
        final calls = await recordHaptics(tester);
        final box = await pumpBubbleBar(tester);
        await crossTwice(tester, box);
        expect(calls, [
          'HapticFeedbackType.selectionClick',
          'HapticFeedbackType.selectionClick',
        ]);
      });

      testWidgets('desktop: none', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          final calls = await recordHaptics(tester);
          final box = await pumpBubbleBar(tester);
          await crossTwice(tester, box);
          expect(calls, isEmpty);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });

    testWidgets('a hold shows the time, the release seeks once', (
      tester,
    ) async {
      final seeks = <Duration>[];
      final states = <KSeekState>[];
      var ends = 0;
      final box = await pumpBubbleBar(
        tester,
        seeks: seeks,
        states: states,
        onSeekEnd: () => ends++,
      );
      final g = await tester.startGesture(
        Offset(xAt(box, 30.5), box.center.dy),
      );
      await tester.pump(_ms(100));
      expect(find.text('0:30'), findsNothing);
      await tester.pump(_ms(60));
      expect(find.text('0:30'), findsOneWidget);
      expect(states.last.holding, isTrue);
      expect(states.last.dragging, isFalse);
      // Nothing seeks while held: the played part stays at 20 s.
      expect(states.last.progress, 0.2);
      expect(seeks, isEmpty);
      await g.up();
      await tester.pump();
      expect(find.text('0:30'), findsNothing);
      expect(states.last.holding, isFalse);
      expect(seeks.single.inMilliseconds, 30500);
      expect(ends, 1);
    });

    testWidgets('a hold turns into a drag the bubble follows', (tester) async {
      final seeks = <Duration>[];
      final box = await pumpBubbleBar(tester, seeks: seeks);
      final g = await tester.startGesture(
        Offset(xAt(box, 30.5), box.center.dy),
      );
      await tester.pump(_ms(200));
      expect(find.text('0:30'), findsOneWidget);
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
      await tester.pump();
      expect(find.text('0:30'), findsNothing);
      expect(find.text('1:05'), findsOneWidget);
      await g.up();
      expect(seeks.single.inMilliseconds, 65500);
    });

    testWidgets('a move past the slop before the delay is no hold', (
      tester,
    ) async {
      final states = <KSeekState>[];
      final box = await pumpBubbleBar(tester, states: states);
      final g = await tester.startGesture(
        Offset(xAt(box, 30.5), box.center.dy),
      );
      await tester.pump(_ms(50));
      await g.moveBy(const Offset(30, 0));
      await tester.pump(_ms(200));
      expect(states.last.holding, isFalse);
      expect(states.last.dragging, isTrue);
      await g.up();
    });

    testWidgets('a pointer cancel never seeks, mid-hold or mid-drag', (
      tester,
    ) async {
      final seeks = <Duration>[];
      var ends = 0;
      final box = await pumpBubbleBar(
        tester,
        seeks: seeks,
        onSeekEnd: () => ends++,
      );
      final held = await tester.startGesture(
        Offset(xAt(box, 30.5), box.center.dy),
      );
      await tester.pump(_ms(200));
      expect(find.text('0:30'), findsOneWidget);
      await held.cancel();
      await tester.pump();
      expect(find.text('0:30'), findsNothing);

      final dragged = await tester.startGesture(
        Offset(box.left + 20, box.center.dy),
      );
      await dragged.moveTo(Offset(xAt(box, 65.5), box.center.dy));
      await tester.pump();
      expect(find.text('1:05'), findsOneWidget);
      await dragged.cancel();
      await tester.pump();
      expect(find.text('1:05'), findsNothing);
      expect(seeks, isEmpty);
      expect(ends, 1);
    });

    testWidgets('a track change ends a hold and drops a drag', (tester) async {
      final seeks = <Duration>[];
      var ends = 0;
      var box = await pumpBubbleBar(
        tester,
        seeks: seeks,
        onSeekEnd: () => ends++,
      );
      final held = await tester.startGesture(
        Offset(xAt(box, 30.5), box.center.dy),
      );
      await tester.pump(_ms(200));
      expect(find.text('0:30'), findsOneWidget);
      box = await pumpBubbleBar(
        tester,
        seeks: seeks,
        onSeekEnd: () => ends++,
        track: 2,
      );
      expect(find.text('0:30'), findsNothing);
      await held.up();
      await tester.pump();
      // The time held was the old track's: the release seeks nothing.
      expect(seeks, isEmpty);
      expect(ends, 0);

      final dragged = await tester.startGesture(
        Offset(box.left + 20, box.center.dy),
      );
      await dragged.moveTo(Offset(xAt(box, 65.5), box.center.dy));
      await tester.pump();
      expect(find.text('1:05'), findsOneWidget);
      await pumpBubbleBar(
        tester,
        seeks: seeks,
        onSeekEnd: () => ends++,
        track: 3,
      );
      expect(find.text('1:05'), findsNothing);
      await dragged.moveTo(Offset(xAt(box, 80), box.center.dy));
      await dragged.up();
      await tester.pump();
      expect(seeks, isEmpty);
      expect(ends, 1);
    });

    testWidgets('leaving the tree mid-hold leaves no bubble or timer', (
      tester,
    ) async {
      final box = await pumpBubbleBar(tester);
      final early = await tester.startGesture(
        Offset(xAt(box, 30.5), box.center.dy),
      );
      await tester.pump(_ms(50));
      await tester.pumpWidget(_hosted(const SizedBox()));
      await tester.pump(_ms(200));
      expect(find.text('0:30'), findsNothing);
      await early.up();

      final box2 = await pumpBubbleBar(tester);
      final held = await tester.startGesture(
        Offset(xAt(box2, 30.5), box2.center.dy),
      );
      await tester.pump(_ms(200));
      expect(find.text('0:30'), findsOneWidget);
      await tester.pumpWidget(_hosted(const SizedBox()));
      expect(find.text('0:30'), findsNothing);
      await held.up();
    });

    testWidgets('without a label: no bubble, no hold, no cancel', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        _hosted(_bar(levels: _levels, status: _ready, seeks: seeks)),
      );
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      final g = await tester.startGesture(Offset(box.left + 20, box.center.dy));
      await tester.pump(_ms(200));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
      await g.moveTo(Offset(xAt(box, 65.5), box.center.dy - 60));
      await tester.pump();
      expect(find.text('1:05'), findsNothing);
      expect(find.text(_cancelText), findsNothing);
      await g.up();
      expect(seeks.single.inMilliseconds, 65500);
    });

    group('scrub report', () {
      /// Every value the bar reported, as whole milliseconds (null: none).
      List<int?> ms(List<Duration?> scrubs) => [
        for (final s in scrubs) s?.inMilliseconds,
      ];

      testWidgets('a drag reports the finger, up past 48 none, down again '
          'the finger, the release none', (tester) async {
        final scrubs = <Duration?>[];
        final box = await pumpBubbleBar(tester, onScrub: scrubs.add);
        final g = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
        );
        await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
        await tester.pump();
        expect(scrubs.last?.inMilliseconds, 65500);
        await g.moveTo(Offset(xAt(box, 65.5), box.center.dy - 60));
        await tester.pump();
        expect(scrubs.last, isNull);
        await g.moveTo(Offset(xAt(box, 40.5), box.center.dy - 10));
        await tester.pump();
        expect(scrubs.last?.inMilliseconds, 40500);
        final before = scrubs.length;
        await g.up();
        await tester.pump();
        expect(ms(scrubs.sublist(before)), [null]);
      });

      testWidgets('only changes are reported', (tester) async {
        final scrubs = <Duration?>[];
        final box = await pumpBubbleBar(tester, onScrub: scrubs.add);
        final g = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
        );
        await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
        await tester.pump();
        // Moving up 20 changes no time and does not cancel yet.
        await g.moveTo(Offset(xAt(box, 65.5), box.center.dy - 20));
        await tester.pump();
        await g.up();
        await tester.pump();
        expect(ms(scrubs).last, isNull);
        for (var i = 1; i < scrubs.length; i++) {
          expect(scrubs[i], isNot(scrubs[i - 1]));
        }
      });

      testWidgets('a hold reports the finger, the release none', (
        tester,
      ) async {
        final scrubs = <Duration?>[];
        final box = await pumpBubbleBar(tester, onScrub: scrubs.add);
        final g = await tester.startGesture(
          Offset(xAt(box, 30.5), box.center.dy),
        );
        await tester.pump(_ms(100));
        expect(scrubs, isEmpty);
        await tester.pump(_ms(60));
        expect(ms(scrubs), [30500]);
        await g.up();
        await tester.pump();
        expect(ms(scrubs), [30500, null]);
      });

      testWidgets('a pointer cancel reports none, mid-hold and mid-drag', (
        tester,
      ) async {
        final scrubs = <Duration?>[];
        final box = await pumpBubbleBar(tester, onScrub: scrubs.add);
        final held = await tester.startGesture(
          Offset(xAt(box, 30.5), box.center.dy),
        );
        await tester.pump(_ms(200));
        expect(scrubs.last?.inMilliseconds, 30500);
        await held.cancel();
        await tester.pump();
        expect(scrubs.last, isNull);

        final dragged = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
        );
        await dragged.moveTo(Offset(xAt(box, 65.5), box.center.dy));
        await tester.pump();
        expect(scrubs.last?.inMilliseconds, 65500);
        await dragged.cancel();
        await tester.pump();
        expect(scrubs.last, isNull);
      });

      testWidgets('a track change reports none after the frame', (
        tester,
      ) async {
        final scrubs = <Duration?>[];
        var box = await pumpBubbleBar(tester, onScrub: scrubs.add);
        final held = await tester.startGesture(
          Offset(xAt(box, 30.5), box.center.dy),
        );
        await tester.pump(_ms(200));
        expect(scrubs.last?.inMilliseconds, 30500);
        box = await pumpBubbleBar(tester, onScrub: scrubs.add, track: 2);
        expect(scrubs.last, isNull);
        await held.up();

        final dragged = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
        );
        await dragged.moveTo(Offset(xAt(box, 65.5), box.center.dy));
        await tester.pump();
        expect(scrubs.last?.inMilliseconds, 65500);
        await pumpBubbleBar(tester, onScrub: scrubs.add, track: 3);
        expect(scrubs.last, isNull);
        await dragged.up();
        await tester.pump();
        expect(scrubs.last, isNull);
      });

      testWidgets('leaving the tree mid-drag reports none', (tester) async {
        final scrubs = <Duration?>[];
        final box = await pumpBubbleBar(tester, onScrub: scrubs.add);
        final g = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
        );
        await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
        await tester.pump();
        expect(scrubs.last?.inMilliseconds, 65500);
        await tester.pumpWidget(_hosted(const SizedBox()));
        expect(scrubs.last, isNull);
        await g.up();
      });

      testWidgets('a tap reports nothing', (tester) async {
        final scrubs = <Duration?>[];
        final box = await pumpBubbleBar(tester, onScrub: scrubs.add);
        await tester.tapAt(Offset(xAt(box, 30.5), box.center.dy));
        await tester.pump();
        expect(scrubs, isEmpty);
      });

      testWidgets('without a callback a drag still seeks', (tester) async {
        final seeks = <Duration>[];
        final box = await pumpBubbleBar(tester, seeks: seeks);
        final g = await tester.startGesture(
          Offset(box.left + 20, box.center.dy),
        );
        await g.moveTo(Offset(xAt(box, 65.5), box.center.dy));
        await tester.pump();
        await g.up();
        expect(seeks.single.inMilliseconds, 65500);
      });
    });
  });

  group('touch feedback', () {
    const jelly = KWaveLook(feedback: KSeekFeedback.jelly);
    const lens = KWaveLook(feedback: KSeekFeedback.lens);

    Widget feedbackBar({
      KWaveLook look = jelly,
      List<Duration>? seeks,
      KSeekKind kind = KSeekKind.bars,
    }) => _bar(
      levels: _levels,
      status: _ready,
      track: 1,
      look: look,
      kind: kind,
      seeks: seeks,
      bubble: true,
    );

    Future<Rect> pumpSteady(
      WidgetTester tester,
      Widget bar, {
      bool reduceMotion = false,
    }) async {
      await tester.pumpWidget(_hosted(bar, reduceMotion: reduceMotion));
      await tester.pump();
      return tester.getRect(find.byType(KWaveformSeekBar));
    }

    testWidgets('steady playback with feedback on schedules no frames', (
      tester,
    ) async {
      await pumpSteady(tester, feedbackBar());
      expect(_isSteady(tester), isTrue);
      expect(_idle(tester), isTrue);
      final recorded = WaveformPictures.recordings;
      for (var i = 1; i <= 20; i++) {
        await tester.pumpWidget(
          _hosted(
            _bar(
              levels: _levels,
              status: _ready,
              track: 1,
              look: jelly,
              position: Duration(milliseconds: 20000 + i * 100),
            ),
          ),
        );
        expect(_idle(tester), isTrue);
      }
      expect(WaveformPictures.recordings, recorded);
    });

    // Mid density at 200 dp: 38 bars, the first at x 6, 5 dp apart.
    double barAt(double dx) => (dx - 6) / 5;

    for (final (name, look) in [('jelly', jelly), ('lens', lens)]) {
      testWidgets('$name: a held finger draws scaled bars directly, the '
          'extreme is on the bar under it, the release returns to the '
          'pictures and a stopped ticker', (tester) async {
        final box = await pumpSteady(tester, feedbackBar(look: look));
        final g = await tester.startGesture(
          Offset(box.left + 100, box.center.dy),
        );
        await tester.pump(_ms(200));
        for (var i = 0; i < 40; i++) {
          await tester.pump(_ms(16));
        }
        expect(_painter(tester)!.pictures, isNull);
        final factors = _painter(tester)!.factors!;
        var extreme = 0;
        for (var i = 0; i < factors.length; i++) {
          final more = look == lens
              ? factors[i] > factors[extreme]
              : factors[i] < factors[extreme];
          if (more) extreme = i;
        }
        expect(extreme, closeTo(barAt(100), 1));
        expect(
          look == lens ? factors[extreme] : 1 - factors[extreme],
          greaterThan(0.2),
        );
        await g.up();
        for (var i = 0; i < 120; i++) {
          await tester.pump(_ms(16));
        }
        expect(_idle(tester), isTrue);
        expect(_isSteady(tester), isTrue);
        expect(_painter(tester)!.factors, isNull);
      });

      testWidgets('$name: a finger resting still schedules no more frames '
          'but keeps the bars scaled', (tester) async {
        final box = await pumpSteady(tester, feedbackBar(look: look));
        final g = await tester.startGesture(
          Offset(box.left + 100, box.center.dy),
        );
        await tester.pump(_ms(200));
        for (var i = 0; i < 150; i++) {
          await tester.pump(_ms(16));
        }
        expect(_idle(tester), isTrue);
        expect(_painter(tester)!.pictures, isNull);
        expect(_painter(tester)!.factors!.any((f) => f != 1), isTrue);
        await g.up();
        for (var i = 0; i < 120; i++) {
          await tester.pump(_ms(16));
        }
        expect(_idle(tester), isTrue);
        expect(_isSteady(tester), isTrue);
      });

      testWidgets('$name: on the fallback (no waveform) it costs no frames', (
        tester,
      ) async {
        // The flat fallback animates under a finger by itself: the feedback
        // must add nothing to what a bar without feedback schedules.
        Future<List<int>> run(KWaveLook look) async {
          final seeks = <Duration>[];
          await tester.pumpWidget(
            _hosted(
              _bar(
                status: _none,
                track: 1,
                look: look,
                bubble: true,
                seeks: seeks,
              ),
            ),
          );
          await tester.pump();
          final box = tester.getRect(find.byType(KWaveformSeekBar));
          final g = await tester.startGesture(
            Offset(box.left + 100, box.center.dy),
          );
          final counts = <int>[];
          for (var i = 0; i < 30; i++) {
            await tester.pump(_ms(16));
            counts.add(tester.binding.transientCallbackCount);
          }
          await g.up();
          await tester.pump();
          expect(seeks, hasLength(1));
          for (var i = 0; i < 60; i++) {
            await tester.pump(_ms(16));
            counts.add(tester.binding.transientCallbackCount);
          }
          return counts;
        }

        final without = await run(const KWaveLook());
        await tester.pumpWidget(const SizedBox());
        expect(await run(look), without);
      });

      testWidgets('$name: on the dotted row (computing) no frames run', (
        tester,
      ) async {
        await tester.pumpWidget(
          _hosted(_bar(status: _computing, track: 1, look: look, bubble: true)),
        );
        await tester.pump();
        final box = tester.getRect(find.byType(KWaveformSeekBar));
        final g = await tester.startGesture(
          Offset(box.left + 100, box.center.dy),
        );
        await tester.pump(_ms(300));
        await tester.pump(_ms(100));
        expect(_idle(tester), isTrue);
        expect(_painter(tester)!.factors, isNull);
        await g.up();
      });
    }

    testWidgets('a tap pokes a ripple that settles and stops the ticker', (
      tester,
    ) async {
      final seeks = <Duration>[];
      final box = await pumpSteady(tester, feedbackBar(seeks: seeks));
      await tester.tapAt(Offset(box.left + 100, box.center.dy));
      await tester.pump();
      expect(seeks, hasLength(1));
      expect(_idle(tester), isFalse);
      await tester.pump(_ms(16));
      final factors = _painter(tester)!.factors!;
      var widest = 0;
      for (var i = 0; i < factors.length; i++) {
        if ((factors[i] - 1).abs() > (factors[widest] - 1).abs()) widest = i;
      }
      expect(widest, closeTo(barAt(100), 2));
      expect((factors[widest] - 1).abs(), greaterThan(0.02));
      for (var i = 0; i < 120; i++) {
        await tester.pump(_ms(16));
      }
      expect(_idle(tester), isTrue);
      expect(_isSteady(tester), isTrue);
    });

    testWidgets('a key seek pokes a small ripple', (tester) async {
      final seeks = <Duration>[];
      await pumpSteady(tester, feedbackBar(seeks: seeks));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(seeks, hasLength(1));
      expect(_idle(tester), isFalse);
      for (var i = 0; i < 120; i++) {
        await tester.pump(_ms(16));
      }
      expect(_idle(tester), isTrue);
    });

    testWidgets('a muted ticker (TickerMode off) schedules no frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(Center(child: TickerMode(enabled: false, child: feedbackBar()))),
      );
      await tester.pump();
      final box = tester.getRect(find.byType(KWaveformSeekBar));
      final g = await tester.startGesture(
        Offset(box.left + 100, box.center.dy),
      );
      await tester.pump(_ms(300));
      expect(_idle(tester), isTrue);
      await g.up();
    });

    testWidgets('reduced motion: no feedback at all', (tester) async {
      final seeks = <Duration>[];
      final box = await pumpSteady(
        tester,
        feedbackBar(seeks: seeks),
        reduceMotion: true,
      );
      final g = await tester.startGesture(
        Offset(box.left + 100, box.center.dy),
      );
      await tester.pump(_ms(300));
      expect(_idle(tester), isTrue);
      expect(_painter(tester)!.factors, isNull);
      expect(_isSteady(tester), isTrue);
      await g.up();
      await tester.pump();
      expect(seeks, hasLength(1));
      expect(_idle(tester), isTrue);
    });

    testWidgets('feedback off: a press schedules no frames', (tester) async {
      final box = await pumpSteady(
        tester,
        feedbackBar(look: const KWaveLook()),
      );
      final g = await tester.startGesture(
        Offset(box.left + 100, box.center.dy),
      );
      await tester.pump(_ms(300));
      expect(_idle(tester), isTrue);
      expect(_isSteady(tester), isTrue);
      await g.up();
    });

    testWidgets('a drag cancelled upwards stops denting', (tester) async {
      final box = await pumpSteady(tester, feedbackBar());
      final g = await tester.startGesture(
        Offset(box.left + 100, box.center.dy),
      );
      await tester.pump(_ms(200));
      await g.moveBy(const Offset(20, 0));
      await tester.pump(_ms(16));
      await g.moveBy(const Offset(0, -80));
      for (var i = 0; i < 120; i++) {
        await tester.pump(_ms(16));
      }
      expect(_idle(tester), isTrue);
      await g.up();
    });

    testWidgets('leaving the tree mid-wobble is clean', (tester) async {
      final box = await pumpSteady(tester, feedbackBar());
      await tester.tapAt(Offset(box.left + 100, box.center.dy));
      await tester.pump(_ms(32));
      await tester.pumpWidget(host(const SizedBox()));
      expect(tester.takeException(), isNull);
      expect(_idle(tester), isTrue);
    });

    for (final kind in KSeekKind.values) {
      testWidgets('${kind.name} draws steady and under feedback', (
        tester,
      ) async {
        final box = await pumpSteady(tester, feedbackBar(kind: kind));
        expect(_painter(tester)!.style.kind, kind);
        final g = await tester.startGesture(
          Offset(box.left + 100, box.center.dy),
        );
        await tester.pump(_ms(250));
        await tester.pump(_ms(50));
        expect(tester.takeException(), isNull);
        await g.up();
        await tester.pump(_ms(16));
      });
    }

    testWidgets('a changed look records the bars again', (tester) async {
      await pumpSteady(tester, feedbackBar(look: const KWaveLook()));
      final before = WaveformPictures.recordings;
      await pumpSteady(
        tester,
        feedbackBar(look: const KWaveLook(density: KWaveDensity.dense)),
      );
      expect(WaveformPictures.recordings, before + 1);
      expect(_isSteady(tester), isTrue);
    });
  });
}
