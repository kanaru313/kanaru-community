import 'package:drift/drift.dart';

import '../../media/domain/track_id.dart';
import '../domain/track_title_lookup.dart';

class DbTrackTitleLookup implements TrackTitleLookup {
  DbTrackTitleLookup(this._db);

  final DatabaseConnectionUser _db;

  @override
  Future<String> titleOf(TrackId id) async {
    final row = await _db
        .customSelect(
          'SELECT title FROM tracks WHERE id = ?',
          variables: [Variable.withInt(id.value)],
        )
        .getSingleOrNull();
    return row?.read<String>('title') ?? '';
  }
}
