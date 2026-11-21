import 'package:drift/drift.dart';

import 'library_track_tables.dart';

/// The values of `track_lyrics_choices.mode`. Raw strings: the database layer
/// knows no lyrics types.
abstract final class LyricsChoiceMode {
  /// The user turned lyrics off for this track.
  static const off = 'off';

  static const values = {off};
}

/// Per-track lyrics choice of the user. No row = automatic (the local
/// selection order decides). Owned child of `tracks`: the track GC deletes it
/// together with the track.
@DataClassName('TrackLyricsChoice')
class TrackLyricsChoices extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();

  /// `off` only for now (see [LyricsChoiceMode]).
  TextColumn get mode =>
      text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(mode.isIn(LyricsChoiceMode.values))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {trackId};
}
