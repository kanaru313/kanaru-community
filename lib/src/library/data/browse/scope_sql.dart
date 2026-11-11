import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../domain/browse/song_scope.dart';

/// A growing `WHERE` clause with its bound variables. Callers add fixed SQL
/// fragments only; every value goes through a [Variable].
class SqlWhere {
  final _clauses = <String>[];
  final vars = <Variable>[];

  void add(String clause, [List<Variable> bound = const []]) {
    _clauses.add(clause);
    vars.addAll(bound);
  }

  String get sql => _clauses.join(' AND ');
}

/// Narrows `tracks t` to [scope]. Needs the alias `t`.
void addScope(SqlWhere w, SongScope scope) {
  switch (scope) {
    case AllSongs():
      break;
    case AlbumSongs(:final key):
      w.add('t.album_artist_key = ? AND t.album_title_key = ?', [
        Variable.withString(key.artistKey),
        Variable.withString(key.titleKey),
      ]);
    case ArtistSongs(:final key):
      // Driven from the (artist_key, track_id) primary key.
      w.add(
        't.id IN (SELECT track_id FROM track_artists WHERE artist_key = ?)',
        [Variable.withString(key.key)],
      );
    case AlbumArtistSongs(:final key):
      w.add('t.album_artist_key = ?', [Variable.withString(key.key)]);
    case GenreSongs(:final genreKey):
      w.add('t.genre_key = ?', [Variable.withString(genreKey)]);
    case LanguageSongs(:final code):
      if (code == null) {
        w.add('t.language IS NULL');
      } else {
        w.add('t.language = ?', [Variable.withString(code)]);
      }
    case FolderSongs(:final sourceId, :final folderKey, :final direct):
      w.add('t.source_id = ?', [Variable.withInt(sourceId)]);
      final range = folderLocatorRange(folderKey);
      if (range != null) {
        w.add('t.locator >= ? AND t.locator < ?', [
          Variable.withString(range.from),
          Variable.withString(range.to),
        ]);
      }
      if (direct) {
        // No further '/' after the folder prefix. SQLite measures the prefix
        // itself: Dart's length counts UTF-16 units, substr counts characters.
        if (range == null) {
          w.add("instr(t.locator, '/') = 0");
        } else {
          w.add("instr(substr(t.locator, length(?) + 1), '/') = 0", [
            Variable.withString(range.from),
          ]);
        }
      }
  }
}
