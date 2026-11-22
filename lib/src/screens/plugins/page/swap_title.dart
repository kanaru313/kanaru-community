import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A header title that cross-fades to [second] while [showSecond] is true and
/// back to [first] after: the old one fades out and rises 4 dp, the new one
/// fades in from 4 dp below ([KMotion.fast]). Reduced motion swaps at once.
class SwapTitle extends StatefulWidget {
  const SwapTitle({
    super.key,
    required this.first,
    required this.second,
    required this.showSecond,
  });

  final String first;

  /// Null keeps [first] whatever [showSecond] says.
  final String? second;
  final bool showSecond;

  @override
  State<SwapTitle> createState() => _SwapTitleState();
}

class _SwapTitleState extends State<SwapTitle>
    with SingleTickerProviderStateMixin {
  static const double _rise = KSpace.x1;

  bool get _wantSecond => widget.showSecond && widget.second != null;

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: KMotion.fast,
    value: _wantSecond ? 1 : 0,
  );

  @override
  void didUpdateWidget(SwapTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _wantSecond ? 1.0 : 0.0;
    if (_fade.value == target && !_fade.isAnimating) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.value = target;
    } else {
      _fade.animateTo(target, curve: KMotion.emphasized);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700);
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) {
        final t = _fade.value;
        Widget line(String text, double opacity, double dy) => ExcludeSemantics(
          excluding: opacity < 0.5,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ),
        );
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              if (t < 1) line(widget.first, 1 - t, -_rise * t),
              if (t > 0 && widget.second != null)
                line(widget.second!, t, _rise * (1 - t)),
            ],
          ),
        );
      },
    );
  }
}
