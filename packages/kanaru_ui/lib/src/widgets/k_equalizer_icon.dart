import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';

/// Animated equalizer bars while [playing]; a static pause glyph when paused.
/// With reduced motion the bars are drawn still.
class KEqualizerIcon extends StatefulWidget {
  const KEqualizerIcon({
    super.key,
    required this.playing,
    this.size = 20,
    this.color,
  });

  final bool playing;
  final double size;
  final Color? color;

  @override
  State<KEqualizerIcon> createState() => _KEqualizerIconState();
}

class _KEqualizerIconState extends State<KEqualizerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KEqualizerIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final animate = widget.playing && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    if (!widget.playing) {
      return Icon(KIcons.pause, size: widget.size, color: color);
    }
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _BarsPainter(_controller, color),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  static const _phases = [0.0, 0.33, 0.66];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final barWidth = size.width / 5;
    for (var i = 0; i < _phases.length; i++) {
      final t = math.sin((animation.value + _phases[i]) * 2 * math.pi);
      final h = size.height * (0.55 + 0.4 * t) * 0.9;
      final left = barWidth * (i * 2 + 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - h, barWidth, h),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.color != color;
}
