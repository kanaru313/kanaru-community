import 'package:material_ui/material_ui.dart';

/// Slot for the multi-select action bar. Both shells render it above the
/// player (mobile: above the mini player; desktop: floating above the player
/// bar). Empty until the library provides selection actions.
class LibrarySelectionBar extends StatelessWidget {
  const LibrarySelectionBar({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
