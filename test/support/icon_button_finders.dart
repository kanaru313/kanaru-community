import 'package:material_ui/material_ui.dart' show IconButton;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

/// Finds a [KIconButton] by its tooltip text. `find.byTooltip` cannot: the
/// button keeps its tooltip out of semantics, which is where that finder
/// looks.
Finder byIconButton(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is KIconButton && widget.tooltip == tooltip,
  description: 'KIconButton "$tooltip"',
);

/// What a test needs to know of an icon button that can be either the light
/// [KIconButton] or the Material one (a toggle swaps between them).
typedef IconButtonState = ({
  bool enabled,
  bool selected,
  String? tooltip,
  bool material,
});

/// State of the icon button that holds [glyph] (the nearest [KIconButton] or
/// [IconButton] above it).
IconButtonState iconButtonAround(WidgetTester tester, Finder glyph) {
  final light = find.ancestor(of: glyph, matching: find.byType(KIconButton));
  if (light.evaluate().isNotEmpty) {
    final w = tester.widget<KIconButton>(light.first);
    return (
      enabled: w.onPressed != null,
      selected: w.selected ?? false,
      tooltip: w.tooltip,
      material: false,
    );
  }
  final w = tester.widget<IconButton>(
    find.ancestor(of: glyph, matching: find.byType(IconButton)).first,
  );
  return (
    enabled: w.onPressed != null,
    selected: w.isSelected ?? false,
    tooltip: w.tooltip,
    material: true,
  );
}

/// Finds an icon button by tooltip whichever look it has: the light
/// [KIconButton] or the Material one (filled play, an open panel toggle).
/// Both are real widgets, so `findsNothing` proves the button is gone.
Finder byAnyIconButton(String tooltip) => find.byWidgetPredicate(
  (widget) =>
      (widget is KIconButton && widget.tooltip == tooltip) ||
      (widget is IconButton && widget.tooltip == tooltip),
  description: 'icon button "$tooltip"',
);
