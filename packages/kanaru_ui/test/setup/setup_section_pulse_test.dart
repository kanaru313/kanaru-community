import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _section(GlobalKey<SetupSectionPulseState> key) => SetupSectionPulse(
  key: key,
  child: const SetupSection(title: Text('Folders'), children: [Text('row')]),
);

/// The border box the pulse draws (the foreground decoration).
Finder get _outline => find.byWidgetPredicate(
  (w) => w is DecoratedBox && w.position == DecorationPosition.foreground,
);

void main() {
  testWidgets('pulse flips the state and ends', (tester) async {
    useWindow(tester, const Size(400, 800));
    final key = GlobalKey<SetupSectionPulseState>();
    await tester.pumpWidget(host(_section(key)));
    expect(key.currentState!.isPulsing, isFalse);
    key.currentState!.pulse();
    await tester.pump();
    expect(key.currentState!.isPulsing, isTrue);
    await tester.pumpAndSettle();
    expect(key.currentState!.isPulsing, isFalse);
  });

  testWidgets('the outline is the card only, not the title', (tester) async {
    useWindow(tester, const Size(400, 800));
    final key = GlobalKey<SetupSectionPulseState>();
    await tester.pumpWidget(host(_section(key)));
    key.currentState!.pulse();
    await tester.pump(const Duration(milliseconds: 100));
    final outline = tester.getRect(_outline.first);
    final card = tester.getRect(
      find.ancestor(of: find.text('row'), matching: find.byType(Material)).first,
    );
    expect(outline, card);
    expect(outline.top, greaterThan(tester.getRect(find.text('Folders')).bottom));
    final border =
        ((tester.widget<DecoratedBox>(_outline.first)).decoration
                as BoxDecoration)
            .border;
    expect(border, isNotNull);
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion does not pulse', (tester) async {
    useWindow(tester, const Size(400, 800));
    final key = GlobalKey<SetupSectionPulseState>();
    await tester.pumpWidget(host(_section(key), reduceMotion: true));
    key.currentState!.pulse();
    await tester.pump();
    expect(key.currentState!.isPulsing, isFalse);
  });
}
