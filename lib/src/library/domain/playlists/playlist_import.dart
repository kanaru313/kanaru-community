import '../../../media/domain/track_id.dart';

/// One usable M3U line, in file order.
sealed class ImportedEntry {
  const ImportedEntry();
}

/// A line that resolved to a track already in the library.
final class ImportedTrack extends ImportedEntry {
  const ImportedTrack(this.id);

  final TrackId id;

  @override
  bool operator ==(Object other) => other is ImportedTrack && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A file under a live local music folder with no `tracks` row: the store
/// creates a placeholder. [locator] is relative to that source's root;
/// [title], [artist] and [durationMs] (from `#EXTINF`) go on the placeholder
/// snapshot.
final class ImportedMissing extends ImportedEntry {
  const ImportedMissing({
    required this.sourceId,
    required this.locator,
    required this.title,
    this.artist,
    this.durationMs,
  });

  final int sourceId;
  final String locator;
  final String title;
  final String? artist;
  final int? durationMs;

  @override
  bool operator ==(Object other) =>
      other is ImportedMissing &&
      other.sourceId == sourceId &&
      other.locator == locator &&
      other.title == title &&
      other.artist == artist &&
      other.durationMs == durationMs;

  @override
  int get hashCode => Object.hash(sourceId, locator, title, artist, durationMs);
}

/// Result of importing a playlist: its [uid], how many entries it holds and
/// how many placeholders were created for [ImportedMissing] lines.
class ImportedPlaylist {
  const ImportedPlaylist({
    required this.uid,
    required this.entryCount,
    required this.missingCreated,
  });

  final String uid;
  final int entryCount;
  final int missingCreated;

  @override
  bool operator ==(Object other) =>
      other is ImportedPlaylist &&
      other.uid == uid &&
      other.entryCount == entryCount &&
      other.missingCreated == missingCreated;

  @override
  int get hashCode => Object.hash(uid, entryCount, missingCreated);
}
