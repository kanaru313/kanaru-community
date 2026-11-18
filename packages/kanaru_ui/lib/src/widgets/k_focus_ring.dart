import 'package:material_ui/material_ui.dart';

/// Draws the 2 px `primary` keyboard-focus ring over [child] while [focused]
/// and focus came from the keyboard (not a pointer). [inset] moves the ring
/// outside (positive) the child's box.
class KFocusRing extends StatefulWidget {
  const KFocusRing({
    super.key,
    required this.focused,
    required this.radius,
    required this.child,
    this.inset = 0,
  });

  final bool focused;
  final BorderRadius radius;
  final double inset;
  final Widget child;

  /// True when the ring is drawn.
  bool get visible =>
      focused &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  State<KFocusRing> createState() => _KFocusRingState();
}

class _KFocusRingState extends State<KFocusRing> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_onMode);
  }

  void _onMode(FocusHighlightMode _) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onMode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    final child = widget.child;
    if (!widget.visible) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          left: -widget.inset,
          top: -widget.inset,
          right: -widget.inset,
          bottom: -widget.inset,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: widget.radius,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
