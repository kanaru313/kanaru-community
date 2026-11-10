import 'package:material_ui/material_ui.dart';

/// Icon button for an on/off state (shuffle, repeat). On shows the icon in
/// the primary colour with a small dot below it, so the state is not told by
/// colour alone. Off shows the plain icon.
class KToggleIconButton extends StatelessWidget {
  const KToggleIconButton({
    super.key,
    required this.icon,
    required this.active,
    required this.onPressed,
    required this.tooltip,
    this.iconSize,
  });

  /// Key of the dot, for tests.
  static const dotKey = ValueKey('k-toggle-dot');

  final IconData icon;
  final bool active;
  final VoidCallback? onPressed;
  final String tooltip;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon),
          selectedIcon: Icon(icon),
          isSelected: active,
          iconSize: iconSize,
          tooltip: tooltip,
          color: active ? scheme.primary : scheme.onSurfaceVariant,
          onPressed: onPressed,
        ),
        if (active)
          Positioned(
            bottom: 4,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  key: dotKey,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
