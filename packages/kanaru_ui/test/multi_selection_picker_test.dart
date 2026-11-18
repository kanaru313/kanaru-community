import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';
import 'support/scaled_host.dart';

SelectionOption<String> _opt(
  String value,
  String filterText, {
  bool icon = true,
  bool enabled = true,
  String? hint,
}) => SelectionOption<String>(
  value: value,
  title: Text(value),
  leading: icon ? const Icon(KIcons.folders) : null,
  filterText: filterText,
  enabled: enabled,
  hint: hint,
);

final _options = [
  _opt('Rock', 'Rock'),
  _opt('Jazz', 'Jazz'),
  _opt('Chill', 'Chill'),
];
final _favorites = _opt('Favorites', 'Yêu thích');

/// Opens the picker; `result` is the future the picker returned.
class _Run {
  Future<Set<String>?>? result;
}

Widget _opener(
  _Run run, {
  List<SelectionOption<String>>? options,
  List<SelectionOption<String>> pinned = const [],
  Set<String> initial = const {},
  MultiSelectionAction<String>? leadingAction,
  String? filterHint,
  Future<bool> Function(Set<String>)? confirm,
  Duration? confirmTimeout = const Duration(seconds: 10),
  bool Function(Set<String>)? canConfirm,
  String? selectAllLabel,
  Widget title = const Text('Add to playlist'),
}) => Builder(
  builder: (context) => TextButton(
    onPressed: () => run.result = showMultiSelectionPicker<String>(
      context,
      title: title,
      subtitle: const Text('3 songs'),
      options: options ?? _options,
      pinned: pinned,
      initial: initial,
      leadingAction: leadingAction,
      filterHint: filterHint,
      selectAllLabel: selectAllLabel,
      selectedCountLabel: selectAllLabel == null ? null : (n, t) => '$n / $t',
      footerNote: (context, s) => Text('${s.length} chosen'),
      cancelLabel: 'Cancel',
      confirmLabel: (s) => 'Add ${s.length}',
      confirm: confirm,
      confirmTimeout: confirmTimeout,
      canConfirm: canConfirm,
    ),
    child: const Text('open'),
  ),
);

const _phone = Size(360, 800);
const _desktop = Size(1300, 900);

Future<_Run> _show(
  WidgetTester tester, {
  Size size = _phone,
  List<SelectionOption<String>>? options,
  List<SelectionOption<String>> pinned = const [],
  Set<String> initial = const {},
  MultiSelectionAction<String>? leadingAction,
  String? filterHint,
  Future<bool> Function(Set<String>)? confirm,
  Duration? confirmTimeout = const Duration(seconds: 10),
  bool Function(Set<String>)? canConfirm,
  String? selectAllLabel,
  Widget title = const Text('Add to playlist'),
  double textScale = 1,
}) async {
  useWindow(tester, size);
  final run = _Run();
  await tester.pumpWidget(
    scaledHost(
      _opener(
        run,
        options: options,
        pinned: pinned,
        initial: initial,
        leadingAction: leadingAction,
        filterHint: filterHint,
        confirm: confirm,
        confirmTimeout: confirmTimeout,
        canConfirm: canConfirm,
        selectAllLabel: selectAllLabel,
        title: title,
      ),
      textScale: textScale,
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return run;
}

Finder _row(String text) => find.widgetWithText(SelectionRow, text);

bool _checked(WidgetTester tester, String text) =>
    tester
        .widget<KCheckMark>(
          find.descendant(of: _row(text), matching: find.byType(KCheckMark)),
        )
        .state ==
    KCheckState.on;

Finder get _confirmButton => find.byType(FilledButton);

bool _confirmEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_confirmButton).onPressed != null;

double _y(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

/// While confirm runs the button keeps its label but is reported disabled.
void _expectBusy(WidgetTester tester) => expect(
  tester.getSemantics(find.byType(FilledButton)),
  isSemantics(
    label: 'Add 1',
    isButton: true,
    hasEnabledState: true,
    isEnabled: false,
  ),
);

void _expectIdle(WidgetTester tester) => expect(
  tester.getSemantics(find.byType(FilledButton)),
  isSemantics(
    label: 'Add 1',
    isButton: true,
    hasEnabledState: true,
    isEnabled: true,
    hasTapAction: true,
  ),
);

MultiSelectionAction<String> _action(List<String> created) =>
    MultiSelectionAction<String>(
      title: const Text('New playlist'),
      onPressed: (context) async {
        final name = 'New${created.length}';
        created.add(name);
        return _opt(name, name);
      },
    );

void main() {
  group('ticks and result', () {
    testWidgets('initial values are ticked, others are not', (tester) async {
      await _show(tester, initial: {'Jazz'});
      expect(_checked(tester, 'Jazz'), isTrue);
      expect(_checked(tester, 'Rock'), isFalse);
    });

    testWidgets('tapping toggles; confirm returns the set', (tester) async {
      final run = await _show(tester);
      await tester.tap(_row('Rock'));
      await tester.tap(_row('Chill'));
      await tester.pumpAndSettle();
      expect(_checked(tester, 'Rock'), isTrue);
      await tester.tap(_row('Rock'));
      await tester.pumpAndSettle();
      expect(_checked(tester, 'Rock'), isFalse);
      expect(find.text('Add 1'), findsOneWidget);
      expect(find.text('1 chosen'), findsOneWidget);
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(await run.result, {'Chill'});
      expect(find.text('Add to playlist'), findsNothing);
    });

    testWidgets('rows have checkbox semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await _show(
        tester,
        initial: {'Jazz'},
        options: [
          _opt('Rock', 'Rock', hint: 'Hint text'),
          _opt('Jazz', 'Jazz'),
        ],
      );
      expect(
        tester.getSemantics(_row('Jazz')),
        isSemantics(
          label: 'Jazz',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      expect(tester.getSemantics(_row('Rock')).hint, 'Hint text');
      handle.dispose();
    });

    testWidgets('confirm is off at 0, cancel returns null', (tester) async {
      final run = await _show(tester);
      expect(_confirmEnabled(tester), isFalse);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await run.result, isNull);
    });

    testWidgets('canConfirm false disables confirm', (tester) async {
      await _show(tester, canConfirm: (s) => !s.contains('Jazz'));
      await tester.tap(_row('Rock'));
      await tester.pump();
      expect(_confirmEnabled(tester), isTrue);
      await tester.tap(_row('Jazz'));
      await tester.pump();
      expect(_confirmEnabled(tester), isFalse);
    });

    testWidgets('a disabled option is never counted or returned', (
      tester,
    ) async {
      final run = await _show(
        tester,
        initial: {'Jazz'},
        options: [_opt('Rock', 'Rock'), _opt('Jazz', 'Jazz', enabled: false)],
      );
      expect(_confirmEnabled(tester), isFalse);
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(await run.result, {'Rock'});
    });
  });

  group('row order', () {
    testWidgets('pinned, divider, action, added row, options', (tester) async {
      final created = <String>[];
      await _show(
        tester,
        pinned: [_favorites],
        leadingAction: _action(created),
      );
      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      final ys = [
        _y(tester, _row('Favorites')),
        _y(tester, find.byType(Divider)),
        _y(tester, find.text('New playlist')),
        _y(tester, _row('New0')),
        _y(tester, _row('Rock')),
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(ys.toSet().length, ys.length);
      expect(_checked(tester, 'New0'), isTrue, reason: 'inserted, selected');
    });

    testWidgets('a second added row goes above the first', (tester) async {
      final created = <String>[];
      await _show(tester, leadingAction: _action(created));
      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      expect(_y(tester, _row('New1')), lessThan(_y(tester, _row('New0'))));
      expect(_y(tester, _row('New0')), lessThan(_y(tester, _row('Rock'))));
    });

    testWidgets('an action that returns null adds nothing', (tester) async {
      await _show(
        tester,
        leadingAction: MultiSelectionAction<String>(
          title: const Text('New playlist'),
          onPressed: (_) async => null,
        ),
      );
      await tester.tap(find.text('New playlist'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectionRow), findsNWidgets(3));
    });

    testWidgets('the action row is a button without a mark', (tester) async {
      final handle = tester.ensureSemantics();
      await _show(tester, leadingAction: _action([]));
      expect(
        tester.getSemantics(find.text('New playlist')),
        isSemantics(
          label: 'New playlist',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('no divider without a pinned row', (tester) async {
      await _show(tester, leadingAction: _action([]));
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('the divider is not in the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      await _show(tester, pinned: [_favorites]);
      expect(find.byType(Divider), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ExcludeSemantics),
          matching: find.byType(Divider),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('pinned only: no divider (nothing follows)', (tester) async {
      await _show(tester, pinned: [_favorites], options: const []);
      expect(find.byType(Divider), findsNothing);
      expect(_row('Favorites'), findsOneWidget);
    });

    testWidgets('a pinned row ticks like the others', (tester) async {
      final run = await _show(tester, pinned: [_favorites]);
      await tester.tap(_row('Favorites'));
      await tester.pumpAndSettle();
      expect(_checked(tester, 'Favorites'), isTrue);
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(await run.result, {'Favorites'});
    });
  });

  group('filter', () {
    testWidgets('no field without filterHint', (tester) async {
      await _show(tester);
      expect(find.byType(KFilterField), findsNothing);
    });

    testWidgets('the field does not take focus on open', (tester) async {
      await _show(tester, filterHint: 'Filter');
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isFalse,
      );
    });

    testWidgets('hides rows but keeps their ticks', (tester) async {
      final run = await _show(tester, filterHint: 'Filter');
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'jazz');
      await tester.pumpAndSettle();
      expect(_row('Rock'), findsNothing);
      expect(_row('Jazz'), findsOneWidget);
      expect(find.text('Add 1'), findsOneWidget, reason: 'hidden pick counts');
      await tester.tap(byIconButton('Close'));
      await tester.pumpAndSettle();
      expect(_row('Rock'), findsOneWidget);
      expect(_checked(tester, 'Rock'), isTrue);
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(await run.result, {'Rock'});
    });

    testWidgets('the cross clears the text and the applied filter', (
      tester,
    ) async {
      await _show(tester, filterHint: 'Filter');
      await tester.enterText(find.byType(TextField), 'jazz');
      await tester.pumpAndSettle();
      expect(find.byType(SelectionRow), findsOneWidget);
      await tester.tap(byIconButton('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectionRow), findsNWidgets(3));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('matches filterText folded, never the title widget', (
      tester,
    ) async {
      await _show(
        tester,
        filterHint: 'Filter',
        options: [
          const SelectionOption<String>(
            value: 'a',
            title: Text('Rock'),
            filterText: 'Metal Vũ Cát',
          ),
          const SelectionOption<String>(value: 'b', title: Text('Always')),
        ],
      );
      await tester.enterText(find.byType(TextField), 'rock');
      await tester.pumpAndSettle();
      expect(find.text('Rock'), findsNothing, reason: 'title is not searched');
      expect(find.text('Always'), findsOneWidget, reason: 'no filterText');
      await tester.enterText(find.byType(TextField), 'vu cat');
      await tester.pumpAndSettle();
      expect(find.text('Rock'), findsOneWidget);
    });

    testWidgets('pinned rows filter; divider goes when none is visible', (
      tester,
    ) async {
      await _show(tester, filterHint: 'Filter', pinned: [_favorites]);
      expect(find.byType(Divider), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'yeu');
      await tester.pumpAndSettle();
      expect(_row('Favorites'), findsOneWidget);
      expect(find.byType(Divider), findsNothing, reason: 'nothing follows');
      await tester.enterText(find.byType(TextField), 'jazz');
      await tester.pumpAndSettle();
      expect(_row('Favorites'), findsNothing);
      expect(find.byType(Divider), findsNothing, reason: 'no pinned row left');
    });

    testWidgets('no match leaves no rows and no error', (tester) async {
      await _show(tester, filterHint: 'Filter');
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byType(SelectionRow), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('confirm', () {
    testWidgets('false keeps it open with the same ticks', (tester) async {
      var calls = 0;
      final run = await _show(tester, confirm: (s) async => ++calls > 1);
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(find.text('Add to playlist'), findsOneWidget);
      expect(_checked(tester, 'Rock'), isTrue);
      expect(_confirmEnabled(tester), isTrue);
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(await run.result, {'Rock'});
    });

    testWidgets('while it runs: busy ring, buttons and pop blocked', (
      tester,
    ) async {
      final gate = Completer<bool>();
      final run = await _show(tester, confirm: (_) => gate.future);
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pump();
      _expectBusy(tester);
      expect(
        tester.getSemantics(find.text('Cancel')),
        isSemantics(
          label: 'Cancel',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Add to playlist'), findsOneWidget, reason: 'Back');
      // A tap on a row does not change the ticks while it runs.
      await tester.tap(_row('Jazz'), warnIfMissed: false);
      await tester.pump();
      expect(_checked(tester, 'Jazz'), isFalse);
      gate.complete(true);
      await tester.pumpAndSettle();
      expect(await run.result, {'Rock'});
    });

    testWidgets('a tap outside does not close it while it runs (dialog)', (
      tester,
    ) async {
      final gate = Completer<bool>();
      await _show(tester, size: _desktop, confirm: (_) => gate.future);
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pump();
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Add to playlist'), findsOneWidget);
      _expectBusy(tester);
      gate.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('Add to playlist'), findsOneWidget);
      _expectIdle(tester);
    });

    testWidgets('past confirmTimeout it counts as false and unblocks', (
      tester,
    ) async {
      final gate = Completer<bool>();
      await _show(
        tester,
        confirm: (_) => gate.future,
        confirmTimeout: const Duration(seconds: 3),
      );
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      _expectBusy(tester);
      await tester.pump(const Duration(seconds: 2));
      _expectIdle(tester);
      expect(_checked(tester, 'Rock'), isTrue);
      expect(_confirmEnabled(tester), isTrue);
      // The late answer is ignored: it must not close the picker.
      gate.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Add to playlist'), findsOneWidget);
    });

    testWidgets('confirmTimeout: null never times out', (tester) async {
      final gate = Completer<bool>();
      final run = await _show(
        tester,
        confirm: (_) => gate.future,
        confirmTimeout: null,
      );
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pump();
      await tester.pump(const Duration(minutes: 5));
      _expectBusy(tester);
      gate.complete(true);
      await tester.pumpAndSettle();
      expect(await run.result, {'Rock'});
    });

    testWidgets('a throwing confirm is reported and unblocks', (tester) async {
      await _show(
        tester,
        confirm: (_) async => throw StateError('write failed'),
      );
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isA<StateError>());
      _expectIdle(tester);
      expect(find.text('Add to playlist'), findsOneWidget);
    });
  });

  group('confirm guards', () {
    testWidgets('two activations before the next frame confirm once', (
      tester,
    ) async {
      var calls = 0;
      final gate = Completer<bool>();
      await _show(
        tester,
        confirm: (_) {
          calls++;
          return gate.future;
        },
      );
      await tester.tap(_row('Rock'));
      await tester.pump();
      final onPressed = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      onPressed();
      onPressed();
      await tester.pump();
      expect(calls, 1);
      gate.complete(false);
      await tester.pumpAndSettle();
    });

    testWidgets('the busy button keeps its label for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final gate = Completer<bool>();
      await _show(tester, confirm: (_) => gate.future);
      await tester.tap(_row('Rock'));
      await tester.pump();
      await tester.tap(find.text('Add 1'));
      await tester.pump();
      _expectBusy(tester);
      gate.complete(false);
      await tester.pumpAndSettle();
      _expectIdle(tester);
      handle.dispose();
    });
  });

  group('focus', () {
    testWidgets('a false answer gives focus back to the confirm button', (
      tester,
    ) async {
      final gate = Completer<bool>();
      await _show(tester, confirm: (_) => gate.future);
      await tester.tap(_row('Rock'));
      await tester.pump();
      final node = tester.widget<FilledButton>(_confirmButton).focusNode!;
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 50));
      expect(node.hasFocus, isFalse, reason: 'disabled while it runs');
      gate.complete(false);
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
    });
  });

  group('frame', () {
    testWidgets('mobile: sheet fixed at 85 % of the height', (tester) async {
      await _show(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.getSize(find.byType(BottomSheet)).height, 800 * 0.85);
    });

    testWidgets('mobile: the footer stays at the bottom with few rows', (
      tester,
    ) async {
      await _show(tester);
      final sheet = tester.getRect(find.byType(BottomSheet));
      expect(
        tester.getRect(_confirmButton).bottom,
        greaterThan(sheet.bottom - 24),
      );
    });

    testWidgets('desktop: dialog 440 wide, at most 620 tall', (tester) async {
      await _show(
        tester,
        size: _desktop,
        options: [for (var i = 0; i < 1000; i++) _opt('Item $i', 'Item $i')],
      );
      final surface = find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first;
      expect(tester.getSize(surface).width, 440);
      expect(tester.getSize(surface).height, 620);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('desktop: few rows make a shorter dialog', (tester) async {
      await _show(tester, size: _desktop);
      final surface = find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first;
      expect(tester.getSize(surface).height, lessThan(620));
    });

    testWidgets('1000 options scroll; the last one is reachable', (
      tester,
    ) async {
      await _show(
        tester,
        options: [for (var i = 0; i < 1000; i++) _opt('Item $i', 'Item $i')],
      );
      await tester.scrollUntilVisible(
        find.text('Item 999'),
        2000,
        scrollable: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(Scrollable),
        ),
        maxScrolls: 200,
      );
      expect(find.text('Item 999'), findsOneWidget);
    });

    testWidgets('no options: renders the header and footer', (tester) async {
      await _show(tester, options: const []);
      expect(find.text('Add to playlist'), findsOneWidget);
      expect(find.byType(SelectionRow), findsNothing);
      expect(_confirmEnabled(tester), isFalse);
    });

    testWidgets('select-all row only with selectAllLabel', (tester) async {
      await _show(tester);
      expect(find.text('Select all'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    });

    testWidgets('select-all row appears with its label and chooses all', (
      tester,
    ) async {
      final run = await _show(tester, selectAllLabel: 'Select all');
      expect(find.text('Select all'), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
      await tester.tap(find.text('Select all'));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.text('Add 3'));
      await tester.pumpAndSettle();
      expect(await run.result, {'Rock', 'Jazz', 'Chill'});
    });

    for (final size in [_phone, _desktop]) {
      testWidgets('long title at 200 % text does not overflow ($size)', (
        tester,
      ) async {
        await _show(
          tester,
          size: size,
          textScale: 2,
          filterHint: 'Filter',
          pinned: [_favorites],
          leadingAction: _action([]),
          title: const Text(
            'Thêm vào danh sách phát với một cái tên thật là dài dòng',
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
