import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/state/audio_engine_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';

import '../support/fake_audio_engine.dart';

void main() {
  test(
    'a bare container: no current track, nothing thrown, no engine',
    () async {
      var engines = 0;
      final c = ProviderContainer(
        overrides: [
          audioEngineFactoryProvider.overrideWithValue(() {
            engines++;
            return FakeAudioEngine() as AudioEngine;
          }),
        ],
      );
      addTearDown(c.dispose);
      expect(c.read(isCurrentTrackProvider(const TrackId(1))), isFalse);
      expect(c.read(hasCurrentTrackProvider), isFalse);
      expect(c.read(isPlayingProvider), isFalse);
      await pumpEventQueue();
      expect(c.read(nowPlayingProvider).hasError, isTrue);
      expect(engines, 0);
    },
  );

  test('has-track is false and creates nothing before the player exists', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(hasCurrentTrackProvider), isFalse);
    expect(c.read(playerControllerProvider.exists), isFalse);
    expect(c.read(nowPlayingProvider.exists), isFalse);
  });
}
