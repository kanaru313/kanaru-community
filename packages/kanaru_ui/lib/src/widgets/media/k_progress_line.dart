import 'package:material_ui/material_ui.dart';

/// Flat 2 dp progress line for the mini player's bottom edge. [value] is
/// 0..1 (clamped); it has no animation of its own because the position
/// stream already ticks.
class KProgressLine extends StatelessWidget {
  const KProgressLine({super.key, required this.value});

  static const double height = 2;

  final double value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: scheme.primary.withValues(alpha: 0.24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: ColoredBox(color: scheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}
