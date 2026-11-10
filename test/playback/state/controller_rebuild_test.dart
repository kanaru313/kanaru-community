import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/state/audio_engine_provider.dart';
import 'package:kanaru/src/playback/state/media_session_bridge.dart';
import 'package:kanaru/src/playback/state/playback_data_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';
import '../support/controller_harness.dart';
import '../support/fake_audio_engine.dart';

void main() {
  late AppDatabase db;
  late List<TrackId> tracks;
  late FakeAudioEngine engine;
  late ProviderContainer container;
  late FakeFocus focusA;

  List<Override> overrides(FakeFocus focus) => [
    appDatabaseProvider.overrideWithValue(db),
    settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
    audioEngineFactoryProvider.overrideWithValue(() => engine),
    playbackFocusProvider.overrideWithValue(focus),
  ];

  setUp(() async {
    db = openTestDb();
    final src = await addSource(db, root: '/music');
    await addMount(db, src, root: '/music');
    tracks = [
      for (var i = 0; i < 4; i++)
        TrackId(await addTrack(db, src, locator: 't$i.mp3')),
    ];
    engine = FakeAudioEngine();
    focusA = FakeFocus();
    container = ProviderContainer(overrides: overrides(focusA));
  });
  tearDown(() async {
    container.dispose();
    await pumpEventQueue();
    await db.close();
  });

  test('the controller survives a change of the focus provider', () async {
    final first = container.read(playerControllerProvider);
    await first.playTracks(tracks, startIndex: 1, context: ctx);
    await first.settled();
    expect(focusA.activations, 1);
    expect(engine.disposed, isFalse);

    final focusB = FakeFocus();
    container.updateOverrides(overrides(focusB));

    final second = container.read(playerControllerProvider);
    expect(second, same(first));
    expect(engine.disposed, isFalse, reason: 'the engine was not dropped');
    expect(second.queueState.length, 4);
    expect(second.queueState.current, 1);
    expect(second.intent, PlayIntent.playing);

    // The next play asks the new focus provider.
    await second.pause();
    await second.play();
    await second.settled();
    expect(focusB.activations, 1);
    expect(focusA.activations, 1);
  });

  test('a rebuilt media bridge is attached to the same controller', () async {
    final controller = container.read(playerControllerProvider);
    await controller.playTracks(tracks, context: ctx);
    await controller.settled();
    final oldBridge = container.read(mediaSessionBridgeProvider);

    container.invalidate(mediaSessionBridgeProvider);
    final newBridge = container.read(mediaSessionBridgeProvider);
    expect(newBridge, isNot(same(oldBridge)));
    expect(container.read(playerControllerProvider), same(controller));
    expect(engine.disposed, isFalse);
    expect(controller.queueState.length, 4);
    expect(newBridge, isA<MediaSessionBridge>());
  });

  test('the controller is disposed with its provider', () async {
    final controller = container.read(playerControllerProvider);
    await controller.playTracks(tracks, context: ctx);
    await controller.settled();
    container.dispose();
    await pumpEventQueue();
    expect(engine.disposed, isTrue);
  });
}
