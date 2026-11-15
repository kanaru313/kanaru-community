import 'package:material_ui/material_ui.dart';

import '../tokens/k_icon_size.dart';
import '../tokens/k_space.dart';
import 'k_icon_button_colors.dart';
import 'k_icon_button_face.dart';
import 'k_icon_button_pulse.dart';
import 'k_icon_button_scope.dart';

/// Light icon button: the icon plus its [padding], no disc and no 48 dp box
/// (width = icon + horizontal padding, height = icon + vertical padding).
///
/// Colour: [color], else the nearest [KIconButtonColors], else
/// `onSurfaceVariant`; `onSurface` under the mouse; [selectedColor] (else
/// primary) while [selected]; `onSurface` at 38 % when [onPressed] is null.
/// A press dims the icon to half and holds it for at least 100 ms, then fades
/// it back over `KMotion.press`. Enter, NumpadEnter, Space and Select
/// activate it through the app's default `ActivateIntent`; a 2 dp ring shows
/// only when focus came from the keyboard. A long press fires [onLongPress],
/// or shows the tooltip when there is none. Semantics: one button node
/// labelled [semanticLabel] (else [tooltip]), toggled when [selected] is set.
/// Filled and tonal icon buttons are the Material ones.
class KIconButton extends StatefulWidget {
  const KIconButton({
    super.key,
    this.icon,
    this.child,
    required this.tooltip,
    this.semanticLabel,
    required this.onPressed,
    this.onLongPress,
    this.selected,
    this.selectedIcon,
    this.size = KIconSize.md,
    this.color,
    this.selectedColor,
    this.padding = const EdgeInsets.symmetric(horizontal: KSpace.x2),
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         (icon == null) != (child == null),
         'give exactly one of icon and child',
       );

  @visibleForTesting
  static const ringKey = ValueKey('k-icon-button-ring');

  /// True when the primary focus sits inside a [KIconButton] (the shell lets
  /// Space activate it instead of play/pause).
  static bool ownsPrimaryFocus() => primaryFocusInsideKIconButton();

  /// Marks a Material icon button (a filled or tonal one, or the open state of
  /// a toggle) as an icon button for [ownsPrimaryFocus], so Space presses it
  /// there too instead of toggling playback.
  static Widget yieldSpace({required Widget child}) =>
      KIconButtonScope(child: child);

  /// The glyph. Give this or [child].
  final IconData? icon;

  /// A custom glyph (drawn with the icon size and colour as `IconTheme`).
  final Widget? child;
  final String tooltip;

  /// Spoken label; [tooltip] when null.
  final String? semanticLabel;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// On/off state; null when the button is not a toggle.
  final bool? selected;

  /// Glyph while [selected] is true; [icon] when null.
  final IconData? selectedIcon;
  final double size;
  final Color? color;
  final Color? selectedColor;
  final EdgeInsetsGeometry padding;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<KIconButton> createState() => _KIconButtonState();
}

class _KIconButtonState extends State<KIconButton>
    with SingleTickerProviderStateMixin {
  late final KIconButtonPulse _pulse = KIconButtonPulse(
    vsync: this,
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  bool _hovered = false;
  bool _ring = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void didUpdateWidget(KIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled) {
      _pulse.reset();
      _hovered = false;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _setHover(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  void _setRing(bool value) {
    if (_ring != value) setState(() => _ring = value);
  }

  void _release() =>
      _pulse.release(reduceMotion: MediaQuery.disableAnimationsOf(context));

  // Null without a callback, so the tooltip's own long press wins.
  VoidCallback? get _longPress => widget.onLongPress == null
      ? null
      : () {
          Feedback.forLongPress(context);
          widget.onLongPress!();
        };

  void _tap() {
    Feedback.forTap(context);
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = resolveKIconButtonColor(
      scheme: scheme,
      colors: KIconButtonColors.maybeOf(context),
      color: widget.color,
      selectedColor: widget.selectedColor,
      selected: widget.selected == true,
      hovered: _hovered,
      enabled: _enabled,
      pressed: _pulse.value,
    );
    final label = widget.semanticLabel ?? widget.tooltip;
    return Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      label: label,
      toggled: widget.selected,
      child: Tooltip(
        message: widget.tooltip,
        excludeFromSemantics: true,
        child: KIconButtonScope(
          child: FocusableActionDetector(
            enabled: _enabled,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            mouseCursor: _enabled
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
            onShowFocusHighlight: _setRing,
            onShowHoverHighlight: _setHover,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: _enabled ? (_) => _pulse.press() : null,
              onTapUp: _enabled ? (_) => _release() : null,
              onTapCancel: _enabled ? _release : null,
              onTap: _enabled ? _tap : null,
              onLongPress: _enabled ? _longPress : null,
              child: Padding(
                padding: widget.padding,
                child: KIconButtonFace(
                  key: KIconButton.ringKey,
                  icon: widget.selected == true
                      ? widget.selectedIcon ?? widget.icon
                      : widget.icon,
                  size: widget.size,
                  color: color,
                  ring: _ring ? scheme.primary : null,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
