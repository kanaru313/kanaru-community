/// Repeat as the system media controls know it.
enum MediaRepeat { none, track, playlist }

/// The track the system controls show. [id] is stable for one queue entry.
class MediaControlsItem {
  const MediaControlsItem({
    required this.id,
    required this.title,
    this.artists = const [],
    this.album,
    this.duration,
    this.artUri,
  });

  final String id;
  final String title;
  final List<String> artists;
  final String? album;
  final Duration? duration;

  /// A `file:` URI of the full cover; never a network address.
  final Uri? artUri;

  @override
  bool operator ==(Object other) {
    if (other is! MediaControlsItem ||
        other.id != id ||
        other.title != title ||
        other.album != album ||
        other.duration != duration ||
        other.artUri != artUri ||
        other.artists.length != artists.length) {
      return false;
    }
    for (var i = 0; i < artists.length; i++) {
      if (other.artists[i] != artists[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, title, album, duration, artUri, Object.hashAll(artists));
}

/// What the system controls show besides the track. Equality leaves out
/// [position]: it ticks, and a tick is never published by itself.
class MediaControlsState {
  const MediaControlsState({
    this.playing = false,
    this.stopped = true,
    this.started = false,
    this.position = Duration.zero,
    this.canPlay = false,
    this.canPrevious = false,
    this.canNext = false,
    this.canSeek = false,
    this.shuffle = false,
    this.repeat = MediaRepeat.none,
    this.volume = 1,
    this.speed = 1,
  });

  /// Audio is playing.
  final bool playing;

  /// The player is stopped (or empty), as opposed to paused.
  final bool stopped;

  /// Something has played since launch. False keeps Android's session idle,
  /// so there is no notification at launch.
  final bool started;
  final Duration position;
  final bool canPlay;
  final bool canPrevious;
  final bool canNext;
  final bool canSeek;
  final bool shuffle;
  final MediaRepeat repeat;

  /// 0..1.
  final double volume;
  final double speed;

  MediaControlsState copyWith({Duration? position}) => MediaControlsState(
    playing: playing,
    stopped: stopped,
    started: started,
    position: position ?? this.position,
    canPlay: canPlay,
    canPrevious: canPrevious,
    canNext: canNext,
    canSeek: canSeek,
    shuffle: shuffle,
    repeat: repeat,
    volume: volume,
    speed: speed,
  );

  @override
  bool operator ==(Object other) =>
      other is MediaControlsState &&
      other.playing == playing &&
      other.stopped == stopped &&
      other.started == started &&
      other.canPlay == canPlay &&
      other.canPrevious == canPrevious &&
      other.canNext == canNext &&
      other.canSeek == canSeek &&
      other.shuffle == shuffle &&
      other.repeat == repeat &&
      other.volume == volume &&
      other.speed == speed;

  @override
  int get hashCode => Object.hash(
    playing,
    stopped,
    started,
    canPlay,
    canPrevious,
    canNext,
    canSeek,
    shuffle,
    repeat,
    volume,
    speed,
  );
}

/// A request from the system: media keys, `playerctl`, the notification, a
/// headset, an audio-focus change.
sealed class MediaCommand {
  const MediaCommand();
}

class Play extends MediaCommand {
  const Play();
}

class Pause extends MediaCommand {
  const Pause();
}

class PlayPause extends MediaCommand {
  const PlayPause();
}

class Stop extends MediaCommand {
  const Stop();
}

class Next extends MediaCommand {
  const Next();
}

class Previous extends MediaCommand {
  const Previous();
}

/// Moves by [offset] from the current position (may be negative).
class Seek extends MediaCommand {
  const Seek(this.offset);
  final Duration offset;
}

/// Jumps to [position] in the item [id]; ignored when [id] is no longer the
/// current item.
class SetPosition extends MediaCommand {
  const SetPosition(this.id, this.position);
  final String id;
  final Duration position;
}

class SetShuffle extends MediaCommand {
  const SetShuffle(this.on);
  final bool on;
}

class SetRepeat extends MediaCommand {
  const SetRepeat(this.repeat);
  final MediaRepeat repeat;
}

/// 0..1.
class SetVolume extends MediaCommand {
  const SetVolume(this.volume);
  final double volume;
}

/// The system side of playback, one implementation per platform. Never
/// throws from [start], [update] or [dispose]: a platform that cannot offer
/// controls stays quiet and logs.
abstract interface class MediaControls {
  /// Makes the controls visible to the system (Linux: takes the bus name).
  Future<void> start();

  /// Publishes the current item (null = none) and state. Calls arrive
  /// already coalesced and different from the last one.
  Future<void> update(MediaControlsItem? item, MediaControlsState state);

  /// The live position, for readers that ask (MPRIS `Position`). Stored
  /// silently; it is never signalled.
  void updatePosition(Duration position);

  /// The position jumped because of a seek.
  void seeked(Duration position);

  /// Requests from the system. Single listener; a request that arrives
  /// before anyone listens may be replayed to the first listener.
  Stream<MediaCommand> get commands;

  /// Asks the system for audio focus before playing. False = denied. Linux
  /// has no focus and always grants.
  Future<bool> activate();

  /// Gives audio focus back (stop).
  Future<void> deactivate();

  Future<void> dispose();
}
