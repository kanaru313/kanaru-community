import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';
import 'package:kanaru/src/playback/state/playback_position_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
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
