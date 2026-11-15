import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

/// Expects the first [KMediaCard] under [within] (the whole tree by default)
/// to be an ordinary row: filled, not playing, not selected. How the fill
/// looks is tested in `kanaru_ui`, not here.
void expectRowFilled(WidgetTester tester, {Finder? within}) {
  final card = within == null
      ? find.byType(KMediaCard).first
      : find.descendant(of: within, matching: find.byType(KMediaCard)).first;
  final widget = tester.widget<KMediaCard>(card);
  expect(widget.filled, isTrue);
  expect(widget.current, isFalse);
  expect(widget.selected, isFalse);
}
