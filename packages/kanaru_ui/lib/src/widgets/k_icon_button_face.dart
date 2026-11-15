import 'package:material_ui/material_ui.dart';

import '../tokens/k_shape.dart';

/// What a `KIconButton` draws: the glyph under a focus ring box. The box is
/// always in the tree; [ring] only sets its border colour (transparent when
/// null), so a focus change repaints and never relayouts. The glyph's own
/// semantics are dropped: the button's node carries the label.
class KIconButtonFace extends StatelessWidget {
  const KIconButtonFace({
    super.key,
    this.icon,
    this.child,
    required this.size,
    required this.color,
    this.ring,
  });

  final IconData? icon;

  /// Custom glyph, drawn with [size] and [color] as `IconTheme`.
  final Widget? child;
  final double size;
  final Color color;

  /// Ring colour while the button shows keyboard focus.
  final Color? ring;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: KRadius.sm,
      border: Border.all(width: 2, color: ring ?? const Color(0x00000000)),
    ),
    child: ExcludeSemantics(
      child: child != null
          ? IconTheme(
              data: IconThemeData(size: size, color: color),
              child: child!,
            )
          : Icon(icon, size: size, color: color),
    ),
  );
}
