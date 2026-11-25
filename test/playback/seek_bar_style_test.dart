import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/domain/seek_bar_style.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';
import 'package:kanaru/src/playback/state/playback_position_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/seek_bar_style_provider.dart';
import 'package:kanaru/src/playback/state/waveform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/ui/playback_waveform_seek_bar.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'support/ui_host.dart';

final _levels = Uint8List.fromList(List.generate(120, (i) => (i * 7) % 256));

final _fourMinutes = playbackPositionProvider.overrideWith(
  (ref) => Stream.value(
    const PlaybackPosition(
      entryId: 1,
      position: Duration(seconds: 10),
      duration: Duration(minutes: 4),
    ),
  ),
);

/// A waveform provider that counts how often it is started.
class _CountingWaveform {
  int started = 0;

  Override get override => waveformProvider.overrideWith((ref) async* {
    started++;
    final now = await ref.watch(nowPlayingProvider.future);
    yield WaveformView(
      entryId: now.entryId,
      levels: _levels,
      durationMs: 240000,
      status: WaveformStatus.ready,
    );
  });
}

/// A seek bar style that starts flat.
class _StartsFlat extends SettingNotifier<SeekBarStyle> {
  _StartsFlat() : super(seekBarStyleSetting);

  @override
  SeekBarStyle build() => SeekBarStyle.flat;
}

KWaveformSeekBar _bar(WidgetTester tester) =>
    tester.widget<KWaveformSeekBar>(find.byType(KWaveformSeekBar));

void main() {
  testWidgets('waveform style listens to the waveform and draws its levels', (
    tester,
  ) async {
    final waveform = _CountingWaveform();
    final host = await pumpWithPlayer(
      tester,
      const Align(child: PlaybackWaveformSeekBar()),
      overrides: [_fourMinutes, waveform.override],
    );
    await host.letStreamsArrive(tester);
    expect(waveform.started, 1);
    expect(_bar(tester).levels, isNotNull);
  });

  testWidgets('mounted flat from the start, the waveform is never started', (
    tester,
  ) async {
    final waveform = _CountingWaveform();
    final host = await pumpWithPlayer(
      tester,
      const Align(child: PlaybackWaveformSeekBar()),
      overrides: [
        _fourMinutes,
        waveform.override,
        seekBarStyleProvider.overrideWith(_StartsFlat.new),
      ],
    );
    await host.letStreamsArrive(tester);
    expect(waveform.started, 0);
    expect(_bar(tester).levels, isNull);
  });

  testWidgets(
    'switching to flat drops the levels, back to waveform restores them',
    (tester) async {
      final waveform = _CountingWaveform();
      final host = await pumpWithPlayer(
        tester,
        const Align(child: PlaybackWaveformSeekBar()),
        overrides: [_fourMinutes, waveform.override],
      );
      await host.container
          .read(seekBarStyleProvider.notifier)
          .set(SeekBarStyle.flat);
      await host.letStreamsArrive(tester);
      await tester.pump();
      expect(_bar(tester).levels, isNull);
      // Switching back to the waveform started it exactly when it was needed.
      final before = waveform.started;
      await host.container
          .read(seekBarStyleProvider.notifier)
          .set(SeekBarStyle.waveform);
      await host.letStreamsArrive(tester);
      await tester.pump();
      expect(waveform.started, before + 1);
      expect(_bar(tester).levels, isNotNull);
    },
  );

  test('an unknown stored name decodes to the default', () {
    expect(
      () => seekBarStyleSetting.decode('sparkle'),
      throwsA(isA<FormatException>()),
    );
    expect(seekBarStyleSetting.defaultValue, SeekBarStyle.waveform);
    expect(seekBarStyleSetting.decode('flat'), SeekBarStyle.flat);
    expect(seekBarStyleSetting.encode(SeekBarStyle.flat), 'flat');
  });
}
