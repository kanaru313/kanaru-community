import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
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
  bool selectAll = false,
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
        selectAllLabel: selectAll ? 'Select all' : null,
        selectedCountLabel: selectAll ? (n, t) => '$n / $t folders' : null,
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

  group('select all', () {
    Future<void> open(
      WidgetTester tester, {
      List<SelectionOption<String>> options = _options,
      Set<String> initial = const {},
      void Function(Set<String>?)? onResult,
    }) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          _opener(
            onResult ?? (_) {},
            options: options,
            initial: initial,
            selectAll: true,
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    SelectionRow allRow(WidgetTester tester) =>
        tester.widget<SelectionRow>(find.byType(SelectionRow).first);

    testWidgets('off, partial, on follow the chosen options', (tester) async {
      await open(tester);
      expect(find.byType(SelectionRow), findsNWidgets(4));
      expect(find.text('0 / 3 folders'), findsOneWidget);
      expect(allRow(tester).selected, isFalse);
      await tester.tap(find.text('Download'));
      await tester.pump();
      expect(find.text('1 / 3 folders'), findsOneWidget);
      expect(allRow(tester).selected, isTrue);
      expect(allRow(tester).partial, isTrue);
      await tester.tap(find.text('Telegram'));
      await tester.tap(find.text('Recordings'));
      await tester.pump();
      expect(allRow(tester).partial, isFalse);
      expect(allRow(tester).selected, isTrue);
    });

    testWidgets('tap chooses all, tap again clears', (tester) async {
      await open(tester, initial: {'a'});
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(find.text('Add 3'), findsOneWidget);
      expect(byCheckState(KCheckState.on), findsNWidgets(4));
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(find.text('Add'), findsOneWidget);
      expect(byCheckState(KCheckState.off), findsNWidgets(4));
    });

    testWidgets('ignores disabled options', (tester) async {
      Set<String>? result;
      await open(
        tester,
        onResult: (r) => result = r,
        options: const [
          SelectionOption(value: 'a', title: Text('A')),
          SelectionOption(value: 'b', title: Text('B')),
          SelectionOption(value: 'c', title: Text('C'), enabled: false),
        ],
      );
      expect(find.text('0 / 2 folders'), findsOneWidget);
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(allRow(tester).partial, isFalse);
      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();
      expect(result, {'a', 'b'});
    });

    testWidgets('hidden with fewer than two enabled options', (tester) async {
      await open(
        tester,
        options: const [
          SelectionOption(value: 'a', title: Text('A')),
          SelectionOption(value: 'b', title: Text('B'), enabled: false),
        ],
      );
      expect(find.text('Select all'), findsNothing);
      expect(find.byType(SelectionRow), findsNWidgets(2));
    });

    testWidgets('semantics: mixed when partial', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, initial: {'a'});
      expect(
        tester.getSemantics(find.byType(SelectionRow).first),
        isSemantics(hasCheckedState: true, isCheckStateMixed: true),
      );
      handle.dispose();
    });

    testWidgets('icon options: select-all is a plain tick on the right', (
      tester,
    ) async {
      await open(
        tester,
        options: const [
          SelectionOption(
            value: 'a',
            title: Text('A'),
            leading: Icon(KIcons.folders),
          ),
          SelectionOption(
            value: 'b',
            title: Text('B'),
            leading: Icon(KIcons.folders),
          ),
        ],
      );
      final all = find.ancestor(
        of: find.text('Select all'),
        matching: find.byType(SelectionRow),
      );
      final mark = find.descendant(of: all, matching: find.byType(KCheckMark));
      expect(tester.widget<KCheckMark>(mark).style, KCheckMarkStyle.plain);
      expect(
        tester.getRect(mark).left,
        greaterThan(tester.getRect(find.text('Select all')).right),
      );
    });

    testWidgets('options without an icon: select-all mark at the start', (
      tester,
    ) async {
      await open(tester); // mixed: one option has no icon
      final all = find.ancestor(
        of: find.text('Select all'),
        matching: find.byType(SelectionRow),
      );
      final mark = find.descendant(of: all, matching: find.byType(KCheckMark));
      expect(tester.widget<KCheckMark>(mark).style, KCheckMarkStyle.surface);
      expect(
        tester.getRect(mark).right,
        lessThanOrEqualTo(tester.getRect(find.text('Select all')).left),
      );
    });
  });
}
