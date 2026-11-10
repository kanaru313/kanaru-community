import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/platform/domain/setting.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/domain/playback_settings.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';

import '../../support/memory_settings_store.dart';

T roundTrip<T>(Setting<T> s, T v) => s.decode(s.encode(v));

void main() {
  test('keys', () {
    expect(currentEntrySetting.key, 'playback.queue.current_entry');
    expect(positionMsSetting.key, 'playback.position_ms');
    expect(shuffleSetting.key, 'playback.shuffle');
    expect(repeatSetting.key, 'playback.repeat');
    expect(contextSetting.key, 'playback.context');
    expect(volumeSetting.key, 'playback.volume');
    expect(npTabSetting.key, 'playback.np_tab');
  });

  test('round trips', () {
    expect(roundTrip(currentEntrySetting, 42), 42);
    expect(roundTrip(currentEntrySetting, null), isNull);
    expect(roundTrip(positionMsSetting, 12345), 12345);
    expect(roundTrip(shuffleSetting, true), isTrue);
    for (final m in RepeatMode.values) {
      expect(roundTrip(repeatSetting, m), m);
    }
    expect(repeatSetting.encode(RepeatMode.one), 'one');
    expect(roundTrip(volumeSetting, 35), 35);
    expect(roundTrip(npTabSetting, NowPlayingTab.queue), NowPlayingTab.queue);
    const ctx = PlayContext(PlayContextKind.folder, ref: 's:f', label: 'Rock');
    expect(roundTrip(contextSetting, ctx), ctx);
    expect(
      roundTrip(contextSetting, const PlayContext(PlayContextKind.songs)),
      const PlayContext(PlayContextKind.songs),
    );
    expect(roundTrip(contextSetting, null), isNull);
  });

  test('an unknown context kind reads as queue', () {
    final c = contextSetting.decode({
      'kind': 'podcast',
      'ref': 'x',
      'label': 'L',
    });
    expect(c, const PlayContext(PlayContextKind.queue, ref: 'x', label: 'L'));
  });

  test('bad values throw FormatException; out of range is clamped', () {
    expect(() => repeatSetting.decode('twice'), throwsFormatException);
    expect(() => repeatSetting.decode(3), throwsFormatException);
    expect(() => shuffleSetting.decode('yes'), throwsFormatException);
    expect(() => currentEntrySetting.decode('x'), throwsFormatException);
    expect(() => contextSetting.decode('x'), throwsFormatException);
    expect(
      () => contextSetting.decode({'kind': 'album', 'ref': 3}),
      throwsFormatException,
    );
    expect(() => npTabSetting.decode('mixer'), throwsFormatException);
    expect(volumeSetting.decode(250), 100);
    expect(volumeSetting.decode(-4), 0);
    expect(positionMsSetting.decode(-5), 0);
  });

  test(
    'providers read stored values and fall back to defaults on bad JSON',
    () async {
      final store = MemorySettingsStore();
      final c = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(c.dispose);
      expect(c.read(shuffleSettingProvider), isFalse);
      expect(c.read(repeatSettingProvider), RepeatMode.off);
      expect(c.read(volumeSettingProvider), 100);
      expect(c.read(npTabSettingProvider), NowPlayingTab.lyrics);
      await store.write('playback.repeat', 'all');
      await store.write('playback.volume', 'loud');
      await store.write('playback.np_tab', 'queue');
      expect(c.read(repeatSettingProvider), RepeatMode.all);
      expect(c.read(volumeSettingProvider), 100);
      expect(c.read(npTabSettingProvider), NowPlayingTab.queue);
    },
  );
}
