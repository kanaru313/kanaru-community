import 'dart:async';

import 'package:flutter/foundation.dart';

import '../tokens/k_motion.dart';

/// How much time is left on a countdown, as the typed value the caller turns
/// into words (kanaru_ui has no strings of its own). Rounded up to whole
/// seconds, so the label never shows 0 while the action is still locked.
sealed class KCountdownLeft {
  const KCountdownLeft();

  /// Left to wait at [now] for [until]; null when the time is up.
  static KCountdownLeft? at(DateTime until, DateTime now) {
    final ms = until.difference(now).inMilliseconds;
    if (ms <= 0) return null;
    final total = (ms / 1000).ceil();
    if (total >= Duration.secondsPerHour) return KCountdownAt(until);
    if (total < Duration.secondsPerMinute) return KCountdownSeconds(total);
    return KCountdownMinutes(
      total ~/ Duration.secondsPerMinute,
      total % Duration.secondsPerMinute,
    );
  }
}

/// Under a minute: "Thử lại sau N giây".
@immutable
final class KCountdownSeconds extends KCountdownLeft {
  const KCountdownSeconds(this.seconds);
  final int seconds;

  @override
  bool operator ==(Object other) =>
      other is KCountdownSeconds && other.seconds == seconds;

  @override
  int get hashCode => Object.hash(KCountdownSeconds, seconds);

  @override
  String toString() => 'KCountdownSeconds($seconds)';
}

/// From a minute up to an hour: "Thử lại sau M phút S giây" ([seconds] may be
/// 0). The label changes every second.
@immutable
final class KCountdownMinutes extends KCountdownLeft {
  const KCountdownMinutes(this.minutes, this.seconds);
  final int minutes;
  final int seconds;

  @override
  bool operator ==(Object other) =>
      other is KCountdownMinutes &&
      other.minutes == minutes &&
      other.seconds == seconds;

  @override
  int get hashCode => Object.hash(KCountdownMinutes, minutes, seconds);

  @override
  String toString() => 'KCountdownMinutes($minutes, $seconds)';
}

/// An hour or more: the caller formats the clock time ("Thử lại lúc 21:05").
/// Not counted down second by second.
@immutable
final class KCountdownAt extends KCountdownLeft {
  const KCountdownAt(this.until);
  final DateTime until;

  @override
  bool operator ==(Object other) =>
      other is KCountdownAt && other.until == until;

  @override
  int get hashCode => Object.hash(KCountdownAt, until);

  @override
  String toString() => 'KCountdownAt($until)';
}

/// Lock on an action of a `KActionCard` until [until]. The card owns the
/// clock; the action stays disabled until the time is up and then shows its
/// own label (nothing is sent by itself).
@immutable
class KActionCardCountdown {
  const KActionCardCountdown({
    required this.until,
    required this.labelOf,
    required this.readyAnnouncement,
    this.now = DateTime.now,
  });

  final DateTime until;

  /// Text of the locked action for the time left.
  final String Function(KCountdownLeft left) labelOf;

  /// Said once to screen readers when the time is up ("Có thể thử lại");
  /// the locked label itself is not re-read every second.
  final String readyAnnouncement;

  /// The clock; tests pass a fake one.
  final DateTime Function() now;
}

/// One pending timer behind a countdown: ticks every [KMotion.countdownTick]
/// while under an hour is left; with an hour or more it sleeps until the hour
/// boundary (the label shows a clock time and does not change). Never more
/// than one timer is alive; [cancel] (also from the owner's `dispose`) leaves
/// none.
class KCountdownTicker {
  KCountdownTicker(this._onTick);

  final VoidCallback _onTick;
  Timer? _timer;

  static const Duration _hour = Duration(hours: 1);

  /// Arms the next tick for a countdown ending at [until]; nothing when the
  /// time is already up.
  void schedule(DateTime until, DateTime now) {
    cancel();
    final left = until.difference(now);
    if (left <= Duration.zero) return;
    final Duration delay;
    if (left > _hour) {
      delay = left - _hour;
    } else if (left < KMotion.countdownTick) {
      delay = left;
    } else {
      delay = KMotion.countdownTick;
    }
    _timer = Timer(delay, _onTick);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
