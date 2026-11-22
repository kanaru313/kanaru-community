import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The text box whose floating label reads [label] (a `*` follows a required
/// one).
Finder boxOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(TextField));

String textIn(WidgetTester tester, String label) =>
    tester.widget<TextField>(boxOf(label)).controller!.text;

bool enabledBox(WidgetTester tester, String label) =>
    tester.widget<TextField>(boxOf(label)).enabled ?? true;

/// Types [text] into the box of [label] and leaves it.
Future<void> typeAndLeave(
  WidgetTester tester,
  String label,
  String text,
) async {
  await tester.enterText(boxOf(label), text);
  await tester.pump();
  await leaveBox(tester);
}

Future<void> leaveBox(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> pressEnter(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}
