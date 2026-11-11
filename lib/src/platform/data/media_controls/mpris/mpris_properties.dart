import 'package:dbus/dbus.dart';

import '../../../domain/media_controls.dart';

const mprisObjectPath = '/org/mpris/MediaPlayer2';
const mprisRootInterface = 'org.mpris.MediaPlayer2';
const mprisPlayerInterface = 'org.mpris.MediaPlayer2.Player';
const mprisNoTrackPath = '/org/mpris/MediaPlayer2/TrackList/NoTrack';
const _trackPathPrefix = '/io/github/kanaru313/kanaru_community/entry';

/// Desktop file id (without `.desktop`) of the app.
const mprisDesktopEntry = 'io.github.kanaru313.kanaru_community';

/// Properties never sent in `PropertiesChanged`: clients read them (or hear
/// `Seeked`).
const _unsignaled = {'Position', 'CanControl'};

/// Object path of the queue entry [id]. Anything that is not made of word
/// characters is replaced, as an object path allows nothing else.
String mprisTrackPath(String id) =>
    '$_trackPathPrefix/${id.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_')}';

/// Fixed properties of `org.mpris.MediaPlayer2`.
Map<String, DBusValue> mprisRootProperties() => {
  'CanQuit': const DBusBoolean(false),
  'Fullscreen': const DBusBoolean(false),
  'CanSetFullscreen': const DBusBoolean(false),
  'CanRaise': const DBusBoolean(false),
  'HasTrackList': const DBusBoolean(false),
  'Identity': const DBusString('Kanaru'),
  'DesktopEntry': const DBusString(mprisDesktopEntry),
  'SupportedUriSchemes': DBusArray.string(const []),
  'SupportedMimeTypes': DBusArray.string(const []),
};

/// `file://` form of [uri], or null for anything else. A network address
/// (a proxy URL with a token, say) must never be published.
String? mprisArtUrl(Uri? uri) =>
    uri != null && uri.scheme == 'file' ? uri.toString() : null;

String mprisPlaybackStatus(MediaControlsItem? item, MediaControlsState state) {
  // Stopped comes from the app's state: the engine may still say "playing"
  // for a moment after a stop.
  if (item == null || state.stopped) return 'Stopped';
  return state.playing ? 'Playing' : 'Paused';
}

String mprisLoopStatus(MediaRepeat repeat) => switch (repeat) {
  MediaRepeat.none => 'None',
  MediaRepeat.track => 'Track',
  MediaRepeat.playlist => 'Playlist',
};

MediaRepeat? mediaRepeatFromLoopStatus(String status) => switch (status) {
  'None' => MediaRepeat.none,
  'Track' => MediaRepeat.track,
  'Playlist' => MediaRepeat.playlist,
  _ => null,
};

/// `a{sv}` of the current item with the types clients insist on: object path
/// id, int64 microseconds length (only when known), string-array artist.
/// Empty strings are left out.
DBusValue mprisMetadata(MediaControlsItem? item) {
  if (item == null) {
    return DBusDict.stringVariant({
      'mpris:trackid': DBusObjectPath(mprisNoTrackPath),
    });
  }
  final artists = [
    for (final a in item.artists)
      if (a.isNotEmpty) a,
  ];
  final length = item.duration;
  final art = mprisArtUrl(item.artUri);
  return DBusDict.stringVariant({
    'mpris:trackid': DBusObjectPath(mprisTrackPath(item.id)),
    if (length != null && length > Duration.zero)
      'mpris:length': DBusInt64(length.inMicroseconds),
    if (item.title.isNotEmpty) 'xesam:title': DBusString(item.title),
    if (artists.isNotEmpty) 'xesam:artist': DBusArray.string(artists),
    if (item.album != null && item.album!.isNotEmpty)
      'xesam:album': DBusString(item.album!),
    'mpris:artUrl': ?(art == null ? null : DBusString(art)),
  });
}

/// All properties of `org.mpris.MediaPlayer2.Player`. [position] is read live
/// by the caller; it is part of the map for `GetAll` only.
Map<String, DBusValue> mprisPlayerProperties(
  MediaControlsItem? item,
  MediaControlsState state, {
  Duration position = Duration.zero,
}) => {
  'PlaybackStatus': DBusString(mprisPlaybackStatus(item, state)),
  'LoopStatus': DBusString(mprisLoopStatus(state.repeat)),
  'Rate': DBusDouble(state.speed),
  'Shuffle': DBusBoolean(state.shuffle),
  'Metadata': mprisMetadata(item),
  'Volume': DBusDouble(state.volume.clamp(0, 1).toDouble()),
  'Position': DBusInt64(position.inMicroseconds),
  'MinimumRate': const DBusDouble(1),
  'MaximumRate': const DBusDouble(1),
  'CanGoNext': DBusBoolean(state.canNext),
  'CanGoPrevious': DBusBoolean(state.canPrevious),
  'CanPlay': DBusBoolean(state.canPlay),
  'CanPause': DBusBoolean(state.canPlay),
  'CanSeek': DBusBoolean(state.canSeek),
  'CanControl': const DBusBoolean(true),
};

/// Entries of [next] that differ from [previous], without the properties
/// that are never signalled.
Map<String, DBusValue> mprisChangedProperties(
  Map<String, DBusValue> previous,
  Map<String, DBusValue> next,
) => {
  for (final e in next.entries)
    if (!_unsignaled.contains(e.key) && previous[e.key] != e.value)
      e.key: e.value,
};
