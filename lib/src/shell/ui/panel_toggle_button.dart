import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Icon button that toggles a side panel: a light [KIconButton] while the
/// panel is closed, the Material icon button with a `secondaryContainer`
/// disc ([disc] dp square) while it is open.
///
/// The two looks swap in place, so one [FocusNode] owned here is given to
/// both: a keyboard user who opens the panel with Enter keeps the focus on
/// the button.
class PanelToggleButton extends StatefulWidget {
  const PanelToggleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    this.size = KIconSize.md,
    this.disc = KLayout.minTargetDesktop,
  });

  final IconData icon;
  final String tooltip;

  /// The panel this button toggles is open.
  final bool selected;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final double size;
  final double disc;

  @override
  State<PanelToggleButton> createState() => _PanelToggleButtonState();
}

class _PanelToggleButtonState extends State<PanelToggleButton> {
  final FocusNode _focus = FocusNode(debugLabel: 'PanelToggleButton');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.selected) {
      return KIconButton(
        icon: widget.icon,
        tooltip: widget.tooltip,
        size: widget.size,
        focusNode: _focus,
        onPressed: widget.onPressed,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return KIconButton.yieldSpace(
      child: IconButton(
        icon: Icon(widget.icon),
        iconSize: widget.size,
        tooltip: widget.tooltip,
        focusNode: _focus,
        isSelected: true,
        style: IconButton.styleFrom(
          backgroundColor: scheme.secondaryContainer,
          foregroundColor: scheme.onSecondaryContainer,
          fixedSize: Size.square(widget.disc),
          padding: EdgeInsets.zero,
        ),
        onPressed: widget.onPressed,
      ),
    );
  }
}
