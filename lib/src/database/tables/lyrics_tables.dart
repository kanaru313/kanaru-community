import 'package:drift/drift.dart';

import 'library_track_tables.dart';

/// The values of `track_lyrics_choices.mode`. Raw strings: the database layer
/// knows no lyrics types.
abstract final class LyricsChoiceMode {
  /// The user turned lyrics off for this track.
  static const off = 'off';

  /// The user picked "Lời trong file" while a kept online copy exists: the
  /// file lyrics win over the copy until the user picks the online one again.
  static const file = 'file';

  static const values = {off, file};
}

/// Per-track lyrics choice of the user. No row = automatic (the local
/// selection order decides). Owned child of `tracks`: the track GC deletes it
/// together with the track.
@DataClassName('TrackLyricsChoice')
class TrackLyricsChoices extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();

  /// `off` or `file` (see [LyricsChoiceMode]).
  TextColumn get mode =>
      text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(mode.isIn(LyricsChoiceMode.values))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {trackId};
}

/// Values of `online_lyrics.status`.
abstract final class OnlineLyricsStatus {
  static const found = 'found';
  static const notFound = 'not_found';

  static const values = {found, notFound};
}

/// The online copy of a track's lyrics the user kept ("Bản đã giữ"). Owned
/// child of `tracks`: deleted with the track. The provider is a plugin install
/// id without a foreign key, so the copy survives removing the plugin.
@DataClassName('LyricsPinRow')
class LyricsPins extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();

  /// `pin:` + hash(track uid).
  TextColumn get uid => text().unique()();
  TextColumn get providerId => text()();

  /// The plugin's name when the copy was kept, shown after the plugin is gone.
  TextColumn get providerName => text()();
  TextColumn get remoteId => text()();

  /// At most 1 MiB each; a copy holds at least one of the two or is
  /// instrumental.
  TextColumn get syncedText => text().nullable()();
  TextColumn get plainText => text().nullable()();
  BoolColumn get instrumental => boolean().withDefault(const Constant(false))();
  IntColumn get remoteDurationMs => integer().nullable()();
  IntColumn get pinnedAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {trackId};

  @override
  List<String> get customConstraints => [
    'CONSTRAINT lyrics_pins_body CHECK (synced_text IS NOT NULL '
        'OR plain_text IS NOT NULL OR instrumental = 1)',
  ];
}

/// "Không đúng bài": a result of a provider the user refused for one track.
/// Owned child of `tracks`.
@DataClassName('LyricsRejectRow')
class LyricsRejects extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();
  TextColumn get providerId => text()();
  TextColumn get remoteId => text()();

  /// Hash of the refused text, so a duplicate of it under another id is
  /// refused too; null for an instrumental or text-less result.
  TextColumn get contentHash => text().nullable()();
  IntColumn get rejectedAt => integer()();

  @override
  Set<Column> get primaryKey => {trackId, providerId, remoteId};
}

/// Lookup cache: one row per song key and provider. Safe to drop, no foreign
/// key. `cache_key` is the sha256 of the folded artist, title, album and
/// rounded seconds, not `tracks.song_key`.
@DataClassName('OnlineLyricsRow')
class OnlineLyrics extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get providerId => text()();

  TextColumn get status =>
      text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(status.isIn(OnlineLyricsStatus.values))();

  /// Null for `not_found`.
  TextColumn get remoteId => text().nullable()();
  TextColumn get syncedText => text().nullable()();
  TextColumn get plainText => text().nullable()();
  BoolColumn get instrumental => boolean().withDefault(const Constant(false))();
  IntColumn get remoteDurationMs => integer().nullable()();
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {cacheKey, providerId};

  @override
  List<String> get customConstraints => [
    // A result names itself and carries lyrics or the instrumental flag; a
    // miss carries nothing.
    'CONSTRAINT online_lyrics_status_columns CHECK ('
        "(status = 'found' AND remote_id IS NOT NULL AND (synced_text IS NOT NULL "
        'OR plain_text IS NOT NULL OR instrumental = 1)) '
        "OR (status = 'not_found' AND remote_id IS NULL AND synced_text IS NULL "
        'AND plain_text IS NULL AND instrumental = 0))',
  ];
}
