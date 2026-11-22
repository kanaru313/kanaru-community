import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _hostKey = ValueKey('host');

void main() {
  testWidgets('inline dot is 8 dp, error colour, silent', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const Center(child: KAlertDot())));
    expect(tester.getSize(find.byType(KAlertDot)), const Size(8, 8));
    final scheme = Theme.of(tester.element(find.byType(KAlertDot))).colorScheme;
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(KAlertDot),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, scheme.error);
    expect(
      find.descendant(
        of: find.byType(KAlertDot),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('corner dot: 12 dp plus 2 dp ring, centre 3 dp outside', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Center(
          child: KAlertDot.corner(
            child: SizedBox.square(key: _hostKey, dimension: 40),
          ),
        ),
      ),
    );
    final host0 = tester.getRect(find.byKey(_hostKey));
    final ring = tester.getRect(
      find.descendant(
        of: find.byType(KAlertDot),
        matching: find.byType(ExcludeSemantics),
      ),
    );
    expect(ring.size, const Size(16, 16));
    expect(ring.center.dx, host0.right + 3);
    expect(ring.center.dy, host0.top - 3);
  });

  testWidgets('corner dot moves to the top-left in right-to-left', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: KAlertDot.corner(
              child: SizedBox.square(key: _hostKey, dimension: 40),
            ),
          ),
        ),
      ),
    );
    final host0 = tester.getRect(find.byKey(_hostKey));
    final ring = tester.getRect(
      find.descendant(
        of: find.byType(KAlertDot),
        matching: find.byType(ExcludeSemantics),
      ),
    );
    expect(ring.center.dx, host0.left - 3);
  });
}
