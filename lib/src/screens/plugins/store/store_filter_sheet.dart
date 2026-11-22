import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'store_filter_body.dart';

/// Opens Lọc: a bottom sheet on mobile, a 360 panel under the Lọc button on
/// desktop (right edges aligned, flipped above when there is no room). Esc and
/// a tap outside close it, the same as Xong.
Future<void> showStoreFilter(BuildContext context, GlobalKey anchor) {
  final rect = AnchoredPanelLayout.rectOf(anchor);
  if (FormFactor.of(context) == FormFactor.mobile || rect == null) {
    return showKSheet<void>(
      context,
      builder: (_) => const StoreFilterBody(raised: false),
    );
  }
  return showDialog<void>(
    context: context,
    animationStyle: KMotion.routeAnimationStyle(context),
    // The panel is placed in global coordinates; the route's safe area would
    // shift it.
    useSafeArea: false,
    barrierColor: const Color(0x00000000),
    builder: (context) => KRowEdgesScope(
      edges: KRowEdges.inset,
      child: CustomSingleChildLayout(
        delegate: AnchoredPanelLayout(
          rect,
          align: KAnchorAlign.end,
          bottomInset: MediaQuery.paddingOf(context).bottom,
        ),
        child: Material(
          elevation: 3,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: KShape.of(KRadius.lg, continuous: true),
          clipBehavior: Clip.antiAlias,
          child: const SizedBox(
            width: _panelWidth,
            child: StoreFilterBody(raised: true),
          ),
        ),
      ),
    ),
  );
}

const double _panelWidth = 360;
