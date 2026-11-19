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

  group('options that change while open', () {
    const two = [
      SelectionOption(value: 'a', title: Text('Download')),
      SelectionOption(value: 'b', title: Text('Telegram')),
    ];

    /// Opens the sheet over a [ValueNotifier] so a test can swap the options
    /// and the suggested picks the way a reloading list does.
    Future<
      ({
        ValueNotifier<(List<SelectionOption<String>>, Set<String>)> config,
        List<Set<String>?> results,
      })
    >
    open(
      WidgetTester tester, {
      required List<SelectionOption<String>> options,
      Set<String> initial = const {},
      Widget? banner,
      Widget? footerNote,
    }) async {
      useWindow(tester, const Size(400, 800));
      final config = ValueNotifier((options, initial));
      addTearDown(config.dispose);
      final results = <Set<String>?>[];
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showKSheet<Set<String>>(
                  context,
                  builder: (_) => ValueListenableBuilder(
                    valueListenable: config,
                    builder: (_, value, _) => MultiSelectionSheet<String>(
                      options: value.$1,
                      initial: value.$2,
                      title: const Text('Add music folders'),
                      emptyNote: const Text('Every folder is chosen.'),
                      banner: banner,
                      footerNote: footerNote,
                      confirmLabel: (n) => n == 0 ? 'Add' : 'Add $n',
                      cancelLabel: 'Cancel',
                      selectAllLabel: 'Select all',
                      selectedCountLabel: (n, t) => '$n / $t folders',
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return (config: config, results: results);
    }

    testWidgets('options 0 to 2 turn the empty note into rows', (tester) async {
      final h = await open(tester, options: const []);
      expect(find.text('Every folder is chosen.'), findsOneWidget);
      expect(find.byType(SelectionRow), findsNothing);
      h.config.value = (two, const <String>{});
      await tester.pump();
      expect(find.text('Every folder is chosen.'), findsNothing);
      expect(find.text('Download'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('0 / 2 folders'), findsOneWidget);
    });

    testWidgets('a pick survives a reload frame with no options', (
      tester,
    ) async {
      final h = await open(tester, options: two);
      await tester.tap(find.text('Download'));
      await tester.pump();
      expect(find.text('Add 1'), findsOneWidget);
      h.config.value = (const [], const <String>{});
      await tester.pump();
      expect(find.byType(SelectionRow), findsNothing);
      // Nothing with an option is chosen, so nothing can be confirmed.
      expect(find.text('Add'), findsOneWidget);
      h.config.value = (two, const <String>{});
      await tester.pump();
      expect(find.text('Add 1'), findsOneWidget);
      expect(
        tester
            .widgetList<SelectionRow>(find.byType(SelectionRow))
            .map((r) => r.selected),
        [true, true, false],
      );
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(h.results.single, {'a'});
    });

    testWidgets('a pick whose option is gone is neither counted nor returned', (
      tester,
    ) async {
      final h = await open(tester, options: two);
      await tester.tap(find.text('Download'));
      await tester.tap(find.text('Telegram'));
      await tester.pump();
      expect(find.text('Add 2'), findsOneWidget);
      h.config.value = ([two.last], const <String>{});
      await tester.pump();
      expect(find.text('Add 1'), findsOneWidget);
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(h.results.single, {'b'});
    });

    testWidgets('a value new to initial is chosen once and can be unticked', (
      tester,
    ) async {
      final h = await open(tester, options: two);
      expect(find.text('Add'), findsOneWidget);
      h.config.value = (two, const {'a'});
      await tester.pump();
      expect(find.text('Add 1'), findsOneWidget);
      // Same initial again (a rebuild) does not re-tick it after the user
      // cleared it.
      await tester.tap(find.text('Download'));
      await tester.pump();
      expect(find.text('Add'), findsOneWidget);
      h.config.value = (List.of(two), const {'a'});
      await tester.pump();
      expect(find.text('Add'), findsOneWidget);
      expect(
        tester
            .widgetList<SelectionRow>(find.byType(SelectionRow))
            .map((r) => r.selected),
        [false, false, false],
      );
    });

    testWidgets('banner is above the rows and footerNote after them', (
      tester,
    ) async {
      await open(
        tester,
        options: two,
        banner: const Text('Rescanned'),
        footerNote: const Text('Missing a folder?'),
      );
      final banner = tester.getRect(find.text('Rescanned'));
      final first = tester.getRect(find.text('Select all'));
      final last = tester.getRect(find.text('Telegram'));
      final foot = tester.getRect(find.text('Missing a folder?'));
      expect(banner.bottom, lessThanOrEqualTo(first.top));
      expect(foot.top, greaterThanOrEqualTo(last.bottom));
    });

    testWidgets('footerNote also follows the empty note', (tester) async {
      await open(
        tester,
        options: const [],
        footerNote: const Text('Missing a folder?'),
      );
      expect(
        tester.getRect(find.text('Missing a folder?')).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text('Every folder is chosen.')).bottom,
        ),
      );
    });
  });

  group('minimum selected', () {
    Future<void> open(
      WidgetTester tester, {
      Set<String> initial = const {'a'},
      int minSelected = 1,
      void Function(Set<String>?)? onResult,
    }) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => (onResult ?? (_) {})(
                await showMultiSelectionSheet<String>(
                  context,
                  options: const [
                    SelectionOption(value: 'a', title: Text('A')),
                    SelectionOption(
                      value: 'b',
                      title: Text('B'),
                      subtitle: Text('b detail'),
                    ),
                    SelectionOption(value: 'c', title: Text('C')),
                  ],
                  initial: initial,
                  title: const Text('Formats'),
                  confirmLabel: (n) => 'Save $n',
                  cancelLabel: 'Cancel',
                  selectAllLabel: 'Select all',
                  selectedCountLabel: (n, t) => '$n / $t',
                  minSelected: minSelected,
                  minSelectedNote: 'Keep at least one',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    SelectionRow row(WidgetTester tester, String title) =>
        tester.widget<SelectionRow>(
          find.ancestor(
            of: find.text(title),
            matching: find.byType(SelectionRow),
          ),
        );

    testWidgets('the last chosen row is locked and says why', (tester) async {
      await open(tester);
      expect(row(tester, 'A').enabled, isFalse);
      expect(row(tester, 'A').selected, isTrue);
      expect(find.text('Keep at least one'), findsOneWidget);
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(find.text('1 / 3'), findsOneWidget);
      expect(row(tester, 'A').selected, isTrue);
    });

    testWidgets('a second pick unlocks every row, the note goes', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(row(tester, 'A').enabled, isTrue);
      expect(row(tester, 'B').enabled, isTrue);
      expect(find.text('Keep at least one'), findsNothing);
      // The note keeps the row's own subtitle when it locks again.
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(row(tester, 'B').enabled, isFalse);
      expect(find.text('b detail · Keep at least one'), findsOneWidget);
    });

    testWidgets('select all is off only once everything is chosen', (
      tester,
    ) async {
      await open(tester);
      expect(row(tester, 'Select all').enabled, isTrue);
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(find.text('3 / 3'), findsOneWidget);
      expect(row(tester, 'Select all').enabled, isFalse);
      await tester.tap(find.text('Select all'));
      await tester.pump();
      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('without a minimum nothing locks (default)', (tester) async {
      await open(tester, minSelected: 0);
      expect(row(tester, 'A').enabled, isTrue);
      await tester.tap(find.text('A'));
      await tester.pump();
      expect(find.text('0 / 3'), findsOneWidget);
    });

    testWidgets('confirm returns the kept picks', (tester) async {
      Set<String>? result;
      await open(tester, onResult: (r) => result = r);
      await tester.tap(find.text('C'));
      await tester.pump();
      await tester.tap(find.text('Save 2'));
      await tester.pumpAndSettle();
      expect(result, {'a', 'c'});
    });
  });

  group('live mode', () {
    testWidgets('reports each tap and has no footer buttons', (tester) async {
      useWindow(tester, const Size(400, 800));
      final seen = <Set<String>>[];
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showMultiSelectionSheet<String>(
                context,
                options: const [
                  SelectionOption(value: 'a', title: Text('A')),
                  SelectionOption(value: 'b', title: Text('B')),
                ],
                initial: const {'a'},
                title: const Text('Formats'),
                minSelected: 1,
                minSelectedNote: 'Keep at least one',
                onChanged: seen.add,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      // The locked last row ignores a tap and reports nothing.
      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'));
      await tester.pump();
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(seen, [
        {'a', 'b'},
        {'a'},
      ]);
    });
  });
}
