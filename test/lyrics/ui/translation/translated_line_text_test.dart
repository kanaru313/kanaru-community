import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/ui/translation/line_translation.dart';
import 'package:kanaru/src/lyrics/ui/translation/translated_line_text.dart';
import 'package:kanaru/src/lyrics/ui/translation/translation_placeholder.dart';
import 'package:material_ui/material_ui.dart';

const _main = TextStyle(fontSize: 20, height: 1.2);
const _under = TextStyle(fontSize: 12, height: 1.2);
const _small = TextStyle(fontSize: 10, height: 1.2);

Future<void> _pump(
  WidgetTester tester,
  LineTranslation translation, {
  TextAlign align = TextAlign.start,
  double width = 300,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: DefaultTextStyle(
            style: _main,
            textAlign: align,
            child: TranslatedLineText(
              original: 'Original',
              translation: translation,
              translationStyle: _under,
              originalStyle: _small,
              textAlign: align,
              duration: Duration.zero,
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('under: the translation sits below the original', (tester) async {
    await _pump(tester, const LineTranslation(text: 'Bản dịch'));
    expect(
      tester.getTopLeft(find.text('Bản dịch')).dy,
      greaterThan(tester.getBottomLeft(find.text('Original')).dy),
    );
  });

  testWidgets('replace: the small original sits above the translation', (
    tester,
  ) async {
    await _pump(tester, const LineTranslation(text: 'Bản dịch', replace: true));
    expect(
      tester.getTopLeft(find.text('Bản dịch')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('Original')).dy),
    );
    expect(tester.getSize(find.text('Original')).height, lessThan(15));
  });

  testWidgets('pending: a bar of about 55 % of the width stands under the '
      'original', (tester) async {
    await _pump(tester, const LineTranslation(pending: true));
    final bar = find.byKey(translationPlaceholderKey);
    expect(tester.getSize(bar).width, 300);
    expect(
      tester.getTopLeft(bar).dy,
      greaterThan(tester.getBottomLeft(find.text('Original')).dy),
    );
    final fill = tester.getSize(
      find.descendant(of: bar, matching: find.byType(DecoratedBox)),
    );
    expect(fill.width, closeTo(300 * 0.55, 0.5));
    expect(
      tester
          .getTopLeft(
            find.descendant(of: bar, matching: find.byType(DecoratedBox)),
          )
          .dx,
      0,
    );
  });

  testWidgets('pending with centred text: the bar is centred', (tester) async {
    await _pump(
      tester,
      const LineTranslation(pending: true),
      align: TextAlign.center,
    );
    final fill = find.descendant(
      of: find.byKey(translationPlaceholderKey),
      matching: find.byType(DecoratedBox),
    );
    expect(tester.getCenter(fill).dx, closeTo(150, 0.5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('nothing to show: the original alone', (tester) async {
    await _pump(tester, const LineTranslation());
    expect(find.byType(Column), findsNothing);
    expect(find.text('Original'), findsOneWidget);
  });

  testWidgets('a blank original gets no bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefaultTextStyle(
          style: _main,
          child: TranslatedLineText(
            original: '  ',
            translation: const LineTranslation(pending: true),
            translationStyle: _under,
            originalStyle: _small,
            textAlign: TextAlign.start,
            duration: Duration.zero,
          ),
        ),
      ),
    );
    expect(find.byKey(translationPlaceholderKey), findsNothing);
  });
}
