import 'package:material_ui/material_ui.dart';

import 'k_focus_ring.dart';

/// Overlay alpha of a hovered / pressed [KPressSurface].
const double kHoverOverlay = 0.08;
const double kPressedOverlay = 0.10;

/// Interaction shell shared by the buttons of `kanaru_ui` that draw their own
/// face (tiles, pills, segments, round and modal buttons): focusable (Enter /
/// Space activate), hover 8 % / press 10 % layer value for the [builder], the
/// 2 dp `primary` keyboard ring, and one semantics node: a button named
/// [semanticLabel] that reports `focusable` / `focused` (so a screen reader
/// with a keyboard announces the focused control). Draws nothing else. Not
/// exported.
class KPressSurface extends StatefulWidget {
  const KPressSurface({
    super.key,
    required this.onPressed,
    required this.radius,
    required this.semanticLabel,
    required this.builder,
    this.selected,
    this.inMutuallyExclusiveGroup = false,
    this.shortcuts,
    this.focusNode,
    this.autofocus = false,
  });

  /// Null = disabled: not focusable, no layers.
  final VoidCallback? onPressed;
  final BorderRadius radius;

  /// Spoken name of the button.
  final String semanticLabel;

  /// Reported as the semantics `selected` flag when not null (a segment).
  final bool? selected;
  final bool inMutuallyExclusiveGroup;

  /// Builds the face; `overlay` is the alpha of the `onSurface`-family layer
  /// (0, [kHoverOverlay], [kPressedOverlay]); `pressed` is true while a
  /// pointer holds it down.
  final Widget Function(BuildContext context, double overlay, bool pressed)
  builder;

  /// Extra key bindings while this button has focus (arrow navigation).
  final Map<ShortcutActivator, Intent>? shortcuts;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KPressSurface> createState() => _KPressSurfaceState();
}

class _KPressSurfaceState extends State<KPressSurface> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final pressed = enabled && _pressed;
    final overlay = !enabled
        ? 0.0
        : pressed
        ? kPressedOverlay
        : (_hovered ? kHoverOverlay : 0.0);
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      focusable: enabled,
      focused: enabled ? _hasFocus : null,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: enabled,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          shortcuts: widget.shortcuts,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          onFocusChange: (v) => setState(() => _hasFocus = v),
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
              child: widget.builder(context, overlay, pressed),
            ),
          ),
        ),
      ),
    );
  }
}
