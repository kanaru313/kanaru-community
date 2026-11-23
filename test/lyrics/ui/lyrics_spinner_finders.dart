import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Finds the lyrics area's spinner by what it says to a screen reader.
Finder byLyricsSpinner([String label = 'Searching for lyrics…']) =>
    find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == label,
      description: 'spinner "$label"',
    );

/// A running spinner never lets the frames settle; a still arc does. Fails
/// (timeout) when something keeps animating.
Future<void> expectStill(WidgetTester tester) => tester.pumpAndSettle();
