import 'package:drift/drift.dart';

/// Colours taken from a cover, keyed by the cover's content key. A cache:
/// it may be dropped at any time and is rebuilt from the cover. No foreign
/// key: the key is a content hash shared by many tracks.
@DataClassName('CoverColorsRow')
class CoverColors extends Table {
  /// Same value as `tracks.cover_key`.
  TextColumn get coverKey => text()();

  /// ARGB seed colour (input of `ColorScheme.fromSeed`).
  IntColumn get seed => integer()();

  /// JSON array of ARGB ints, most dominant first.
  TextColumn get colors => text()();

  /// Version of the algorithm that produced the row.
  IntColumn get version => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {coverKey};
}
