import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

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
    await tester.tap(find.byType(Switch));
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
    final sw = tester.widget<Switch>(find.byType(Switch));
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
}
