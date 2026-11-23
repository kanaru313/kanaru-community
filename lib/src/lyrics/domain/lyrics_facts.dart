import '../../media/domain/track_id.dart';
import 'online/lyrics_candidate.dart';

/// What the database knows about the lyrics of one track. The audio path and
/// whether the track is playable come from the playback resolver, never from
/// here.
class LyricsFacts {
  const LyricsFacts({
    required this.trackId,
    required this.trackRevision,
    required this.lrcLocator,
    required this.lrcRevision,
    required this.off,
    this.file = false,
    this.title,
    this.artist,
    this.artists = const [],
    this.album,
    this.duration,
  });

  final TrackId trackId;

  /// `tracks.revision` of the audio file.
  final String? trackRevision;

  /// Locator of the `.lrc` the scan matched; null when it found none.
  final String? lrcLocator;
  final String? lrcRevision;

  /// The user turned lyrics off for this track.
  final bool off;

  /// The user chose "Lời trong file": the file's lyrics win over a kept
  /// online copy.
  final bool file;

  /// Tags the online search is made from (never a path or a file name).
  final String? title;

  /// The library artist tag, possibly several names (`A; B`).
  final String? artist;

  /// The artists in tag order.
  final List<String> artists;
  final String? album;
  final Duration? duration;

  /// The online search key of the track.
  LyricsQuery get query => LyricsQuery(
    title: title,
    artist: artist,
    album: album,
    duration: duration,
  );

  /// What changes the lyrics read from files; not the choice, so a choice
  /// write never re-reads.
  (String?, String?, String?) get readKey =>
      (trackRevision, lrcLocator, lrcRevision);

  @override
  bool operator ==(Object other) =>
      other is LyricsFacts &&
      other.trackId == trackId &&
      other.trackRevision == trackRevision &&
      other.lrcLocator == lrcLocator &&
      other.lrcRevision == lrcRevision &&
      other.off == off &&
      other.file == file &&
      other.title == title &&
      other.artist == artist &&
      _sameList(other.artists, artists) &&
      other.album == album &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(
    trackId,
    trackRevision,
    lrcLocator,
    lrcRevision,
    off,
    file,
    title,
    artist,
    Object.hashAll(artists),
    album,
    duration,
  );
}

/// The `.lrc` file of a track: the folder of its resolved audio path plus the
/// file name of the scan's [lrcLocator]. The scan matches sidecars only in
/// the track's own folder, so the locator's folder part is not needed.
String lrcPathBeside(String audioPath, String lrcLocator) {
  final slash = audioPath.lastIndexOf('/');
  final folder = slash < 0 ? '' : audioPath.substring(0, slash + 1);
  return '$folder${lrcLocator.substring(lrcLocator.lastIndexOf('/') + 1)}';
}

/// The paths probed when the scan found no sidecar: `<stem>.lrc`, then
/// `<stem>.LRC`, where `<stem>` is the file name without its extension (a
/// name without one, or a dot file, is kept whole).
List<String> lrcProbeCandidates(String audioPath) {
  final slash = audioPath.lastIndexOf('/');
  final dot = audioPath.lastIndexOf('.');
  final stem = dot > slash + 1 ? audioPath.substring(0, dot) : audioPath;
  return ['$stem.lrc', '$stem.LRC'];
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
