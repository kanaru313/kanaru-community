import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/config_form_provider.dart';

import 'support/config_harness.dart';
import 'support/form_finders.dart';
import 'support/pump_form.dart';

const _server = InputField(
  key: 'server',
  title: 'Server',
  format: InputFormat.url,
);
const _temp = InputField(
  key: 'temp',
  title: 'Temperature',
  format: InputFormat.number,
  min: 0,
  max: 1,
);
const _other = InputField(key: 'other', title: 'Other');
const _token = InputField(
  key: 'token',
  title: 'Token',
  required: true,
  minLength: 3,
);

/// Leave the focused box with Tab, as a keyboard user does.
Future<void> tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
}

/// How a box is left: Tab, Enter, or a plain focus change.
final _leaves = <String, Future<void> Function(WidgetTester)>{
  'Tab': tab,
  'Enter': pressEnter,
  'unfocus': leaveBox,
};

void main() {
  for (final (shell, size) in [
    ('phone', phoneSize),
    ('desktop', desktopSize),
  ]) {
    for (final entry in _leaves.entries) {
      final leave = entry.value;
      group('$shell, leaving with ${entry.key}', () {
        testWidgets('url: http shows the error, https then saves', (
          tester,
        ) async {
          final h = ConfigHarness([_server, _other]);
          await pumpConfigForm(tester, h, size: size);
          await tester.enterText(boxOf('Server'), 'http://example.com');
          await tester.pump();
          await leave(tester);
          expect(find.text('Enter an https address'), findsOneWidget);
          expect(h.calls, isEmpty);
          await tester.enterText(boxOf('Server'), 'https://example.com');
          await tester.pump();
          await leave(tester);
          expect(find.text('Enter an https address'), findsNothing);
          expect(h.calls, ['set:server="https://example.com"']);
          expect(textIn(tester, 'Server'), 'https://example.com');
        });

        testWidgets('number: out of range, then valid saves', (tester) async {
          final h = ConfigHarness([_temp, _other]);
          await pumpConfigForm(tester, h, size: size);
          await tester.enterText(boxOf('Temperature'), '5');
          await tester.pump();
          await leave(tester);
          expect(find.text('Must be 1 or less'), findsOneWidget);
          expect(h.calls, isEmpty);
          await tester.enterText(boxOf('Temperature'), '0.5');
          await tester.pump();
          await leave(tester);
          expect(find.text('Must be 1 or less'), findsNothing);
          expect(h.calls, ['set:temp=0.5']);
          expect(textIn(tester, 'Temperature'), '0.5');
        });

        testWidgets('required: cleared, then filled saves', (tester) async {
          final h = ConfigHarness(
            [_token, _other],
            values: {'token': 'abcdef'},
          );
          await pumpConfigForm(tester, h, size: size);
          await tester.enterText(boxOf('Token *'), '');
          await tester.pump();
          await leave(tester);
          expect(find.text('This setting is required'), findsOneWidget);
          expect(h.calls, ['set:token=null']);
          await tester.enterText(boxOf('Token *'), 'xyz123');
          await tester.pump();
          await leave(tester);
          expect(find.text('This setting is required'), findsNothing);
          expect(h.calls.last, 'set:token="xyz123"');
          expect(textIn(tester, 'Token *'), 'xyz123');
        });
      });
    }
  }

  group('text box saves and outside changes', () {
    testWidgets('retyping a saved value after an outside reset saves it', (
      tester,
    ) async {
      final h = ConfigHarness([_other, _token]);
      await pumpConfigForm(tester, h);
      await tester.enterText(boxOf('Other'), 'B');
      await leaveBox(tester);
      expect(h.calls, ['set:other="B"']);
      h.setOutside('other', null);
      await tester.pumpAndSettle();
      expect(textIn(tester, 'Other'), '');
      await tester.enterText(boxOf('Other'), 'B');
      await leaveBox(tester);
      expect(h.calls, ['set:other="B"', 'set:other="B"']);
      expect(h.values['other'], 'B');
    });

    testWidgets('echo between Enter and blur sends once', (tester) async {
      final h = ConfigHarness([_other, _token]);
      await pumpConfigForm(tester, h);
      await tester.enterText(boxOf('Other'), 'B');
      await pressEnter(tester);
      expect(h.values['other'], 'B');
      await leaveBox(tester);
      expect(h.calls, ['set:other="B"']);
      expect(textIn(tester, 'Other'), 'B');
    });

    testWidgets('outside change during an in-flight save does not replace '
        'the text', (tester) async {
      final h = ConfigHarness([_other, _token], values: {'other': 'A'});
      final gate = Completer<void>();
      h.gate = gate.future;
      await pumpConfigForm(tester, h);
      await tester.enterText(boxOf('Other'), 'B');
      await pressEnter(tester);
      h.setOutside('other', 'Z');
      await tester.pump();
      expect(textIn(tester, 'Other'), 'B');
      await leaveBox(tester);
      expect(h.calls, ['set:other="B"']);
      gate.complete();
      await tester.pumpAndSettle();
      expect(h.values['other'], 'B');
      expect(textIn(tester, 'Other'), 'B');
    });

    testWidgets('two quick edits: the latest wins, one in flight, one queued', (
      tester,
    ) async {
      final h = ConfigHarness([_other, _token]);
      final gate = Completer<void>();
      h.gate = gate.future;
      await pumpConfigForm(tester, h);
      await tester.enterText(boxOf('Other'), 'one');
      await pressEnter(tester);
      await tester.enterText(boxOf('Other'), 'two');
      await pressEnter(tester);
      expect(h.calls, ['set:other="one"']);
      gate.complete();
      await tester.pumpAndSettle();
      expect(h.calls, ['set:other="one"', 'set:other="two"']);
      expect(h.values['other'], 'two');
      expect(textIn(tester, 'Other'), 'two');
    });

    testWidgets('a refused save keeps the text and is retried on blur', (
      tester,
    ) async {
      final h = ConfigHarness([_other, _token]);
      h.refusals['other'] = ConfigWrite.failed;
      await pumpConfigForm(tester, h);
      await tester.enterText(boxOf('Other'), 'B');
      await leaveBox(tester);
      expect(h.calls, ['set:other="B"']);
      expect(h.values['other'], isNull);
      expect(textIn(tester, 'Other'), 'B');
      await tester.tap(boxOf('Other'));
      await tester.pump();
      await leaveBox(tester);
      expect(h.calls, ['set:other="B"', 'set:other="B"']);
      expect(h.values['other'], 'B');
    });

    testWidgets('outside revert to the pre-save value after the echo shows', (
      tester,
    ) async {
      final h = ConfigHarness([_other, _token], values: {'other': 'A'});
      await pumpConfigForm(tester, h);
      await tester.tap(boxOf('Other'));
      await tester.enterText(boxOf('Other'), 'B');
      await pressEnter(tester); // saves; echo arrives, box still focused
      expect(h.values['other'], 'B');
      h.setOutside('other', 'A');
      await tester.pump();
      await leaveBox(tester);
      expect(textIn(tester, 'Other'), 'A');
      expect(h.calls, ['set:other="B"']);
    });
  });
}
