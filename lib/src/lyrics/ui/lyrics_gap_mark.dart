import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

/// One pulse cycle of the notes (3.5 slow steps).
final Duration _cycle = KMotion.slow * 3.5;

/// Delay between two notes, as a share of the cycle.
const double _noteDelay = 0.2 / 1.4;

/// The three music notes of an instrumental gap, in the colour of the
/// surrounding text at half strength. While [active] (the gap is the current
/// line) and animations are on they pulse one after another (opacity and a
/// slight scale); otherwise they are still.
/// The ticker exists only while pulsing.
class LyricsGapMark extends StatefulWidget {
  const LyricsGapMark({super.key, required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  State<LyricsGapMark> createState() => _LyricsGapMarkState();
}

class _LyricsGapMarkState extends State<LyricsGapMark>
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
  void didUpdateWidget(LyricsGapMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 0 at rest, 1 at the peak of a note's pulse (a triangle over the cycle).
  double _peak(int note) {
    final t = (_controller.value - note * _noteDelay) % 1.0;
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
            for (var note = 0; note < 3; note++)
              Opacity(
                opacity: 0.5 + 0.5 * (_pulsing ? _peak(note) : 0),
                child: Transform.scale(
                  scale: 1 + 0.25 * (_pulsing ? _peak(note) : 0),
                  child: Icon(
                    KIcons.songs,
                    size: KIconSize.sm,
                    color: widget.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
