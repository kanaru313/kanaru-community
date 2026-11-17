import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  testWidgets('shows the title and its caption under it', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(const KGridHeading(title: 'Albums', caption: '12 albums')),
    );
    expect(
      tester.getTopLeft(find.text('Albums')).dy,
      lessThan(tester.getTopLeft(find.text('12 albums')).dy),
    );
  });

  testWidgets('without a caption it is just the title', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(const KGridHeading(title: 'Albums')));
    expect(find.text('Albums'), findsOneWidget);
  });

  testWidgets('the title is a semantics header', (tester) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const KGridHeading(title: 'Albums')));
    expect(
      tester.getSemantics(find.text('Albums')),
      isSemantics(isHeader: true, label: 'Albums'),
    );
    handle.dispose();
  });

  testWidgets('a long title is clamped to two lines', (tester) async {
    useWindow(tester, const Size(200, 800));
    const long =
        'Những bài hát hay nhất của Trịnh Công Sơn tuyển tập đặc biệt nhiều';
    await tester.pumpWidget(host(const KGridHeading(title: 'A')));
    final one = tester.getSize(find.text('A')).height;
    await tester.pumpWidget(host(const KGridHeading(title: long)));
    expect(tester.getSize(find.text(long)).height, closeTo(one * 2, 1));
  });

  testWidgets('it reports to a host when scrolled out of sight', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    var collapsed = false;
    await tester.pumpWidget(
      host(
        KDetailTitleHost(
          child: Column(
            children: [
              Builder(
                builder: (context) {
                  collapsed = KDetailTitleHost.collapsedOf(context);
                  return const SizedBox(height: 10);
                },
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(
                      child: KGridHeading(title: 'Albums'),
                    ),
                    SliverList.builder(
                      itemCount: 40,
                      itemBuilder: (_, i) => const SizedBox(height: 48),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(collapsed, isFalse);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pump();
    expect(collapsed, isTrue);
  });
}
