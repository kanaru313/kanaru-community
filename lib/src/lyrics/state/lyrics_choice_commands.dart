import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../database/state/database_providers.dart';
import '../../media/domain/track_id.dart';
import '../data/lyrics_choice_store.dart';

/// Milliseconds since the epoch; tests replace it.
final lyricsClockProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().millisecondsSinceEpoch,
);

/// Writes the user's per-track lyrics choice. Reads nothing: the facts stream
/// refreshes, and the lyrics providers recompute without touching a file.
class LyricsChoiceCommands {
  LyricsChoiceCommands(this._db, this._nowMs);

  final AppDatabase _db;
  final int Function() _nowMs;

  /// "Không hiện lời" for [id].
  Future<void> setOff(TrackId id) => setLyricsOff(_db, id, now: _nowMs());

  /// "Lời trong file": the file's lyrics win over a kept online copy.
  Future<void> setFile(TrackId id) => setLyricsFile(_db, id, now: _nowMs());

  /// Back to automatic selection.
  Future<void> clear(TrackId id) => clearLyricsChoice(_db, id);

  /// Off becomes automatic, anything else becomes off. [currentlyOff] is what
  /// the caller shows.
  Future<void> toggle(TrackId id, {required bool currentlyOff}) =>
      currentlyOff ? clear(id) : setOff(id);
}

final lyricsChoiceCommandsProvider = Provider<LyricsChoiceCommands>(
  (ref) => LyricsChoiceCommands(
    ref.watch(appDatabaseProvider),
    ref.watch(lyricsClockProvider),
  ),
);
