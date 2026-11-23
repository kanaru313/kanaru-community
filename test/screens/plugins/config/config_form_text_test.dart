import 'dart:async';

import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/config_form_provider.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import 'support/config_harness.dart';
import 'support/form_finders.dart';
import 'support/pump_form.dart';

const _token = InputField(
  key: 'token',
  title: 'Token',
  subtitle: 'From your account page',
  placeholder: 'paste it here',
  required: true,
  minLength: 3,
);
const _host = InputField(
  key: 'host',
  title: 'Host',
  defaultValue: 'api.example.com',
  subtitle: 'Where to connect',
);
const _temperature = InputField(
  key: 'temp',
  title: 'Temperature',
  format: InputFormat.number,
  min: 0,
  max: 1,
  step: 0.25,
  defaultValue: 0.5,
);
const _retries = InputField(
  key: 'retries',
  title: 'Retries',
  format: InputFormat.integer,
  min: 0,
  max: 3,
);
const _server = InputField(
  key: 'server',
  title: 'Server',
  format: InputFormat.url,
);
const _prompt = InputField(
  key: 'prompt',
  title: 'Prompt',
  format: InputFormat.multiline,
  rows: 6,
  defaultValue: 'Be brief.',
);

void main() {
  for (final (shell, size) in [
    ('phone', phoneSize),
    ('desktop', desktopSize),
  ]) {
    group(shell, () {
      testWidgets(
        'a default is the value in the box, unchanged saves nothing',
        (tester) async {
          final h = ConfigHarness([_host]);
          await pumpConfigForm(tester, h, size: size);
          expect(textIn(tester, 'Host'), 'api.example.com');
          expect(find.text('Where to connect'), findsOneWidget);
          await tester.tap(boxOf('Host'));
          await leaveBox(tester);
          expect(h.calls, isEmpty);
        },
      );

      testWidgets('a stored value shows instead of the default', (
        tester,
      ) async {
        final h = ConfigHarness([_host], values: {'host': 'mine.example.com'});
        await pumpConfigForm(tester, h, size: size);
        expect(textIn(tester, 'Host'), 'mine.example.com');
      });

      testWidgets('leaving the box saves; Enter saves too', (tester) async {
        final h = ConfigHarness([_host, _token]);
        await pumpConfigForm(tester, h, size: size);
        await typeAndLeave(tester, 'Host', 'other.example.com');
        expect(h.calls, ['set:host="other.example.com"']);
        await tester.enterText(boxOf('Token *'), 'abcdef');
        await pressEnter(tester);
        expect(h.calls.last, 'set:token="abcdef"');
        expect(h.values['token'], 'abcdef');
      });

      testWidgets('clearing a box with a default goes back to it, no error', (
        tester,
      ) async {
        final h = ConfigHarness([_host], values: {'host': 'mine.example.com'});
        await pumpConfigForm(tester, h, size: size);
        await typeAndLeave(tester, 'Host', '');
        expect(h.calls, ['set:host=null']);
        expect(textIn(tester, 'Host'), 'api.example.com');
        expect(find.text('This setting is required'), findsNothing);
      });

      testWidgets('a required box cleared says so only after it was left', (
        tester,
      ) async {
        final h = ConfigHarness([_token], values: {'token': 'abcdef'});
        await pumpConfigForm(tester, h, size: size);
        await tester.enterText(boxOf('Token *'), '');
        await tester.pump();
        expect(find.text('This setting is required'), findsNothing);
        await leaveBox(tester);
        expect(find.text('This setting is required'), findsOneWidget);
        // The empty value is stored, so the page's band can name the field.
        expect(h.calls, ['set:token=null']);
        // The hint replaces nothing: the helper line is gone behind the error.
        expect(find.text('From your account page'), findsNothing);
        await tester.enterText(boxOf('Token *'), 'abcd');
        await tester.pumpAndSettle();
        expect(find.text('This setting is required'), findsNothing);
        expect(find.text('From your account page'), findsOneWidget);
      });

      testWidgets(
        'text that does not fit is never sent, the error goes when fixed',
        (tester) async {
          final h = ConfigHarness([_token]);
          await pumpConfigForm(tester, h, size: size);
          await typeAndLeave(tester, 'Token *', 'ab');
          expect(find.text('Enter at least 3 characters'), findsOneWidget);
          expect(h.calls, isEmpty);
          await tester.enterText(boxOf('Token *'), 'abc');
          await tester.pumpAndSettle();
          expect(find.text('Enter at least 3 characters'), findsNothing);
          await leaveBox(tester);
          expect(h.calls, ['set:token="abc"']);
        },
      );

      testWidgets('a number is checked, sent as a number, steps save at once', (
        tester,
      ) async {
        final h = ConfigHarness([_temperature, _retries]);
        await pumpConfigForm(tester, h, size: size);
        expect(textIn(tester, 'Temperature'), '0.5');
        await typeAndLeave(tester, 'Temperature', '1e');
        expect(find.text('Enter a number'), findsOneWidget);
        await typeAndLeave(tester, 'Temperature', '2');
        expect(find.text('Must be 1 or less'), findsOneWidget);
        await typeAndLeave(tester, 'Temperature', '0.75');
        expect(h.calls, ['set:temp=0.75']);
        await typeAndLeave(tester, 'Retries', '-');
        expect(find.text('Enter a whole number'), findsOneWidget);
        expect(h.calls, hasLength(1));
        // Each tap on + saves at once.
        await tester.tap(byIconButton('Increase by 0.25'));
        await tester.pumpAndSettle();
        expect(h.calls.last, 'set:temp=1');
        expect(textIn(tester, 'Temperature'), '1');
        await tester.tap(byIconButton('Decrease by 0.25'));
        await tester.pumpAndSettle();
        expect(h.calls.last, 'set:temp=0.75');
      });

      testWidgets('a url must be https', (tester) async {
        final h = ConfigHarness([_server]);
        await pumpConfigForm(tester, h, size: size);
        await typeAndLeave(tester, 'Server', 'http://a.example.com');
        expect(find.text('Enter an https address'), findsOneWidget);
        await typeAndLeave(tester, 'Server', 'https://a.example.com');
        expect(find.text('Enter an https address'), findsNothing);
        expect(h.calls, ['set:server="https://a.example.com"']);
      });

      testWidgets('multiline keeps Enter as a new line and shows its default', (
        tester,
      ) async {
        final h = ConfigHarness([_prompt]);
        await pumpConfigForm(tester, h, size: size);
        expect(textIn(tester, 'Prompt'), 'Be brief.');
        await tester.enterText(boxOf('Prompt'), 'Line one\nLine two');
        await tester.pump();
        expect(h.calls, isEmpty);
        await leaveBox(tester);
        expect(h.calls, ['set:prompt="Line one\\nLine two"']);
      });

      testWidgets('a refused save says why under the box and keeps the text', (
        tester,
      ) async {
        final h = ConfigHarness([_host]);
        h.refusals['host'] = ConfigWrite.invalidValue;
        await pumpConfigForm(tester, h, size: size);
        await typeAndLeave(tester, 'Host', 'x.example.com');
        expect(
          find.text('This setting doesn’t accept that value.'),
          findsOneWidget,
        );
        expect(textIn(tester, 'Host'), 'x.example.com');
        // Editing again takes the line away.
        await tester.enterText(boxOf('Host'), 'y.example.com');
        await tester.pumpAndSettle();
        expect(
          find.text('This setting doesn’t accept that value.'),
          findsNothing,
        );
      });

      testWidgets('a refused edit stays in the box after focus and blur', (
        tester,
      ) async {
        const line = 'This setting doesn’t accept that value.';
        final h = ConfigHarness([_host, _token]);
        h.refusals['host'] = ConfigWrite.invalidValue;
        await pumpConfigForm(tester, h, size: size);
        await typeAndLeave(tester, 'Host', 'x.example.com');
        expect(find.text(line), findsOneWidget);
        // Focus the box again and leave it without typing (leaving retries
        // the save; the store refuses again).
        h.refusals['host'] = ConfigWrite.invalidValue;
        await tester.tap(boxOf('Host'));
        await tester.pump();
        await leaveBox(tester);
        expect(textIn(tester, 'Host'), 'x.example.com');
        expect(find.text(line), findsOneWidget);
        // Something else changing the stored value does not replace the
        // refused text either: the user's edit stays until they change it.
        h.setOutside('host', 'elsewhere.example.com');
        await tester.pumpAndSettle();
        expect(textIn(tester, 'Host'), 'x.example.com');
      });

      for (final (result, text) in [
        (ConfigWrite.tooLarge, 'The plugin’s settings are too large to save.'),
        (
          ConfigWrite.unknownKey,
          'This setting no longer exists. The plugin may have been removed or changed.',
        ),
        (ConfigWrite.failed, 'Couldn’t save the setting (try again later)'),
      ]) {
        testWidgets('refusal ${result.name} reads "$text"', (tester) async {
          final h = ConfigHarness([_host]);
          h.refusals['host'] = result;
          await pumpConfigForm(tester, h, size: size);
          await typeAndLeave(tester, 'Host', 'x.example.com');
          expect(find.text(text), findsOneWidget);
        });
      }

      testWidgets(
        'a change made elsewhere shows, but not over the box being typed in',
        (tester) async {
          final h = ConfigHarness([_host, _token]);
          await pumpConfigForm(tester, h, size: size);
          h.setOutside('host', 'elsewhere.example.com');
          await tester.pumpAndSettle();
          expect(textIn(tester, 'Host'), 'elsewhere.example.com');
          // Typing in Token: an outside change to the same box is not applied.
          await tester.enterText(boxOf('Token *'), 'typing');
          h.setOutside('token', 'from-outside');
          await tester.pumpAndSettle();
          expect(textIn(tester, 'Token *'), 'typing');
        },
      );

      testWidgets('typing the default back clears the stored override', (
        tester,
      ) async {
        final h = ConfigHarness([_host], values: {'host': 'x.example.com'});
        await pumpConfigForm(tester, h, size: size);
        await typeAndLeave(tester, 'Host', 'api.example.com');
        expect(h.calls, ['set:host=null']);
        expect(h.values, isEmpty);
      });

      testWidgets(
        'an outside change that came while the box was focused wins when '
        'nothing was typed',
        (tester) async {
          final h = ConfigHarness([_host]);
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(boxOf('Host'));
          await tester.pump();
          h.setOutside('host', 'elsewhere.example.com');
          await tester.pumpAndSettle();
          await leaveBox(tester);
          expect(textIn(tester, 'Host'), 'elsewhere.example.com');
          expect(h.calls, isEmpty);
          expect(h.values['host'], 'elsewhere.example.com');
        },
      );

      testWidgets('an edit typed while an outside change waits still wins', (
        tester,
      ) async {
        final h = ConfigHarness([_host]);
        await pumpConfigForm(tester, h, size: size);
        await tester.tap(boxOf('Host'));
        await tester.pump();
        h.setOutside('host', 'elsewhere.example.com');
        await tester.pumpAndSettle();
        await tester.enterText(boxOf('Host'), 'mine.example.com');
        await leaveBox(tester);
        expect(h.calls, ['set:host="mine.example.com"']);
        expect(h.values['host'], 'mine.example.com');
      });

      testWidgets(
        'leaving the page with the box still focused saves the last edit',
        (tester) async {
          final h = ConfigHarness([_host]);
          await pumpConfigForm(tester, h, size: size);
          await tester.enterText(boxOf('Host'), 'last.example.com');
          await tester.pump();
          expect(h.calls, isEmpty);
          // The page goes away without the box ever losing focus first.
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
          expect(h.calls, ['set:host="last.example.com"']);
          expect(h.values['host'], 'last.example.com');
        },
      );

      testWidgets('a locked form cannot be edited', (tester) async {
        final h = ConfigHarness([_host]);
        await pumpConfigForm(tester, h, size: size, locked: true);
        expect(enabledBox(tester, 'Host'), isFalse);
      });
    });
  }

  testWidgets(
    'a write still in flight keeps its text over an older stored value',
    (tester) async {
      final h = ConfigHarness([_host]);
      final gate = Completer<void>();
      h.gate = gate.future;
      await pumpConfigForm(tester, h);
      await typeAndLeave(tester, 'Host', 'a.example.com');
      h.refresh();
      await tester.pump();
      expect(textIn(tester, 'Host'), 'a.example.com');
      gate.complete();
      await tester.pumpAndSettle();
      expect(h.values['host'], 'a.example.com');
    },
  );
}
