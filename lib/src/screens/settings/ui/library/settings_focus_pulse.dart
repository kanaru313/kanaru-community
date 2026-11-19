import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Draws a primary border over [child] once when asked, to show which block a
/// deep link led to: held for the first 60 % of [KMotion.focusPulse], then
/// faded out. With reduced motion [SettingsFocusPulseState.pulse] does
/// nothing (the page only scrolls).
///
/// Private to Settings: the only user is the Library page, and only one
/// producer links to it. Use it through a `GlobalKey<SettingsFocusPulseState>`.
class SettingsFocusPulse extends StatefulWidget {
  const SettingsFocusPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SettingsFocusPulse> createState() => SettingsFocusPulseState();
}

class SettingsFocusPulseState extends State<SettingsFocusPulse>
    with SingleTickerProviderStateMixin {
  /// Share of the pulse during which the border stays fully visible.
  static const double _hold = 0.6;

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

  /// Opacity of the border at [t] of the pulse (0..1).
  static double opacityAt(double t) =>
      t <= _hold ? 1 : 1 - Curves.easeOut.transform((t - _hold) / (1 - _hold));

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final running = _controller.isAnimating;
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: KRadius.lg,
            border: running
                ? Border.all(
                    color: color.withValues(
                      alpha: opacityAt(_controller.value),
                    ),
                    width: 2,
                  )
                : null,
          ),
          child: child,
        );
      },
    );
  }
}
