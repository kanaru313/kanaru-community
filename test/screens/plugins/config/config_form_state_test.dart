import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_values.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:material_ui/material_ui.dart';

import 'support/config_harness.dart';
import 'support/form_finders.dart';
import 'support/pump_form.dart';

const _mixed = <ConfigField>[
  InputField(key: 'a', title: 'Alpha', subtitle: 'A long note under the box'),
  InputField(
    key: 'b',
    title: 'Beta',
    format: InputFormat.number,
    defaultValue: 2,
    max: 5,
  ),
  ToggleField(key: 'c', title: 'Gamma', subtitle: 'Switch it'),
  SelectField(
    key: 'd',
    title: 'Delta',
    options: [
      ConfigOption(value: 'x', title: 'Ex'),
      ConfigOption(value: 'y', title: 'Why'),
    ],
    defaultValue: 'x',
  ),
  SelectField(
    key: 'e',
    title: 'Epsilon',
    format: SelectFormat.multiple,
    options: [
      ConfigOption(value: 'x', title: 'Ex'),
      ConfigOption(value: 'y', title: 'Why'),
    ],
  ),
  ListField(key: 'f', title: 'Zeta', placeholder: 'item'),
  MapField(key: 'g', title: 'Eta'),
];

void main() {
  for (final (shell, size) in [
    ('phone', phoneSize),
    ('desktop', desktopSize),
  ]) {
    group(shell, () {
      testWidgets('while the values are read the card is empty and 56 high', (
        tester,
      ) async {
        final h = ConfigHarness(_mixed)..answer = const AsyncLoading();
        await pumpConfigForm(tester, h, size: size, settle: false);
        expect(find.text('The plugin’s settings'), findsOneWidget);
        expect(find.text('Alpha'), findsNothing);
        final card = find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 56,
        );
        expect(card, findsOneWidget);
      });

      testWidgets('an unreadable store says so and Retry reads it again', (
        tester,
      ) async {
        var builds = 0;
        final h = ConfigHarness(_mixed)
          ..followsStore = true
          ..answer = AsyncError('db', StackTrace.empty);
        // The form's provider depends on the stored config, as the real one.
        await pumpConfigForm(
          tester,
          h,
          size: size,
          extra: [
            pluginConfigProvider.overrideWith((ref, id) {
              // The first read fails, the one after Retry works.
              return builds++ == 0
                  ? Stream<PluginConfigData>.error('db')
                  : Stream.value(const PluginConfigData());
            }),
          ],
        );
        expect(
          find.text('Couldn’t read the plugin’s settings'),
          findsOneWidget,
        );
        expect(find.text('Alpha'), findsNothing);
        final before = builds;
        h.answer = null;
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(builds, before + 1);
        expect(find.text('Alpha'), findsOneWidget);
      });

      testWidgets('every kind of field reads at 200 % text without overflow', (
        tester,
      ) async {
        final h = ConfigHarness(
          _mixed,
          values: {
            'f': ['one'],
            'g': {'k': 'v'},
          },
        );
        await pumpConfigForm(tester, h, size: size, textScale: 2);
        expect(tester.takeException(), isNull);
        expect(find.text('A long note under the box'), findsOneWidget);
      });

      testWidgets('a locked form dims and freezes every kind of field', (
        tester,
      ) async {
        final h = ConfigHarness(_mixed);
        await pumpConfigForm(tester, h, size: size, locked: true);
        expect(enabledBox(tester, 'Alpha'), isFalse);
        expect(enabledBox(tester, 'Beta'), isFalse);
        await tester.tap(find.text('Gamma'), warnIfMissed: false);
        await tester.tap(find.text('Delta'), warnIfMissed: false);
        await tester.tap(find.text('Ex').last, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(h.calls, isEmpty);
        expect(find.text('Why'), findsOneWidget);
      });

      testWidgets('with animations off nothing waits for a transition', (
        tester,
      ) async {
        final h = ConfigHarness(_mixed);
        await pumpConfigForm(tester, h, size: size, reduceMotion: true);
        await tester.tap(find.text('Gamma'));
        await tester.pump();
        await tester.pump();
        expect(h.calls, ['set:c=true']);
      });
    });
  }
}
