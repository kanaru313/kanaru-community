import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

Widget _page({bool circle = false}) => KDetailLayout(
  header: KDetailHero(
    circle: circle,
    coverBuilder: (context, side) =>
        SizedBox.square(key: const ValueKey('cover'), dimension: side),
    body: const [Text('by artist')],
    actions: const Text('buttons'),
  ),
  slivers: [
    SliverList.builder(
      itemCount: 5,
      itemBuilder: (_, i) => SizedBox(height: 48, child: Text('row $i')),
    ),
  ],
);

void main() {
  testWidgets('narrow: 132 cover on the left, text bottom aligned', (
    tester,
  ) async {
    useWindow(tester, const Size(839, 800));
    await tester.pumpWidget(host(_page()));
    expect(tester.getSize(find.byKey(const ValueKey('cover'))).width, 132);
    final cover = tester.getRect(find.byKey(const ValueKey('cover')));
    final buttons = tester.getRect(find.text('buttons'));
    expect(buttons.left, greaterThan(cover.right));
    expect(buttons.bottom, lessThanOrEqualTo(cover.bottom + 1));
  });

  testWidgets('wide: 320 cover column, text under the cover', (tester) async {
    useWindow(tester, const Size(840, 800));
    await tester.pumpWidget(host(_page()));
    expect(tester.getSize(find.byKey(const ValueKey('cover'))).width, 320);
    final cover = tester.getRect(find.byKey(const ValueKey('cover')));
    expect(tester.getRect(find.text('by artist')).top, cover.bottom);
    expect(find.byType(ShaderMask), findsNWidgets(2));
  });

  testWidgets('a round photo is not faded', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_page(circle: true)));
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.getSize(find.byKey(const ValueKey('cover'))).width, 288);
  });
}
