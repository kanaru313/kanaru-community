import 'package:material_ui/material_ui.dart';

import '../../tokens/k_motion.dart';

/// Lets the [SetupSection]s below it pulse their card once when
/// [SetupSectionPulseState.pulse] is called (use a
/// `GlobalKey<SetupSectionPulseState>`), to show which block a deep link led
/// to. Only the card gets the primary border, never the heading. With reduced
/// motion [SetupSectionPulseState.pulse] does nothing (the page only scrolls).
class SetupSectionPulse extends StatefulWidget {
  const SetupSectionPulse({super.key, required this.child});

  final Widget child;

  /// The pulse of the nearest [SetupSectionPulse] above [context], or null.
  /// Used by [SetupSection]; listening rebuilds only the card's border.
  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PulseScope>()
      ?.animation;

  @override
  State<SetupSectionPulse> createState() => SetupSectionPulseState();
}

class SetupSectionPulseState extends State<SetupSectionPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: KMotion.focusPulse,
  );

  /// Whether a pulse is playing.
  bool get isPulsing => _controller.isAnimating;

  /// Plays one pulse from the start. A pulse already playing restarts.
  void pulse() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _PulseScope(animation: _controller, child: widget.child);
}

class _PulseScope extends InheritedWidget {
  const _PulseScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_PulseScope old) => animation != old.animation;
}

/// Draws the pulse border over [child] (the card) while [animation] runs:
/// held for the first 60 % of the pulse, then faded out.
class SetupCardPulse extends StatelessWidget {
  const SetupCardPulse({
    super.key,
    required this.animation,
    required this.radius,
    required this.child,
  });

  final Animation<double> animation;
  final BorderRadius radius;
  final Widget child;

  /// Share of the pulse during which the border stays fully visible.
  static const double _hold = 0.6;

  /// Opacity of the border at [t] of the pulse (0..1).
  static double opacityAt(double t) =>
      t <= _hold ? 1 : 1 - Curves.easeOut.transform((t - _hold) / (1 - _hold));

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: animation.isAnimating
              ? Border.all(
                  color: color.withValues(alpha: opacityAt(animation.value)),
                  width: 2,
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}
