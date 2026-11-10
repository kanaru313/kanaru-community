import '../../media/domain/track_id.dart';

/// Why a track cannot be played from this device.
enum UnplayableReason {
  /// The file was not found by the last complete scan.
  missing,

  /// The user took the track out of the library.
  hidden,

  /// A remote or plugin track (not playable in this version).
  remote,

  /// A track inside a CUE sheet (not playable in this version).
  cue,

  /// Its source has no enabled mount on this device.
  noMount,

  /// Its source was removed.
  removedSource,

  /// No such track.
  unknownTrack,
}

/// What the engine may be given for one track.
sealed class Playable {
  const Playable();
}

/// A local file, with the duration the library knows.
class LocalFile extends Playable {
  const LocalFile(this.path, this.durationMs);

  final String path;
  final int? durationMs;

  @override
  bool operator ==(Object other) =>
      other is LocalFile &&
      other.path == path &&
      other.durationMs == durationMs;

  @override
  int get hashCode => Object.hash(path, durationMs);

  @override
  String toString() => 'LocalFile($path)';
}

class Unplayable extends Playable {
  const Unplayable(this.reason);

  final UnplayableReason reason;

  @override
  bool operator ==(Object other) =>
      other is Unplayable && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'Unplayable($reason)';
}

/// Turns track ids into files. Ids missing from the result were not asked.
abstract interface class PlayableResolver {
  /// One entry per distinct id of [ids]; an id without a track is
  /// `Unplayable(unknownTrack)`.
  Future<Map<TrackId, Playable>> resolve(List<TrackId> ids);
}
