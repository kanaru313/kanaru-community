import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

/// Finds a [KIconButton] by its tooltip text. `find.byTooltip` cannot: the
/// button keeps its tooltip out of semantics, which is where that finder
/// looks.
Finder byIconButton(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is KIconButton && widget.tooltip == tooltip,
  description: 'KIconButton "$tooltip"',
);

/// Finds every [KCheckMark] whose state is [state].
Finder byCheckState(KCheckState state) => find.byWidgetPredicate(
  (widget) => widget is KCheckMark && widget.state == state,
  description: 'KCheckMark $state',
);

/// Finds the [KDragHandle] of the row at [index].
Finder byDragHandle(int index) => find.byWidgetPredicate(
  (widget) => widget is KDragHandle && widget.index == index,
  description: 'KDragHandle $index',
);
