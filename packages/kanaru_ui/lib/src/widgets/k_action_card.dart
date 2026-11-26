import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/k_icon_size.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_action_card_buttons.dart';
import 'k_action_card_countdown.dart';

export 'k_action_card_buttons.dart' show KActionCardAction;
export 'k_action_card_countdown.dart';

/// Look of a [KActionCard].
enum KActionCardTone {
  /// A question or a result: `surfaceContainerHigh`.
  normal,

  /// Something failed: `errorContainer`; announced to screen readers unless
  /// the card is read-only.
  error,

  /// Over and done with (refused, expired, not run): dimmed, grey icon, never
  /// any button.
  finished,
}

/// Colour of the round icon of a [KActionCardTone.normal] card.
enum KActionCardEmphasis {
  /// Plain: `secondaryContainer`.
  normal,

  /// A change was made ("Đã làm"): `primary`.
  done,

  /// Outcome unknown or a limit changed: `tertiaryContainer`.
  caution,
}

/// Frame of a card in the AI chat: confirm, done, error, unknown, limit.
///
/// Round icon, bold [title], [subtitle] and optional [reason] (both wrap, never
/// cut), an optional [body] slot, then up to two [actions] on their own row:
/// one button sits at the end of the row, two share it evenly. Buttons are 40
/// high on the mobile shell and compact on the desktop one.
///
/// [readOnly] is a card of an older turn: no buttons, no clock, no alert
/// role. [tone] finished also shows no buttons.
///
/// [countdown] locks the first action until a time: the card owns the clock,
/// and the caller words it through [KActionCardCountdown.labelOf] with a
/// typed [KCountdownLeft]. At zero the action turns on with its own label;
/// nothing is sent by itself.
class KActionCard extends StatefulWidget {
  const KActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.reason,
    this.body,
    this.tone = KActionCardTone.normal,
    this.emphasis = KActionCardEmphasis.normal,
    this.actions = const [],
    this.countdown,
    this.readOnly = false,
  }) : assert(actions.length <= 2, 'a card has at most two actions');

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Why it happened, in `onSurface`, under [subtitle].
  final String? reason;

  /// Content between the text and the buttons (a list of songs, a fold).
  final Widget? body;
  final KActionCardTone tone;
  final KActionCardEmphasis emphasis;
  final List<KActionCardAction> actions;
  final KActionCardCountdown? countdown;
  final bool readOnly;

  @override
  State<KActionCard> createState() => _KActionCardState();
}

class _KActionCardState extends State<KActionCard> {
  late final KCountdownTicker _ticker = KCountdownTicker(_onTick);

  /// The clock was running (time left) at the last look: the next time-up is
  /// announced once.
  bool _counting = false;

  KActionCardCountdown? get _clock =>
      widget.readOnly || widget.actions.isEmpty ? null : widget.countdown;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(KActionCard old) {
    super.didUpdateWidget(old);
    if (old.countdown?.until != widget.countdown?.until ||
        old.readOnly != widget.readOnly ||
        old.actions.isEmpty != widget.actions.isEmpty) {
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
    final clock = _clock;
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
    final clock = _clock;
    if (clock == null || !clock.until.isAfter(clock.now())) {
      _counting = false;
      _ticker.cancel();
      return;
    }
    _counting = true;
    _ticker.schedule(clock.until, clock.now());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final texts = Theme.of(context).textTheme;
    final error = widget.tone == KActionCardTone.error;
    final finished = widget.tone == KActionCardTone.finished;
    final foreground = error ? scheme.onErrorContainer : scheme.onSurface;
    final muted = error
        ? scheme.onErrorContainer.withValues(alpha: 0.85)
        : scheme.onSurfaceVariant;
    final (iconBg, iconFg) = _iconColors(scheme);
    final live = !widget.readOnly && !finished && widget.actions.isNotEmpty;

    final card = DecoratedBox(
      decoration: ShapeDecoration(
        color: error ? scheme.errorContainer : scheme.surfaceContainerHigh,
        shape: KShape.of(KRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(KSpace.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: KIconSize.lg,
                    child: Icon(widget.icon, size: KIconSize.sm, color: iconFg),
                  ),
                ),
                const SizedBox(width: KSpace.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: texts.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: KSpace.x1 / 2),
                          child: Text(
                            widget.subtitle!,
                            style: texts.bodySmall?.copyWith(color: muted),
                          ),
                        ),
                      if (widget.reason != null)
                        Padding(
                          padding: const EdgeInsets.only(top: KSpace.x1),
                          child: Text(
                            widget.reason!,
                            style: texts.bodySmall?.copyWith(color: foreground),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            ?widget.body,
            if (live)
              KActionCardButtons(
                actions: widget.actions,
                countdown: _clock,
                error: error,
              ),
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      liveRegion: error && !widget.readOnly,
      child: finished ? Opacity(opacity: _finishedOpacity, child: card) : card,
    );
  }

  static const double _finishedOpacity = 0.62;

  (Color, Color) _iconColors(ColorScheme scheme) {
    if (widget.tone == KActionCardTone.error) {
      return (scheme.error, scheme.onError);
    }
    if (widget.tone == KActionCardTone.finished) {
      return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    }
    return switch (widget.emphasis) {
      KActionCardEmphasis.normal => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      KActionCardEmphasis.done => (scheme.primary, scheme.onPrimary),
      KActionCardEmphasis.caution => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
    };
  }
}
