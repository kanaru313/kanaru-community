import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'store_filter_body.dart';

/// Opens Lọc: a bottom sheet on mobile, a 360 panel under the Lọc button on
/// desktop (right edges aligned, flipped above when there is no room). Esc and
/// a tap outside close it, the same as Xong.
Future<void> showStoreFilter(BuildContext context, GlobalKey anchor) {
  final rect = kAnchorRectOf(anchor);
  if (FormFactor.of(context) == FormFactor.mobile || rect == null) {
    return showKSheet<void>(
      context,
      builder: (_) => const StoreFilterBody(raised: false),
    );
  }
  return showKAnchoredPanel<void>(
    context,
    anchor: rect,
    align: KAnchorAlign.end,
    builder: (_) => const SizedBox(
      width: _panelWidth,
      child: StoreFilterBody(raised: true),
    ),
  );
}

const double _panelWidth = 360;
