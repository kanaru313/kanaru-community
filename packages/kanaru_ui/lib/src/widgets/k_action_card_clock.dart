import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import 'k_action_card_buttons.dart';
import 'k_action_card_countdown.dart';

/// The live button row of a `KActionCard`. It owns the countdown clock, so a
/// tick rebuilds only the buttons, never the card's text or body.
class KActionCardClockButtons extends StatefulWidget {
  const KActionCardClockButtons({
    super.key,
    required this.actions,
    required this.error,
    this.countdown,
  });

  final List<KActionCardAction> actions;
  final bool error;
  final KActionCardCountdown? countdown;

  @override
  State<KActionCardClockButtons> createState() =>
      _KActionCardClockButtonsState();
}

class _KActionCardClockButtonsState extends State<KActionCardClockButtons> {
  late final KCountdownTicker _ticker = KCountdownTicker(_onTick);

  /// The clock was running (time left) at the last look: the next time-up is
  /// announced once.
  bool _counting = false;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(KActionCardClockButtons old) {
    super.didUpdateWidget(old);
    if (old.countdown?.until != widget.countdown?.until) {
      _counting = false;
      _arm();
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _onTick() {
    if (!mounted) return;
    final clock = widget.countdown;
    final timeUp = clock != null && !clock.until.isAfter(clock.now());
    if (timeUp && _counting) {
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          clock.readyAnnouncement,
          Directionality.of(context),
        ),
      );
    }
    setState(() {});
    _arm();
  }

  void _arm() {
    final clock = widget.countdown;
    if (clock == null || !clock.until.isAfter(clock.now())) {
      _counting = false;
      _ticker.cancel();
      return;
    }
    _counting = true;
    _ticker.schedule(clock.until, clock.now());
  }

  @override
  Widget build(BuildContext context) => KActionCardButtons(
    actions: widget.actions,
    countdown: widget.countdown,
    error: widget.error,
  );
}
