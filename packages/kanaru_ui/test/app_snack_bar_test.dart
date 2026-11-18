import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _opener({
  required VoidCallback onAction,
  required VoidCallback onClosed,
  bool viaMessenger = false,
}) => Builder(
  builder: (context) => Column(
    children: [
      TextButton(
        onPressed: () => viaMessenger
            ? showAppSnackBarOn(
                ScaffoldMessenger.of(context),
                'Removed',
                actionLabel: 'Undo',
                onAction: onAction,
                onClosedWithoutAction: onClosed,
              )
            : showAppSnackBar(
                context,
                'Removed',
                actionLabel: 'Undo',
                onAction: onAction,
                onClosedWithoutAction: onClosed,
              ),
        child: const Text('go'),
      ),
      TextButton(
        onPressed: () => showAppSnackBar(context, 'other'),
        child: const Text('other'),
      ),
    ],
  ),
);

void main() {
  for (final viaMessenger in [false, true]) {
    final via = viaMessenger ? 'showAppSnackBarOn' : 'showAppSnackBar';

    testWidgets('$via: closing on timeout fires onClosedWithoutAction', (
      tester,
    ) async {
      var action = 0, closed = 0;
      await tester.pumpWidget(
        host(
          _opener(
            onAction: () => action++,
            onClosed: () => closed++,
            viaMessenger: viaMessenger,
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(closed, 0, reason: 'still showing');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(closed, 1);
      expect(action, 0);
    });

    testWidgets('$via: the action does not fire it', (tester) async {
      var action = 0, closed = 0;
      await tester.pumpWidget(
        host(
          _opener(
            onAction: () => action++,
            onClosed: () => closed++,
            viaMessenger: viaMessenger,
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(action, 1);
      expect(closed, 0);
    });

    testWidgets('$via: being replaced by another snack bar fires it', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        host(
          _opener(
            onAction: () {},
            onClosed: () => closed++,
            viaMessenger: viaMessenger,
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('other'));
      await tester.pumpAndSettle();
      expect(closed, 1);
    });
  }
}
