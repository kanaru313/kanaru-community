import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/online/pin_store.dart';
import 'package:kanaru/src/lyrics/data/online/reject_store.dart';
import 'package:kanaru/src/lyrics/data/online/store_result.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late TrackId track;
  late PinStore pins;
  late RejectStore rejects;

  setUp(() async {
    db = openTestDb();
    final source = await addSource(db);
    track = TrackId(await addTrack(db, source, locator: 'a.flac'));
    pins = PinStore(db);
    rejects = RejectStore(db);
  });
  tearDown(() => db.close());

  Future<StoreResult> keep({
    TrackId? id,
    String? synced,
    String? plain = 'words',
    bool instrumental = false,
    int now = 10,
    String remoteId = 'r1',
  }) => pins.put(
    id ?? track,
    providerId: 'plugin-1',
    providerName: 'LRCLIB',
    remoteId: remoteId,
    syncedText: synced,
    plainText: plain,
    instrumental: instrumental,
    remoteDurationMs: 201000,
    now: now,
  );

  group('pins', () {
    test('put writes the row with a pin: uid', () async {
      expect(await keep(), StoreResult.stored);
      final row = (await pins.read(track))!;
      expect(row.uid, startsWith('pin:'));
      expect(
        (row.providerId, row.providerName, row.remoteId, row.plainText),
        ('plugin-1', 'LRCLIB', 'r1', 'words'),
      );
      expect(
        (row.syncedText, row.instrumental, row.remoteDurationMs),
        (null, false, 201000),
      );
      expect((row.pinnedAt, row.updatedAt), (10, 10));
    });

    test('keeping again replaces the copy, keeps uid and pinned_at', () async {
      await keep();
      final first = (await pins.read(track))!;
      await keep(plain: null, synced: '[00:01.00] x', now: 99, remoteId: 'r2');
      final row = (await pins.read(track))!;
      expect((row.uid, row.pinnedAt), (first.uid, 10));
      expect(
        (row.remoteId, row.syncedText, row.plainText, row.updatedAt),
        ('r2', '[00:01.00] x', null, 99),
      );
      expect(await db.select(db.lyricsPins).get(), hasLength(1));
    });

    test('an instrumental copy needs no text', () async {
      expect(await keep(plain: null, instrumental: true), StoreResult.stored);
      expect((await pins.read(track))!.instrumental, isTrue);
    });

    test('a write for a track that is gone is refused, not thrown', () async {
      expect(await keep(id: const TrackId(9999)), StoreResult.notStored);
      expect(await db.select(db.lyricsPins).get(), isEmpty);
    });

    test(
      'no text and not instrumental, blank text or over 1 MiB: refused',
      () async {
        expect(await keep(plain: null), StoreResult.notStored);
        expect(await keep(plain: '  \n'), StoreResult.notStored);
        expect(
          await keep(plain: 'x' * (1024 * 1024 + 1)),
          StoreResult.notStored,
        );
        expect(await keep(plain: 'x' * (1024 * 1024)), StoreResult.stored);
      },
    );

    test('text that parses to no line is not kept', () async {
      expect(await keep(plain: '[ar:Foo]\n[ti:Bar]'), StoreResult.notStored);
      expect(
        await keep(plain: null, synced: '[00:01.00]'),
        StoreResult.notStored,
      );
      expect(await pins.read(track), isNull);
    });

    test('the table refuses a row with no body, whatever the store does', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO lyrics_pins (track_id, uid, provider_id, provider_name, '
          "remote_id, pinned_at, updated_at) VALUES (?, 'pin:z', 'p', 'P', 'r', 1, 1)",
          [track.value],
        ),
        throwsConstraint('CHECK'),
      );
    });

    test('clear drops the copy and is harmless without one', () async {
      await pins.clear(track);
      await keep();
      await pins.clear(track);
      expect(await pins.read(track), isNull);
    });

    test('watch re-emits on keep and clear', () async {
      final seen = <String?>[];
      final sub = pins.watch(track).listen((r) => seen.add(r?.remoteId));
      await pumpEventQueue();
      await keep();
      await pumpEventQueue();
      await pins.clear(track);
      await pumpEventQueue();
      await sub.cancel();
      expect(seen, [null, 'r1', null]);
    });

    test('a track with a copy cannot be deleted', () async {
      await keep();
      await expectLater(
        db.customStatement('DELETE FROM tracks WHERE id = ?', [track.value]),
        throwsConstraint('FOREIGN KEY'),
      );
    });

    test('the copy needs no plugin row', () async {
      await keep();
      expect(
        await db.customSelect('SELECT 1 FROM plugins').get(),
        isEmpty,
        reason: 'provider_id has no foreign key',
      );
      expect(await pins.read(track), isNotNull);
    });
  });

  group('rejects', () {
    Future<StoreResult> reject({
      TrackId? id,
      String remoteId = 'r1',
      String? hash,
      int now = 5,
    }) => rejects.add(
      id ?? track,
      providerId: 'plugin-1',
      remoteId: remoteId,
      contentHash: hash,
      now: now,
    );

    test(
      'add stores, a repeat refreshes the time and keeps the hash',
      () async {
        expect(await reject(hash: 'h1'), StoreResult.stored);
        expect(await reject(now: 8), StoreResult.stored);
        final rows = await rejects.list(track);
        expect(rows, hasLength(1));
        expect((rows.single.contentHash, rows.single.rejectedAt), ('h1', 8));
      },
    );

    test('a write for a track that is gone is refused, not thrown', () async {
      expect(await reject(id: const TrackId(9999)), StoreResult.notStored);
      expect(await db.select(db.lyricsRejects).get(), isEmpty);
    });

    test('RejectedSet gives the ids and the hashes for the gate', () async {
      await reject(hash: 'h1');
      await reject(remoteId: 'r2');
      final set = RejectedSet.of(await rejects.list(track));
      expect(set.refs, {
        (providerId: 'plugin-1', remoteId: 'r1'),
        (providerId: 'plugin-1', remoteId: 'r2'),
      });
      expect(set.hashes, {'h1'});
    });

    test('rejects are per track', () async {
      final other = TrackId(
        await addTrack(db, await addSource(db, name: 'B'), locator: 'b.flac'),
      );
      await reject();
      expect(await rejects.list(other), isEmpty);
    });

    test('a track with a reject cannot be deleted', () async {
      await reject();
      await expectLater(
        db.customStatement('DELETE FROM tracks WHERE id = ?', [track.value]),
        throwsConstraint('FOREIGN KEY'),
      );
      final left = await db
          .customSelect(
            'SELECT 1 FROM tracks WHERE id = ?',
            variables: [Variable.withInt(track.value)],
          )
          .get();
      expect(left, hasLength(1));
    });
  });
}
