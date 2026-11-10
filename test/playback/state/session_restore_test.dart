import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/queue_repository.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/session_restore.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';

void main() {
  late AppDatabase db;
  late QueueRepository repo;
  late MemorySettingsStore settings;
  late List<TrackId> tracks;
  late List<int> entryIds;

  setUp(() async {
    db = openTestDb();
    repo = QueueRepository(db);
    settings = MemorySettingsStore();
    final src = await addSource(db, root: '/music');
    await addMount(db, src, root: '/music');
    tracks = [
      for (var i = 0; i < 4; i++)
        TrackId(await addTrack(db, src, locator: 't$i.mp3')),
    ];
    await db.customStatement('UPDATE tracks SET duration_ms = 200000');
    final items = await repo.replace(tracks, 1000);
    entryIds = [for (final i in items) i.entryId];
  });
  tearDown(() => db.close());

  Future<RestoredSession?> load() =>
      loadSession(repo: repo, settings: settings);

  test('empty queue: nothing to restore', () async {
    await repo.replace(const [], 2000);
    expect(await load(), isNull);
  });

  test('the saved entry, position, repeat and context come back', () async {
    await settings.write('playback.queue.current_entry', entryIds[2]);
    await settings.write('playback.position_ms', 61000);
    await settings.write('playback.repeat', 'all');
    await settings.write('playback.context', {
      'kind': 'album',
      'ref': 'k',
      'label': 'Album',
    });
    final s = (await load())!;
    expect(s.queue.current, 2);
    expect(s.queue.currentItem!.entryId, entryIds[2]);
    expect(s.queue.repeat, RepeatMode.all);
    expect(s.position, const Duration(seconds: 61));
    expect(s.context, const PlayContext(PlayContextKind.album, ref: 'k', label: 'Album'));
  });

  test('a dangling current entry falls back to the first, at 0', () async {
    await settings.write('playback.queue.current_entry', 9999);
    await settings.write('playback.position_ms', 50000);
    final s = (await load())!;
    expect(s.queue.current, 0);
    expect(s.position, Duration.zero);
  });

  test('no saved entry: first entry', () async {
    final s = (await load())!;
    expect(s.queue.current, 0);
    expect(s.context, isNull);
  });

  group('position clamp', () {
    test('a position inside the track is kept', () async {
      await settings.write('playback.queue.current_entry', entryIds[0]);
      await settings.write('playback.position_ms', 198999);
      expect((await load())!.position, const Duration(milliseconds: 198999));
    });

    test('at duration minus one second it is 0', () async {
      await settings.write('playback.queue.current_entry', entryIds[0]);
      await settings.write('playback.position_ms', 199000);
      expect((await load())!.position, Duration.zero);
    });

    test('past the end it is 0', () async {
      await settings.write('playback.queue.current_entry', entryIds[0]);
      await settings.write('playback.position_ms', 900000);
      expect((await load())!.position, Duration.zero);
    });

    test('an unknown duration keeps the position', () async {
      await db.customStatement('UPDATE tracks SET duration_ms = NULL');
      await settings.write('playback.queue.current_entry', entryIds[0]);
      await settings.write('playback.position_ms', 900000);
      expect((await load())!.position, const Duration(milliseconds: 900000));
    });
  });

  test('shuffle on with no shuffle keys keeps every entry', () async {
    await settings.write('playback.shuffle', true);
    final s = (await load())!;
    expect(s.queue.shuffled, isTrue);
    expect(s.queue.length, 4);
  });

  test('a context that cannot be read becomes the plain queue', () async {
    await settings.write('playback.context', 'garbage');
    expect((await load())!.context, const PlayContext(PlayContextKind.queue));
  });

  test('an unknown context kind reads as the queue', () async {
    await settings.write('playback.context', {'kind': 'from-the-future'});
    expect((await load())!.context?.kind, PlayContextKind.queue);
  });

  test('a bad stored value for a key uses the default', () async {
    await settings.write('playback.repeat', 'sideways');
    await settings.write('playback.position_ms', 'soon');
    final s = (await load())!;
    expect(s.queue.repeat, RepeatMode.off);
    expect(s.position, Duration.zero);
  });

  test('restoring never rewrites queue_entries or the settings', () async {
    await settings.write('playback.queue.current_entry', 9999);
    final before = await repo.load(shuffled: false);
    await load();
    expect(await repo.load(shuffled: false), before);
    expect(settings.read('playback.queue.current_entry'), 9999);
  });
}
