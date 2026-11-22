import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/config_form_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/config_harness.dart';
import 'support/form_finders.dart';
import 'support/pump_form.dart';

const _keys = ListField(
  key: 'keys',
  title: 'API keys',
  subtitle: 'One per row',
  required: true,
  placeholder: 'sk-…',
  maxItems: 3,
);
const _mirrors = ListField(
  key: 'mirrors',
  title: 'Mirrors',
  format: ListFormat.url,
  placeholder: 'https://…',
);
const _names = MapField(key: 'names', title: 'Artist names', maxItems: 2);

Finder _boxes() => find.byType(TextField);

TextField _box(WidgetTester tester, int i) =>
    tester.widget<TextField>(_boxes().at(i));

Finder _removeRow() =>
    find.byWidgetPredicate((w) => w is KIconButton && w.tooltip == 'Remove');

Future<void> _type(WidgetTester tester, int i, String text) async {
  await tester.enterText(_boxes().at(i), text);
  await tester.pump();
}

/// The box has the error outline (no error line of its own).
bool _red(WidgetTester tester, int i) {
  final border = _box(tester, i).decoration?.enabledBorder;
  final error = Theme.of(tester.element(_boxes().at(i))).colorScheme.error;
  return border is OutlineInputBorder && border.borderSide.color == error;
}

void main() {
  for (final (shell, size) in [
    ('phone', phoneSize),
    ('desktop', desktopSize),
  ]) {
    group(shell, () {
      testWidgets('a list shows its items; a row saves when left, in order', (
        tester,
      ) async {
        final h = ConfigHarness(
          [_keys],
          values: {
            'keys': ['a', 'b'],
          },
        );
        await pumpConfigForm(tester, h, size: size);
        expect(find.text('One per row'), findsOneWidget);
        expect(_box(tester, 0).controller!.text, 'a');
        expect(_box(tester, 1).controller!.text, 'b');
        await _type(tester, 1, 'bb');
        expect(h.calls, isEmpty);
        await leaveBox(tester);
        expect(h.calls, ['set:keys=["a","bb"]']);
      });

      testWidgets(
        'Add makes a blank row, blank rows are not items, delete saves at once',
        (tester) async {
          final h = ConfigHarness(
            [_keys],
            values: {
              'keys': ['a'],
            },
          );
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(find.text('Add'));
          await tester.pumpAndSettle();
          expect(_boxes(), findsNWidgets(2));
          await leaveBox(tester);
          expect(h.calls, isEmpty);
          await tester.tap(_removeRow().first);
          await tester.pumpAndSettle();
          expect(h.calls, ['set:keys=[]']);
        },
      );

      testWidgets('Add is off at the maximum', (tester) async {
        final h = ConfigHarness(
          [_keys],
          values: {
            'keys': ['a', 'b', 'c'],
          },
        );
        await pumpConfigForm(tester, h, size: size);
        final add = find.widgetWithText(TextButton, 'Add');
        expect(tester.widget<TextButton>(add).onPressed, isNull);
      });

      testWidgets(
        'a required list emptied is stored empty and says it is required',
        (tester) async {
          final h = ConfigHarness(
            [_keys],
            values: {
              'keys': ['a'],
            },
          );
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(_removeRow());
          await tester.pumpAndSettle();
          expect(h.calls, ['set:keys=[]']);
          expect(find.text('This setting is required'), findsOneWidget);
        },
      );

      testWidgets(
        'a bad item gets the red outline and one line under the list, nothing is sent',
        (tester) async {
          final h = ConfigHarness(
            [_mirrors],
            values: {
              'mirrors': ['https://a.example.com'],
            },
          );
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(find.text('Add'));
          await tester.pumpAndSettle();
          await _type(tester, 1, 'http://b.example.com');
          await leaveBox(tester);
          expect(find.text('One of the items is not valid'), findsOneWidget);
          expect(_red(tester, 1), isTrue);
          expect(_red(tester, 0), isFalse);
          expect(h.calls, isEmpty);
          // Fixing it saves the whole list and takes the line away.
          await _type(tester, 1, 'https://b.example.com');
          await leaveBox(tester);
          expect(find.text('One of the items is not valid'), findsNothing);
          expect(h.calls, [
            'set:mirrors=["https://a.example.com","https://b.example.com"]',
          ]);
        },
      );

      testWidgets('a refused list says why under it', (tester) async {
        final h = ConfigHarness(
          [_keys],
          values: {
            'keys': ['a'],
          },
        );
        h.refusals['keys'] = ConfigWrite.tooLarge;
        await pumpConfigForm(tester, h, size: size);
        await _type(tester, 0, 'aa');
        await leaveBox(tester);
        expect(
          find.text('The plugin’s settings are too large to save.'),
          findsOneWidget,
        );
      });

      testWidgets('a map saves its rows as a table', (tester) async {
        final h = ConfigHarness(
          [_names],
          values: {
            'names': {'Sơn Tùng': 'SMTP'},
          },
        );
        await pumpConfigForm(tester, h, size: size);
        expect(_box(tester, 0).controller!.text, 'Sơn Tùng');
        expect(_box(tester, 1).controller!.text, 'SMTP');
        await _type(tester, 1, 'M-TP');
        await leaveBox(tester);
        expect(h.calls, ['set:names={"Sơn Tùng":"M-TP"}']);
      });

      testWidgets(
        'a repeated or padded name is told under its row and nothing is saved',
        (tester) async {
          final h = ConfigHarness(
            [_names],
            values: {
              'names': {'a': '1'},
            },
          );
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(find.text('Add'));
          await tester.pumpAndSettle();
          await _type(tester, 2, 'a');
          await _type(tester, 3, '2');
          await leaveBox(tester);
          expect(
            find.text('Another row already uses this name'),
            findsOneWidget,
          );
          expect(h.calls, isEmpty);
          await _type(tester, 2, ' b');
          await leaveBox(tester);
          expect(
            find.text(
              'Enter a name of 1 to 100 characters with no space at either end',
            ),
            findsOneWidget,
          );
          expect(h.calls, isEmpty);
          await _type(tester, 2, 'b');
          await leaveBox(tester);
          expect(h.calls, ['set:names={"a":"1","b":"2"}']);
        },
      );

      testWidgets('a locked list and table cannot be edited', (tester) async {
        final h = ConfigHarness(
          [_keys, _names],
          values: {
            'keys': ['a'],
          },
        );
        await pumpConfigForm(tester, h, size: size, locked: true);
        expect(_box(tester, 0).enabled, isFalse);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'Add').first)
              .onPressed,
          isNull,
        );
      });
    });
  }
}
