import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/history/history_days.dart';

/// The wall clock the history screens read; tests override it.
final historyClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Midnight of the local day it is now. Ticks when the day changes, so day
/// labels, the current-year chip and the Most played window follow a screen
/// left open overnight.
final localDayProvider = NotifierProvider<LocalDayNotifier, DateTime>(
  LocalDayNotifier.new,
);

class LocalDayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    final clock = ref.read(historyClockProvider);
    _schedule(clock);
    return localDay(clock());
  }

  void _schedule(DateTime Function() clock) {
    final now = clock();
    final wait = addDays(localDay(now), 1).difference(now);
    // Never spin: a timer that fires a hair early finds the same day and
    // waits again.
    final delay = Duration(milliseconds: math.max(wait.inMilliseconds, 1000));
    _timer = Timer(delay, () {
      final day = localDay(clock());
      if (day != state) state = day;
      _schedule(clock);
    });
  }
}
