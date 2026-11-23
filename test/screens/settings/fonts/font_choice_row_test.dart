import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/ui/appearance/fonts/font_choice_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';

Future<void> _pump(
  WidgetTester tester,
  FontChoiceRow row, {
  double textScale = 1,
  double width = 400,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(body: row),
    ),
  );
}

void main() {
  testWidgets('selected row reports selected and does not react to taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const FontChoiceRow(
        title: 'Inter',
        sample: 'Aa',
        family: 'Inter',
        selected: true,
      ),
    );
    expect(
      tester.getSemantics(find.byType(FontChoiceRow)),
      isSemantics(
        label: 'Inter\nAa',
        isButton: true,
        isSelected: true,
        hasTapAction: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a tappable row runs onTap and is not selected', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await _pump(
      tester,
      FontChoiceRow(
        title: 'Inter',
        sample: 'Aa',
        family: 'Inter',
        onTap: () => taps++,
      ),
    );
    final node = tester.getSemantics(find.byType(FontChoiceRow));
    expect(
      node,
      isSemantics(
        isButton: true,
        isSelected: false,
        hasTapAction: true,
        label: 'Inter\nAa',
      ),
    );
    await tester.tap(find.text('Inter'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('an inert row is not disabled and shows the trailing slot', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      const FontChoiceRow(
        title: 'Inter',
        sample: 'Aa',
        family: 'Inter',
        trailing: Text('120 KB'),
      ),
    );
    expect(find.text('120 KB'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(FontChoiceRow)),
      isSemantics(isButton: true, isSelected: false, hasTapAction: false),
    );
    semantics.dispose();
  });

  testWidgets('buttons in the trailing slot are their own nodes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    var deletes = 0;
    await _pump(
      tester,
      FontChoiceRow(
        title: 'Inter',
        sample: 'Aa',
        family: 'Inter',
        onTap: () => taps++,
        trailing: KIconButton(
          icon: KIcons.delete,
          tooltip: 'Delete Inter',
          onPressed: () => deletes++,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(FontChoiceRow)),
      isSemantics(
        isButton: true,
        isSelected: false,
        hasTapAction: true,
        label: 'Inter\nAa',
      ),
    );
    expect(
      tester.getSemantics(byIconButton('Delete Inter')),
      isSemantics(isButton: true, hasTapAction: true, label: 'Delete Inter'),
    );
    await tester.tap(byIconButton('Delete Inter'));
    expect(deletes, 1);
    expect(taps, 0);
    semantics.dispose();
  });

  testWidgets('the selected row replaces the trailing slot', (tester) async {
    await _pump(
      tester,
      const FontChoiceRow(
        title: 'Inter',
        sample: 'Aa',
        family: 'Inter',
        selected: true,
        trailing: Text('120 KB'),
      ),
    );
    expect(find.text('120 KB'), findsNothing);
  });

  testWidgets('a long name ellipsizes at 200 % text without overflow', (
    tester,
  ) async {
    await _pump(
      tester,
      FontChoiceRow(
        title: 'A very long font name ' * 8,
        sample: 'Aa Bb Cc Gg Qq Rr Yy 0123456789',
        family: 'Inter',
        defaultSuffix: ' · default',
        trailing: const Text('120 KB'),
      ),
      textScale: 2,
      width: 320,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('name and sample use the given family', (tester) async {
    await _pump(
      tester,
      const FontChoiceRow(title: 'Inter', sample: 'Aa', family: 'Inter'),
    );
    final sample = tester.widget<Text>(find.text('Aa'));
    expect(sample.style?.fontFamily, 'Inter');
  });
}
