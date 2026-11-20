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
  desktopTests();
  touchTests();
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
}

/// Desktop: typing lands where the caret is.
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

/// Touch shells: a plain text field. The platform places the caret and what
/// the keyboard sends stays.
void touchTests() {
  Future<TextEditingController> tapped(
    WidgetTester tester, {
    int start = 45,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(_Host(focus: focus, log: [], start: start));
    final c = tester.widget<TextField>(find.byType(TextField)).controller!;
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(seconds: 1));
    expect(focus.hasFocus, isTrue);
    return c;
  }

  void send(WidgetTester tester, String text) {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  testWidgets('touch: a tap focuses and does not select the number', (
    tester,
  ) async {
    final c = await tapped(tester);
    expect(c.selection.isCollapsed, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('touch: a digit typed after a tap is appended', (tester) async {
    final c = await tapped(tester);
    send(tester, '457');
    await tester.pump();
    expect(c.text, '457');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('touch: backspace removes one digit', (tester) async {
    final c = await tapped(tester);
    send(tester, '4');
    await tester.pump();
    expect(c.text, '4');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('touch: tracks 3 then 2 gives 20 (clamped)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _Host(focus: focus, log: [], start: 5, range: sleepTracksRange),
    );
    final c = tester.widget<TextField>(find.byType(TextField)).controller!;
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(seconds: 1));
    send(tester, '3');
    await tester.pump();
    expect(c.text, '3');
    send(tester, '32');
    await tester.pump();
    expect(c.text, '20');
    debugDefaultTargetPlatformOverride = null;
  });
}
