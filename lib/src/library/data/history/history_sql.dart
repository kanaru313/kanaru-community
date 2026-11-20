// SQL of the history reads, nothing else. Every statement leaves out removed
// (tombstoned) and skipped plays, and the ones over `play_log` are written to
// be answered by one of its indexes (`play_log_played_at` for time windows,
// `play_log_track_played` for one song), never by a scan of the table.
// `play_log` is never given an alias so a query plan names it plainly.

const _counted = 'deleted_at IS NULL AND skipped = 0';
const _inWindow = 'played_at >= ?1 AND played_at < ?2';

/// First and last counted play, from the per-track aggregate (one row per
/// played track), so it does not read `play_log`.
const historyBoundsSql =
    'SELECT min(first_played_at) AS lo, max(last_played_at) AS hi '
    'FROM play_stats WHERE last_played_at IS NOT NULL';

/// Whether `[?1, ?2)` has a counted play (a candidate year of the year chips).
const historyWindowHasPlaySql =
    'SELECT EXISTS(SELECT 1 FROM play_log WHERE $_counted AND $_inWindow) '
    'AS has_play';

/// The plays of `[?1, ?2)`, newest first; ties by row id.
const historyYearPlaysSql =
    'SELECT id, uid, track_id, played_at, listened_ms FROM play_log '
    'WHERE $_counted AND $_inWindow ORDER BY played_at DESC, id DESC';

/// Plays at or after `?1` per track (the plays after a year). The index is
/// named because, left alone, the planner picks the one that already orders by
/// track to skip the grouping sort, and that reads the whole log.
const historyAfterCountsSql =
    'SELECT track_id, count(*) AS n FROM play_log '
    'INDEXED BY play_log_played_at '
    'WHERE $_counted AND played_at >= ?1 GROUP BY track_id';

/// All-time play count of the tracks in the JSON array `?1`.
const historyPlayCountsSql =
    'SELECT track_id, play_count FROM play_stats '
    'WHERE track_id IN (SELECT value FROM json_each(?1))';

/// Plays and songs over all time, and the first play.
const historyOverviewSql =
    'SELECT coalesce(sum(play_count), 0) AS plays, count(*) AS songs, '
    'min(first_played_at) AS since FROM play_stats WHERE play_count > 0';

/// Every play of track `?1`, newest first.
const historyTrackPlaysSql =
    'SELECT id, uid, played_at, listened_ms FROM play_log '
    'WHERE track_id = ?1 AND $_counted ORDER BY played_at DESC, id DESC';

/// The most played tracks of `[?1, ?2)`, at most `?3`. Ties: the earlier last
/// play first, then the track id.
const historyTopWindowSql =
    'SELECT track_id, count(*) AS n, max(played_at) AS last FROM play_log '
    'WHERE $_counted AND $_inWindow GROUP BY track_id '
    'ORDER BY n DESC, last ASC, track_id LIMIT ?3';

/// Songs and plays of `[?1, ?2)`.
const historyWindowTotalsSql =
    'SELECT count(DISTINCT track_id) AS songs, count(*) AS plays '
    'FROM play_log WHERE $_counted AND $_inWindow';

/// The most played tracks over all time, at most `?1`; same tie rule.
const historyTopAllSql =
    'SELECT track_id, play_count AS n, last_played_at AS last FROM play_stats '
    'WHERE play_count > 0 ORDER BY n DESC, last ASC, track_id LIMIT ?1';

/// The plays of `[?1, ?2)` (their days are worked out in Dart, local time).
const historyPlayTimesSql =
    'SELECT played_at FROM play_log WHERE $_counted AND $_inWindow';

/// Number of plays in `[?1, ?2)`.
const historyCountSql =
    'SELECT count(*) AS n FROM play_log WHERE $_counted AND $_inWindow';

/// Tracks ever played, last played first.
const historyPlayedTracksSql =
    'SELECT track_id FROM play_stats WHERE last_played_at IS NOT NULL '
    'ORDER BY last_played_at DESC, track_id DESC';
