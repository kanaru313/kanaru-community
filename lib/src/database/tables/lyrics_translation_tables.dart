import 'package:drift/drift.dart';

import 'library_track_tables.dart';

/// Limits of the translation cache.
abstract final class TranslationLimits {
  /// Longest `lyrics_translations.lines_json` (characters, 2 MiB).
  static const maxLinesJsonLength = 2097152;
}

/// Cached translation of one lyrics text by one plugin into one language. A
/// cache class table: no foreign key (a cached translation survives removing
/// the plugin and collecting the track), no uid, safe to drop. `content_hash`
/// is the hash of the source lines, not a track id.
///
/// The set of valid `target_lang` codes lives in the plugins module; the
/// database only checks the shape, the store checks the code.
@TableIndex(
  name: 'lyrics_translations_lookup',
  columns: {#contentHash, #targetLang, #createdAt},
)
@DataClassName('LyricsTranslationRow')
class LyricsTranslations extends Table {
  TextColumn get contentHash => text()();

  /// The translate plugin's install id (no foreign key).
  TextColumn get installId => text()();
  TextColumn get targetLang =>
      text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(targetLang.length.isBetweenValues(2, 7))();

  /// Dominant source language the plugin saw; null when unknown.
  TextColumn get sourceLang => text().nullable()();

  /// JSON object: source line to translated line.
  TextColumn get linesJson =>
      text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(
        linesJson.length.isSmallerOrEqualValue(
          TranslationLimits.maxLinesJsonLength,
        ),
      )();

  /// JSON `{pluginVersion, model, style, instructionHash}` of the run.
  TextColumn get settingsJson => text()();

  /// False while chunks are still arriving; only a complete row is reused.
  BoolColumn get complete => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {contentHash, installId, targetLang};
}

/// The translation language the user picked for one track. No row = the
/// global setting. Owned child of `tracks`: the track GC deletes it together
/// with the track.
@DataClassName('TrackTranslationPref')
class TrackTranslationPrefs extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();

  /// Shape check only (see [LyricsTranslations.targetLang]); never null in
  /// practice: "no choice" deletes the row.
  TextColumn get targetLang =>
      text().nullable()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(targetLang.length.isBetweenValues(2, 7))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {trackId};
}
