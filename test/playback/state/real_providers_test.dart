import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/player_controller.dart';
import 'package:kanaru/src/playback/state/player_ready.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';
import '../support/controller_harness.dart';

void main() {
  late AppDatabase db;
  late List<TrackId> tracks;
  late ProviderContainer c;

  setUp(() async {
    db = openTestDb();
    final src = await addSource(db, root: '/music');
    await addMount(db, src, root: '/music');
    tracks = [
      for (var i = 0; i < 4; i++)
        TrackId(await addTrack(db, src, locator: 't$i.mp3')),
    ];
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      ],
    );
  });
  tearDown(() async {
    c.dispose();
    await pumpEventQueue();
    await db.close();
  });

  test('the providers are the real player, not the seeds', () async {
    expect(c.read(playbackCommandsProvider), isA<PlayerController>());
    expect(
      c.read(playbackCommandsProvider),
      same(c.read(playerControllerProvider)),
    );
    c.listen(nowPlayingProvider, (_, _) {});
    final now = await c.read(nowPlayingProvider.future);
    expect(now, NowPlaying.none);
    expect(c.read(hasCurrentTrackProvider), isFalse);
  });

  test(
    'the commands work through the provider (silent engine under flutter test)',
    () async {
      c.listen(nowPlayingProvider, (_, _) {});
      await c
          .read(playerPhaseProvider.notifier)
          .attach(c.read(playerControllerProvider));
      await c
          .read(playbackCommandsProvider)
          .playTracks(tracks, startIndex: 1, context: ctx);
      await c.read(playerControllerProvider).settled();
      await pumpEventQueue();
      expect(c.read(isCurrentTrackProvider(tracks[1])), isTrue);
      expect(c.read(hasCurrentTrackProvider), isTrue);
      expect(c.read(isPlayingProvider), isTrue);
    },
  );

  test('a track change notifies only the two tiles that change', () async {
    final seen = <int, int>{};
    for (final t in tracks) {
      c.listen(
        isCurrentTrackProvider(t),
        (_, _) => seen[t.value] = (seen[t.value] ?? 0) + 1,
      );
    }
    await c.read(nowPlayingProvider.future);
    await c.read(playbackCommandsProvider).playTracks(tracks, context: ctx);
    await pumpEventQueue();
    expect(seen, {tracks[0].value: 1});
    seen.clear();
    await c.read(playerControllerProvider).next();
    await pumpEventQueue();
    expect(seen, {tracks[0].value: 1, tracks[1].value: 1});
  });
}
