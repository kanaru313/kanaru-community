import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/data/playable_resolver.dart';
import 'package:kanaru/src/playback/domain/playable.dart';

import '../../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late LocalPlayableResolver resolver;
  late int src;

  setUp(() async {
    db = openTestDb();
    resolver = LocalPlayableResolver(db);
    src = await addSource(db, root: '/music');
    await addMount(db, src, root: '/music');
  });
  tearDown(() => db.close());

  Future<Playable> one(int id) async =>
      (await resolver.resolve([TrackId(id)]))[TrackId(id)]!;

  test('a present local track joins the mount root and the locator', () async {
    final id = await addTrack(db, src, locator: 'Rock/Live/a.flac');
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(durationMs: Value(1234)),
    );
    expect(await one(id), const LocalFile('/music/Rock/Live/a.flac', 1234));
  });

  test('a locator is kept byte for byte (NFD)', () async {
    const nfd = 'Béla/cáncion.mp3';
    final id = await addTrack(db, src, locator: nfd);
    final p = await one(id) as LocalFile;
    expect(p.path, '/music/$nfd');
    expect(p.path.codeUnits, '/music/$nfd'.codeUnits);
  });

  test('status decides the reason', () async {
    final missing = await addTrack(
      db,
      src,
      locator: 'm.mp3',
      status: TrackStatus.missing,
    );
    final hidden = await addTrack(
      db,
      src,
      locator: 'h.mp3',
      status: TrackStatus.hidden,
    );
    final remote = await addTrack(
      db,
      src,
      locator: 'r.mp3',
      status: TrackStatus.remote,
    );
    expect(await one(missing), const Unplayable(UnplayableReason.missing));
    expect(await one(hidden), const Unplayable(UnplayableReason.hidden));
    expect(await one(remote), const Unplayable(UnplayableReason.remote));
  });

  test('a remote source kind is remote', () async {
    final web = await addSource(db, kind: SourceKind.webdav, name: 'dav');
    final id = await addTrack(db, web, locator: 'x.mp3');
    expect(await one(id), const Unplayable(UnplayableReason.remote));
  });

  for (final loc in ['disc.flac#1', 'disc.flac#01', 'disc.flac#123']) {
    test('CUE locator $loc', () async {
      final id = await addTrack(db, src, locator: loc);
      expect(await one(id), const Unplayable(UnplayableReason.cue));
    });
  }

  test('a hash inside the name is not a CUE track', () async {
    final id = await addTrack(db, src, locator: 'C# Minor.flac');
    expect(await one(id), isA<LocalFile>());
  });

  test('a removed source', () async {
    final id = await addTrack(db, src, locator: 'a.mp3');
    await db.customStatement('UPDATE sources SET deleted_at = 5 WHERE id = ?', [
      src,
    ]);
    expect(await one(id), const Unplayable(UnplayableReason.removedSource));
  });

  test('a disabled mount and a missing mount', () async {
    final id = await addTrack(db, src, locator: 'a.mp3');
    await db.customStatement(
      'UPDATE source_mounts SET enabled = 0 WHERE source_id = ?',
      [src],
    );
    expect(await one(id), const Unplayable(UnplayableReason.noMount));
    final other = await addSource(db, name: 'other');
    final id2 = await addTrack(db, other, locator: 'b.mp3');
    expect(await one(id2), const Unplayable(UnplayableReason.noMount));
  });

  test('an unknown id', () async {
    expect(await one(424242), const Unplayable(UnplayableReason.unknownTrack));
  });

  test('more than 500 ids in one call', () async {
    final first = await addTrack(db, src, locator: 't0.mp3');
    for (var i = 1; i < 600; i++) {
      await addTrack(db, src, locator: 't$i.mp3');
    }
    final ids = [for (var i = 0; i < 600; i++) TrackId(first + i)];
    final out = await resolver.resolve([...ids, ids.first]);
    expect(out, hasLength(600));
    expect(out.values.every((p) => p is LocalFile), isTrue);
  });

  test('decidePlayable is pure', () {
    expect(
      decidePlayable(null),
      const Unplayable(UnplayableReason.unknownTrack),
    );
  });
}
