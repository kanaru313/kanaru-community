import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Length of the pretend track the seek bar preview plays.
const Duration seekPreviewDuration = Duration(seconds: 225);

/// Where the pretend track starts, as a fraction of its length.
const double seekPreviewStart = 0.32;

/// The longest step one frame may advance the position. A frame that comes
/// late (the ticker was muted behind another route) moves it by this much,
/// not by everything it missed.
const Duration _maxStep = Duration(milliseconds: 50);

/// A fake playback clock for the seek bar preview: a position that runs along
/// [seekPreviewDuration] and loops at the end. No audio and no player: it never
/// touches the real playback state.
///
/// It runs a single [Ticker] only while the clock is [playing]. Under reduced
/// motion the clock starts paused (the button shows Play, never a frozen
/// "playing"); pressing Play runs it, because the position is playback, not
/// decoration (the bars switch their own effects off). The ticker comes from
/// the page's [TickerProvider], so it is muted (no frames scheduled) while that page is
/// covered by an opaque route (`TickerMode`).
///
/// [notifyListeners] fires on every position change. [playingListenable] only
/// changes with the play / pause switch, for widgets that must not rebuild
/// per frame.
class SeekPreviewClock extends ChangeNotifier {
  SeekPreviewClock({required TickerProvider vsync}) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;
  final ValueNotifier<bool> _playing = ValueNotifier(false);
  double _fraction = seekPreviewStart;
  bool _motionAllowed = true;
  bool _motionKnown = false;
  bool _disposed = false;
  bool _holding = false;
  Duration? _last;

  /// True while the preview plays (the page opens playing).
  bool get playing => _playing.value;

  ValueListenable<bool> get playingListenable => _playing;

  /// False when the platform asks for reduced motion. The page sets it once
  /// its dependencies are known: the first value decides whether the clock
  /// starts playing; a later switch to false pauses it.
  bool get motionAllowed => _motionAllowed;

  Duration get duration => seekPreviewDuration;

  Duration get position => seekPreviewDuration * _fraction;

  /// Whether the ticker is running (a muted ticker still counts).
  @visibleForTesting
  bool get tickerActive => _ticker.isActive;

  set motionAllowed(bool value) {
    if (_disposed) return;
    final changed = value != _motionAllowed;
    _motionAllowed = value;
    if (!_motionKnown) {
      _motionKnown = true;
      _playing.value = value;
    } else if (changed && !value) {
      _playing.value = false;
    }
    _sync();
  }

  void togglePlaying() {
    if (_disposed) return;
    _playing.value = !_playing.value;
    _sync();
    notifyListeners();
  }

  /// A finger holds or drags the bar: the position stops until it is
  /// released.
  void hold(bool value) {
    if (_disposed) return;
    _holding = value;
  }

  void seekTo(Duration to) {
    if (_disposed) return;
    final total = seekPreviewDuration.inMicroseconds;
    _fraction = (to.inMicroseconds / total).clamp(0.0, 1.0);
    notifyListeners();
  }

  void _sync() {
    final run = _playing.value;
    if (run && !_ticker.isActive) {
      _last = null;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (_disposed) return;
    final last = _last;
    _last = elapsed;
    if (last == null || _holding) return;
    var step = elapsed - last;
    if (step > _maxStep) step = _maxStep;
    if (step.isNegative) return;
    _fraction += step.inMicroseconds / seekPreviewDuration.inMicroseconds;
    if (_fraction >= 1) _fraction = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    _playing.dispose();
    super.dispose();
  }
}
