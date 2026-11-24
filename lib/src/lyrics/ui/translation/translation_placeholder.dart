import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Finds a placeholder bar (tests).
const Key translationPlaceholderKey = ValueKey('translation-placeholder');

/// Width of the bar, as a share of the line.
const double _barWidth = 0.55;

/// Height of the bar, as a share of the translation's font size.
const double _barHeight = 0.8;

/// One sweep of the shimmer: three of the slow steps.
final Duration _sweep = KMotion.slow * 3;

/// The bar that stands where a translation is still coming: one translation
/// line high, [style] sizes it, a light sweep runs over it. With animations
/// off the bar is still. Its own repaint boundary keeps the sweep from
/// repainting any text.
class TranslationPlaceholder extends StatefulWidget {
  const TranslationPlaceholder({
    super.key,
    required this.style,
    required this.centered,
  });

  /// The translation style the bar stands in for.
  final TextStyle style;
  final bool centered;

  @override
  State<TranslationPlaceholder> createState() => _TranslationPlaceholderState();
}

class _TranslationPlaceholderState extends State<TranslationPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController = AnimationController(
    vsync: this,
    duration: _sweep,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sweepController.stop();
      _sweepController.value = 0;
    } else if (!_sweepController.isAnimating) {
      _sweepController.repeat();
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.style.fontSize ?? 14;
    final line = size * (widget.style.height ?? 1.3);
    final base = scheme.surfaceContainerHigh;
    final light = scheme.surfaceContainerHighest;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          key: translationPlaceholderKey,
          height: line,
          child: Align(
            alignment: widget.centered
                ? Alignment.center
                : AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: _barWidth,
              child: SizedBox(
                height: size * _barHeight,
                child: AnimatedBuilder(
                  animation: _sweepController,
                  builder: (context, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: KRadius.xs,
                      gradient: LinearGradient(
                        colors: [base, light, base],
                        stops: const [0, 0.5, 1],
                        tileMode: TileMode.repeated,
                        transform: _Slide(_sweepController.value),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Moves a repeating gradient right by [t] of its width; at 1 it looks as it
/// did at 0, so the sweep loops without a jump.
class _Slide extends GradientTransform {
  const _Slide(this.t);

  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * t, 0, 0);
}
