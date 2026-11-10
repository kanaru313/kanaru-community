import 'dart:async';

import 'package:logging/logging.dart';

import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';
import '../../platform/domain/media_controls.dart';
import '../domain/now_playing.dart';
import '../domain/play_intent.dart';
import '../domain/playback_focus.dart';
import '../domain/playback_views.dart';
import '../domain/queue_logic.dart' show nextIndex;
import '../domain/repeat_mode.dart';
import 'player_controller.dart';

final _log = Logger('MediaSessionBridge');

/// Changes within this window go to the system controls as one update.
const mediaUpdateWindow = Duration(milliseconds: 150);

/// Audio focus that takes longer to answer than this counts as denied.
const mediaFocusTimeout = Duration(seconds: 2);

/// Connects the player to the system media controls (MPRIS, the Android
/// notification and session): one coalesced update per change, commands from
/// the system into the player, and audio focus as the gate before playing.
///
/// It listens to plain streams of the controller, never to Riverpod
/// providers, so a paused widget subtree cannot pause it. Position ticks are
/// stored for readers but never trigger an update; a seek does, through
/// `seeked`.
class MediaSessionBridge implements PlaybackFocus {
  MediaSessionBridge({
    required this.controls,
    required this.infoOf,
    required this.artPathOf,
    this.startOnRestore = false,
    this.window = mediaUpdateWindow,
    this.focusTimeout = mediaFocusTimeout,
  }) {
    // Subscribed at once: a command that arrived before the player existed
    // is replayed to this listener.
    _commandSub = controls.commands.listen(
      _onCommand,
      onError: (Object e) => _log.warning('media command stream: $e'),
    );
  }

  final MediaControls controls;

  /// Track facts for an item; null when the track is gone.
  final Future<TrackInfo?> Function(TrackId id) infoOf;

  /// Path of the full cover file for a cover key, or null when there is no
  /// such file. Only an existing file is published as art.
  final String? Function(String coverKey) artPathOf;

  /// Start the controls once the restored session has a current entry (Linux
  /// media keys work right after launch). Otherwise they start at the first
  /// play.
  final bool startOnRestore;
  final Duration window;
  final Duration focusTimeout;

  PlayerController? _controller;
  final _subs = <StreamSubscription<Object?>>[];
  late final StreamSubscription<MediaCommand> _commandSub;
  Timer? _timer;
  Future<void>? _inFlight;
  bool _again = false;
  bool _disposed = false;
  bool _controlsStarted = false;
  bool _everPlayed = false;

  NowPlaying _now = NowPlaying.none;
  QueueView _queue = const QueueView();
  TransportView _transport = const TransportView();
  int? _positionEntry;
  Duration? _duration;
  Duration _position = Duration.zero;

  // The track facts of the current entry, reloaded when the entry changes.
  int? _infoEntry;
  MediaControlsItem? _baseItem;

  MediaControlsItem? _lastItem;
  MediaControlsState? _lastState;

  /// Follows [controller]. Attaching the same controller again does nothing;
  /// a different one replaces the first.
  void attach(PlayerController controller) {
    if (_disposed || identical(_controller, controller)) return;
    _detach();
    _controller = controller;
    _subs
      ..add(
        controller.nowPlaying.listen((n) {
          _now = n;
          if (n.playing) _everPlayed = true;
          _schedule();
        }),
      )
      ..add(
        controller.queueView.listen((q) {
          _queue = q;
          _schedule();
        }),
      )
      ..add(
        controller.transport.listen((t) {
          _transport = t;
          _schedule();
        }),
      )
      ..add(
        controller.position.listen((p) {
          _position = p.position;
          controls.updatePosition(p.position);
          // Ticks change nothing published; a new entry or length does.
          if (p.entryId != _positionEntry || p.duration != _duration) {
            _positionEntry = p.entryId;
            _duration = p.duration;
            _schedule();
          }
        }),
      )
      ..add(controller.seeks.listen(_onSeek));
    _schedule();
  }

  void _detach() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _controller = null;
  }

  void _schedule() {
    if (_disposed) return;
    _timer ??= Timer(window, () {
      _timer = null;
      unawaited(_flush());
    });
  }

  /// Sends pending changes now and completes when they are out, also when
  /// a publish was already running (it is run once more, for what changed
  /// meanwhile). Used before `seeked`, so the new item goes out first.
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    return _flush();
  }

  Future<void> _flush() {
    if (_disposed) return Future.value();
    final running = _inFlight;
    if (running != null) {
      _again = true;
      return running;
    }
    return _inFlight = _run();
  }

  Future<void> _run() async {
    try {
      do {
        _again = false;
        await _publish();
      } while (_again && !_disposed);
    } on Object catch (e, st) {
      _log.warning('media update failed: $e', e, st);
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _publish() async {
    final controller = _controller;
    if (controller == null) return;
    final item = await _currentItem();
    if (_disposed) return;
    final state = _currentState(controller, item);
    if (!_controlsStarted &&
        ((startOnRestore && item != null) || _everPlayed)) {
      _controlsStarted = true;
      try {
        await controls.start();
      } on Object catch (e) {
        _log.warning('media controls did not start: $e');
      }
    }
    // Nothing loaded and nothing said yet: nothing to say.
    if (item == null && _lastState == null) return;
    if (item == _lastItem && state == _lastState) return;
    _lastItem = item;
    _lastState = state;
    await controls.update(item, state);
  }

  MediaControlsState _currentState(
    PlayerController controller,
    MediaControlsItem? item,
  ) {
    final queue = controller.queueState;
    final hasTrack = item != null;
    final intent = _transport.intent;
    return MediaControlsState(
      playing: hasTrack && _now.playing,
      stopped: !hasTrack || intent == PlayIntent.stopped,
      started: _everPlayed && hasTrack && intent != PlayIntent.stopped,
      position: _position,
      canPlay: hasTrack,
      // Previous always works: at the first entry it goes back to the start.
      canPrevious: hasTrack,
      canNext: hasTrack && nextIndex(queue, auto: false) != null,
      canSeek: hasTrack && (_duration ?? Duration.zero) > Duration.zero,
      shuffle: _queue.shuffled,
      repeat: switch (_queue.repeat) {
        RepeatMode.off => MediaRepeat.none,
        RepeatMode.one => MediaRepeat.track,
        RepeatMode.all => MediaRepeat.playlist,
      },
      volume: _transport.volume / 100,
    );
  }

  Future<MediaControlsItem?> _currentItem() async {
    final entry = _now.entryId;
    final track = _now.trackId;
    if (entry == null || track == null) {
      _infoEntry = null;
      _baseItem = null;
      return null;
    }
    if (_infoEntry != entry || _baseItem == null) {
      _infoEntry = entry;
      _baseItem = null;
      TrackInfo? info;
      try {
        info = await infoOf(track);
      } on Object catch (e) {
        _log.warning('track facts for the media controls: $e');
      }
      // The entry changed while the lookup ran: the next flush redoes it.
      if (_now.entryId != entry) {
        _again = true;
        return _lastItem;
      }
      _baseItem = _buildItem(entry, info);
    }
    final base = _baseItem!;
    final length = _positionEntry == entry ? _duration : null;
    if (length == null || length == base.duration) return base;
    return MediaControlsItem(
      id: base.id,
      title: base.title,
      artists: base.artists,
      album: base.album,
      duration: length,
      artUri: base.artUri,
    );
  }

  MediaControlsItem _buildItem(int entry, TrackInfo? info) {
    if (info == null) return MediaControlsItem(id: '$entry', title: '');
    final key = info.coverKey;
    String? art;
    if (key != null) {
      try {
        art = artPathOf(key);
      } on Object catch (e) {
        _log.fine('cover for the media controls: $e');
      }
    }
    return MediaControlsItem(
      id: '$entry',
      title: info.title,
      artists: info.artists.isNotEmpty
          ? info.artists
          : [if (info.artist != null) info.artist!],
      album: info.album,
      duration: info.durationMs == null
          ? null
          : Duration(milliseconds: info.durationMs!),
      artUri: art == null ? null : Uri.file(art),
    );
  }

  Future<void> _onSeek(Duration position) async {
    _position = position;
    await flush();
    if (!_disposed) controls.seeked(position);
  }

  void _onCommand(MediaCommand command) {
    if (_disposed) return;
    // A request that came before the player was attached was held by the
    // platform's own command buffer and arrives after the attach.
    final controller = _controller;
    if (controller == null) return;
    final Future<Object?> run;
    switch (command) {
      case Play():
        run = controller.play();
      case Pause():
        run = controller.pause();
      case PlayPause():
        run = controller.playPause();
      case Stop():
        run = controller.stop();
      case Next():
        run = controller.next();
      case Previous():
        run = controller.previous();
      case Seek(:final offset):
        run = controller.seekRelative(offset);
      case SetPosition(:final id, :final position):
        // A late request for the entry that has gone is ignored.
        if (id != '${_now.entryId}') return;
        run = controller.seek(position);
      case SetShuffle(:final on):
        run = controller.setShuffle(on);
      case SetRepeat(:final repeat):
        run = controller.setRepeat(switch (repeat) {
          MediaRepeat.none => RepeatMode.off,
          MediaRepeat.track => RepeatMode.one,
          MediaRepeat.playlist => RepeatMode.all,
        });
      case SetVolume(:final volume):
        run = controller.setVolume((volume * 100).round());
    }
    run.then<void>(
      (_) {},
      onError: (Object e) => _log.warning('media command $command failed: $e'),
    );
  }

  // ---- PlaybackFocus ----

  @override
  Future<bool> activate() async {
    try {
      return await controls.activate().timeout(focusTimeout);
    } on Object catch (e) {
      _log.warning('audio focus: $e');
      return false;
    }
  }

  @override
  Future<void> deactivate() async {
    try {
      await controls.deactivate();
    } on Object catch (e) {
      _log.fine('audio focus release: $e');
    }
  }

  /// Stops following the player. The controls are owned by their provider.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _detach();
    unawaited(_commandSub.cancel());
  }
}
