import 'dart:math' as math;
import 'dart:typed_data';

import 'seek_look.dart';

/// A row of springs coupled to their neighbours (a wave equation): a press
/// dents the bars under the finger, a poke starts a wobble that rolls along.
///
/// Pure Dart. Time advances in fixed steps of [step]; one [advance] call
/// covers at most [maxFrameTime] (so [maxSubsteps] steps) and a slower frame
/// drops the rest, so it cannot snowball. A bar's factor is `1 + offset`, kept within
/// [[minFactor], [maxFactor]].
class JellySprings {
  JellySprings(this.count)
    : _offset = Float64List(count),
      _velocity = Float64List(count);

  static const double stiffness = 350;
  static const double spread = 300;
  static final double damping = 2 * 0.4 * math.sqrt(stiffness);
  static const double step = 1 / 240;
  static const double maxFrameTime = 0.05;
  static const int maxSubsteps = 12;
  static const double pressStrength = 0.5;
  static const double pressWidth = 1.8;
  static const double pokeStrength = 2;
  static const double pokeWidth = 1.6;
  static const double pokeImpulse = 12;
  static const double minFactor = 0.35;
  static const double maxFactor = 2.2;

  /// A spring is at rest below these.
  static const double _restOffset = 0.002;
  static const double _restVelocity = 0.05;

  /// Below this speed a dent held by a finger no longer visibly moves.
  static const double _quietVelocity = 0.01;

  final int count;
  final Float64List _offset;
  final Float64List _velocity;
  double _pending = 0;
  bool _rest = true;
  bool _quiet = false;

  /// Nothing moves: every bar is at its normal height.
  bool get atRest => _rest;

  /// No spring moves visibly (a dent held by a finger has settled).
  bool get quiet => _quiet;

  /// Height factor of bar [i].
  double factorAt(int i) =>
      (1 + _offset[i]).clamp(minFactor, maxFactor).toDouble();

  /// Kicks the bars around the (fractional) bar index [index].
  void poke(double index, double strength) {
    if (count == 0 || !index.isFinite) return;
    for (var b = 0; b < count; b++) {
      final d = (b - index) / pokeWidth;
      _velocity[b] += pokeStrength * strength * math.exp(-d * d) * pokeImpulse;
    }
    _rest = false;
    _quiet = false;
  }

  /// Moves [dt] seconds on. [pressIndex] is the bar under a finger that is
  /// down (null: none); while it is set the springs never count as at rest.
  void advance(double dt, {double? pressIndex}) {
    if (count == 0) return;
    final press = pressIndex != null && pressIndex.isFinite ? pressIndex : null;
    if (_rest && press == null) return;
    _pending += dt.isFinite && dt > 0 ? math.min(dt, maxFrameTime) : 0;
    final steps = math.min(maxSubsteps, (_pending / step + 1e-9).floor());
    _pending = math.min(_pending - steps * step, step);
    for (var t = 0; t < steps; t++) {
      _step(press);
    }
    _rest = press == null && _settled();
    _quiet = _rest || _settledBelow(_quietVelocity);
    if (_rest) {
      _offset.fillRange(0, count, 0);
      _velocity.fillRange(0, count, 0);
      _pending = 0;
    }
  }

  void _step(double? press) {
    for (var b = 0; b < count; b++) {
      final left = b > 0 ? _offset[b - 1] : _offset[b];
      final right = b < count - 1 ? _offset[b + 1] : _offset[b];
      var force =
          -stiffness * _offset[b] +
          spread * (left + right - 2 * _offset[b]) -
          damping * _velocity[b];
      if (press != null) {
        final d = (b - press) / pressWidth;
        force += -pressStrength * stiffness * math.exp(-d * d);
      }
      _velocity[b] += force * step;
    }
    for (var b = 0; b < count; b++) {
      _offset[b] += _velocity[b] * step;
    }
  }

  bool _settled() => _settledBelow(_restVelocity, offset: _restOffset);

  bool _settledBelow(double velocity, {double offset = double.infinity}) {
    for (var b = 0; b < count; b++) {
      if (_offset[b].abs() > offset || _velocity[b].abs() > velocity) {
        return false;
      }
    }
    return true;
  }
}

/// How much the bars near the finger grow: 0 with the finger up, 1 with it
/// down, easing between them in about 120 ms.
class LensEnvelope {
  static const double peak = 0.7;
  static const double widthInBars = 3.5;

  /// Easing rate per second (about 120 ms to settle).
  static const double rate = 12;

  double _level = 0;

  double get level => _level;

  /// The finger is up and the level has faded out.
  bool get atRest => _level == 0;

  void advance(double dt, {required bool down}) {
    final target = down ? 1.0 : 0.0;
    _level += (target - _level) * math.min(1, math.max(0, dt) * rate);
    if (!down && _level < 0.001) _level = 0;
    if (down && _level > 0.999) _level = 1;
  }

  void reset() => _level = 0;

  /// Height factor of a bar [distance] bars away from the finger.
  double factorAt(double distance) {
    final d = distance / widthInBars;
    return 1 + peak * _level * math.exp(-d * d);
  }
}

/// The touch feedback of one bar: [KSeekFeedback.jelly] or
/// [KSeekFeedback.lens] over [count] bars, producing one height factor per bar.
///
/// The owner calls [press] with the bar under the finger (null: finger up or
/// cancelling) and [poke] after a seek, and [advance] on each frame while
/// [active]; when it is not active nothing needs a frame and the bars are at
/// their normal height.
class SeekFeedback {
  KSeekFeedback _kind = KSeekFeedback.off;
  int _count = 0;
  JellySprings? _jelly;
  final LensEnvelope _lens = LensEnvelope();
  double? _press;

  /// The press index the last [advance] drew; while a finger rests on it and
  /// nothing moves, no more frames are needed ([_held]).
  double? _advancedPress;
  bool _held = false;

  /// Where the lens was last centred, so it can fade out after the finger
  /// has gone.
  double _lensAt = 0;

  /// One factor per bar; valid while [active].
  Float32List factors = Float32List(0);

  /// Counts [advance] calls, so a painter knows [factors] changed in place.
  int revision = 0;

  /// Sets the kind and the number of bars; a change starts from rest.
  void configure({required KSeekFeedback kind, required int count}) {
    if (kind == _kind && count == _count) return;
    _kind = kind;
    _count = count;
    _press = null;
    _advancedPress = null;
    _held = false;
    _jelly = kind == KSeekFeedback.jelly ? JellySprings(count) : null;
    _lens.reset();
    final n = kind == KSeekFeedback.off ? 0 : count;
    factors = Float32List(n)..fillRange(0, n, 1);
  }

  /// The bar index under the finger, null when it is up.
  void press(double? index) {
    final next = index != null && index.isFinite ? index : null;
    if (next != _press) _held = false;
    _press = next;
    final at = _press;
    if (at != null) _lensAt = at;
  }

  /// A seek landed near bar [index]; [strength] 1 for a pointer, less for a key.
  void poke(double index, double strength) {
    final jelly = _jelly;
    if (jelly == null) return;
    _held = false;
    jelly.poke(index, strength);
  }

  /// The bars differ from their normal height: draw [factors].
  bool get showing => switch (_kind) {
    KSeekFeedback.off => false,
    KSeekFeedback.jelly => _press != null || !_jelly!.atRest,
    KSeekFeedback.lens => _press != null || !_lens.atRest,
  };

  /// Whether frames are needed: [showing] and still changing (a finger that
  /// rests on the same bar after the dent settled needs none).
  bool get active => showing && !_held;

  void advance(double dt) {
    switch (_kind) {
      case KSeekFeedback.off:
        return;
      case KSeekFeedback.jelly:
        final jelly = _jelly!;
        jelly.advance(dt, pressIndex: _press);
        for (var b = 0; b < _count; b++) {
          factors[b] = jelly.factorAt(b);
        }
      case KSeekFeedback.lens:
        _lens.advance(dt, down: _press != null);
        for (var b = 0; b < _count; b++) {
          factors[b] = _lens.factorAt(b - _lensAt);
        }
    }
    final settled =
        _press != null &&
        _press == _advancedPress &&
        switch (_kind) {
          KSeekFeedback.jelly => _jelly!.quiet,
          KSeekFeedback.lens => _lens.level == 1,
          KSeekFeedback.off => false,
        };
    _advancedPress = _press;
    if (settled) {
      _held = true;
      return;
    }
    revision++;
  }
}
