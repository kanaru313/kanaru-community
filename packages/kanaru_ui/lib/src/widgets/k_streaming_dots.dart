import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import '../tokens/k_space.dart';

/// Three dots rising in turn while an answer streams. Sits on its own line
/// under the text.
///
/// The wave is driven by one repeating controller owned by the state, so a
/// rebuild (every streamed chunk) never restarts it. With reduced motion
/// (`MediaQuery.disableAnimationsOf`) the dots stand still at 70 % opacity and
/// no ticker runs. Dots keep their size at any text scale. Screen readers get
/// a polite live-region status labelled [label] (the caller's words, e.g.
/// "Đang trả lời").
class KStreamingDots extends StatefulWidget {
  const KStreamingDots({super.key, required this.label});

  /// What a screen reader says (status role).
  final String label;

  /// Key of dot [i] (0..2), for tests.
  @visibleForTesting
  static ValueKey<String> dotKey(int i) => ValueKey('k-streaming-dot-$i');

  static const double _dot = 6;
  static const double _rise = 5;
  static const double _restOpacity = 0.45;
  static const double _stillOpacity = 0.7;

  /// Each dot starts this much later than the one before, as a share of the
  /// cycle (0.15 s of 1.2 s).
  static const double _stagger = 0.125;

  @override
  State<KStreamingDots> createState() => _KStreamingDotsState();
}

class _KStreamingDotsState extends State<KStreamingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: KMotion.streamingDots,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Rise 0..1 of dot [i] at cycle position [t]: up over the first quarter,
  /// back down over the second, then at rest.
  static double _lift(double t, int i) {
    final p = (t - i * KStreamingDots._stagger) % 1.0;
    if (p < 0.25) return Curves.easeInOut.transform(p / 0.25);
    if (p < 0.5) return Curves.easeInOut.transform((0.5 - p) / 0.25);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 16,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: KSpace.x1),
                  _dot(
                    color,
                    still ? 0 : _lift(_controller.value, i),
                    i,
                    still,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, double lift, int i, bool still) {
    final opacity = still
        ? KStreamingDots._stillOpacity
        : KStreamingDots._restOpacity +
              (1 - KStreamingDots._restOpacity) * lift;
    return Transform.translate(
      key: KStreamingDots.dotKey(i),
      offset: Offset(0, -KStreamingDots._rise * lift),
      child: Container(
        width: KStreamingDots._dot,
        height: KStreamingDots._dot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
