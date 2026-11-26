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
  _CountingWaveform({this.status = WaveformStatus.ready});

  /// What the provider reports for the playing entry.
  final WaveformStatus status;
  int started = 0;

  Override get override => waveformProvider.overrideWith((ref) async* {
    started++;
    final now = await ref.watch(nowPlayingProvider.future);
    yield WaveformView(
      entryId: now.entryId,
      levels: status == WaveformStatus.ready ? _levels : null,
      durationMs: 240000,
      status: status,
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

/// The painter-less state of the squiggle track the fallback built.
KSquiggleTrack _squiggleTrack(WidgetTester tester) =>
    tester.widget<KSquiggleTrack>(find.byType(KSquiggleTrack));

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
    expect(find.byType(KFlatStyledSeekBar), findsOneWidget);
    expect(find.byType(KWaveformSeekBar), findsNothing);
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
      expect(find.byType(KWaveformSeekBar), findsNothing);
      expect(find.byType(KFlatStyledSeekBar), findsOneWidget);
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

  testWidgets('a flat style with a squiggle-music fallback never decodes', (
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

  testWidgets('squiggle music as the fallback of a wave kind drifts and '
      'reads no levels', (tester) async {
    // The wave kind decodes for itself; the squiggle fallback adds nothing:
    // no waveform for the track, so it shows, and it must not follow music.
    final waveform = _CountingWaveform(status: WaveformStatus.none);
    final host = await pumpWithPlayer(
      tester,
      const Align(child: PlaybackWaveformSeekBar()),
      overrides: [
        _fourMinutes,
        waveform.override,
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
    await tester.pump(const Duration(milliseconds: 300));
    expect(waveform.started, 1, reason: 'only the wave kind decodes');
    expect(_bar(tester).status, KWaveformStatus.none);
    expect(_squiggleTrack(tester).look.motion, KSquiggleMotion.drift);
    expect(_squiggleTrack(tester).level, isNull);
    expect(find.byType(KSeekGestureArea), findsOneWidget);
  });

  testWidgets('the flat ★ fallback uses the flat options', (tester) async {
    final host = await pumpWithPlayer(
      tester,
      const Align(child: PlaybackWaveformSeekBar()),
      overrides: [
        _fourMinutes,
        _CountingWaveform(status: WaveformStatus.none).override,
        _startsAt(
          flatSeekOptionsProvider,
          flatSeekOptionsSetting,
          const FlatSeekOptions(
            thickness: FlatThickness.thick,
            effect: FlatEffect.shine,
          ),
        ),
      ],
    );
    await host.letStreamsArrive(tester);
    await tester.pump(const Duration(milliseconds: 300));
    final track = tester.widget<KFlatSeekTrack>(find.byType(KFlatSeekTrack));
    expect(track.look.thickness, KFlatThickness.thick);
    expect(track.look.effect, KFlatEffect.shine);
  });

  testWidgets('a squiggle chosen with music motion follows the levels', (
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
    await tester.pump(const Duration(milliseconds: 300));
    final bar = tester.widget<KSquiggleSeekBar>(find.byType(KSquiggleSeekBar));
    expect(bar.look.motion, KSquiggleMotion.music);
    expect(bar.levels, _levels);
    expect(find.byType(KWaveformSeekBar), findsNothing);
  });

  for (final style in [SeekBarStyle.flat, SeekBarStyle.squiggle]) {
    testWidgets('the playing state reaches the ${style.name} bar', (
      tester,
    ) async {
      final host = await pumpWithPlayer(
        tester,
        const Align(child: PlaybackWaveformSeekBar()),
        overrides: [
          _fourMinutes,
          _startsAt(seekBarStyleProvider, seekBarStyleSetting, style),
        ],
      );
      await host.letStreamsArrive(tester);
      bool playing() => style == SeekBarStyle.flat
          ? tester
                .widget<KFlatStyledSeekBar>(find.byType(KFlatStyledSeekBar))
                .playing
          : tester
                .widget<KSquiggleSeekBar>(find.byType(KSquiggleSeekBar))
                .playing;
      expect(playing(), isTrue);
      await host.run(tester, host.h.c.pause);
      await host.letStreamsArrive(tester);
      expect(playing(), isFalse);
    });
  }

  for (final (name, fallback) in [
    ('squiggle', SeekBarFallback.squiggle),
    ('flat', SeekBarFallback.flat),
  ]) {
    testWidgets('the playing state reaches the $name ★ fallback track', (
      tester,
    ) async {
      final host = await pumpWithPlayer(
        tester,
        const Align(child: PlaybackWaveformSeekBar()),
        overrides: [
          _fourMinutes,
          _CountingWaveform(status: WaveformStatus.none).override,
          _startsAt(seekBarFallbackProvider, seekBarFallbackSetting, fallback),
        ],
      );
      await host.letStreamsArrive(tester);
      await tester.pump(const Duration(milliseconds: 300));
      bool playing() => fallback == SeekBarFallback.squiggle
          ? tester.widget<KSquiggleTrack>(find.byType(KSquiggleTrack)).playing
          : tester.widget<KFlatSeekTrack>(find.byType(KFlatSeekTrack)).playing;
      expect(playing(), isTrue);
      await host.run(tester, host.h.c.pause);
      await host.letStreamsArrive(tester);
      expect(playing(), isFalse);
    });
  }

  testWidgets('the ★ fallback keeps its own look, not the wave look', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const Align(child: PlaybackWaveformSeekBar()),
      overrides: [
        _fourMinutes,
        _CountingWaveform(status: WaveformStatus.none).override,
        _startsAt(
          waveSeekOptionsProvider,
          waveSeekOptionsSetting,
          const WaveSeekOptions(
            played: WavePlayed.gradient,
            density: WaveDensity.dense,
            rest: WaveRest.outline,
          ),
        ),
      ],
    );
    await host.letStreamsArrive(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.widget<KFlatSeekTrack>(find.byType(KFlatSeekTrack)).look,
      const KFlatLook(),
    );
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
