import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/queue_totals_provider.dart';

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
    for (var i = 0; i < 4; i++) {
      await db.customStatement(
        'UPDATE tracks SET duration_ms = ${(i + 1) * 1000} WHERE id = ${tracks[i].value}',
      );
    }
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

  Future<Duration> latest() async {
    await c.read(playerControllerProvider).settled();
    await pumpEventQueue();
    return c.read(queueRemainingProvider).requireValue;
  }

  test('sums the entries after the current one, in sort order', () async {
    c.listen(queueRemainingProvider, (_, _) {});
    await c
        .read(playbackCommandsProvider)
        .playTracks(tracks, startIndex: 1, context: ctx);
    expect(await latest(), const Duration(seconds: 7)); // 3 s + 4 s
    await c.read(playerControllerProvider).next();
    expect(await latest(), const Duration(seconds: 4));
  });

  test(
    'follows the shuffled order and counts a queue change at once',
    () async {
      c.listen(queueRemainingProvider, (_, _) {});
      final ctl = c.read(playerControllerProvider);
      await ctl.playTracks(tracks, context: ctx);
      await ctl.setShuffle(true);
      expect(
        await latest(),
        const Duration(seconds: 9),
      ); // all but the first (1 s)
      await ctl.enqueue([tracks[3]]);
      expect(await latest(), const Duration(seconds: 13));
    },
  );
}
