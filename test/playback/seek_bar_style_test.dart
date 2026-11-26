import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show NotifierProvider;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/playback_views.dart';
import 'package:kanaru/src/playback/domain/seek_bar_options.dart';
import 'package:kanaru/src/playback/domain/seek_bar_style.dart';
import 'package:kanaru/src/playback/domain/waveform.dart';
import 'package:kanaru/src/playback/state/playback_position_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/seek_bar_style_provider.dart';
import 'package:kanaru/src/playback/state/waveform_providers.dart';
import 'package:kanaru/src/platform/domain/setting.dart';
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

/// A setting notifier that starts at [initial] instead of the stored value.
class _Starts<T> extends SettingNotifier<T> {
  _Starts(super.setting, this.initial);

  final T initial;

  @override
  T build() => initial;
}

Override _startsAt<T>(
  NotifierProvider<SettingNotifier<T>, T> provider,
  Setting<T> setting,
  T initial,
) => provider.overrideWith(() => _Starts<T>(setting, initial));

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
        _startsAt(seekBarStyleProvider, seekBarStyleSetting, SeekBarStyle.flat),
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
          .set(SeekBarStyle.bars);
      await host.letStreamsArrive(tester);
      await tester.pump();
      expect(waveform.started, before + 1);
      expect(_bar(tester).levels, isNotNull);
    },
  );

  for (final (name, options) in [
    ('squiggle drifting', const SquiggleSeekOptions()),
    ('squiggle still', const SquiggleSeekOptions(motion: SquiggleMotion.still)),
  ]) {
    testWidgets('$name never starts the waveform', (tester) async {
      final waveform = _CountingWaveform();
      final host = await pumpWithPlayer(
        tester,
        const Align(child: PlaybackWaveformSeekBar()),
        overrides: [
          _fourMinutes,
          waveform.override,
          _startsAt(
            seekBarStyleProvider,
            seekBarStyleSetting,
            SeekBarStyle.squiggle,
          ),
          _startsAt(
            squiggleSeekOptionsProvider,
            squiggleSeekOptionsSetting,
            options,
          ),
        ],
      );
      await host.letStreamsArrive(tester);
      expect(waveform.started, 0);
    });
  }

  testWidgets('squiggle as the fallback never starts the waveform', (
    tester,
  ) async {
    final waveform = _CountingWaveform();
    final host = await pumpWithPlayer(
      tester,
      const Align(child: PlaybackWaveformSeekBar()),
      overrides: [
        _fourMinutes,
        waveform.override,
        _startsAt(seekBarStyleProvider, seekBarStyleSetting, SeekBarStyle.flat),
        _startsAt(
          seekBarFallbackProvider,
          seekBarFallbackSetting,
          SeekBarFallback.squiggle,
        ),
        _startsAt(
          squiggleSeekOptionsProvider,
          squiggleSeekOptionsSetting,
          const SquiggleSeekOptions(motion: SquiggleMotion.music),
        ),
      ],
    );
    await host.letStreamsArrive(tester);
    expect(waveform.started, 0);
  });

  testWidgets('squiggle with music motion chosen starts the waveform', (
    tester,
  ) async {
    final waveform = _CountingWaveform();
    final host = await pumpWithPlayer(
      tester,
      const Align(child: PlaybackWaveformSeekBar()),
      overrides: [
        _fourMinutes,
        waveform.override,
        _startsAt(
          seekBarStyleProvider,
          seekBarStyleSetting,
          SeekBarStyle.squiggle,
        ),
        _startsAt(
          squiggleSeekOptionsProvider,
          squiggleSeekOptionsSetting,
          const SquiggleSeekOptions(motion: SquiggleMotion.music),
        ),
      ],
    );
    await host.letStreamsArrive(tester);
    expect(waveform.started, 1);
  });

  test('stored names decode, garbage falls back, reading writes nothing', () {
    expect(seekBarStyleSetting.defaultValue, SeekBarStyle.bars);
    expect(seekBarStyleSetting.decode('waveform'), SeekBarStyle.bars);
    expect(seekBarStyleSetting.decode('flat'), SeekBarStyle.flat);
    expect(seekBarStyleSetting.decode('bars'), SeekBarStyle.bars);
    for (final bad in <Object?>['sparkle', 3, null]) {
      expect(
        () => seekBarStyleSetting.decode(bad),
        throwsA(isA<FormatException>()),
      );
    }
    for (final s in SeekBarStyle.values) {
      expect(seekBarStyleSetting.decode(seekBarStyleSetting.encode(s)), s);
    }
    expect(seekBarFallbackSetting.defaultValue, SeekBarFallback.flat);
    expect(seekBarFallbackSetting.decode('squiggle'), SeekBarFallback.squiggle);
    expect(
      () => seekBarFallbackSetting.decode('bars'),
      throwsA(isA<FormatException>()),
    );
  });

  test('needsWaveform: wave kinds and chosen squiggle with music only', () {
    const drift = SquiggleSeekOptions();
    const music = SquiggleSeekOptions(motion: SquiggleMotion.music);
    for (final s in [
      SeekBarStyle.bars,
      SeekBarStyle.dots,
      SeekBarStyle.line,
      SeekBarStyle.mirror,
    ]) {
      expect(needsWaveform(s, drift), isTrue);
    }
    expect(needsWaveform(SeekBarStyle.flat, music), isFalse);
    expect(needsWaveform(SeekBarStyle.squiggle, drift), isFalse);
    expect(needsWaveform(SeekBarStyle.squiggle, music), isTrue);
  });
}
