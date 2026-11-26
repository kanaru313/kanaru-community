import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

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

/// Finds the semantics node labelled [label] that reports itself selected
/// (a preview card, a chosen option).
Finder bySelected(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.label == label &&
      widget.properties.selected == true,
  description: 'selected "$label"',
);

/// Finds the semantics node labelled [label] that reports itself toggled on.
Finder byToggled(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.label == label &&
      widget.properties.toggled == true,
  description: 'toggled on "$label"',
);

/// Finds the semantics node labelled [label] that reports itself selected,
/// including nodes Material or our widgets build without an own [Semantics]
/// widget (icon rows). Needs semantics enabled in the test.
SemanticsFinder bySemanticsSelected(String label) =>
    find.semantics.byPredicate((node) {
      final data = node.getSemanticsData();
      return data.label.split('\n').contains(label) &&
          data.flagsCollection.isSelected == Tristate.isTrue;
    }, describeMatch: (_) => 'selected "$label"');

/// Finds the semantics node labelled [label] whose toggle state is [on]
/// (a switch row). Needs semantics enabled in the test.
SemanticsFinder byToggledState(String label, {bool on = true}) =>
    find.semantics.byPredicate((node) {
      final data = node.getSemanticsData();
      return data.label.split('\n').contains(label) &&
          data.flagsCollection.isToggled ==
              (on ? Tristate.isTrue : Tristate.isFalse);
    }, describeMatch: (_) => 'toggled ${on ? 'on' : 'off'} "$label"');

/// Finds the stop slider whose spoken value is [label] (its live label).
Finder bySliderValue(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Slider &&
      widget.semanticFormatterCallback?.call(widget.value) == label,
  description: 'Slider at "$label"',
);

/// Finds the start tile whose spoken label is [label].
Finder byStartTile(String label) => find.byWidgetPredicate(
  (widget) => widget is KStartTile && widget.semanticLabel == label,
  description: 'KStartTile "$label"',
);

/// Finds the modal button labelled [label].
Finder byModalButton(String label) => find.byWidgetPredicate(
  (widget) => widget is KModalButton && widget.label == label,
  description: 'KModalButton "$label"',
);

/// Finds the step button whose spoken label is [label].
Finder byStepButton(String label) => find.byWidgetPredicate(
  (widget) => widget is KStepButton && widget.semanticLabel == label,
  description: 'KStepButton "$label"',
);

/// Makes the keyboard focus ring show (as after a Tab press) for the test.
void useKeyboardHighlight() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

/// Finds the semantics node labelled [label] whose enabled state is [enabled]
/// (a button that may be switched off). Needs semantics enabled in the test.
SemanticsFinder byEnabledState(String label, {required bool enabled}) =>
    find.semantics.byPredicate((node) {
      final data = node.getSemanticsData();
      return data.label.split('\n').contains(label) &&
          data.flagsCollection.isEnabled ==
              (enabled ? Tristate.isTrue : Tristate.isFalse);
    }, describeMatch: (_) => '${enabled ? 'enabled' : 'disabled'} "$label"');
