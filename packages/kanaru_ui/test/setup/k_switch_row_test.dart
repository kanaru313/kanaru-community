import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders without overflow ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(
          KSwitchRow(
            title: const Text(
              'A rather long title that has to wrap on a phone',
            ),
            subtitle: const Text('and a subtitle'),
            leading: const Icon(KIcons.folders),
            value: true,
            onChanged: (_) {},
          ),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tapping the switch or the row reports the new value', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final seen = <bool>[];
    await tester.pumpWidget(
      host(
        KSwitchRow(
          title: const Text('Albums'),
          value: false,
          onChanged: seen.add,
        ),
      ),
    );
    await tester.tap(find.byType(KSwitch));
    await tester.tap(find.text('Albums'));
    expect(seen, [true, true]);
  });

  testWidgets('onChanged null locks the row and says so', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const KSwitchRow(
          title: Text('Songs'),
          value: true,
          onChanged: null,
          lockedLabel: 'At least one tab stays on',
        ),
      ),
    );
    final sw = tester.widget<KSwitch>(find.byType(KSwitch));
    expect(sw.onChanged, isNull);
    await tester.tap(find.text('Songs'));
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(KSwitchRow)),
      matchesSemantics(
        label: 'Songs',
        hint: 'At least one tab stays on',
        hasEnabledState: true,
        hasToggledState: true,
        isToggled: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('rows are at least 56 dp tall on a phone', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(KSwitchRow(title: const Text('X'), value: true, onChanged: (_) {})),
    );
    expect(
      tester.getSize(find.byType(KSwitchRow)).height,
      greaterThanOrEqualTo(56),
    );
  });

  testWidgets('onTap replaces the row toggle; the switch still toggles', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final seen = <bool>[];
    var taps = 0;
    await tester.pumpWidget(
      host(
        KSwitchRow(
          title: const Text('Prompt'),
          value: false,
          onChanged: seen.add,
          onTap: () => taps++,
          tapSemanticsLabel: 'Prompt, open',
        ),
      ),
    );
    await tester.tap(find.text('Prompt'));
    expect(taps, 1);
    expect(seen, isEmpty);
    await tester.tap(find.byType(KSwitch));
    expect(taps, 1);
    expect(seen, [true]);
  });

  group('onTap semantics', () {
    Widget row({required ValueChanged<bool>? onChanged}) => KSwitchRow(
      title: const Text('Prompt'),
      value: true,
      onChanged: onChanged,
      onTap: () {},
      tapSemanticsLabel: 'Prompt, open',
      switchLabel: 'Turn on Prompt',
    );

    testWidgets('row is a button, the switch a separate toggled node', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(row(onChanged: (_) {})));
      expect(
        find.semantics.byPredicate((n) {
          final d = n.getSemanticsData();
          return d.label.contains('Prompt, open') &&
              d.hasAction(SemanticsAction.tap);
        }, describeMatch: (_) => 'row button "Prompt, open"'),
        findsOneWidget,
      );
      expect(byToggledState('Turn on Prompt'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('locked switch keeps the row button', (tester) async {
      useWindow(tester, const Size(400, 800));
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(row(onChanged: null)));
      expect(find.semantics.byLabel('Prompt, open'), findsOneWidget);
      final sw = tester.widget<KSwitch>(find.byType(KSwitch));
      expect(sw.onChanged, isNull);
      handle.dispose();
    });
  });
}
