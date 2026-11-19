import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../domain/cleared_queue.dart';
import '../domain/play_intent.dart';
import '../domain/sleep_policies.dart';
import '../domain/sleep_stop_policy.dart';
import '../domain/sleep_timer_state.dart';
import 'playback_data_providers.dart' show mediaSessionBridgeProvider;
import 'playback_providers.dart' show playerControllerProvider;
import 'player_controller.dart';
import 'player_ready.dart';
import 'queue_row_infos.dart';
import 'sleep_ticker_provider.dart';
import 'sleep_timer_album.dart';

export '../domain/sleep_timer_state.dart';

final _log = Logger('SleepTimer');

/// How often the minutes mode looks at the clock.
const sleepTimerTick = Duration(milliseconds: 250);

/// How long the minutes mode fades the volume out before it pauses.
const sleepFadeLength = Duration(seconds: 10);

final sleepTimerProvider = NotifierProvider<SleepTimer, SleepTimerState>(
  SleepTimer.new,
);

/// Pauses playback later: after some minutes, after some tracks, or at the
/// end of the track, the album or the queue. Session only: nothing is saved.
///
/// The minutes mode counts wall-clock time against a deadline on the
/// player's clock, also while playback is paused and across a sleeping
/// device: a tick (or the app resuming) that finds the deadline gone acts at
/// once. Over the last [sleepFadeLength], while playing, the volume fades to
/// silence; at zero the player pauses and gets the user's volume back.
/// Expiring while paused only turns the timer off. The other modes install a
/// [SleepStopPolicy] in the player, which decides at the moment it picks the
/// next entry, and turn off when the player reports the stop.
///
/// It does nothing until the player phase is attached ([playerCreatedProvider]
/// turns true only when the shell attaches it; reading the controller does
/// not): a `start*` before that is ignored and logged.
class SleepTimer extends Notifier<SleepTimerState> {
  PlayerController? _controller;
  StreamSubscription<TrackEnd>? _endsSub;
  AppLifecycleListener? _lifecycle;
  Timer? _ticker;
  SleepStopPolicy? _policy;
  SleepAlbumKeys? _albums;
  ProviderSubscription<AsyncValue<void>>? _tracksSub;
  StreamSubscription<ClearedQueue>? _clearedSub;

  /// Minutes mode: the deadline on the controller's clock, and the time left
  /// while the count is on hold.
  int _deadlineMs = 0;
  int _heldMs = 0;

  /// A fade ran (or was due and skipped) since the countdown was last armed.
  /// A fade that then ended early was interrupted by the user and is not
  /// started again: the timer pauses at zero without one.
  bool _fadeStarted = false;

  @override
  SleepTimerState build() {
    _controller = null;
    _policy = null;
    _albums = null;
    _fadeStarted = false;
    if (!ref.watch(playerCreatedProvider)) return const SleepTimerState.off();
    final controller = ref.watch(playerControllerProvider);
    _controller = controller;
    _endsSub = controller.trackEnds.listen(
      _onTrackEnd,
      onError: (Object e) => _log.warning('track ends: ${e.runtimeType}'),
    );
    _clearedSub = controller.queueCleared.listen(
      (_) => _onQueueCleared(),
      onError: (Object e) => _log.warning('queue cleared: ${e.runtimeType}'),
    );
    _lifecycle = AppLifecycleListener(onResume: _tick);
    ref.onDispose(_onDispose);
    return const SleepTimerState.off();
  }

  void _onDispose() {
    final controller = _controller;
    _controller = null;
    _stopTicker();
    _lifecycle?.dispose();
    _lifecycle = null;
    unawaited(_endsSub?.cancel());
    _endsSub = null;
    unawaited(_clearedSub?.cancel());
    _clearedSub = null;
    _dropAlbums();
    // Queued behind any command of a rebuilt timer's predecessor and ahead of
    // its own, so they cannot undo a new install.
    if (controller != null) {
      if (_policy != null) _send(controller.setSleepStopPolicy(null));
      if (_fadeStarted) _send(controller.endSleepFade());
    }
    _policy = null;
    _fadeStarted = false;
  }

  // ---- commands ----

  bool _ready() {
    if (_controller != null) return true;
    _log.fine('start ignored: the player is not attached yet');
    return false;
  }

  /// Pauses after [minutes], kept within 1 to 720.
  void startMinutes(int minutes) {
    if (!_ready()) return;
    _dropRuntime();
    _setPolicy(null);
    final length = Duration(
      minutes: minutes.clamp(sleepTimerMinMinutes, sleepTimerMaxMinutes),
    );
    _arm(length.inMilliseconds);
  }

  /// Pauses after [count] tracks (1 to 20, the current one included) played
  /// to their end. Skipping does not use a track up.
  void startTracks(int count) {
    if (!_ready()) return;
    final policy = TracksPolicy(count);
    _startPolicyMode(policy);
    state = SleepTimerState(
      mode: SleepTimerMode.tracks,
      tracksLeft: policy.left,
    );
  }

  void startEndOfTrack() {
    if (!_ready()) return;
    _startPolicyMode(EndOfTrackPolicy());
    state = const SleepTimerState(mode: SleepTimerMode.endOfTrack);
  }

  void startEndOfQueue() {
    if (!_ready()) return;
    _startPolicyMode(EndOfQueuePolicy());
    state = const SleepTimerState(mode: SleepTimerMode.endOfQueue);
  }

  void startEndOfAlbum() {
    if (!_ready()) return;
    _dropRuntime();
    final keys = SleepAlbumKeys(
      loaded: () => ref.mounted ? ref.read(queueRowInfosProvider) : const {},
      load: (ids) => ref.read(queueRowInfoLoaderProvider)(ids),
      onAnswer: () => _policyChanged(SleepTimerMode.endOfAlbum),
    );
    _albums = keys;
    _tracksSub = ref.listen<AsyncValue<void>>(queueTracksChangedProvider, (
      _,
      next,
    ) {
      if (next is! AsyncData<void>) return;
      keys.reset();
      _policyChanged(SleepTimerMode.endOfAlbum);
    });
    _setPolicy(EndOfAlbumPolicy(albumOf: keys.lookup, want: keys.want));
    state = const SleepTimerState(mode: SleepTimerMode.endOfAlbum);
  }

  /// Adds [delta] minutes (or takes them off when negative) in the minutes
  /// mode, up to 720 minutes left. Taking off is refused unless more than
  /// that is left.
  void addMinutes(int delta) {
    final c = _controller;
    if (c == null || state.mode != SleepTimerMode.minutes || delta == 0) return;
    if (delta < 0 && !state.canSubtract(-delta)) return;
    const most = sleepTimerMaxMinutes * Duration.millisecondsPerMinute;
    final held = state.countingPaused;
    final left = held ? _heldMs : _deadlineMs - c.nowMs;
    final next = (left + delta * Duration.millisecondsPerMinute).clamp(1, most);
    if (held) {
      _heldMs = next;
      _publishHeld();
      return;
    }
    _deadlineMs = c.nowMs + next;
    _tick();
  }

  /// Adds [delta] tracks (or takes them off when negative) in the tracks
  /// mode, within 1 to 20 left. Taking off below one is refused.
  void addTracks(int delta) {
    final c = _controller;
    final policy = _policy;
    if (c == null || policy is! TracksPolicy || delta == 0) return;
    if (delta < 0 && policy.left + delta < sleepTimerMinTracks) return;
    final next = (policy.left + delta).clamp(
      sleepTimerMinTracks,
      sleepTimerMaxTracks,
    );
    if (next == policy.left) return;
    policy.left = next;
    state = SleepTimerState(mode: SleepTimerMode.tracks, tracksLeft: next);
    _send(c.sleepPolicyChanged());
  }

  /// Holds the minutes countdown at the time left; a fade under way ends.
  void pauseCounting() {
    final c = _controller;
    if (c == null || state.mode != SleepTimerMode.minutes) return;
    if (state.countingPaused) return;
    _heldMs = (_deadlineMs - c.nowMs).clamp(0, 1 << 40);
    _stopTicker();
    if (_fadeStarted) _send(c.endSleepFade());
    _fadeStarted = false;
    _publishHeld();
  }

  void resumeCounting() {
    if (_controller == null) return;
    if (state.mode != SleepTimerMode.minutes || !state.countingPaused) return;
    _arm(_heldMs);
  }

  /// Turns the timer off; playback goes on as if it never ran.
  void cancel() {
    if (_controller == null) return;
    _dropRuntime();
    _setPolicy(null);
    state = const SleepTimerState.off();
  }

  // ---- minutes ----

  /// Starts counting [leftMs] from now.
  void _arm(int leftMs) {
    final c = _controller!;
    _stopTicker();
    _fadeStarted = false;
    _deadlineMs = c.nowMs + leftMs;
    _publish(leftMs);
    _ticker = ref.read(sleepTickerProvider)(sleepTimerTick, _tick);
    _tick();
  }

  /// Publishes the time left and fades, pauses or ends when it is due.
  void _tick() {
    final c = _controller;
    if (c == null || state.mode != SleepTimerMode.minutes) return;
    if (_ticker == null) return; // on hold
    final now = c.nowMs;
    final leftMs = _deadlineMs - now;
    final playing = c.intent == PlayIntent.playing;
    if (leftMs > 0) {
      _publish(leftMs);
      if (leftMs > sleepFadeLength.inMilliseconds) {
        // Time was added during the fade: undo it and arm it again.
        if (_fadeStarted) _send(c.endSleepFade());
        _fadeStarted = false;
      } else if (!_fadeStarted && playing) {
        _fadeStarted = true;
        _send(c.fadeOutForSleep(Duration(milliseconds: leftMs)));
      }
      return;
    }
    if (!playing) {
      _finishMinutes(pause: false);
    } else if (_fadeStarted) {
      _finishMinutes(pause: true);
    } else {
      // The device slept past the deadline (or the window was skipped): fade
      // for a last moment instead of cutting the sound.
      _fadeStarted = true;
      _deadlineMs = now + sleepFadeLength.inMilliseconds;
      _send(c.fadeOutForSleep(sleepFadeLength));
      _publish(sleepFadeLength.inMilliseconds);
    }
  }

  void _finishMinutes({required bool pause}) {
    final c = _controller!;
    _stopTicker();
    _fadeStarted = false;
    state = const SleepTimerState.off();
    _send(pause ? c.sleepPause() : c.endSleepFade());
    _cancelPendingResume();
  }

  void _publish(int leftMs) {
    final next = SleepTimerState(
      mode: SleepTimerMode.minutes,
      remaining: Duration(seconds: (leftMs + 999) ~/ 1000),
      endsAt: DateTime.fromMillisecondsSinceEpoch(_deadlineMs),
    );
    if (next != state) state = next;
  }

  void _publishHeld() {
    state = SleepTimerState(
      mode: SleepTimerMode.minutes,
      remaining: Duration(seconds: (_heldMs + 999) ~/ 1000),
      countingPaused: true,
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  // ---- track modes ----

  void _startPolicyMode(SleepStopPolicy policy) {
    _dropRuntime();
    _setPolicy(policy);
  }

  /// Installs [policy] in the player, or removes the installed one. Removal
  /// is always sent (it is idempotent), so the player never keeps a policy
  /// the timer has forgotten.
  void _setPolicy(SleepStopPolicy? policy) {
    final c = _controller;
    if (c == null) return;
    _policy = policy;
    _send(c.setSleepStopPolicy(policy));
  }

  void _policyChanged(SleepTimerMode mode) {
    final c = _controller;
    if (c == null || !ref.mounted || state.mode != mode) return;
    _send(c.sleepPolicyChanged());
  }

  /// The player dropped its policy with the queue: a track mode has nothing
  /// left to wait for. The minutes mode keeps counting.
  void _onQueueCleared() {
    final mode = state.mode;
    if (_controller == null || mode == null || mode == SleepTimerMode.minutes) {
      return;
    }
    _dropRuntime();
    _policy = null;
    state = const SleepTimerState.off();
  }

  void _onTrackEnd(TrackEnd end) {
    final mode = state.mode;
    if (_controller == null || mode == null) return;
    if (mode == SleepTimerMode.minutes) return;
    // The late stop of a policy that was replaced since: not ours.
    if (end.sleepStop &&
        end.policy != null &&
        !identical(end.policy, _policy)) {
      return;
    }
    if (end.sleepStop || end.queueEnded) {
      _dropRuntime();
      // A stop consumed the policy in the player already.
      if (!end.sleepStop) _setPolicy(null);
      _policy = null;
      state = const SleepTimerState.off();
      if (end.sleepStop) _cancelPendingResume();
      return;
    }
    final policy = _policy;
    if (mode == SleepTimerMode.tracks && policy is TracksPolicy) {
      state = SleepTimerState(
        mode: SleepTimerMode.tracks,
        tracksLeft: policy.left,
      );
    }
  }

  // ---- shared ----

  /// Stops everything the running mode keeps going, except the policy slot.
  void _dropRuntime() {
    _stopTicker();
    final c = _controller;
    if (_fadeStarted && c != null) _send(c.endSleepFade());
    _fadeStarted = false;
    _dropAlbums();
  }

  void _dropAlbums() {
    _tracksSub?.close();
    _tracksSub = null;
    _albums?.dispose();
    _albums = null;
  }

  /// A sleep ended: an Android interruption that paused playback must not
  /// resume it.
  void _cancelPendingResume() {
    try {
      ref.read(mediaSessionBridgeProvider).cancelPendingResume();
    } on Object catch (e, st) {
      _log.warning('cancel pending resume: ${e.runtimeType}', null, st);
    }
  }

  /// Fire and forget: a failure is logged, never left unhandled.
  void _send(Future<void> call) {
    call.then<void>(
      (_) {},
      onError: (Object e, StackTrace st) =>
          _log.warning('player command failed: ${e.runtimeType}', null, st),
    );
  }
}
