import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/config_form_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/config_harness.dart';
import 'support/pump_form.dart';

const _stream = ToggleField(
  key: 'stream',
  title: 'Stream replies',
  subtitle: 'Show the text as it arrives',
  defaultValue: true,
);
const _style = SelectField(
  key: 'style',
  title: 'Style',
  subtitle: 'How the text reads',
  required: true,
  options: [
    ConfigOption(value: 'plain', title: 'Plain', subtitle: 'No decoration'),
    ConfigOption(value: 'poetic', title: 'Poetic'),
  ],
  defaultValue: 'plain',
);
const _model = SelectField(
  key: 'model',
  title: 'Model',
  subtitle: 'The model the server runs',
  required: true,
  custom: true,
  options: [ConfigOption(value: 'base', title: 'base')],
);
const _noModels = SelectField(
  key: 'model',
  title: 'Model',
  required: true,
  custom: true,
);
const _langs = SelectField(
  key: 'langs',
  title: 'Languages',
  subtitle: 'Pick the ones you read',
  format: SelectFormat.multiple,
  minItems: 1,
  maxItems: 2,
  options: [
    ConfigOption(value: 'vi', title: 'Vietnamese', subtitle: 'Tiếng Việt'),
    ConfigOption(value: 'en', title: 'English'),
    ConfigOption(value: 'ja', title: 'Japanese'),
  ],
  defaultValue: ['vi'],
);

Finder _chip(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(KChip));

bool _chipOn(WidgetTester tester, String title) =>
    tester.widget<KChip>(_chip(title)).selected;

bool _chipEnabled(WidgetTester tester, String title) =>
    tester.widget<KChip>(_chip(title)).enabled;

void main() {
  for (final (shell, size) in [
    ('phone', phoneSize),
    ('desktop', desktopSize),
  ]) {
    group(shell, () {
      testWidgets('a toggle shows its default and saves at once', (
        tester,
      ) async {
        final h = ConfigHarness([_stream]);
        await pumpConfigForm(tester, h, size: size);
        expect(find.text('Show the text as it arrives'), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(KSwitch)),
          isSemantics(hasToggledState: true, isToggled: true),
        );
        await tester.tap(find.text('Stream replies'));
        await tester.pumpAndSettle();
        expect(h.calls, ['set:stream=false']);
        expect(
          tester.getSemantics(find.byType(KSwitch)),
          isSemantics(hasToggledState: true, isToggled: false),
        );
      });

      testWidgets(
        'a refused toggle goes back to the stored value and says why',
        (tester) async {
          final h = ConfigHarness([_stream]);
          h.refusals['stream'] = ConfigWrite.failed;
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(find.text('Stream replies'));
          await tester.pumpAndSettle();
          expect(
            find.text('Couldn’t save the setting (try again later)'),
            findsOneWidget,
          );
          expect(
            tester.getSemantics(find.byType(KSwitch)),
            isSemantics(hasToggledState: true, isToggled: true),
          );
          expect(h.values, isEmpty);
        },
      );

      testWidgets('a single select shows the chosen option, picks and saves', (
        tester,
      ) async {
        final h = ConfigHarness([_style]);
        await pumpConfigForm(tester, h, size: size);
        expect(find.text('Plain'), findsOneWidget);
        // The field's own note is the picker's caption, not on the row.
        expect(find.text('How the text reads'), findsNothing);
        await tester.tap(find.text('Style *'));
        await tester.pumpAndSettle();
        expect(find.text('How the text reads'), findsOneWidget);
        expect(find.text('No decoration'), findsOneWidget);
        await tester.tap(find.text('Poetic'));
        await tester.pumpAndSettle();
        expect(h.calls, ['set:style="poetic"']);
        expect(find.text('Poetic'), findsOneWidget);
        expect(find.text('No decoration'), findsNothing);
      });

      testWidgets('choosing what is already chosen saves nothing', (
        tester,
      ) async {
        final h = ConfigHarness([_style]);
        await pumpConfigForm(tester, h, size: size);
        await tester.tap(find.text('Style *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('No decoration'));
        await tester.pumpAndSettle();
        expect(h.calls, isEmpty);
      });

      testWidgets('a refused pick leaves the stored choice and says why', (
        tester,
      ) async {
        final h = ConfigHarness([_style], values: {'style': 'plain'});
        h.refusals['style'] = ConfigWrite.invalidValue;
        await pumpConfigForm(tester, h, size: size);
        await tester.tap(find.text('Style *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Poetic'));
        await tester.pumpAndSettle();
        expect(
          find.text('This setting doesn’t accept that value.'),
          findsOneWidget,
        );
        expect(find.text('Plain'), findsOneWidget);
      });

      testWidgets('a locked select cannot be opened', (tester) async {
        final h = ConfigHarness([_style, _stream]);
        await pumpConfigForm(tester, h, size: size, locked: true);
        await tester.tap(find.text('Style *'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Poetic'), findsNothing);
        await tester.tap(find.text('Stream replies'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(h.calls, isEmpty);
      });

      testWidgets(
        'custom: add a model, it is chosen and marked "Added by you"',
        (tester) async {
          final h = ConfigHarness([_model], values: {'model': 'base'});
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(find.text('Model *'));
          await tester.pumpAndSettle();
          expect(find.text('The model the server runs'), findsOneWidget);
          await tester.tap(find.text('Add model…'));
          await tester.pumpAndSettle();
          final add = find.widgetWithText(FilledButton, 'Add and choose');
          expect(tester.widget<FilledButton>(add).onPressed, isNull);
          await tester.enterText(
            find.ancestor(
              of: find.text('Model name, exactly as the server expects it'),
              matching: find.byType(TextField),
            ),
            'llama3',
          );
          await tester.enterText(
            find.ancestor(
              of: find.text('Note (optional), for example: Ollama at home'),
              matching: find.byType(TextField),
            ),
            'Ollama at home',
          );
          await tester.pump();
          expect(tester.widget<FilledButton>(add).onPressed, isNotNull);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(h.calls, ['add:model=llama3']);
          expect(h.values['model'], 'llama3');
          // The picker closed; the row says which and that the user added it.
          expect(find.text('llama3'), findsOneWidget);
          expect(find.text('Added by you'), findsOneWidget);
          expect(find.text('Add model…'), findsNothing);
        },
      );

      testWidgets('custom: the box can be cancelled', (tester) async {
        final h = ConfigHarness([_model]);
        await pumpConfigForm(tester, h, size: size);
        await tester.tap(find.text('Model *'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add model…'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(h.calls, isEmpty);
        // The picker is still there.
        expect(find.text('Add model…'), findsOneWidget);
      });

      testWidgets(
        'custom: removing the chosen one picks the first left, the picker stays open',
        (tester) async {
          final h = ConfigHarness(
            [
              const SelectField(
                key: 'model',
                title: 'Model',
                custom: true,
                options: [
                  ConfigOption(value: 'base', title: 'base'),
                  ConfigOption(value: 'mine', title: 'mine'),
                ],
              ),
            ],
            values: {'model': 'mine'},
            own: {
              'model': {'mine'},
            },
          );
          await pumpConfigForm(tester, h, size: size);
          expect(find.text('Added by you'), findsOneWidget);
          await tester.tap(find.text('mine'));
          await tester.pumpAndSettle();
          await tester.tap(byRemoveModel());
          await tester.pumpAndSettle();
          expect(h.calls, ['remove:model=mine']);
          expect(h.values['model'], 'base');
          // Open still, with one row left and no ✕ (it is the plugin's own).
          expect(find.text('Add model…'), findsOneWidget);
          expect(byRemoveModel(), findsNothing);
        },
      );

      testWidgets(
        'custom: a fresh install with no model says "Not chosen" and nothing red',
        (tester) async {
          final fresh = ConfigHarness([_noModels]);
          await pumpConfigForm(tester, fresh, size: size);
          expect(find.text('Not chosen'), findsOneWidget);
          expect(find.text('No model'), findsNothing);
          await tester.tap(find.text('Model *'));
          await tester.pumpAndSettle();
          expect(find.text('No model'), findsNothing);
        },
      );

      testWidgets(
        'custom: deleting every model says "No model" under the row',
        (tester) async {
          final h = ConfigHarness(
            [
              const SelectField(
                key: 'model',
                title: 'Model',
                custom: true,
                options: [ConfigOption(value: 'mine', title: 'mine')],
              ),
            ],
            values: {'model': 'mine'},
            own: {
              'model': {'mine'},
            },
          );
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(find.text('mine'));
          await tester.pumpAndSettle();
          await tester.tap(byRemoveModel());
          await tester.pumpAndSettle();
          await tester.tapAt(const Offset(2, 2));
          await tester.pumpAndSettle();
          expect(find.text('Not chosen'), findsOneWidget);
          expect(find.text('No model'), findsOneWidget);
          expect(h.values.containsKey('model'), isFalse);
        },
      );

      testWidgets(
        'custom: a model beyond 50 choices is refused with a line in the picker',
        (tester) async {
          final h = ConfigHarness([
            SelectField(
              key: 'model',
              title: 'Model',
              custom: true,
              options: [
                for (var i = 0; i < 50; i++)
                  ConfigOption(value: 'm$i', title: 'm$i'),
              ],
            ),
          ]);
          await pumpConfigForm(tester, h, size: size);
          await tester.tap(find.text('Model'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Add model…'));
          await tester.pumpAndSettle();
          expect(find.text('At most 50 items'), findsOneWidget);
          expect(h.calls, isEmpty);
        },
      );

      testWidgets('chips: chosen are tinted, a tap saves in manifest order', (
        tester,
      ) async {
        final h = ConfigHarness([_langs]);
        await pumpConfigForm(tester, h, size: size);
        expect(_chipOn(tester, 'Vietnamese'), isTrue);
        expect(_chipOn(tester, 'English'), isFalse);
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        expect(h.calls, ['set:langs=["vi","en"]']);
        expect(_chipOn(tester, 'English'), isTrue);
      });

      testWidgets(
        'chips: at the maximum the rest are dimmed and "At most 2" says why',
        (tester) async {
          final h = ConfigHarness(
            [_langs],
            values: {
              'langs': ['vi', 'en'],
            },
          );
          await pumpConfigForm(tester, h, size: size);
          expect(_chipEnabled(tester, 'Japanese'), isFalse);
          expect(_chipEnabled(tester, 'English'), isTrue);
          expect(find.text('At most 2'), findsOneWidget);
          await tester.tap(find.text('Japanese'), warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(h.calls, isEmpty);
          // Taking one off frees the rest.
          await tester.tap(find.text('English'));
          await tester.pumpAndSettle();
          expect(find.text('At most 2'), findsNothing);
          expect(_chipEnabled(tester, 'Japanese'), isTrue);
        },
      );

      testWidgets(
        'chips: below the minimum is not saved and the line says so',
        (tester) async {
          final h = ConfigHarness(
            [_langs],
            values: {
              'langs': ['vi'],
            },
          );
          await pumpConfigForm(tester, h, size: size);
          expect(find.text('Choose or add at least 1 items'), findsNothing);
          await tester.tap(find.text('Vietnamese'));
          await tester.pumpAndSettle();
          expect(h.calls, isEmpty);
          expect(_chipOn(tester, 'Vietnamese'), isFalse);
          expect(find.text('Choose or add at least 1 items'), findsOneWidget);
        },
      );

      testWidgets('chips: a refused pick goes back to the stored choice', (
        tester,
      ) async {
        final h = ConfigHarness([_langs]);
        h.refusals['langs'] = ConfigWrite.invalidValue;
        await pumpConfigForm(tester, h, size: size);
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        expect(_chipOn(tester, 'English'), isFalse);
        expect(
          find.text('This setting doesn’t accept that value.'),
          findsOneWidget,
        );
      });
    });
  }
}

Finder byRemoveModel() => find.byWidgetPredicate(
  (w) => w is KIconButton && w.tooltip == 'Remove this model',
);
