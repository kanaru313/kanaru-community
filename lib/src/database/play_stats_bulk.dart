import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// SQL that aggregates live `play_log` rows into `play_stats` columns. With
/// [touchedOnly] it covers only the tracks in `play_stats_touched`. This is the
/// single definition of correct stats: the bulk recompute inserts it, and
/// tests compare the incremental triggers against it.
@visibleForTesting
String playStatsAggregateSql({bool touchedOnly = false}) => '''
SELECT track_id,
       sum(skipped = 0) AS play_count,
       sum(skipped = 1) AS skip_count,
       min(CASE WHEN skipped = 0 THEN played_at END) AS first_played_at,
       max(CASE WHEN skipped = 0 THEN played_at END) AS last_played_at
FROM main.play_log
WHERE deleted_at IS NULL
${touchedOnly ? 'AND track_id IN (SELECT track_id FROM temp.play_stats_touched)' : ''}
GROUP BY track_id''';

const _bulkOf = '(SELECT bulk FROM main.play_stats_ctl WHERE id = 1) = 1';

/// The inserts use ON CONFLICT, not `INSERT OR IGNORE`: inside a trigger the
/// outer statement's conflict mode overrides `OR IGNORE`, and a second play of
/// a touched track would fail the whole write.
///
/// TEMP objects are per connection, so each outer call creates them if
/// missing. They record the old and new `track_id` of every `play_log` row
/// written while the switch is on.
const _touchSetup = [
  'CREATE TEMP TABLE IF NOT EXISTS play_stats_touched '
      '(track_id INTEGER PRIMARY KEY)',
  'CREATE TEMP TRIGGER IF NOT EXISTS play_stats_touch_insert '
      'AFTER INSERT ON main.play_log WHEN $_bulkOf BEGIN '
      'INSERT INTO play_stats_touched VALUES (new.track_id) ON CONFLICT DO NOTHING; END',
  'CREATE TEMP TRIGGER IF NOT EXISTS play_stats_touch_update '
      'AFTER UPDATE ON main.play_log WHEN $_bulkOf BEGIN '
      'INSERT INTO play_stats_touched VALUES (old.track_id) ON CONFLICT DO NOTHING; '
      'INSERT INTO play_stats_touched VALUES (new.track_id) ON CONFLICT DO NOTHING; END',
  'CREATE TEMP TRIGGER IF NOT EXISTS play_stats_touch_delete '
      'AFTER DELETE ON main.play_log WHEN $_bulkOf BEGIN '
      'INSERT INTO play_stats_touched VALUES (old.track_id) ON CONFLICT DO NOTHING; END',
];

/// Runs [write], which changes many `play_log` rows (clear history, import a
/// backup, large tombstone cleanup), with the incremental stats triggers off,
/// then recomputes `play_stats` for the tracks it touched. The tracks are
/// found by the database itself, so [write] passes no ids.
///
/// Everything runs in one transaction: an exception rolls back the writes and
/// the switch. Re-entrant: inside another call it only runs [write]; the
/// outermost call recomputes. [db] is the caller's database object (the app
/// database, or an extension database on the same connection). Do not call
/// it inside a transaction of another database object.
Future<T> runPlayStatsBulk<T>(
  DatabaseConnectionUser db,
  Future<T> Function() write,
) =>
    db.transaction(() async {
      final ctl = await db
          .customSelect('SELECT bulk FROM main.play_stats_ctl WHERE id = 1')
          .getSingle();
      if (ctl.read<int>('bulk') == 1) return write();

      for (final sql in _touchSetup) {
        await db.customStatement(sql);
      }
      await db.customStatement('DELETE FROM temp.play_stats_touched');
      await db.customStatement('UPDATE main.play_stats_ctl SET bulk = 1 WHERE id = 1');
      final result = await write();
      await db.customStatement('''
DELETE FROM main.play_stats
WHERE track_id IN (SELECT track_id FROM temp.play_stats_touched)''');
      await db.customStatement('''
INSERT INTO main.play_stats
  (track_id, play_count, skip_count, first_played_at, last_played_at)
${playStatsAggregateSql(touchedOnly: true)}''');
      await db.customStatement('DELETE FROM temp.play_stats_touched');
      await db.customStatement('UPDATE main.play_stats_ctl SET bulk = 0 WHERE id = 1');
      db.notifyUpdates({
        const TableUpdate('play_log'),
        const TableUpdate('play_stats'),
      });
      return result;
    });
