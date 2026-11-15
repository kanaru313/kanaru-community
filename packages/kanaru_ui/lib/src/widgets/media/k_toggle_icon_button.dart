import 'package:material_ui/material_ui.dart';

import '../../tokens/k_icon_size.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';

/// Icon button ([KIconButton]) for an on/off state (shuffle, repeat). On shows the icon in
/// the primary colour with a small dot below it, so the state is not told by
/// colour alone. Off shows the plain icon. Give [icon], or [iconWidget] for a
/// drawing that changes with the state (the repeat glyphs).
class KToggleIconButton extends StatelessWidget {
  const KToggleIconButton({
    super.key,
    this.icon,
    this.iconWidget,
    required this.active,
    required this.onPressed,
    required this.tooltip,
    this.iconSize,
  }) : assert(
         (icon == null) != (iconWidget == null),
         'give exactly one of icon and iconWidget',
       );

  /// Key of the dot, for tests.
  static const dotKey = ValueKey('k-toggle-dot');

  final IconData? icon;
  final Widget? iconWidget;
  final bool active;
  final VoidCallback? onPressed;
  final String tooltip;
  final double? iconSize;

  /// Diameter of the dot and its gap under the glyph.
  static const double _dot = KSpace.x1;
  static const double _gap = KSpace.x1 / 2;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return KIconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      selected: active,
      size: iconSize ?? KIconSize.md,
      // The dot hangs below the glyph, so it does not depend on the height of
      // the slot the button sits in.
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          iconWidget ?? Icon(icon),
          if (active)
            Positioned(
              bottom: -(_gap + _dot),
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: DecoratedBox(
                    key: dotKey,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: _dot),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
