import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/browse/selection_providers.dart';
import 'selection_panel.dart';

/// Slot for the multi-select panel. Both shells render it above the player
/// (mobile: above the mini player; desktop: floating above the player bar).
/// Empty while nothing is selected; the selection lives as long as the app,
/// so the panel follows the user from one screen to the next.
///
/// The desktop slot is a centred, 440 wide box: the empty slot and the space
/// beside the panel pass clicks to the page.
class LibrarySelectionBar extends ConsumerWidget {
  const LibrarySelectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(hasSelectionProvider)) return const SizedBox.shrink();
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    return Padding(
      padding: EdgeInsets.only(bottom: mobile ? KSpace.x1 : 0),
      child: const SelectionPanel(),
    );
  }
}
