import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

const _options = [
  SelectionOption(
    value: 'a',
    title: Text('Download'),
    subtitle: Text('Internal storage › Download · 18 songs'),
    leading: Icon(KIcons.folders),
  ),
  SelectionOption(
    value: 'b',
    title: Text('Telegram'),
    leading: Icon(KIcons.folders),
  ),
  SelectionOption(value: 'c', title: Text('Recordings')),
];

Widget _opener(
  void Function(Set<String>?) onResult, {
  List<SelectionOption<String>> options = _options,
  Set<String> initial = const {},
}) => Builder(
  builder: (context) => TextButton(
    onPressed: () async => onResult(
      await showMultiSelectionSheet<String>(
        context,
        options: options,
        initial: initial,
        title: const Text('Add music folders'),
        subtitle: const Text('Folders Android found with music.'),
        emptyNote: const Text('Every folder is chosen.'),
        confirmLabel: (n) => n == 0 ? 'Add' : 'Add $n',
        cancelLabel: 'Cancel',
      ),
    ),
    child: const Text('open'),
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders as a sheet without overflow ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(
        host(_opener((_) {}), brightness: brightness, textScale: scale),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(SelectionRow), findsNWidgets(3));
    });
  }

  testWidgets('toggling two rows gives "Add 2" and confirm returns both', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    Set<String>? result;
    var done = false;
    await tester.pumpWidget(
      host(
        _opener((r) {
          result = r;
          done = true;
        }),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Add'), findsOneWidget);
    await tester.tap(find.text('Download'));
    await tester.tap(find.text('Recordings'));
    await tester.pump();
    expect(find.text('Add 2'), findsOneWidget);
    await tester.tap(find.text('Add 2'));
    await tester.pumpAndSettle();
    expect(done, isTrue);
    expect(result, {'a', 'c'});
  });

  testWidgets('tapping a chosen row again unchooses it', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener((_) {})));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Telegram'));
    await tester.pump();
    expect(find.text('Add 1'), findsOneWidget);
    await tester.tap(find.text('Telegram'));
    await tester.pump();
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('confirm is off with nothing chosen', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener((_) {})));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('selected rows are tinted and checked', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener((_) {})));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pump();
    final rows = tester
        .widgetList<SelectionRow>(find.byType(SelectionRow))
        .toList();
    expect(rows.map((r) => r.selected), [true, false, false]);
  });

  testWidgets('initial choices are shown as chosen', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener((_) {}, initial: {'b'})));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Add 1'), findsOneWidget);
  });

  testWidgets('cancel returns null', (tester) async {
    useWindow(tester, const Size(400, 800));
    Set<String>? result = {'x'};
    await tester.pumpWidget(host(_opener((r) => result = r)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Back returns null', (tester) async {
    useWindow(tester, const Size(400, 800));
    Set<String>? result = {'x'};
    await tester.pumpWidget(host(_opener((r) => result = r)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    final observer =
        tester.state(find.byType(WidgetsApp)) as WidgetsBindingObserver;
    await observer.didPopRoute();
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('no options shows the note instead of rows', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener((_) {}, options: const [])));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Every folder is chosen.'), findsOneWidget);
    expect(find.byType(SelectionRow), findsNothing);
  });

  testWidgets('from 600 dp it is a dialog', (tester) async {
    useWindow(tester, const Size(900, 800));
    await tester.pumpWidget(host(_opener((_) {})));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
  });
}
