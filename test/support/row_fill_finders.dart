import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The background the card [card] paints on its own row Material.
Color? cardBackground(WidgetTester tester, Finder card) => tester
    .widget<Material>(
      find.descendant(of: card, matching: find.byType(Material)).first,
    )
    .color;

/// Expects the first [KMediaCard] under [within] (the whole tree by default)
/// to paint the neutral row fill of the theme's brightness.
void expectRowFilled(WidgetTester tester, {Finder? within}) {
  final card = within == null
      ? find.byType(KMediaCard).first
      : find.descendant(of: within, matching: find.byType(KMediaCard)).first;
  expect(
    cardBackground(tester, card),
    KRowColors.fill(Theme.of(tester.element(card)).brightness),
  );
}
