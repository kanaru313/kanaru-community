import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../media/domain/track_id.dart';
import '../domain/lyrics_facts.dart';
import 'lyrics_choice_store.dart';

/// The lyrics facts of one track, re-emitted when the track row, its details
/// or its choice change; `null` for an unknown track. Equal values are not
/// emitted twice. Playability and the audio path are not here: they come only
/// from the playback resolver.
Stream<LyricsFacts?> watchLyricsFacts(AppDatabase db, TrackId id) {
  return db
      .customSelect(
        'SELECT t.revision AS revision, d.lrc_locator AS lrc_locator, '
        'd.lrc_revision AS lrc_revision, c.mode AS mode '
        'FROM tracks t '
        'LEFT JOIN track_details d ON d.track_id = t.id '
        'LEFT JOIN track_lyrics_choices c ON c.track_id = t.id '
        'WHERE t.id = ?',
        variables: [Variable.withInt(id.value)],
        readsFrom: {db.tracks, db.trackDetails, db.trackLyricsChoices},
      )
      .watchSingleOrNull()
      .map(
        (row) => row == null
            ? null
            : LyricsFacts(
                trackId: id,
                trackRevision: row.readNullable<String>('revision'),
                lrcLocator: row.readNullable<String>('lrc_locator'),
                lrcRevision: row.readNullable<String>('lrc_revision'),
                off: row.readNullable<String>('mode') == lyricsModeOff,
              ),
      )
      .distinct();
}
