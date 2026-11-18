import 'package:drift/drift.dart' show BooleanExpressionOperators;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_text_rules.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/library/data/scan/scan_pipeline.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_import.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../database/support/test_db.dart';
import '../scan/support/cover_fixtures.dart';
import '../scan/support/pipeline_fixtures.dart';
import '../scan/support/scan_fixtures.dart';
import 'support/playlist_fixtures.dart';

void main() {
  late PlaylistFixture f;
  setUp(() async => f = await PlaylistFixture.open());

  Future<Track> trackAt(int source, String locator) =>
      (f.db.select(f.db.tracks)..where(
            (t) => t.sourceId.equals(source) & t.locator.equals(locator),
          ))
          .getSingle();

  test(
    'existing track reused, placeholder created missing with snapshot',
    () async {
      final a = await f.track('a');
      final r = await f.repo.createImportedPlaylist(
        name: ' Imp ',
        entries: [
          ImportedTrack(a),
          ImportedMissing(
            sourceId: f.source,
            locator: 'x/new.mp3',
            title: 'New',
            artist: 'Ann',
            durationMs: 120000,
          ),
          ImportedMissing(sourceId: f.source, locator: 'a.flac', title: 'A'),
          ImportedTrack(a),
          ImportedMissing(
            sourceId: f.source,
            locator: 'x/new.mp3',
            title: 'New',
          ),
        ],
      );
      expect(r.entryCount, 5);
      expect(r.missingCreated, 1);
      final row = await trackAt(f.source, 'x/new.mp3');
      expect(row.status, TrackStatus.missing);
      expect(row.missingSince, 10000);
      expect(row.uid, trackUid('src-pl', 'x/new.mp3'));
      expect(row.artist, 'Ann');
      expect(row.durationMs, 120000);
      final d = (await f.repo.loadPlaylist(r.uid))!;
      expect(d.entries.map((e) => e.info.id.value), [
        a.value,
        row.id,
        a.value,
        a.value,
        row.id,
      ]);
      expect(d.entries[1].info.artist, 'Ann');
      expect(d.summary.durationMs, 120000);
      expect(d.unavailableCount, 2);
    },
  );

  test('placeholder has sort and search forms; long name is cut', () async {
    final r = await f.repo.createImportedPlaylist(
      name: 'x' * 250,
      entries: [
        ImportedMissing(
          sourceId: f.source,
          locator: 'é.mp3',
          title: 'Été',
          artist: 'Zoë',
        ),
      ],
    );
    final row = await trackAt(f.source, 'é.mp3');
    expect(row.titleSort, sortForm('Été'));
    expect(row.titleSearch, searchForm('Été'));
    expect(row.artistSearch, searchForm('Zoë'));
    final name = (await f.repo.loadPlaylist(r.uid))!.summary.name;
    expect(graphemeLength(name), playlistNameMaxLength);
    await expectLater(
      f.repo.createImportedPlaylist(name: ' ', entries: const []),
      throwsArgumentError,
    );
  });

  test('placeholder under a live exclusion is hidden', () async {
    await f.db.customStatement(
      'INSERT INTO excluded_folders '
      '(uid, source_id, folder_key, display_path, added_at, updated_at) '
      "VALUES ('ex1', ${f.source}, 'skip', 'skip', 1, 1)",
    );
    final r = await f.repo.createImportedPlaylist(
      name: 'I',
      entries: [
        ImportedMissing(sourceId: f.source, locator: 'skip/z.mp3', title: 'Z'),
      ],
    );
    expect(r.missingCreated, 1);
    expect((await trackAt(f.source, 'skip/z.mp3')).status, TrackStatus.hidden);
  });

  test('removed or non-local source and bad input write nothing', () async {
    final gone = await addSource(f.db, uid: 'gone');
    await f.db.customStatement(
      'UPDATE sources SET deleted_at = 5 WHERE id = $gone',
    );
    final remote = await addSource(f.db, uid: 'rem', kind: SourceKind.webdav);
    for (final id in [gone, remote, 9999]) {
      await expectLater(
        f.repo.createImportedPlaylist(
          name: 'I',
          entries: [
            ImportedMissing(sourceId: f.source, locator: 'ok.mp3', title: 'ok'),
            ImportedMissing(sourceId: id, locator: 'b.mp3', title: 'b'),
          ],
        ),
        throwsArgumentError,
      );
    }
    await expectLater(
      f.repo.createImportedPlaylist(name: ' ', entries: const []),
      throwsArgumentError,
    );
    await expectLater(
      f.repo.createImportedPlaylist(
        name: 'I',
        entries: [const ImportedTrack(TrackId(9999))],
      ),
      throwsArgumentError,
    );
    expect(await f.db.select(f.db.playlists).get(), isEmpty);
    expect(await f.db.select(f.db.tracks).get(), isEmpty);
  });

  test('a scan with the file present adopts the placeholder', () async {
    final db = f.db;
    final folder = await addScanFolder(db);
    final cache = makeCacheDir();
    writeLayoutMarker(cache);
    addTearDown(() => cache.deleteSync(recursive: true));
    final repo = f.repo;
    final r = await repo.createImportedPlaylist(
      name: 'I',
      entries: [
        ImportedMissing(
          sourceId: folder.sourceId,
          locator: 'one.mp3',
          title: 'one',
        ),
      ],
    );
    final placeholder = await trackAt(folder.sourceId, 'one.mp3');
    expect(placeholder.status, TrackStatus.missing);
    final out = await runScanPass(
      pipelineDeps(
        db,
        catalog: MapCatalog({
          scanRoot: listingOf(scanRoot, ['one.mp3']),
        }),
        reader: FakeTagReader(),
        maker: FakeCoverMaker(),
        cache: cache,
      ),
      ScanSession(),
      StatusLog().hooks(),
    );
    expect(out.failureKind, isNull);
    final after = await trackAt(folder.sourceId, 'one.mp3');
    expect(after.id, placeholder.id);
    expect(after.status, TrackStatus.present);
    expect(after.missingSince, isNull);
    final d = (await repo.loadPlaylist(r.uid))!;
    expect(d.entries.single.info.id.value, placeholder.id);
    expect(d.unavailableCount, 0);
  });
}
