import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Asserts that no text under [within] is cut and none is painted outside
/// [within]: every paragraph keeps all its lines (no ellipsis, no dropped
/// line), its laid-out text is not larger than its box (text clipped at the
/// bottom or side by a too small box), and its painted rect, with any scaling
/// applied, lies inside the rect of [within]. `takeException() == null` alone
/// cannot see any of these problems.
///
/// Tests draw with the Ahem font, one full em per glyph, wider than any real
/// font: size the widget so its text fits in Ahem, or pass [allowEllipsis]
/// for a case that only checks the painted rect and the text height (an
/// ellipsized line may legitimately be wider than the box it was cut to, so
/// the width check is skipped; the height check stays).
void expectTextsFit(
  WidgetTester tester,
  Finder within, {
  double slack = 0.5,
  bool allowEllipsis = false,
}) {
  final box = tester.getRect(within).inflate(slack);
  final paragraphs = find
      .descendant(of: within, matching: find.byType(RichText))
      .evaluate();
  expect(paragraphs, isNotEmpty, reason: 'no text found under $within');
  for (final element in paragraphs) {
    final paragraph = element.renderObject! as RenderParagraph;
    final text = paragraph.text.toPlainText();
    if (!allowEllipsis) {
      expect(paragraph.didExceedMaxLines, isFalse, reason: '"$text" is cut');
    }
    final laidOut = paragraph.textSize;
    expect(
      laidOut.height,
      lessThanOrEqualTo(paragraph.size.height + slack),
      reason:
          '"$text" needs ${laidOut.height} dp but its box is '
          '${paragraph.size.height} dp (clipped)',
    );
    if (!allowEllipsis) {
      expect(
        laidOut.width,
        lessThanOrEqualTo(paragraph.size.width + slack),
        reason:
            '"$text" needs ${laidOut.width} dp but its box is '
            '${paragraph.size.width} dp (clipped)',
      );
    }
    final painted = MatrixUtils.transformRect(
      paragraph.getTransformTo(null),
      Offset.zero & paragraph.size,
    );
    expect(
      box.contains(painted.topLeft) && box.contains(painted.bottomRight),
      isTrue,
      reason: '"$text" painted at $painted outside $box',
    );
  }
}
