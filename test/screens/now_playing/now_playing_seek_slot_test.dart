import 'dart:typed_data';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
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
    instant: true,
  );
});

/// A waveform that belongs to an entry other than the playing one.
final _stale = waveformProvider.overrideWith(
  (ref) => Stream.value(
    WaveformView(entryId: -1, levels: _levels, durationMs: 240000),
  ),
);

Future<UiHost> _pump(WidgetTester tester, double width, {Override? waveform}) =>
    pumpWithPlayer(
      tester,
      const Align(child: NowPlayingSeekSlot()),
      size: Size(width, 800),
      overrides: [_fourMinutes, ?waveform],
    );

void main() {
  // 390 is the phone page, 560 the desktop track column.
  for (final width in [390.0, 560.0]) {
    group('slot at $width dp', () {
      testWidgets('holds the waveform bar at 48 dp', (tester) async {
        final host = await _pump(tester, width);
        await host.letStreamsArrive(tester);
        expect(find.byType(PlaybackWaveformSeekBar), findsOneWidget);
        expect(find.byType(KWaveformSeekBar), findsOneWidget);
        expect(find.byType(KSeekBar), findsNothing);
        expect(
          tester.getSize(find.byType(NowPlayingSeekSlot)).height,
          nowPlayingSeekSlotHeight,
        );
        expect(nowPlayingSeekSlotHeight, 48);
      });

      testWidgets('is flat while there are no levels', (tester) async {
        final host = await _pump(tester, width);
        await host.letStreamsArrive(tester);
        expect(find.byType(KFlatSeekTrack), findsOneWidget);
        expect(find.byKey(const ValueKey('waveform bars')), findsNothing);
      });

      testWidgets('draws the bars of the playing entry', (tester) async {
        final host = await _pump(tester, width, waveform: _playing);
        await host.letStreamsArrive(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('waveform bars')), findsOneWidget);
        expect(find.byType(KFlatSeekTrack), findsNothing);
        expect(
          tester.getSize(find.byType(NowPlayingSeekSlot)).height,
          nowPlayingSeekSlotHeight,
        );
      });

      testWidgets("never draws another entry's bars", (tester) async {
        final host = await _pump(tester, width, waveform: _stale);
        await host.letStreamsArrive(tester);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('waveform bars')), findsNothing);
        expect(find.byType(KFlatSeekTrack), findsOneWidget);
      });
    });
  }
}
