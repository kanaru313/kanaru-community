import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/src/widgets/setup/setup_row_frame.dart';
import 'package:flutter/services.dart';
import 'package:kanaru_ui/src/widgets/k_focus_ring.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  testWidgets('a coming-soon frame shows its label and ignores taps', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(
      host(
        SetupRowFrame(
          title: const Text('Equalizer'),
          comingSoon: true,
          soonLabel: 'Sắp có',
          trailing: const Text('hidden'),
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('Sắp có'), findsOneWidget);
    expect(find.text('hidden'), findsNothing);
    await tester.tap(find.text('Equalizer'), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('an enabled frame taps and is not dimmed', (tester) async {
    useWindow(tester, const Size(400, 800));
    var taps = 0;
    await tester.pumpWidget(
      host(SetupRowFrame(title: const Text('Row'), onTap: () => taps++)),
    );
    await tester.tap(find.text('Row'));
    expect(taps, 1);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('a disabled frame is dimmed and reports disabled', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        SetupRowFrame(title: const Text('Row'), enabled: false, onTap: () {}),
      ),
    );
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
    expect(
      tester.getSemantics(find.text('Row')),
      matchesSemantics(label: 'Row', hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('keyboard focus shows the ring on a tappable row', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(SetupRowFrame(title: const Text('Row'), onTap: () {})),
    );
    expect(tester.widget<KFocusRing>(find.byType(KFocusRing)).visible, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.widget<KFocusRing>(find.byType(KFocusRing)).visible, isTrue);
  });

  group('long press and secondary tap', () {
    testWidgets('both run on the row; a trailing button keeps its own', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      var long = 0, secondary = 0, buttons = 0;
      await tester.pumpWidget(
        host(
          SetupRowFrame(
            title: const Text('Row'),
            onLongPress: () => long++,
            onSecondaryTap: () => secondary++,
            trailing: IconButton(
              onPressed: () => buttons++,
              icon: const Text('btn'),
            ),
          ),
        ),
      );
      await tester.longPress(find.text('Row'));
      expect(long, 1);
      await tester.tap(find.text('Row'), buttons: kSecondaryButton);
      expect(secondary, 1);
      await tester.longPress(find.text('btn'));
      expect(long, 1);
      await tester.tap(find.text('btn'), buttons: kSecondaryButton);
      expect(secondary, 1);
      await tester.tap(find.text('btn'));
      expect(buttons, 1);
    });

    testWidgets('the long-press label is a custom semantics action', (
      tester,
    ) async {
      useWindow(tester, const Size(400, 800));
      final handle = tester.ensureSemantics();
      var long = 0;
      await tester.pumpWidget(
        host(
          SetupRowFrame(
            title: const Text('Row'),
            onLongPress: () => long++,
            longPressLabel: 'Copy',
          ),
        ),
      );
      final data = tester.getSemantics(find.text('Row')).getSemanticsData();
      expect(
        data.customSemanticsActionIds!.map(
          (id) => CustomSemanticsAction.getAction(id)!.label,
        ),
        contains('Copy'),
      );
      handle.dispose();
    });
  });
}
