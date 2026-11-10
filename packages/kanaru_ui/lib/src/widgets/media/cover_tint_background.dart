import 'package:material_ui/material_ui.dart';

/// Background tinted by the two dominant colours of a cover: a vertical
/// gradient (first colour darkened to 60 %, second to 90 % of its lightness)
/// that fades into the surface colour. A track change moves the colours over
/// [duration]; losing the colours (no cover) fades only the alpha, so the
/// hue does not slide through grey. Never drives the app theme.
class CoverTintBackground extends StatefulWidget {
  const CoverTintBackground({
    super.key,
    required this.first,
    required this.second,
    required this.child,
    this.duration = const Duration(milliseconds: 700),
  });

  /// Dominant colours; both null = no tint.
  final Color? first;
  final Color? second;
  final Widget child;
  final Duration duration;

  @override
  State<CoverTintBackground> createState() => _CoverTintBackgroundState();
}

class _CoverTintBackgroundState extends State<CoverTintBackground> {
  /// Last colours that were set, kept while the tint fades out.
  Color _first = const Color(0x00000000);
  Color _second = const Color(0x00000000);

  static Color _darken(Color c, double factor) {
    final hsl = HSLColor.fromColor(c.withAlpha(0xFF));
    return hsl
        .withLightness((hsl.lightness * factor).clamp(0.0, 1.0))
        .toColor();
  }

  void _remember() {
    final f = widget.first;
    final s = widget.second ?? f;
    if (f != null && s != null) {
      _first = _darken(f, 0.6);
      _second = _darken(s, 0.9);
    }
  }

  @override
  void initState() {
    super.initState();
    _remember();
  }

  @override
  void didUpdateWidget(CoverTintBackground old) {
    super.didUpdateWidget(old);
    _remember();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final tinted = widget.first != null;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : widget.duration;
    // Hue tweens while tinted; the alpha alone goes to 0 when it is not.
    final a = tinted ? _first : _first.withAlpha(0);
    final b = tinted ? _second : _second.withAlpha(0);
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: a),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, top, _) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: b),
        duration: duration,
        curve: Curves.easeInOut,
        builder: (context, mid, child) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(top ?? a, surface),
                Color.alphaBlend(mid ?? b, surface),
                surface,
              ],
            ),
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
