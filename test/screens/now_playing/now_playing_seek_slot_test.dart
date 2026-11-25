import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show UncontrolledProviderScope;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';
import 'package:kanaru/src/playback/state/playback_position_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/playback_scrub_provider.dart';
import 'package:kanaru/src/playback/ui/playback_time_label.dart';
import 'package:kanaru/src/playback/state/waveform_providers.dart';
import 'package:kanaru/src/playback/ui/playback_waveform_seek_bar.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_seek_slot.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/ui_host.dart';

final _levels = Uint8List.fromList(List.generate(120, (i) => (i * 7) % 256));

/// The engine fake reports no duration; the bar needs one to draw bars.
final _fourMinutes = playbackPositionProvider.overrideWith(
  (ref) => Stream.value(
    const PlaybackPosition(
      entryId: 1,
      position: Duration(seconds: 10),
      duration: Duration(minutes: 4),
    ),
  ),
);

/// A waveform for the entry that is playing.
final _playing = waveformProvider.overrideWith((ref) async* {
  final now = await ref.watch(nowPlayingProvider.future);
  yield WaveformView(
    entryId: now.entryId,
    levels: _levels,
    durationMs: 240000,
    status: WaveformStatus.ready,
  );
});

/// The playing entry's waveform in [status] (computing or none: no levels).
Override _playingWithStatus(WaveformStatus status) =>
    waveformProvider.overrideWith((ref) async* {
      final now = await ref.watch(nowPlayingProvider.future);
      yield WaveformView(entryId: now.entryId, status: status);
    });

/// A waveform that belongs to an entry other than the playing one.
final _stale = waveformProvider.overrideWith(
  (ref) => Stream.value(
    WaveformView(
      entryId: -1,
      status: WaveformStatus.ready,
      levels: _levels,
      durationMs: 240000,
    ),
  ),
);

Future<UiHost> _pump(WidgetTester tester, double width, {Override? waveform}) =>
    pumpWithPlayer(
      tester,
      const Align(child: NowPlayingSeekSlot()),
      size: Size(width, 800),
      overrides: [_fourMinutes, ?waveform],
    );

/// What the slot hands to the bar; how the bar draws it is tested in
/// kanaru_ui.
KWaveformSeekBar _bar(WidgetTester tester) =>
    tester.widget<KWaveformSeekBar>(find.byType(KWaveformSeekBar));

const _followKey = ValueKey('follows the scrub');
const _plainKey = ValueKey('ignores the scrub');
const _totalKey = ValueKey('total');

/// A settle timeout no test reaches: what shows while a seek settles.
const _neverTimesOut = Duration(hours: 1);

/// A settle timeout the timeout tests wait out in real time.
const _shortTimeout = Duration(milliseconds: 50);

/// The slot with an elapsed label that follows the scrub, one that does not
/// (the player bar's) and the total. [position], when set, replaces the
/// fixed 0:10 of 4:00.
Future<UiHost> _pumpWithLabels(
  WidgetTester tester,
  double width, {
  Override? position,
  Duration settleTimeout = _neverTimesOut,
}) => pumpWithPlayer(
  tester,
  const Align(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NowPlayingSeekSlot(),
        PlaybackTimeLabel(key: _followKey, followScrub: true),
        PlaybackTimeLabel(key: _plainKey),
        PlaybackTimeLabel(key: _totalKey, total: true, followScrub: true),
      ],
    ),
  ),
  size: Size(width, 800),
  overrides: [
    position ?? _fourMinutes,
    _playing,
    seekSettleTimeoutProvider.overrideWithValue(settleTimeout),
  ],
);

/// A position stream the test drives, starting at 0:10 of 4:00 on entry 1.
class _Positions {
  final _controller = StreamController<PlaybackPosition>.broadcast();

  Override get override => playbackPositionProvider.overrideWith((ref) async* {
    yield _at(1, 10);
    yield* _controller.stream;
  });

  static PlaybackPosition _at(int entry, double seconds) => PlaybackPosition(
    entryId: entry,
    position: Duration(milliseconds: (seconds * 1000).round()),
    duration: const Duration(minutes: 4),
  );

  Future<void> emit(WidgetTester tester, int entry, double seconds) async {
    _controller.add(_at(entry, seconds));
    // One frame delivers it, the next rebuilds what it changed.
    await tester.pump();
    await tester.pump();
  }
}

/// Drags from the start of the bar to [seconds] and lets go.
Future<void> _dragTo(WidgetTester tester, UiHost host, double seconds) async {
  final box = tester.getRect(find.byType(KWaveformSeekBar));
  final g = await tester.startGesture(
    Offset(box.left + 40, box.center.dy),
    kind: PointerDeviceKind.mouse,
  );
  await g.moveTo(Offset(_xAt(box, seconds), box.center.dy));
  await tester.pump();
  await tester.runAsync(() async {
    await g.up();
    await host.h.settle();
  });
  await tester.pump();
}

/// Lets [_shortTimeout] pass. The release ran in real time (so its seek
/// reaches the engine), and so does the timer it started.
Future<void> _waitShortTimeout(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(_shortTimeout * 3));
  await tester.pump();
}

String _label(WidgetTester tester, Key key) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(key), matching: find.byType(Text)),
    )
    .data!;

String? _spoken(WidgetTester tester) =>
    tester.getSemantics(find.byType(KWaveformSeekBar)).getSemanticsData().value;

/// x of [seconds] on the 240 s bar: (x - 6) / (width - 12) of the length.
double _xAt(Rect box, double seconds) =>
    box.left + 6 + (box.width - 12) * seconds / 240;

void main() {
  // 390 is the phone page, 560 the desktop track column.
  for (final width in [390.0, 560.0]) {
    group('slot at $width dp', () {
      testWidgets('holds the waveform bar in the 56 dp band', (tester) async {
        final host = await _pump(tester, width);
        await host.letStreamsArrive(tester);
        expect(find.byType(PlaybackWaveformSeekBar), findsOneWidget);
        expect(find.byType(KWaveformSeekBar), findsOneWidget);
        // One source for the slot and the band it holds.
        expect(nowPlayingSeekSlotHeight, seekBandHeight);
        expect(nowPlayingSeekSlotHeight, 56);
        expect(tester.getSize(find.byType(NowPlayingSeekSlot)).height, 56);
        expect(tester.getSize(find.byKey(waveformBandKey)).height, 56);
      });

      testWidgets('shows the dotted band while nothing is known', (
        tester,
      ) async {
        final host = await _pump(tester, width);
        await host.letStreamsArrive(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(_bar(tester).status, KWaveformStatus.unknown);
        expect(_bar(tester).levels, isNull);
        // The band layer stays (dots), no fallback seek bar.
        expect(find.byKey(waveformBandKey), findsOneWidget);
        expect(find.byKey(waveformFallbackKey), findsNothing);
      });

      testWidgets('draws the bars of the playing entry', (tester) async {
        final host = await _pump(tester, width, waveform: _playing);
        await host.letStreamsArrive(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(_bar(tester).status, KWaveformStatus.ready);
        expect(_bar(tester).levels, _levels);
        expect(find.byKey(waveformBandKey), findsOneWidget);
        expect(find.byKey(waveformFallbackKey), findsNothing);
        expect(
          tester.getSize(find.byType(NowPlayingSeekSlot)).height,
          nowPlayingSeekSlotHeight,
        );
      });

      testWidgets('no waveform for the playing entry: the fallback bar', (
        tester,
      ) async {
        final host = await _pump(
          tester,
          width,
          waveform: _playingWithStatus(WaveformStatus.none),
        );
        await host.letStreamsArrive(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(_bar(tester).status, KWaveformStatus.none);
        expect(_bar(tester).levels, isNull);
        expect(find.byKey(waveformFallbackKey), findsOneWidget);
        expect(tester.getSize(find.byType(NowPlayingSeekSlot)).height, 56);
      });

      testWidgets('computing for the playing entry: dots, no fallback', (
        tester,
      ) async {
        final host = await _pump(
          tester,
          width,
          waveform: _playingWithStatus(WaveformStatus.computing),
        );
        await host.letStreamsArrive(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(_bar(tester).status, KWaveformStatus.computing);
        expect(find.byKey(waveformBandKey), findsOneWidget);
        expect(find.byKey(waveformFallbackKey), findsNothing);
      });

      testWidgets('passes the time bubble and the cancel text', (tester) async {
        final host = await _pump(tester, width, waveform: _playing);
        await host.letStreamsArrive(tester);
        expect(_bar(tester).bubbleLabel!(const Duration(seconds: 65)), '1:05');
        expect(_bar(tester).cancelLabel, 'Release to cancel');
      });

      testWidgets('a drag shows the finger time in the following label and '
          'the spoken value; cancelling shows the real one, the release '
          'the target', (tester) async {
        final semantics = tester.ensureSemantics();
        final host = await _pumpWithLabels(tester, width);
        await host.letStreamsArrive(tester);
        expect(_label(tester, _followKey), '0:10');
        expect(_spoken(tester), '0:10 of 4:00');

        final box = tester.getRect(find.byType(KWaveformSeekBar));
        final g = await tester.startGesture(
          Offset(box.left + 40, box.center.dy),
          kind: PointerDeviceKind.mouse,
        );
        await g.moveTo(Offset(_xAt(box, 65.5), box.center.dy));
        await tester.pump();
        expect(_label(tester, _followKey), '1:05');
        expect(_spoken(tester), '1:05 of 4:00');
        // The player bar's label and the total never follow.
        expect(_label(tester, _plainKey), '0:10');
        expect(_label(tester, _totalKey), '4:00');

        // Up past the cancel distance: the real position again.
        await g.moveTo(Offset(_xAt(box, 65.5), box.center.dy - 60));
        await tester.pump();
        expect(_label(tester, _followKey), '0:10');
        expect(_spoken(tester), '0:10 of 4:00');

        await g.moveTo(Offset(_xAt(box, 90.5), box.center.dy));
        await tester.pump();
        expect(_label(tester, _followKey), '1:30');

        await tester.runAsync(() async {
          await g.up();
          await host.h.settle();
        });
        await tester.pump();
        // The seek target shows while it settles, not the old position.
        expect(_label(tester, _followKey), '1:30');
        expect(_spoken(tester), '1:30 of 4:00');
        expect(_label(tester, _plainKey), '0:10');
        semantics.dispose();
      });

      testWidgets('a seek the player never reports shows the real position '
          'after the timeout', (tester) async {
        final semantics = tester.ensureSemantics();
        final host = await _pumpWithLabels(
          tester,
          width,
          settleTimeout: _shortTimeout,
        );
        await host.letStreamsArrive(tester);
        await _dragTo(tester, host, 90.5);
        await _waitShortTimeout(tester);
        expect(host.container.read(playbackScrubProvider), isNull);
        expect(_label(tester, _followKey), '0:10');
        expect(_spoken(tester), '0:10 of 4:00');
        semantics.dispose();
      });

      testWidgets('a hold shows the finger time until the release', (
        tester,
      ) async {
        final host = await _pumpWithLabels(tester, width);
        await host.letStreamsArrive(tester);
        final box = tester.getRect(find.byType(KWaveformSeekBar));
        final g = await tester.startGesture(
          Offset(_xAt(box, 30.5), box.center.dy),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(_label(tester, _followKey), '0:30');
        expect(_label(tester, _plainKey), '0:10');
        await tester.runAsync(() async {
          await g.up();
          await host.h.settle();
        });
        await tester.pump();
        // The release is a tap: it seeks there, and the target shows.
        expect(_label(tester, _followKey), '0:30');
      });

      testWidgets('after a seek the label follows playback once the player '
          'reaches the target', (tester) async {
        final positions = _Positions();
        final host = await _pumpWithLabels(
          tester,
          width,
          position: positions.override,
        );
        await host.letStreamsArrive(tester);
        await _dragTo(tester, host, 65.5);
        expect(_label(tester, _followKey), '1:05');
        // An old tick before the seek lands changes nothing.
        await positions.emit(tester, 1, 10.5);
        expect(_label(tester, _followKey), '1:05');
        await positions.emit(tester, 1, 65.5);
        expect(host.container.read(playbackScrubProvider), isNull);
        expect(_label(tester, _followKey), '1:05');
        await positions.emit(tester, 1, 70.2);
        expect(_label(tester, _followKey), '1:10');
      });

      testWidgets('a first position in the next second still ends the settle', (
        tester,
      ) async {
        final positions = _Positions();
        final host = await _pumpWithLabels(
          tester,
          width,
          position: positions.override,
        );
        await host.letStreamsArrive(tester);
        await _dragTo(tester, host, 65.9);
        expect(_label(tester, _followKey), '1:05');
        await positions.emit(tester, 1, 66.1);
        expect(host.container.read(playbackScrubProvider), isNull);
        expect(_label(tester, _followKey), '1:06');
      });

      testWidgets('an entry change ends a settling seek', (tester) async {
        final positions = _Positions();
        final host = await _pumpWithLabels(
          tester,
          width,
          position: positions.override,
        );
        await host.letStreamsArrive(tester);
        await _dragTo(tester, host, 65.5);
        expect(_label(tester, _followKey), '1:05');
        await positions.emit(tester, 2, 0);
        expect(host.container.read(playbackScrubProvider), isNull);
        expect(_label(tester, _followKey), '0:00');
      });

      testWidgets('leaving the tree mid-drag clears the scrub', (tester) async {
        final host = await _pumpWithLabels(tester, width);
        await host.letStreamsArrive(tester);
        final box = tester.getRect(find.byType(KWaveformSeekBar));
        final g = await tester.startGesture(
          Offset(box.left + 40, box.center.dy),
          kind: PointerDeviceKind.mouse,
        );
        await g.moveTo(Offset(_xAt(box, 65.5), box.center.dy));
        await tester.pump();
        expect(host.container.read(playbackScrubProvider), isNotNull);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: host.container,
            child: const SizedBox(),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(host.container.read(playbackScrubProvider), isNull);
        await g.up();
      });

      testWidgets('leaving the tree mid-settle clears the target', (
        tester,
      ) async {
        final again = await _pumpWithLabels(tester, width);
        await again.letStreamsArrive(tester);
        await _dragTo(tester, again, 65.5);
        expect(again.container.read(playbackScrubProvider), isNotNull);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: again.container,
            child: const SizedBox(),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(again.container.read(playbackScrubProvider), isNull);
      });

      testWidgets("another entry's scrub is ignored", (tester) async {
        final host = await _pumpWithLabels(tester, width);
        await host.letStreamsArrive(tester);
        host.container
            .read(playbackScrubProvider.notifier)
            .report(2, const Duration(seconds: 65));
        await tester.pump();
        expect(_label(tester, _followKey), '0:10');
        host.container
            .read(playbackScrubProvider.notifier)
            .report(1, const Duration(seconds: 65));
        await tester.pump();
        expect(_label(tester, _followKey), '1:05');
      });

      testWidgets("never draws another entry's bars", (tester) async {
        final host = await _pump(tester, width, waveform: _stale);
        await host.letStreamsArrive(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(_bar(tester).levels, isNull);
        expect(_bar(tester).status, KWaveformStatus.unknown);
        expect(find.byKey(waveformFallbackKey), findsNothing);
      });

      testWidgets('a drag that outlives its track does not seek the next one', (
        tester,
      ) async {
        final host = await pumpWithPlayer(
          tester,
          const Align(child: NowPlayingSeekSlot()),
          size: Size(width, 800),
          overrides: [_playing],
        );
        await host.run(
          tester,
          () async => host.h.engine.emit(
            EngineLoaded(host.h.loadedToken, const Duration(seconds: 240)),
          ),
        );
        await host.letStreamsArrive(tester);

        final strip = tester.getRect(find.byType(KWaveformSeekBar));
        final drag = await tester.startGesture(
          Offset(strip.left + strip.width / 4, strip.center.dy),
          kind: PointerDeviceKind.mouse,
        );
        await drag.moveBy(const Offset(40, 0));
        await tester.pump();

        // Advance to the next track and even load its duration before release.
        final nextToken = host.h.engine.nexts.last!.token;
        await host.run(tester, () async {
          host.h.engine.emit(EngineAdvanced(nextToken));
          await host.h.settle();
          host.h.engine.emit(
            EngineLoaded(nextToken, const Duration(seconds: 180)),
          );
        });
        await host.letStreamsArrive(tester);

        await drag.moveBy(const Offset(40, 0));
        await tester.runAsync(() async {
          await drag.up();
          await host.h.settle();
        });
        await tester.pump();

        expect(
          host.h.engine.commands.where((c) => c.startsWith('seek:')),
          isEmpty,
        );

        final again = await tester.startGesture(
          Offset(strip.left + strip.width / 4, strip.center.dy),
          kind: PointerDeviceKind.mouse,
        );
        await again.moveBy(const Offset(40, 0));
        await tester.runAsync(() async {
          await again.up();
          await host.h.settle();
        });
        await tester.pump();
        expect(
          host.h.engine.commands.where((c) => c.startsWith('seek:')),
          hasLength(1),
        );
      });
    });
  }
}
