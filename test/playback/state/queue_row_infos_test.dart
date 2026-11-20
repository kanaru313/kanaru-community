import 'package:drift/drift.dart' show TableUpdate;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/state/queue_row_infos.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> touchTracks() async {
    db.notifyUpdates({const TableUpdate('tracks')});
    await pumpEventQueue();
  }

  test('every tracks change reaches a listener with a new value', () async {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final seen = <int>[];
    container.listen(queueTracksChangedProvider, (_, next) {
      final v = next.value;
      if (v != null) seen.add(v);
    });
    await pumpEventQueue();
    await touchTracks();
    await touchTracks();
    await touchTracks();
    expect(seen, [1, 2, 3]);
  });

  testWidgets('queue row infos reload after each tracks change', (
    tester,
  ) async {
    var calls = 0;
    var title = 'a';
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        queueRowInfoLoaderProvider.overrideWithValue((ids) async {
          calls++;
          return [
            for (final id in ids)
              TrackInfo(
                id: id,
                title: title,
                status: TrackAvailability.present,
                relPath: 'x.mp3',
              ),
          ];
        }),
      ],
    );
    addTearDown(c.dispose);
    c.listen(queueRowInfosProvider, (_, _) {});
    c.read(queueRowInfosProvider.notifier).ensure(const [TrackId(1)]);
    await tester.pump();
    expect(c.read(queueRowInfosProvider)[const TrackId(1)]?.title, 'a');

    for (final next in ['b', 'c']) {
      title = next;
      db.notifyUpdates({const TableUpdate('tracks')});
      await tester.pump();
      await tester.pump(
        queueRowInfoReloadDelay + const Duration(milliseconds: 1),
      );
      await tester.pump();
      expect(c.read(queueRowInfosProvider)[const TrackId(1)]?.title, next);
    }
    expect(calls, 3);
  });
}
