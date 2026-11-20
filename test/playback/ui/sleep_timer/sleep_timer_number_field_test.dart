import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_draft.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_number_field.dart';
import 'package:material_ui/material_ui.dart';

/// Holds the value like the custom screen does and records what the field
/// reports.
class _Host extends StatefulWidget {
  const _Host({
    required this.focus,
    required this.log,
    this.range,
    this.start = 45,
  });
  final int start;
  final FocusNode focus;
  final List<String> log;
  final SleepTimerRange? range;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int value = widget.start;
  SleepTimerRange? range;
  void bump() => setState(() {});

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          child: SleepTimerNumberField(
            value: value,
            range: range ?? widget.range ?? sleepMinutesRange,
            semanticsLabel: 'Số phút',
            focusNode: widget.focus,
            onChanged: (v) {
              widget.log.add('changed $v');
              setState(() => value = v);
            },
            onSubmit: () => widget.log.add('submit $value'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  realTapTests();
  honouredSelectAllTests();
  desktopTests();
  imeAppendTest();
  formatterTests();
  late FocusNode focus;
  late List<String> log;

  setUp(() {
    focus = FocusNode();
    log = [];
  });
  tearDown(() => focus.dispose());

  void size(WidgetTester tester, Size s) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pump(WidgetTester tester, {Size? s}) async {
    size(tester, s ?? const Size(400, 800));
    await tester.pumpWidget(_Host(focus: focus, log: log));
  }

  String shown(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  TextSelection selection(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.selection;

  testWidgets('shows the value and does not take focus on its own', (
    tester,
  ) async {
    await pump(tester);
    expect(shown(tester), '45');
    expect(focus.hasFocus, isFalse);
    await pump(tester, s: const Size(1400, 900));
    expect(focus.hasFocus, isFalse);
  });

  testWidgets('desktop focus selects the whole number', (tester) async {
    await pump(tester, s: const Size(1400, 900));
    focus.requestFocus();
    await tester.pump();
    expect(
      selection(tester),
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
  });

  testWidgets('touch: tapping the field selects the whole number', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    expect(
      selection(tester),
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
    await tester.enterText(find.byType(TextField), '6');
    await tester.pump();
    expect(shown(tester), '6');
    expect(log.last, 'changed 6');
  });

  testWidgets('a number past the maximum shows and reports the maximum', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '1000');
    await tester.pump();
    expect(shown(tester), '720');
    expect(log.last, 'changed 720');
  });

  testWidgets('full-width digits and extra characters are cleaned', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '１２０');
    await tester.pump();
    expect(shown(tester), '120');
    await tester.enterText(find.byType(TextField), '-5 ph');
    await tester.pump();
    expect(shown(tester), '5');
    expect(log, ['changed 120', 'changed 5']);
  });

  testWidgets('empty and zero report nothing', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(shown(tester), '');
    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    expect(shown(tester), '0');
    expect(log, isEmpty);
  });

  testWidgets('an unrelated rebuild keeps what is being typed', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    tester.state<_HostState>(find.byType(_Host)).bump();
    await tester.pump();
    expect(shown(tester), '');
  });

  testWidgets('leaving the field shows the last valid number again', (
    tester,
  ) async {
    await pump(tester);
    focus.requestFocus();
    await tester.pump();
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(shown(tester), '');
    focus.unfocus();
    await tester.pump();
    expect(shown(tester), '45');
    expect(log, isEmpty);
  });

  testWidgets('Done on an empty field submits the last valid number', (
    tester,
  ) async {
    await pump(tester);
    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(shown(tester), '45');
    expect(log, ['submit 45']);
  });

  testWidgets('Done on zero restores the value and submits it', (tester) async {
    await pump(tester);
    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '0');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(shown(tester), '45');
    expect(log, ['submit 45']);
  });

  testWidgets('Done after typing submits the typed number', (tester) async {
    await pump(tester);
    await tester.showKeyboard(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '90');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(log, ['changed 90', 'submit 90']);
  });

  testWidgets('text under IME composition is left alone until it ends', (
    tester,
  ) async {
    await pump(tester);
    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '１２abc',
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 0, end: 5),
      ),
    );
    await tester.pump();
    expect(shown(tester), '１２abc');
    expect(log, isEmpty);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '１２０',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(shown(tester), '120');
    expect(log, ['changed 120']);
  });

  const composingNinety = TextEditingValue(
    text: '90',
    selection: TextSelection.collapsed(offset: 2),
    composing: TextRange(start: 0, end: 2),
  );

  testWidgets('Done with digits still composing reports them, then submits', (
    tester,
  ) async {
    await pump(tester);
    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(composingNinety);
    await tester.pump();
    expect(log, isEmpty);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(shown(tester), '90');
    expect(log, ['changed 90', 'submit 90']);
  });

  testWidgets('leaving the field with digits still composing keeps them', (
    tester,
  ) async {
    await pump(tester);
    focus.requestFocus();
    await tester.pump();
    await tester.showKeyboard(find.byType(TextField));
    tester.testTextInput.updateEditingValue(composingNinety);
    await tester.pump();
    expect(log, isEmpty);
    focus.unfocus();
    await tester.pump();
    expect(shown(tester), '90');
    expect(log, ['changed 90']);
  });

  testWidgets('a value from outside (button, chip) replaces the text', (
    tester,
  ) async {
    await pump(tester);
    final host = tester.state<_HostState>(find.byType(_Host));
    host.value = 50;
    host.bump();
    await tester.pump();
    expect(shown(tester), '50');
  });

  testWidgets('tracks range clamps at 20', (tester) async {
    size(tester, const Size(400, 800));
    await tester.pumpWidget(
      _Host(focus: focus, log: log, range: sleepTracksRange),
    );
    await tester.enterText(find.byType(TextField), '100');
    await tester.pump();
    expect(shown(tester), '20');
    expect(log.last, 'changed 20');
  });

  const all2 = TextSelection(baseOffset: 0, extentOffset: 2);

  testWidgets('touch: kind switch while focused, then a tap selects all', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
    final host = tester.state<_HostState>(find.byType(_Host));
    host.range = sleepTracksRange;
    host.value = 12;
    host.bump();
    await tester.pump();
    await tester.pump();
    expect(shown(tester), '12');
    expect(focus.hasFocus, isTrue);
    expect(selection(tester), all2);
    // The caret moves (e.g. the platform placed it); the next tap selects all.
    tester.widget<TextField>(find.byType(TextField)).controller!.selection =
        const TextSelection.collapsed(offset: 2);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
    expect(selection(tester), all2);
  });

  testWidgets('touch: outside value while focused selects all', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
    final host = tester.state<_HostState>(find.byType(_Host));
    host.value = 50;
    host.bump();
    await tester.pump();
    await tester.pump();
    expect(selection(tester), all2);
  });

  testWidgets('touch: a tap on a focused field selects all; typing replaces', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
    tester.widget<TextField>(find.byType(TextField)).controller!.selection =
        const TextSelection.collapsed(offset: 1);
    // Past the double-tap window, so it is a plain second tap.
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump();
    expect(selection(tester), all2);
    await tester.enterText(find.byType(TextField), '7');
    await tester.pump();
    expect(shown(tester), '7');
    await tester.pumpWidget(const SizedBox());
  });
}

/// The real gesture path of a phone: the framework's own tap handling runs
/// (caret placement, toolbar), then typing goes through the text input channel.
void realTapTests() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final composing in [false, true]) {
      testWidgets(
        'real tap on $platform (composing after typing: $composing): every tap '
        'selects all, typing replaces',
        (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
          final focus = FocusNode();
          addTearDown(focus.dispose);
          final log = <String>[];
          tester.view.physicalSize = const Size(400, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            _Host(focus: focus, log: log, range: sleepTracksRange),
          );
          final controller = tester
              .widget<TextField>(find.byType(TextField))
              .controller!;

          /// Replaces the selection with [digit] like the keyboard does.
          Future<void> type(String digit) async {
            final v = controller.value;
            final text = v.text.replaceRange(
              v.selection.start,
              v.selection.end,
              digit,
            );
            final end = v.selection.start + digit.length;
            tester.testTextInput.updateEditingValue(
              TextEditingValue(
                text: text,
                selection: TextSelection.collapsed(offset: end),
                composing: composing
                    ? TextRange(start: 0, end: text.length)
                    : TextRange.empty,
              ),
            );
            await tester.pump();
          }

          await tester.tap(find.byType(TextField));
          await tester.pump(const Duration(seconds: 1));
          await type('6');
          expect(controller.text, '6');

          // Second tap on the focused field, past the double-tap timeout.
          await tester.pump(const Duration(seconds: 1));
          await tester.tap(find.byType(TextField));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(
            controller.selection,
            const TextSelection(baseOffset: 0, extentOffset: 1),
          );
          await type('7');
          expect(controller.text, '7');
          if (!composing) expect(log.last, 'changed 7');
          // The binding checks the override is unset before the test ends.
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }
  }
}

/// An IME that ignores our select-all and appends at its own caret.
void imeAppendTest() {
  testWidgets('real tap on android: an IME that appends still gets replaced', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final log = <String>[];
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_Host(focus: focus, log: log));
    final controller = tester
        .widget<TextField>(find.byType(TextField))
        .controller!;
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(seconds: 1));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '6',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // The IME ignores the select-all and keeps its own collapsed caret.
    controller.selection = const TextSelection.collapsed(offset: 1);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '67',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(controller.text, '7');
    expect(log.last, 'changed 7');
    debugDefaultTargetPlatformOverride = null;
  });
}

/// An IME that honours the select-all: the typed or pasted text replaces the
/// selection, so its first/last digit may equal the old number's.
void honouredSelectAllTests() {
  Future<void> tapAndSend(
    WidgetTester tester,
    FocusNode focus,
    String text, {
    String? then,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  const cases = <(String, int, String, String)>[
    ('45 sel-all, type 4', 45, '4', '4'),
    ('45 sel-all, type 5', 45, '5', '5'),
    ('45 sel-all, paste 450', 45, '450', '450'),
    ('30 sel-all, paste 1000 clamps', 30, '1000', '720'),
  ];
  for (final (name, start, typed, expected) in cases) {
    testWidgets('android tap: $name', (tester) async {
      await tapAndSend(tester, FocusNode(), typed);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(_Host(focus: focus, log: [], start: start));
      final c = tester.widget<TextField>(find.byType(TextField)).controller!;
      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(seconds: 1));
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: typed,
          selection: TextSelection.collapsed(offset: typed.length),
        ),
      );
      await tester.pump();
      expect(c.text, expected);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('android tap: 30 sel-all, type 3 then 5 gives 35', (
    tester,
  ) async {
    await tapAndSend(tester, FocusNode(), '');
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(_Host(focus: focus, log: [], start: 30));
    final c = tester.widget<TextField>(find.byType(TextField)).controller!;
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(seconds: 1));
    for (final (text, shown) in [('3', '3'), ('35', '35')]) {
      tester.testTextInput.updateEditingValue(
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
      await tester.pump();
      expect(c.text, shown);
    }
    debugDefaultTargetPlatformOverride = null;
  });
}

/// Desktop never arms the replace: typing lands where the caret is.
void desktopTests() {
  testWidgets('desktop: focus, End, type 7 appends; delete removes one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(_Host(focus: focus, log: []));
    final c = tester.widget<TextField>(find.byType(TextField)).controller!;
    focus.requestFocus();
    await tester.pump();
    c.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '457',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(c.text, '457');
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '45',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pump();
    expect(c.text, '45');
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '4',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    await tester.pump();
    expect(c.text, '4');
  });
}

void formatterTests() {
  const old45 = TextEditingValue(
    text: '45',
    selection: TextSelection.collapsed(offset: 2),
  );
  TextEditingValue v(String t, int caret) => TextEditingValue(
    text: t,
    selection: TextSelection.collapsed(offset: caret),
  );
  String run(TextEditingValue o, TextEditingValue n, {bool armed = true}) {
    final flag = SleepReplaceFlag()..armed = armed;
    return SleepNumberFormatter(
      sleepMinutesRange,
      replace: flag,
    ).formatEditUpdate(o, n).text;
  }

  test('armed: appended, prepended and swapped digits replace the number', () {
    expect(run(old45, v('457', 3)), '7');
    expect(run(old45, v('745', 1)), '7');
    expect(run(v('3', 1), v('32', 2)), '2');
    expect(run(v('3', 1), v('23', 1)), '2');
    expect(run(old45, v('7', 1)), '7');
  });

  test('armed: composing inserted digits become the whole text', () {
    final composing = const TextEditingValue(
      text: '457',
      selection: TextSelection.collapsed(offset: 3),
      composing: TextRange(start: 2, end: 3),
    );
    final out = SleepNumberFormatter(
      sleepMinutesRange,
      replace: SleepReplaceFlag()..armed = true,
    ).formatEditUpdate(old45, composing);
    expect(out.text, '7');
    expect(out.composing, const TextRange(start: 0, end: 1));
  });

  test('armed: a deletion empties the field', () {
    expect(run(old45, v('4', 1)), '');
    expect(run(old45, v('5', 1)), '');
  });

  test('armed: shared digit appended or prepended by the IME', () {
    expect(run(old45, v('455', 3)), '5');
    expect(run(old45, v('445', 1)), '4');
    expect(run(v('6', 1), v('67', 2)), '7');
  });

  test('armed: a selected-all old text is replaced by the new text', () {
    const all = TextSelection(baseOffset: 0, extentOffset: 2);
    final sel45 = old45.copyWith(selection: all);
    expect(run(sel45, v('4', 1)), '4');
    expect(run(sel45, v('5', 1)), '5');
    expect(run(sel45, v('450', 3)), '450');
    final sel30 = const TextEditingValue(text: '30', selection: all);
    expect(run(sel30, v('3', 1)), '3');
    expect(run(sel30, v('1000', 4)), '720');
  });

  test('armed: the flag is spent by the first text change', () {
    final flag = SleepReplaceFlag()..armed = true;
    final f = SleepNumberFormatter(sleepMinutesRange, replace: flag);
    expect(f.formatEditUpdate(old45, v('457', 3)).text, '7');
    expect(flag.armed, isFalse);
    expect(f.formatEditUpdate(v('7', 1), v('78', 2)).text, '78');
  });

  test('armed: a selection-only update keeps the flag', () {
    final flag = SleepReplaceFlag()..armed = true;
    SleepNumberFormatter(
      sleepMinutesRange,
      replace: flag,
    ).formatEditUpdate(old45, v('45', 0));
    expect(flag.armed, isTrue);
  });

  test('not armed: normal append and clamp', () {
    expect(run(old45, v('457', 3), armed: false), '457');
    expect(run(old45, v('4500', 4), armed: false), '720');
  });
}
