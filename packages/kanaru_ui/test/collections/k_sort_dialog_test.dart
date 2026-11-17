import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'package:kanaru_ui/src/widgets/collections/k_sort_dialog_rows.dart'
    show SortSectionHeader;

import '../support/finders.dart';
import '../support/host.dart';
import '../support/scaled_host.dart';

const _strings = KSortDialogStrings(
  title: 'Sort by',
  chosen: 'Chosen',
  notChosen: 'Not chosen',
  reset: 'Reset',
  done: 'Done',
  dragHint: _drag,
  flipTooltip: _flipTip,
  flipSemantics: _flipSem,
  remove: _remove,
  add: _add,
);
String _drag(String l) => 'Drag $l';
String _flipTip(String w) => 'Switch to $w';
String _flipSem(String l, String w) => '$l: $w';
String _remove(String l) => 'Remove $l';
String _add(String l) => 'Add $l';

List<KSortOption<String>> _options(int n, {String? longName}) => [
  for (var i = 0; i < n; i++)
    KSortOption(
      value: 'k$i',
      label: i == 0 && longName != null ? longName : 'Key $i',
      icon: KIcons.songs,
      ascendingLabel: 'A to Z',
      descendingLabel: 'Z to A',
    ),
];

/// Stands in for the app's sort rules: records each intent and applies it to
/// the listenable, as the real controller does.
class _Rules {
  _Rules(List<KSortEntry<String>> start)
    : chosen = ValueNotifier(List.of(start));

  final ValueNotifier<List<KSortEntry<String>>> chosen;
  final calls = <String>[];

  void add(String v) {
    calls.add('add $v');
    chosen.value = [...chosen.value, KSortEntry(value: v, descending: false)];
  }

  void remove(String v) {
    calls.add('remove $v');
    chosen.value = [
      for (final e in chosen.value)
        if (e.value != v) e,
    ];
  }

  void flip(String v) {
    calls.add('flip $v');
    chosen.value = [
      for (final e in chosen.value)
        e.value == v ? KSortEntry(value: v, descending: !e.descending) : e,
    ];
  }

  void move(int from, int to) {
    calls.add('move $from $to');
    final list = [...chosen.value];
    list.insert(to, list.removeAt(from));
    chosen.value = list;
  }

  void reset() {
    calls.add('reset');
    chosen.value = const [KSortEntry(value: 'k0', descending: false)];
  }
}

List<KSortEntry<String>> _entries(List<String> values) => [
  for (final v in values) KSortEntry(value: v, descending: false),
];

Future<_Rules> _open(
  WidgetTester tester, {
  List<String> chosen = const ['k0', 'k1'],
  int options = 4,
  String? longName,
  Size size = const Size(400, 800),
  double textScale = 1.0,
  bool reduceMotion = false,
}) async {
  useWindow(tester, size);
  final rules = _Rules(_entries(chosen));
  await tester.pumpWidget(
    scaledHost(
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showKSortDialog<String>(
            context,
            options: _options(options, longName: longName),
            chosen: rules.chosen,
            onAdd: rules.add,
            onRemove: rules.remove,
            onFlip: rules.flip,
            onMove: rules.move,
            onReset: rules.reset,
            strings: _strings,
          ),
          child: const Text('open'),
        ),
      ),
      textScale: textScale,
      reduceMotion: reduceMotion,
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return rules;
}

/// The Move up / down / to start / to end actions Flutter's reorderable list
/// puts on every row, keyed by their spoken label.
Map<String, int> _moveActions(WidgetTester tester, Finder row) {
  final data = tester.getSemantics(row).getSemanticsData();
  return {
    for (final id in data.customSemanticsActionIds ?? const <int>[])
      CustomSemanticsAction.getAction(id)!.label!: id,
  };
}

void _perform(WidgetTester tester, String name, int n, String label) {
  final id = _moveActions(tester, _row(name, n))[label]!;
  tester.semantics.performAction(
    find.semantics.byLabel(_rowLabel(name, n)),
    SemanticsAction.customAction,
    args: id,
  );
}

/// The semantics node of chosen row [n] (its label starts with "n. name").
Finder _row(String name, int n) => find.bySemanticsLabel(_rowLabel(name, n));

RegExp _rowLabel(String name, int n) => RegExp('^$n\\. $name(\\n|\$)');

/// Drags the handle of row [index] by [dy] in small steps, as a finger does.
Future<TestGesture> _dragHandle(
  WidgetTester tester,
  int index,
  double dy, {
  bool release = true,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(byDragHandle(index)),
  );
  final steps = (dy.abs() / 12).ceil();
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, dy.sign * 12));
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (release) {
    await gesture.up();
    await tester.pumpAndSettle();
  }
  return gesture;
}

void main() {
  group('look', () {
    for (final (name, size) in [
      ('mobile', const Size(400, 800)),
      ('desktop', const Size(1300, 800)),
    ]) {
      testWidgets('centred and at most 400 wide ($name)', (tester) async {
        await _open(tester, size: size);
        final box = tester.getRect(
          find
              .descendant(
                of: find.byType(Dialog),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(box.center.dx, closeTo(size.width / 2, 0.5));
        expect(box.center.dy, closeTo(size.height / 2, 0.5));
        expect(box.width, lessThanOrEqualTo(KLayout.sortDialog));
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Sort by'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final (name, brightness, scale) in hostVariants) {
      testWidgets('renders both sections ($name)', (tester) async {
        useWindow(tester, const Size(400, 800));
        final rules = _Rules(_entries(['k0', 'k1']));
        await tester.pumpWidget(
          scaledHost(
            Builder(
              builder: (context) => TextButton(
                onPressed: () => showKSortDialog<String>(
                  context,
                  options: _options(4),
                  chosen: rules.chosen,
                  onAdd: rules.add,
                  onRemove: rules.remove,
                  onFlip: rules.flip,
                  onMove: rules.move,
                  onReset: rules.reset,
                  strings: _strings,
                ),
                child: const Text('open'),
              ),
            ),
            brightness: brightness,
            textScale: scale,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Chosen'), findsOneWidget);
        expect(find.text('Not chosen'), findsOneWidget);
        expect(find.text('Key 0'), findsOneWidget);
        expect(find.text('Key 3'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('the not chosen header is hidden when nothing is left', (
      tester,
    ) async {
      await _open(tester, chosen: ['k0', 'k1'], options: 2);
      expect(find.text('Chosen'), findsOneWidget);
      expect(find.text('Not chosen'), findsNothing);
    });

    testWidgets('200 % text and a long name do not overflow', (tester) async {
      await _open(
        tester,
        size: const Size(320, 640),
        textScale: 2.0,
        longName:
            'A very long criterion name that cannot fit in the row at all',
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('number disc is 22 at 1x', (tester) async {
      await _open(tester);
      expect(
        tester.getSize(find.byKey(const ValueKey('sort-number-disc')).first),
        const Size(22, 22),
      );
    });

    testWidgets('number disc holds its number at 200 %', (tester) async {
      await _open(tester, textScale: 2.0);
      final disc = find.byKey(const ValueKey('sort-number-disc')).first;
      final box = tester.getRect(disc);
      final number = tester.getRect(
        find.descendant(of: disc, matching: find.text('1')),
      );
      expect(box.width, greaterThan(22));
      expect(box.contains(number.topLeft), isTrue);
      expect(box.contains(number.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('actions: Reset left of Done on one line at 1x', (
      tester,
    ) async {
      await _open(tester);
      final reset = tester.getRect(find.text('Reset'));
      final done = tester.getRect(find.text('Done'));
      expect(reset.right, lessThan(done.left));
      expect(reset.center.dy, closeTo(done.center.dy, 0.5));
      final bar = tester.getRect(find.byType(OverflowBar));
      expect(
        tester.getRect(find.widgetWithText(TextButton, 'Done')).right,
        closeTo(bar.right, 0.5),
      );
    });

    testWidgets('actions at 200 % on 320 px stack with Done at the end', (
      tester,
    ) async {
      await _open(tester, size: const Size(320, 640), textScale: 2.0);
      expect(tester.takeException(), isNull);
      final reset = tester.getRect(find.widgetWithText(TextButton, 'Reset'));
      final done = tester.getRect(find.widgetWithText(TextButton, 'Done'));
      final bar = tester.getRect(find.byType(OverflowBar));
      expect(reset.bottom, lessThanOrEqualTo(done.top));
      expect(done.right, closeTo(bar.right, 0.5));
    });

    testWidgets('chosen header keeps its count at 200 % on 320 px', (
      tester,
    ) async {
      await _open(tester, size: const Size(320, 640), textScale: 2.0);
      expect(tester.takeException(), isNull);
      expect(find.text('Chosen'), findsOneWidget);
      final count = find.descendant(
        of: find.byType(SortSectionHeader).first,
        matching: find.text('2'),
      );
      final title = tester.getRect(find.text('Chosen'));
      final box = tester.getRect(find.byType(SortSectionHeader).first);
      expect(count, findsOneWidget);
      expect(box.contains(tester.getRect(count).bottomRight), isTrue);
      expect(title.right, lessThanOrEqualTo(tester.getRect(count).left));
    });

    testWidgets('animations off: a drag still moves the row', (tester) async {
      final rules = await _open(tester, reduceMotion: true);
      await _dragHandle(tester, 0, 96);
      expect(rules.calls, ['move 0 1']);
      expect(tester.takeException(), isNull);
    });
  });

  group('rows', () {
    testWidgets('one criterion: no handle, remove is disabled', (tester) async {
      final handle = tester.ensureSemantics();
      final rules = await _open(tester, chosen: ['k0']);
      expect(find.bySemanticsLabel(RegExp('Drag')), findsNothing);
      final remove = tester
          .getSemantics(byIconButton('Remove Key 0'))
          .getSemanticsData()
          .flagsCollection;
      expect(remove.isEnabled.name, 'isFalse');
      await tester.tap(byIconButton('Remove Key 0'));
      await tester.pump();
      expect(rules.calls, isEmpty);
      handle.dispose();
    });

    testWidgets('several criteria: every row has a handle and remove works', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final rules = await _open(tester);
      expect(find.bySemanticsLabel(RegExp('Drag Key 0')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Drag Key 1')), findsOneWidget);
      final flags = tester
          .getSemantics(byIconButton('Remove Key 1'))
          .getSemanticsData()
          .flagsCollection;
      expect(flags.isEnabled.name, 'isTrue');
      await tester.tap(byIconButton('Remove Key 1'));
      await tester.pump();
      expect(rules.calls, ['remove k1']);
      handle.dispose();
    });

    testWidgets('the handle is 28 wide and 48 tall', (tester) async {
      await _open(tester);
      expect(
        tester.getSize(byDragHandle(0)),
        const Size(KDragHandle.compactWidth, KLayout.minTarget),
      );
    });

    testWidgets('a chosen entry that is not an option is skipped', (
      tester,
    ) async {
      final rules = await _open(tester, chosen: ['k0', 'gone', 'k1']);
      expect(tester.takeException(), isNull);
      expect(find.text('Key 0'), findsOneWidget);
      expect(find.text('Key 1'), findsOneWidget);
      expect(byIconButton('Add Key 2'), findsOneWidget);
      expect(rules.calls, isEmpty);
    });

    testWidgets('a chosen row reads "<n>. <name>"', (tester) async {
      final handle = tester.ensureSemantics();
      await _open(tester);
      expect(_row('Key 0', 1), findsOneWidget);
      expect(_row('Key 1', 2), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the direction button names the direction and flips', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final rules = await _open(tester);
      expect(find.bySemanticsLabel('Key 0: A to Z'), findsOneWidget);
      expect(byIconButton('Switch to Z to A'), findsNWidgets(2));
      await tester.tap(byIconButton('Switch to Z to A').first);
      await tester.pump();
      expect(rules.calls, ['flip k0']);
      expect(find.bySemanticsLabel('Key 0: Z to A'), findsOneWidget);
      expect(byIconButton('Switch to A to Z'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('plus and the whole row add; Enter and Space add', (
      tester,
    ) async {
      final rules = await _open(tester);
      await tester.tap(byIconButton('Add Key 2'));
      await tester.pump();
      expect(rules.calls, ['add k2']);
      await tester.tap(find.text('Key 3'));
      await tester.pump();
      expect(rules.calls, ['add k2', 'add k3']);
      expect(find.text('Not chosen'), findsNothing);
    });

    for (final (name, key) in [
      ('Enter', LogicalKeyboardKey.enter),
      ('Space', LogicalKeyboardKey.space),
    ]) {
      testWidgets('keyboard: Tab reaches a not chosen row, $name adds it', (
        tester,
      ) async {
        final rules = await _open(tester, chosen: ['k0'], options: 2);
        bool onKey1() {
          final focused = FocusManager.instance.primaryFocus?.context;
          // The box's own focus node wraps everything: only a row's InkWell counts.
          if (focused == null ||
              focused.findAncestorWidgetOfExactType<InkWell>() == null) {
            return false;
          }
          return find
              .descendant(
                of: find.byElementPredicate((e) => identical(e, focused)),
                matching: find.text('Key 1'),
              )
              .evaluate()
              .isNotEmpty;
        }

        for (var i = 0; i < 8 && !onKey1(); i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        expect(onKey1(), isTrue, reason: 'Tab reaches the Key 1 row');
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(rules.calls, ['add k1']);
      });
    }
  });

  group('reorder', () {
    testWidgets('the built-in Move down action reports onMove(0, 1)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final rules = await _open(tester);
      final row = _row('Key 0', 1);
      expect(_moveActions(tester, row).keys, contains('Move down'));
      _perform(tester, 'Key 0', 1, 'Move down');
      await tester.pumpAndSettle();
      expect(rules.calls, ['move 0 1']);
      handle.dispose();
    });

    testWidgets('dragging row 0 below row 1 reports onMove(0, 1)', (
      tester,
    ) async {
      final rules = await _open(tester);
      await _dragHandle(tester, 0, 96);
      expect(rules.calls, ['move 0 1']);
      expect(find.text('Key 1').evaluate().length, 1);
      expect(
        tester.getTopLeft(find.text('Key 1')).dy,
        lessThan(tester.getTopLeft(find.text('Key 0')).dy),
      );
    });

    testWidgets('Alt + Down moves the focused row down, Alt + Up on the first '
        'row does nothing', (tester) async {
      final rules = await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      expect(rules.calls, ['move 0 1']);
    });

    testWidgets('a tall list auto-scrolls while a row is dragged', (
      tester,
    ) async {
      final rules = await _open(
        tester,
        size: const Size(400, 500),
        chosen: [for (var i = 0; i < 10; i++) 'k$i'],
        options: 12,
      );
      final scrollable = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable.first).position;
      expect(position.pixels, 0);
      final bottom = tester.getRect(scrollable.first).bottom;
      final x = tester.getCenter(byDragHandle(0)).dx;
      final gesture = await _dragHandle(tester, 0, 24, release: false);
      await gesture.moveTo(Offset(x, bottom - 4));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(position.pixels, greaterThan(0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(rules.calls.single, startsWith('move 0 '));
    });
  });

  group('behaviour', () {
    testWidgets('the rows follow the listenable', (tester) async {
      final handle = tester.ensureSemantics();
      final rules = await _open(tester);
      rules.chosen.value = _entries(['k2', 'k0', 'k1']);
      await tester.pump();
      expect(_row('Key 2', 1), findsOneWidget);
      expect(_row('Key 0', 2), findsOneWidget);
      expect(_row('Key 1', 3), findsOneWidget);
      expect(byIconButton('Add Key 2'), findsNothing);
      expect(byIconButton('Add Key 3'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Reset reports onReset and the box stays open', (tester) async {
      final rules = await _open(tester);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(rules.calls, ['reset']);
      expect(find.text('Sort by'), findsOneWidget);
      expect(find.text('Key 1'), findsOneWidget);
    });

    testWidgets('Done closes it', (tester) async {
      await _open(tester);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing);
    });

    testWidgets('Esc closes it', (tester) async {
      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing);
    });

    testWidgets('Back closes it', (tester) async {
      await _open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing);
    });

    testWidgets('a tap outside closes it', (tester) async {
      await _open(tester);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Sort by'), findsNothing);
    });
  });
}
