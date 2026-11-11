import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../state/browse/selection_providers.dart';

/// Room a page's scroll content leaves at its end for the floating panel
/// (desktop): the panel's height for [state] plus its distance from the
/// bottom edge. Zero without a selection.
double selectionPanelInset(
  BuildContext context,
  SelectionState state,
  TextScaler scaler,
) {
  if (state.isEmpty) return 0;
  return KSelectionPanel.heightFor(
        context,
        expanded: state.expanded,
        bodyHeight: state.ids.length * KMediaCard.extentOf(scaler),
      ) +
      KSpace.x4 +
      KSpace.x2;
}

/// The last sliver of a library page: empty room as high as the floating
/// panel (desktop), so the last row can be scrolled clear of it. The page
/// keeps its full height and rows beside the panel stay reachable. On the
/// mobile shell the panel sits in the bottom bar and pushes the page up, so
/// this is the plain end gap.
class SelectionInsetSliver extends ConsumerWidget {
  const SelectionInsetSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (FormFactor.of(context) == FormFactor.mobile) {
      return const SliverToBoxAdapter(child: SizedBox(height: KSpace.x4));
    }
    final scaler = MediaQuery.textScalerOf(context);
    final inset = ref.watch(
      librarySelectionProvider.select(
        (s) => selectionPanelInset(context, s, scaler),
      ),
    );
    // Never less than the page's usual end gap, so the last row is not flush.
    return SliverToBoxAdapter(
      child: SizedBox(height: math.max(KSpace.x4, inset)),
    );
  }
}
