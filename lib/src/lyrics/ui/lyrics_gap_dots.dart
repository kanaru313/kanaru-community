import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

/// One pulse cycle of the dots.
const Duration _cycle = Duration(milliseconds: 1400);

/// Diameter of a dot.
const double _dotSize = 10;

/// Delay between two dots, as a share of the cycle (0.2 s of 1.4 s).
const double _dotDelay = 0.2 / 1.4;

/// The three dots of an instrumental gap, in the colour of the surrounding
/// text at half strength. While [active] (the gap is the current line) and
/// animations are on they pulse one after another; otherwise they are still.
/// The ticker exists only while pulsing.
class LyricsGapDots extends StatefulWidget {
  const LyricsGapDots({super.key, required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  State<LyricsGapDots> createState() => _LyricsGapDotsState();
}

class _LyricsGapDotsState extends State<LyricsGapDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  );

  bool get _pulsing =>
      widget.active && !MediaQuery.disableAnimationsOf(context);

  void _sync() {
    if (_pulsing) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LyricsGapDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0 at rest, 1 at the peak of a dot's pulse (a triangle over the cycle).
  double _peak(int dot) {
    final t = (_controller.value - dot * _dotDelay) % 1.0;
    return 1 - (2 * t - 1).abs();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KSpace.x2,
          children: [
            for (var dot = 0; dot < 3; dot++)
              Opacity(
                opacity: 0.5 + 0.5 * (_pulsing ? _peak(dot) : 0),
                child: Transform.scale(
                  scale: 1 + 0.25 * (_pulsing ? _peak(dot) : 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: _dotSize),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
