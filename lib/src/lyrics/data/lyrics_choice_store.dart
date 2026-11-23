import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../database/tables.dart';
import '../../media/domain/track_id.dart';

/// `track_lyrics_choices.mode` of "lyrics off".
const lyricsModeOff = LyricsChoiceMode.off;

/// `track_lyrics_choices.mode` of "lyrics from the file": the file's lyrics win
/// over a kept online copy.
const lyricsModeFile = LyricsChoiceMode.file;

Future<void> _setMode(AppDatabase db, TrackId id, String mode, int now) =>
    db.customInsert(
      'INSERT INTO track_lyrics_choices (track_id, mode, updated_at) '
      'VALUES (?, ?, ?) '
      'ON CONFLICT(track_id) DO UPDATE SET mode = excluded.mode, '
      'updated_at = excluded.updated_at',
      variables: [
        Variable.withInt(id.value),
        Variable.withString(mode),
        Variable.withInt(now),
      ],
      updates: {db.trackLyricsChoices},
    );

/// Turns lyrics off for [id]; the row is replaced when there is one. The
/// track must exist (the foreign key refuses an unknown id).
Future<void> setLyricsOff(AppDatabase db, TrackId id, {required int now}) =>
    _setMode(db, id, lyricsModeOff, now);

/// Makes the file's lyrics win for [id] (also over a kept online copy); the
/// row is replaced when there is one. The track must exist.
Future<void> setLyricsFile(AppDatabase db, TrackId id, {required int now}) =>
    _setMode(db, id, lyricsModeFile, now);

/// Back to automatic selection: removes the choice row of [id].
Future<void> clearLyricsChoice(AppDatabase db, TrackId id) => db.customUpdate(
  'DELETE FROM track_lyrics_choices WHERE track_id = ?',
  variables: [Variable.withInt(id.value)],
  updates: {db.trackLyricsChoices},
  updateKind: UpdateKind.delete,
);
