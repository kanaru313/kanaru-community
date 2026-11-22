import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/config_form_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/config_harness.dart';
import 'support/pump_form.dart';

const _two = SelectField(
  key: 'model',
  title: 'Model',
  custom: true,
  options: [
    ConfigOption(value: 'base', title: 'base'),
    ConfigOption(value: 'mine', title: 'mine'),
  ],
);
const _one = SelectField(
  key: 'model',
  title: 'Model',
  custom: true,
  options: [ConfigOption(value: 'mine', title: 'mine')],
);

Finder _byRemoveModel() => find.byWidgetPredicate(
  (w) => w is KIconButton && w.tooltip == 'Remove this model',
);

ConfigHarness _harness(SelectField field) => ConfigHarness(
  [field],
  values: {'model': 'mine'},
  own: {
    'model': {'mine'},
  },
);

void main() {
  for (final (shell, size) in [
    ('phone', phoneSize),
    ('desktop', desktopSize),
  ]) {
    group(shell, () {
      testWidgets('a removal waits for the pick still being saved', (
        tester,
      ) async {
        final h = _harness(_two);
        final gate = Completer<void>();
        h.gate = gate.future;
        await pumpConfigForm(tester, h, size: size);
        await tester.tap(find.text('mine'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('base'));
        await tester.pumpAndSettle();
        expect(h.calls, ['set:model="base"']);
        // Open again while the pick is in flight (the row still shows the
        // stored choice) and remove it.
        await tester.tap(find.text('mine'));
        await tester.pumpAndSettle();
        await tester.tap(_byRemoveModel());
        await tester.pump();
        expect(h.calls, ['set:model="base"'], reason: 'ordered after the pick');
        gate.complete();
        await tester.pumpAndSettle();
        expect(h.calls, ['set:model="base"', 'remove:model=mine']);
        expect(h.values['model'], 'base');
      });

      testWidgets('an add confirmed reaches the store though the row is gone', (
        tester,
      ) async {
        final h = _harness(_two);
        await pumpConfigForm(tester, h, size: size);
        await tester.tap(find.text('mine'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add model…'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.ancestor(
            of: find.text('Model name, exactly as the server expects it'),
            matching: find.byType(TextField),
          ),
          'llama3',
        );
        await tester.pump();
        // The form goes away (plugin removed) while the box is open.
        h.answer = const AsyncData<ConfigFormData?>(null);
        h.refresh();
        await tester.pump();
        await tester.tap(find.text('Add and choose'));
        await tester.pumpAndSettle();
        expect(h.calls, ['add:model=llama3']);
      });

      testWidgets('"No model" goes when a choice comes back from outside', (
        tester,
      ) async {
        final h = _harness(_one);
        await pumpConfigForm(tester, h, size: size);
        await tester.tap(find.text('mine'));
        await tester.pumpAndSettle();
        await tester.tap(_byRemoveModel());
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(2, 2));
        await tester.pumpAndSettle();
        expect(find.text('No model'), findsOneWidget);
        // A choice appears from outside, then the list empties again.
        await h.addChoice('id-demo', 'model', 'x');
        await tester.pumpAndSettle();
        expect(find.text('No model'), findsNothing);
        await h.removeChoice('id-demo', 'model', 'x');
        await tester.pumpAndSettle();
        expect(find.text('No model'), findsNothing);
        expect(find.text('Not chosen'), findsOneWidget);
      });
    });
  }
}
