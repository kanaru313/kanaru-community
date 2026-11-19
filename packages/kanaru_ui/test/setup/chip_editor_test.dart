import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

/// A host that keeps the list, as a screen would.
class _Harness extends StatefulWidget {
  const _Harness({this.initial = const [';', 'feat.'], this.refuse = const {}});

  final List<String> initial;

  /// Text mapped to the error message the host answers with.
  final Map<String, String> refuse;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late List<String> values = [...widget.initial];

  @override
  Widget build(BuildContext context) => KChipEditor(
    values: values,
    suggestions: const ['with'],
    inputHint: 'Add a separator',
    addLabel: 'Add',
    emptyNote: 'Nothing is split.',
    display: (v) => v.length > 1 && RegExp(r'^[a-z]').hasMatch(v) ? '␣$v␣' : v,
    removeTooltip: (v) => 'Remove $v',
    onAdd: (raw) {
      final error = widget.refuse[raw];
      if (error != null) return error;
      setState(() => values = [...values, raw.trim()]);
      return null;
    },
    onRemove: (v) => setState(() => values = [...values]..remove(v)),
  );
}

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(child));
  }

  testWidgets('shows each value with the display form and a remove button', (
    tester,
  ) async {
    await pump(tester, const _Harness());
    expect(find.text(';'), findsOneWidget);
    expect(find.text('␣feat.␣'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove ;'), findsOneWidget);
    expect(find.bySemanticsLabel('Remove feat.'), findsOneWidget);
  });

  testWidgets('remove takes a value out at once', (tester) async {
    await pump(tester, const _Harness());
    await tester.tap(find.bySemanticsLabel('Remove ;'));
    await tester.pump();
    expect(find.text(';'), findsNothing);
    expect(find.text('␣feat.␣'), findsOneWidget);
  });

  testWidgets('a suggestion adds itself and then hides', (tester) async {
    await pump(tester, const _Harness());
    expect(find.text('+ ␣with␣'), findsOneWidget);
    await tester.tap(find.text('+ ␣with␣'));
    await tester.pump();
    expect(find.text('+ ␣with␣'), findsNothing);
    expect(find.text('␣with␣'), findsOneWidget);
  });

  testWidgets('typing and Add adds the value and clears the field', (
    tester,
  ) async {
    await pump(tester, const _Harness());
    await tester.enterText(find.byType(TextField), ' & ');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('&'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('a refusal shows under the field and typing clears it', (
    tester,
  ) async {
    await pump(tester, const _Harness(refuse: {'x': 'Already in the list'}));
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Already in the list'), findsOneWidget);
    // The refused text stays for the user to fix.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'x',
    );
    await tester.enterText(find.byType(TextField), 'xy');
    await tester.pump();
    expect(find.text('Already in the list'), findsNothing);
  });

  testWidgets('an empty list shows the note, suggestions stay', (tester) async {
    await pump(tester, const _Harness(initial: []));
    expect(find.text('Nothing is split.'), findsOneWidget);
    expect(find.text('+ ␣with␣'), findsOneWidget);
  });

  testWidgets('many chips at 200 % text wrap without overflow', (tester) async {
    useWindow(tester, const Size(360, 1200));
    await tester.pumpWidget(
      host(
        _Harness(initial: [for (var i = 0; i < 12; i++) 'sep$i']),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('value chips are not choices: no selected, no button', (
    tester,
  ) async {
    await pump(tester, const _Harness());
    final semantics = tester.ensureSemantics();
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.selected == true,
      ),
      findsNothing,
    );
    // The only ink around a value is the remove button's, not a chip tap.
    expect(
      find.ancestor(of: find.text(';'), matching: find.byType(InkWell)),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('a refused suggestion shows its message under the field', (
    tester,
  ) async {
    await pump(tester, const _Harness(refuse: {'with': 'List is full'}));
    await tester.tap(find.text('+ ␣with␣'));
    await tester.pump();
    expect(find.text('List is full'), findsOneWidget);
    expect(find.text('+ ␣with␣'), findsOneWidget);
  });

  testWidgets('a suggestion is hidden when present in any case', (
    tester,
  ) async {
    await pump(tester, const _Harness(initial: ['With']));
    expect(find.text('+ ␣with␣'), findsNothing);
  });

  testWidgets('the input is not monospaced and hint and input share one size', (
    tester,
  ) async {
    useWindow(tester, const Size(411, 800));
    const hint = 'Tên nghệ sĩ, vd. “Hồ Ngọc Hà / Noo”';
    await tester.pumpWidget(
      host(
        KChipEditor(
          values: const ['AC/DC'],
          inputHint: hint,
          addLabel: 'Thêm',
          removeTooltip: (v) => 'Bỏ $v',
          onAdd: (_) => null,
          onRemove: (_) {},
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.fontFamily, isNot(KFont.mono));
    final hintText = tester.widget<Text>(find.text(hint));
    expect(hintText.style?.fontFamily, isNot(KFont.mono));
    // Hint and input share the 14 sp body size (the test font is wider than
    // the real one, so line fit is checked on the phone).
    expect(hintText.style?.fontSize, field.style?.fontSize);
  });
}
