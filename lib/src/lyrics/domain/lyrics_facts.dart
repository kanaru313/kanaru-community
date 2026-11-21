import '../../media/domain/track_id.dart';

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
  });

  final TrackId trackId;

  /// `tracks.revision` of the audio file.
  final String? trackRevision;

  /// Locator of the `.lrc` the scan matched; null when it found none.
  final String? lrcLocator;
  final String? lrcRevision;

  /// The user turned lyrics off for this track.
  final bool off;

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
      other.off == off;

  @override
  int get hashCode =>
      Object.hash(trackId, trackRevision, lrcLocator, lrcRevision, off);
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
