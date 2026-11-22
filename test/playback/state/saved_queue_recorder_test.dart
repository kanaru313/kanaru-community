import 'dart:async';

import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/replaced_queue.dart';
import 'package:kanaru/src/playback/data/saved_queue_writer.dart';
import 'package:kanaru/src/playback/state/saved_queue_recorder.dart';
import 'package:logging/logging.dart';

import '../../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late List<TrackId> a;
  late List<TrackId> b;
  late SavedQueueRecorder rec;
  var clock = 0;

  setUp(() async {
    db = openTestDb();
    final src = await addSource(db, root: '/music');
    await addMount(db, src, root: '/music');
    final ids = [
      for (var i = 0; i < 6; i++)
        TrackId(await addTrack(db, src, locator: 't$i.mp3')),
    ];
    a = ids.sublist(0, 3);
    b = ids.sublist(3);
    clock = 1000;
    rec = SavedQueueRecorder(
      writer: SavedQueueWriter(db),
      now: () => clock += 10,
    );
  });
  tearDown(() async {
    rec.dispose();
    await db.close();
  });

  Future<List<QueryRow>> rows() => db
      .customSelect(
        "SELECT saved_at, context_kind FROM playlists WHERE kind = 'queue' "
        'ORDER BY saved_at',
      )
      .get();

  ReplacedQueue event(
    List<TrackId> old, {
    List<TrackId>? next,
    List<TrackId>? user,
  }) => ReplacedQueue(
    tracks: old,
    userOrder: user ?? old,
    context: const PlayContext(PlayContextKind.album, ref: 'k', label: 'L'),
    next: next,
  );

  test('a clear writes one saved queue with its context', () async {
    rec.onReplaced(event(a));
    await rec.idle;
    final r = await rows();
    expect(r, hasLength(1));
    expect(r.single.read<String>('context_kind'), 'album');
  });

  test('replaced by the same tracks in user order writes nothing', () async {
    rec.onReplaced(event([a[2], a[0], a[1]], user: a, next: a));
    await rec.idle;
    expect(await rows(), isEmpty);
  });

  test('replaced by other tracks writes', () async {
    rec.onReplaced(event(a, next: b));
    await rec.idle;
    expect(await rows(), hasLength(1));
  });

  test('idle waits for every queued write, in order', () async {
    final gate = Completer<void>();
    await db.customStatement('SELECT 1'); // connection open
    final slow = SavedQueueRecorder(
      writer: SavedQueueWriter(db),
      now: () => clock += 10,
    );
    // Hold the chain with a gate by queueing through a held transaction.
    final held = db.transaction(() async {
      await gate.future;
    });
    slow.onReplaced(event(a));
    slow.onReplaced(event(b));
    var idle = false;
    final waiting = slow.idle.then((_) => idle = true);
    await pumpEventQueue();
    expect(idle, isFalse, reason: 'writes are still held');
    gate.complete();
    await held;
    await waiting;
    expect(await rows(), hasLength(2));
    final r = await rows();
    expect(r, hasLength(2));
    expect(r[0].read<int>('saved_at') < r[1].read<int>('saved_at'), isTrue);
    slow.dispose();
  });

  test('a failed write is logged and the next one still saves', () async {
    final logs = <LogRecord>[];
    final sub = Logger('playback.saved_queue').onRecord.listen(logs.add);
    addTearDown(sub.cancel);
    await db.customStatement(
      'CREATE TRIGGER no_ins BEFORE INSERT ON playlists '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );
    rec.onReplaced(event(a));
    await rec.idle;
    expect(logs.where((l) => l.level == Level.WARNING), hasLength(1));
    expect(logs.first.stackTrace, isNotNull);
    await db.customStatement('DROP TRIGGER no_ins');
    rec.onReplaced(event(b));
    await rec.idle;
    expect(await rows(), hasLength(1));
  });

  test(
    'dispose drops queued writes and later events; idle completes',
    () async {
      rec.onReplaced(event(a));
      rec.onReplaced(event(b));
      rec.dispose();
      rec.onReplaced(event(a, next: b));
      await rec.idle;
      expect(await rows(), isEmpty);
    },
  );
}
