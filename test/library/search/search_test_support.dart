import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

import '../../database/support/test_db.dart';

/// Inserts a track with the tag fields and their search forms, and returns
/// its id. The search forms follow the scanner: `searchForm` of each field.
Future<int> addSearchTrack(
  AppDatabase db,
  int sourceId, {
  required String locator,
  required String title,
  String? artist,
  String? album,
  int? year,
  String status = 'present',
}) async {
  final id = await addTrack(
    db,
    sourceId,
    locator: locator,
    title: title,
    status: status,
  );
  await db.customStatement(
    'UPDATE tracks SET artist = ?, album = ?, year = ?, title_search = ?, '
    'artist_search = ?, album_search = ? WHERE id = ?',
    [
      artist,
      album,
      year,
      searchForm(title),
      searchForm(artist ?? ''),
      searchForm(album ?? ''),
      id,
    ],
  );
  return id;
}
