import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/online/data/tracks/online_track_writer.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';

import '../../database/support/test_db.dart';
import '../../plugins/data/store_test_support.dart';
import 'tracks_test_support.dart';

/// Median milliseconds of three writes of 200 new cards on [db].
Future<int> medianUpsertMs(AppDatabase db) async {
  final rows = PluginRows(db);
  final id = testInstallId();
  await installStreaming(rows);
  final writer = OnlineTrackWriter(db, rows, configOf(db, rows));
  // Opens the database and warms the statement cache outside the timing.
  await writer.upsertCards(id, [track('warm-up')]);
  final times = <int>[];
  for (var run = 0; run < 3; run++) {
    final cards = [
      for (var i = 0; i < 200; i++)
        track(
          'run$run-$i',
          artist: 'Artist $i',
          artworkUrl: 'https://cdn.example.com/c/$i.jpg',
        ),
    ];
    final watch = Stopwatch()..start();
    await writer.upsertCards(id, cards);
    watch.stop();
    times.add(watch.elapsedMilliseconds);
  }
  times.sort();
  return times[1];
}

void main() {
  test('200 upserts, in-memory database', () async {
    final db = openTestDb();
    addTearDown(db.close);
    final ms = await medianUpsertMs(db);
    // ignore: avoid_print
    print('upsert 200 (in-memory): $ms ms');
    expect(ms, lessThan(1000));
  });

  test('200 upserts, file database on a background isolate', () async {
    final dir = Directory.systemTemp.createTempSync('kanaru-upsert-cost');
    final db = AppDatabase.file(File('${dir.path}/kanaru.db'));
    addTearDown(() async {
      await db.close();
      dir.deleteSync(recursive: true);
    });
    final ms = await medianUpsertMs(db);
    // ignore: avoid_print
    print('upsert 200 (file, background isolate): $ms ms');
    expect(ms, lessThan(1000));
  });
}
