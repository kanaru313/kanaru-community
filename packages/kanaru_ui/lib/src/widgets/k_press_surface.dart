import 'package:material_ui/material_ui.dart';

import 'k_focus_ring.dart';

/// Interaction shell shared by the round / pill buttons of `kanaru_ui`:
/// focusable (Enter / Space activate), hover 8 % / press 10 % layer value for
/// the [builder], the 2 dp `primary` keyboard ring. Draws nothing else and
/// adds no semantics: the owner wraps it. Not exported.
class KPressSurface extends StatefulWidget {
  const KPressSurface({
    super.key,
    required this.onPressed,
    required this.radius,
    required this.builder,
    this.focusNode,
    this.autofocus = false,
  });

  /// Null = disabled: not focusable, no layers.
  final VoidCallback? onPressed;
  final BorderRadius radius;

  /// Builds the face; `overlay` is the alpha of the `onSurface`-family layer
  /// (0, 0.08 hover, 0.10 pressed).
  final Widget Function(BuildContext context, double overlay) builder;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KPressSurface> createState() => _KPressSurfaceState();
}

class _KPressSurfaceState extends State<KPressSurface> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final overlay = !enabled
        ? 0.0
        : _pressed
        ? 0.10
        : (_hovered ? 0.08 : 0.0);
    return FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: KFocusRing(
          focused: _focused,
          radius: widget.radius,
          child: widget.builder(context, overlay),
        ),
      ),
    );
  }
}
