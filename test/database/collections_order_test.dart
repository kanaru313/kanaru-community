import 'dart:math';
import 'package:drift/drift.dart' show Variable;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/foundation/ordering/fractional_keys.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int playlistId;
  late int trackId;
  setUp(() async {
    db = openTestDb();
    final source = await addSource(db);
    trackId = await addTrack(db, source, locator: 'a.flac');
    playlistId = await addPlaylist(db);
  });
  tearDown(() => db.close());

  Future<List<String>> liveUids() async => (await db.customSelect(
        'SELECT uid FROM playlist_entries '
        'WHERE playlist_id = ? AND deleted_at IS NULL ORDER BY sort_key, uid',
        variables: [Variable.withInt(playlistId)],
      ).get())
          .map((r) => r.read<String>('uid'))
          .toList();

  test('entries read in sort_key then uid order', () async {
    await addEntry(db, playlistId, trackId, sortKey: 'a1', uid: 'z');
    await addEntry(db, playlistId, trackId, sortKey: 'a0', uid: 'y');
    await addEntry(db, playlistId, trackId, sortKey: 'a1', uid: 'b');
    expect(await liveUids(), ['y', 'b', 'z']);
  });

  test('an insert between two neighbours lands between them', () async {
    final k1 = generateKeyBetween(null, null);
    final k3 = generateKeyBetween(k1, null);
    await addEntry(db, playlistId, trackId, sortKey: k1, uid: 'first');
    await addEntry(db, playlistId, trackId, sortKey: k3, uid: 'last');
    await addEntry(db, playlistId, trackId,
        sortKey: generateKeyBetween(k1, k3), uid: 'mid');
    expect(await liveUids(), ['first', 'mid', 'last']);
  });

  test('200 random inserts keep the list in order', () async {
    final random = Random(42);
    final keys = <String>[];
    final names = <String>[];
    for (var i = 0; i < 200; i++) {
      final at = random.nextInt(keys.length + 1);
      final key = generateKeyBetween(
          at == 0 ? null : keys[at - 1], at == keys.length ? null : keys[at]);
      keys.insert(at, key);
      names.insert(at, 'e$i');
      await addEntry(db, playlistId, trackId, sortKey: key, uid: 'e$i');
    }
    expect(await liveUids(), names);
  });

  test('SQLite order equals Dart compareTo order for generated keys', () async {
    final random = Random(7);
    final keys = <String>{...generateNKeysBetween(null, null, 300)};
    var prev = keys.last;
    for (var i = 0; i < 300; i++) {
      final next = generateKeyBetween(prev, random.nextBool() ? null : '${prev}V');
      keys.add(next);
      prev = random.nextBool() ? next : keys.elementAt(random.nextInt(keys.length));
    }
    var n = 0;
    for (final k in keys) {
      await addEntry(db, playlistId, trackId, sortKey: k, uid: 'k${n++}');
    }
    final sql = (await db.customSelect(
            'SELECT sort_key FROM playlist_entries ORDER BY sort_key')
        .get())
        .map((r) => r.read<String>('sort_key'))
        .toList();
    expect(sql, (keys.toList()..sort((a, b) => a.compareTo(b))));
  });
}
