import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

/// A picker whose options can be removed and which has an "add" footer.
class _Case {
  final names = ValueNotifier(['a', 'b', 'c']);
  late final live = ValueNotifier(_state());
  String? removeError;
  SelectionActionResult added = const SelectionActionResult.stay();
  var adds = 0;
  Future<String?>? result;
  int? chosen;

  _Case() {
    names.addListener(() => live.value = _state());
  }

  SelectionPickerState<String> _state() => SelectionPickerState(
    selected: 'a',
    options: [
      for (final n in names.value)
        SelectionOption(
          value: n,
          title: Text(n),
          removeTooltip: n == 'a' ? null : 'Remove $n',
          onRemove: n == 'a'
              ? null
              : () async {
                  if (removeError != null) return removeError;
                  names.value = [...names.value]..remove(n);
                  return null;
                },
        ),
    ],
  );

  Widget opener() => Builder(
    builder: (context) => TextButton(
      onPressed: () => result = showSelectionPicker<String>(
        context,
        options: live.value.options,
        selected: 'a',
        live: live,
        title: const Text('Pick'),
        footerAction: SelectionPickerAction(
          label: 'Add model',
          onPressed: (_) async {
            adds++;
            return added;
          },
        ),
      ),
      child: const Text('open'),
    ),
  );
}

void main() {
  Future<_Case> open(WidgetTester tester, Size size) async {
    useWindow(tester, size);
    final c = _Case();
    await tester.pumpWidget(host(c.opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return c;
  }

  for (final size in const [Size(400, 800), Size(1400, 900)]) {
    group('live picker at ${size.width.toInt()}', () {
      testWidgets('remove keeps it open and redraws; others have no ✕', (
        tester,
      ) async {
        await open(tester, size);
        expect(byIconButton('Remove a'), findsNothing);
        expect(byIconButton('Remove b'), findsOneWidget);
        await tester.tap(byIconButton('Remove b'));
        await tester.pumpAndSettle();
        expect(find.text('Pick'), findsOneWidget, reason: 'still open');
        expect(find.text('b'), findsNothing);
        expect(find.text('c'), findsOneWidget);
        expect(byCheckState(KCheckState.on), findsOneWidget);
      });

      testWidgets('a refused removal shows its line, the row stays', (
        tester,
      ) async {
        final c = await open(tester, size);
        c.removeError = 'Could not remove';
        await tester.tap(byIconButton('Remove b'));
        await tester.pumpAndSettle();
        expect(find.text('Could not remove'), findsOneWidget);
        expect(find.text('b'), findsOneWidget);
      });

      testWidgets('choosing closes with the value', (tester) async {
        final c = await open(tester, size);
        await tester.tap(find.text('c'));
        await tester.pumpAndSettle();
        expect(find.text('Pick'), findsNothing);
        expect(await c.result, 'c');
      });

      testWidgets('footer action: stay, error, close', (tester) async {
        final c = await open(tester, size);
        await tester.tap(find.text('Add model'));
        await tester.pumpAndSettle();
        expect(c.adds, 1);
        expect(find.text('Pick'), findsOneWidget);

        c.added = const SelectionActionResult.error('At most 50');
        await tester.tap(find.text('Add model'));
        await tester.pumpAndSettle();
        expect(find.text('At most 50'), findsOneWidget);

        c.added = const SelectionActionResult.close();
        await tester.tap(find.text('Add model'));
        await tester.pumpAndSettle();
        expect(find.text('Pick'), findsNothing);
        expect(await c.result, isNull);
      });
    });
  }
}
