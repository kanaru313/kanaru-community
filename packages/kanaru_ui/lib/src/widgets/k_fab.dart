import 'package:material_ui/material_ui.dart';

import 'k_fab_menu_parts.dart';

/// Icon-only floating action button: the 56 dp rounded square of [KFabMenu]
/// in its closed state, without a menu. The caller places it (bottom end of
/// the page) and keeps the list above it padded so the last row stays clear.
/// [tooltip] is also its spoken name.
class KFab extends StatelessWidget {
  const KFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// End padding a scrolling list needs so its last row clears the button.
  static const double listEndPadding = 88;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: tooltip,
    onTap: onPressed,
    excludeSemantics: true,
    child: FabMenuButton(
      icon: icon,
      open: false,
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  );
}
