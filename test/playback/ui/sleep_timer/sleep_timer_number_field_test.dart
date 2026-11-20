import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_draft.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_number_field.dart';
import 'package:material_ui/material_ui.dart';

/// Holds the value like the custom screen does and records what the field
/// reports.
class _Host extends StatefulWidget {
  const _Host({required this.focus, required this.log, this.range});
  final FocusNode focus;
  final List<String> log;
  final SleepTimerRange? range;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int value = 45;
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
          // Must be unset before the test body ends (checked by the binding).
          debugDefaultTargetPlatformOverride = null;
        },
      );
    }
  }
}
