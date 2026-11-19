import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Makes a periodic timer. The player's sleep fade and the sleep timer both
/// get their ticks from here, so a test replaces one provider to drive both.
final sleepTickerProvider = Provider<Timer Function(Duration, void Function())>(
  (_) =>
      (interval, onTick) => Timer.periodic(interval, (_) => onTick()),
);
