import 'package:material_ui/material_ui.dart';

import '../tokens/k_icon_size.dart';
import '../tokens/k_space.dart';
import 'k_icon_button.dart';

/// Icon button of a two-state toggle (a filter bar, an edit mode): a light
/// [KIconButton] while off, the tonal `secondaryContainer` disc of the same
/// box while on.
///
/// The two looks swap in place, so one [FocusNode] owned here is given to
/// both: a keyboard user who turns it on with Enter keeps the focus. The
/// disc is [disc] wide, exactly the light button's box.
/// [selectedIcon] (else [icon]) is drawn while [selected]; the on look
/// carries toggled semantics. A null [onPressed] disables the button.
class KTonalToggleButton extends StatefulWidget {
  const KTonalToggleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    this.selectedIcon,
    this.size = KIconSize.sm,
    this.disc,
  });

  final IconData icon;

  /// Glyph while [selected]; [icon] when null.
  final IconData? selectedIcon;
  final String tooltip;
  final bool selected;
  final VoidCallback? onPressed;
  final double size;

  /// Side in dp of the tonal square, and of the light button's box (the glyph
  /// is centred in it), like the shell's panel toggle. Null: [size] plus
  /// [KSpace.x2] on every side.
  final double? disc;

  @override
  State<KTonalToggleButton> createState() => _KTonalToggleButtonState();
}

class _KTonalToggleButtonState extends State<KTonalToggleButton> {
  final FocusNode _focus = FocusNode(debugLabel: 'KTonalToggleButton');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.disc ?? widget.size + 2 * KSpace.x2;
    if (!widget.selected) {
      return KIconButton(
        icon: widget.icon,
        tooltip: widget.tooltip,
        size: widget.size,
        padding: EdgeInsets.all((box - widget.size) / 2),
        focusNode: _focus,
        onPressed: widget.onPressed,
      );
    }
    return KIconButton.yieldSpace(
      child: IconButton.filledTonal(
        focusNode: _focus,
        tooltip: widget.tooltip,
        isSelected: true,
        onPressed: widget.onPressed,
        iconSize: widget.size,
        style: IconButton.styleFrom(
          fixedSize: Size.square(box),
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(widget.selectedIcon ?? widget.icon),
      ),
    );
  }
}
