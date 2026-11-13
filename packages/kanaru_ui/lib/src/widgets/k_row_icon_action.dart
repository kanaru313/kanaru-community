import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';

/// Colour a list row gives to the icon actions inside it (its "soft" ink).
/// Only [KMediaCard] places one; an action outside a row finds none and keeps
/// `onSurfaceVariant`, so a plain `IconTheme` elsewhere never recolours it.
class KRowIconColor extends InheritedWidget {
  const KRowIconColor({super.key, required this.color, required super.child});

  final Color color;

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KRowIconColor>()?.color;

  @override
  bool updateShouldNotify(KRowIconColor old) => color != old.color;
}

// 8-bit alphas of the 8 % hover / focus, 10 % press and 38 % disabled layers,
// rounded the way IconButton rounds them so both paint the same colours.
const _hoverAlpha = 20;
const _pressAlpha = 26;
const _disabledAlpha = 97;

/// A light icon-only action for a row, card or page header (the ♥ and ⋮ of a
/// list row). Looks like a Material `IconButton` (40 dp state circle, 8 % hover
/// and 10 % press layers, ripple, tooltip, disabled state) but builds no
/// `AnimatedTheme`, `ThemeData` copy or `ButtonStyle`: one `InkResponse`.
///
/// The touch target is [KLayout.minTargetDesktop] on the desktop shell and
/// [KLayout.minTarget] on mobile. Unselected colour: [color], else the
/// enclosing row's ([KRowIconColor]), else `onSurfaceVariant`. A non-null
/// [selected] makes it a toggle drawn with [selectedIcon] in [selectedColor]
/// (default `primary`). A null [onPressed] disables it. Keyboard focus shows
/// a 2 dp `primary` ring on top of the state layer. Needs a [Material]
/// ancestor.
class KRowIconAction extends StatefulWidget {
  const KRowIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selectedIcon,
    this.selected,
    this.semanticLabel,
    this.iconSize = 20,
    this.color,
    this.selectedColor,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final bool? selected;

  /// Hover / long-press text; also what a screen reader says unless
  /// [semanticLabel] is set (then that label replaces it).
  final String tooltip;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color? color;
  final Color? selectedColor;

  /// Diameter of the state layer and of the keyboard focus ring.
  static const double circle = 40;

  @override
  State<KRowIconAction> createState() => _KRowIconActionState();
}

class _KRowIconActionState extends State<KRowIconAction> {
  bool _focused = false;
  bool _keyboardMode = false;

  void _onMode(FocusHighlightMode mode) {
    final keyboard = mode == FocusHighlightMode.traditional;
    if (keyboard != _keyboardMode && mounted) {
      setState(() => _keyboardMode = keyboard);
    }
  }

  void _onFocus(bool focused) {
    if (!mounted || focused == _focused) return;
    final manager = FocusManager.instance;
    if (focused) {
      manager.addHighlightModeListener(_onMode);
    } else {
      manager.removeHighlightModeListener(_onMode);
    }
    setState(() {
      _focused = focused;
      _keyboardMode = manager.highlightMode == FocusHighlightMode.traditional;
    });
  }

  @override
  void dispose() {
    if (_focused) FocusManager.instance.removeHighlightModeListener(_onMode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final enabled = w.onPressed != null;
    final toggle = w.selected != null;
    final on = w.selected ?? false;
    final ink = !enabled
        ? scheme.onSurface.withAlpha(_disabledAlpha)
        : on
        ? w.selectedColor ?? scheme.primary
        : w.color ?? KRowIconColor.maybeOf(context) ?? scheme.onSurfaceVariant;
    final target = FormFactor.of(context) == FormFactor.desktop
        ? KLayout.minTargetDesktop
        : KLayout.minTarget;
    final showRing = enabled && _focused && _keyboardMode;

    Widget action = InkResponse(
      onTap: w.onPressed,
      canRequestFocus: enabled,
      onFocusChange: _onFocus,
      radius: KRowIconAction.circle / 2,
      highlightShape: BoxShape.circle,
      containedInkWell: false,
      splashColor: ink.withAlpha(_pressAlpha),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.pressed)
            ? ink.withAlpha(_pressAlpha)
            : s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
            ? ink.withAlpha(_hoverAlpha)
            : null,
      ),
      child: SizedBox.square(
        dimension: target,
        child: Center(
          // Always in the tree (transparent when hidden) so a focus change
          // never remounts the icon.
          child: SizedBox.square(
            dimension: KRowIconAction.circle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: showRing ? scheme.primary : const Color(0x00000000),
                ),
              ),
              child: Center(
                child: Icon(
                  on ? w.selectedIcon ?? w.icon : w.icon,
                  size: w.iconSize,
                  color: ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (enabled) {
      action = Tooltip(
        message: w.tooltip,
        // The tooltip reaches screen readers as the button's tooltip, unless
        // an own label is given: then that label is the only name.
        excludeFromSemantics: w.semanticLabel != null,
        child: action,
      );
    }
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      // A disabled action has no Tooltip, so it names itself.
      label: w.semanticLabel ?? (enabled ? null : w.tooltip),
      selected: w.selected,
      toggled: toggle ? on : null,
      child: action,
    );
  }
}
