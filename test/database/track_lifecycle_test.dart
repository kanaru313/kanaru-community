import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int source;
  late int plugin;
  late int remoteTrack;
  setUp(() async {
    db = openTestDb();
    source = await addSource(db, root: '/music');
    await addMount(db, source, root: '/music');
    plugin = await addSource(db, kind: SourceKind.plugin, name: 'Plug');
    remoteTrack = await addTrack(
      db,
      plugin,
      locator: 'r',
      status: TrackStatus.remote,
    );
    await db.customStatement(
      "UPDATE source_mounts SET scan_cursor = 'c', last_scan_at = 9",
    );
  });
  tearDown(() => db.close());

  Future<String> status(String locator) async => (await (db.select(
    db.tracks,
  )..where((t) => t.locator.equals(locator))).getSingle()).status;

  Future<SourceMount> mount() => db.select(db.sourceMounts).getSingle();

  Future<void> seed() async {
    await addTrack(db, source, locator: 'p.flac');
    await addTrack(db, source, locator: 'm.flac', status: TrackStatus.missing);
  }

  test('removeSource tombstones, disables and hides', () async {
    await seed();
    await removeSource(db, source, 50);
    final src = await (db.select(
      db.sources,
    )..where((s) => s.id.equals(source))).getSingle();
    expect(src.deletedAt, 50);
    expect(src.updatedAt, 50);
    final m = await mount();
    expect(m.enabled, isFalse);
    expect(m.scanCursor, isNull);
    expect(m.lastScanAt, isNull);
    expect(await status('p.flac'), TrackStatus.hidden);
    expect(await status('m.flac'), TrackStatus.hidden);
  });

  test('reviveSource rewrites fields and unhides as missing', () async {
    await seed();
    await removeSource(db, source, 50);
    await reviveSource(
      db,
      source,
      60,
      name: 'New',
      account: 'acc',
      configJson: '{"a":1}',
      credentialRef: 'ref',
    );
    final src = await (db.select(
      db.sources,
    )..where((s) => s.id.equals(source))).getSingle();
    expect(src.deletedAt, isNull);
    expect(
      [src.name, src.account, src.configJson, src.credentialRef],
      ['New', 'acc', '{"a":1}', 'ref'],
    );
    expect(src.updatedAt, 60);
    final m = await mount();
    expect(m.enabled, isTrue);
    expect(m.scanCursor, isNull);
    final t = await (db.select(
      db.tracks,
    )..where((t) => t.locator.equals('p.flac'))).getSingle();
    expect(t.status, TrackStatus.missing);
    expect(t.missingSince, 60);
    // Only the scanner's upsert makes it present again.
    await upsertTrackSnapshot(
      db,
      db.tracks,
      TracksCompanion.insert(
        uid: t.uid,
        sourceId: source,
        locator: 'p.flac',
        relPath: 'p.flac',
        title: 'T',
        addedAt: 70,
        updatedAt: 70,
      ),
    );
    expect(await status('p.flac'), TrackStatus.present);
  });

  test('setMountEnabled hides and unhides the same way', () async {
    await seed();
    await setMountEnabled(db, source, false, 50);
    expect((await mount()).enabled, isFalse);
    expect(await status('p.flac'), TrackStatus.hidden);
    expect(await status('m.flac'), TrackStatus.hidden);
    await db.customStatement("UPDATE source_mounts SET scan_cursor = 'z'");
    await setMountEnabled(db, source, true, 60);
    final m = await mount();
    expect(m.enabled, isTrue);
    expect(m.scanCursor, isNull);
    expect(await status('p.flac'), TrackStatus.missing);
  });

  test('unhideTracks with a locator range touches only that range', () async {
    await addTrack(db, source, locator: 'a/1.flac', status: TrackStatus.hidden);
    await addTrack(db, source, locator: 'b/1.flac', status: TrackStatus.hidden);
    await unhideTracks(db, source, 70, locatorFrom: 'a/', locatorTo: 'a0');
    expect(await status('a/1.flac'), TrackStatus.missing);
    expect(await status('b/1.flac'), TrackStatus.hidden);
    expect((await mount()).scanCursor, isNull);
  });

  test('a removed source cannot be unhidden except by revive', () async {
    await seed();
    await removeSource(db, source, 50);
    await expectLater(setMountEnabled(db, source, true, 60), throwsStateError);
    await expectLater(unhideTracks(db, source, 60), throwsStateError);
    expect(await status('p.flac'), TrackStatus.hidden);
    expect((await mount()).enabled, isFalse);
    await setMountEnabled(db, source, false, 61); // still safe
  });

  test('a locator range needs both bounds', () async {
    await expectLater(
      unhideTracks(db, source, 1, locatorFrom: 'a'),
      throwsArgumentError,
    );
  });

  test('present rows are not touched by unhide', () async {
    await seed();
    await unhideTracks(db, source, 70);
    expect(await status('p.flac'), TrackStatus.present);
  });

  test('remote rows are untouched by every helper', () async {
    await setMountEnabled(db, plugin, false, 51);
    await setMountEnabled(db, plugin, true, 52);
    await removeSource(db, plugin, 50);
    await reviveSource(
      db,
      plugin,
      53,
      name: 'P',
      account: null,
      configJson: '{}',
      credentialRef: null,
    );
    await unhideTracks(db, plugin, 54);
    final row = await (db.select(
      db.tracks,
    )..where((t) => t.id.equals(remoteTrack))).getSingle();
    expect(row.status, TrackStatus.remote);
    expect(row.updatedAt, 1000);
    expect(row.missingSince, isNull);
  });

  test('a stream on tracks re-emits after lifecycle changes', () async {
    await seed();
    final stream =
        (db.select(
          db.tracks,
        )..where((t) => t.sourceId.equals(source))).watch().map(
          (rows) => rows.where((t) => t.status == TrackStatus.hidden).length,
        );
    final done = expectLater(stream, emitsInOrder([0, 2, 0]));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await removeSource(db, source, 50);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await reviveSource(
      db,
      source,
      60,
      name: 'M',
      account: null,
      configJson: '{}',
      credentialRef: null,
    );
    await done;
  });
}
