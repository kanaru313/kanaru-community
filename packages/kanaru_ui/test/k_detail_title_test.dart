import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _name = 'Blue Hour';

/// The name as the header (not the content) draws it.
Finder get _inHeader =>
    find.descendant(of: find.byType(PageHeader), matching: find.text(_name));

Widget _page(Widget content) => host(
  KDetailTitleHost(
    child: Column(
      children: [
        PageHeader(title: _name, onBack: () {}, titleInContent: true),
        Expanded(child: content),
      ],
    ),
  ),
);

List<Widget> _rows(int n) => [
  SliverList.builder(
    itemCount: n,
    itemBuilder: (_, i) => SizedBox(height: 48, child: Text('row $i')),
  ),
];

/// A vertical scroll: 100 dp of space, the name, a long list.
Widget _scroll() => CustomScrollView(
  slivers: [
    const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.only(top: 100),
        child: KGridHeading(title: _name),
      ),
    ),
    ..._rows(40),
  ],
);

Future<void> _drag(WidgetTester tester, Finder f, double dy) async {
  await tester.drag(f, Offset(0, dy));
  await tester.pump();
}

double space = 100;

void main() {
  testWidgets('the header is empty at the top of the page', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(_scroll()));
    await tester.pumpAndSettle();
    expect(_inHeader, findsNothing);
    expect(find.text(_name), findsOneWidget);
  });

  testWidgets('one drag past the name shows it in the header next frame', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(_scroll()));
    await _drag(tester, find.byType(CustomScrollView), -300);
    expect(_inHeader, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the name is a header in the content, not in the page header', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_page(_scroll()));
    expect(
      tester.getSemantics(find.bySemanticsLabel(_name)),
      isSemantics(isHeader: true, label: _name),
    );
    // Scrolled away: the name shows in the page header, which says nothing.
    await _drag(tester, find.byType(CustomScrollView), -300);
    await tester.pumpAndSettle();
    expect(_inHeader, findsOneWidget);
    expect(find.bySemanticsLabel(_name), findsNothing);
    handle.dispose();
  });

  testWidgets('scrolling back hides it again and drops the Text', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(_scroll()));
    await _drag(tester, find.byType(CustomScrollView), -300);
    expect(_inHeader, findsOneWidget);
    await _drag(tester, find.byType(CustomScrollView), 300);
    await tester.pumpAndSettle();
    expect(_inHeader, findsNothing);
  });

  testWidgets('wide, tall window: the left column stays put, header empty', (
    tester,
  ) async {
    useWindow(tester, const Size(1000, 800));
    await tester.pumpWidget(
      _page(
        KDetailLayout(
          header: const Padding(
            padding: EdgeInsets.only(top: 100),
            child: KGridHeading(title: _name),
          ),
          slivers: _rows(40),
        ),
      ),
    );
    await _drag(tester, find.text('row 3'), -500);
    await tester.pumpAndSettle();
    expect(_inHeader, findsNothing);
  });

  testWidgets('wide, short window: scrolling the left column shows it', (
    tester,
  ) async {
    useWindow(tester, const Size(1000, 360));
    await tester.pumpWidget(
      _page(
        KDetailLayout(
          header: const Column(
            children: [
              SizedBox(height: 100),
              KGridHeading(title: _name),
              SizedBox(height: 600),
            ],
          ),
          slivers: _rows(40),
        ),
      ),
    );
    expect(_inHeader, findsNothing);
    await _drag(tester, find.text(_name), -300);
    expect(_inHeader, findsOneWidget);
  });

  testWidgets('crossing 839 to 840 and back while collapsed raises nothing', (
    tester,
  ) async {
    Widget page() => _page(
      KDetailLayout(
        header: const Padding(
          padding: EdgeInsets.only(top: 100),
          child: KGridHeading(title: _name),
        ),
        slivers: _rows(40),
      ),
    );
    useWindow(tester, const Size(839, 800));
    await tester.pumpWidget(page());
    await _drag(tester, find.byType(CustomScrollView), -300);
    expect(_inHeader, findsOneWidget);
    useWindow(tester, const Size(840, 800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_inHeader, findsNothing, reason: 'the wide column is not scrolled');
    useWindow(tester, const Size(839, 800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_inHeader, findsNothing);
  });

  testWidgets('a horizontal shelf scrolling changes nothing', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      _page(
        CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: KGridHeading(title: _name)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < 20; i++)
                      SizedBox(width: 120, child: Text('card $i')),
                  ],
                ),
              ),
            ),
            ..._rows(40),
          ],
        ),
      ),
    );
    await tester.drag(find.text('card 1'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(_inHeader, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removing host and title together raises nothing', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_page(_scroll()));
    await _drag(tester, find.byType(CustomScrollView), -300);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('without a host the title and the header work alone', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(
        Column(
          children: [
            PageHeader(title: _name, onBack: () {}, titleInContent: true),
            Expanded(child: _scroll()),
          ],
        ),
      ),
    );
    await _drag(tester, find.byType(CustomScrollView), -300);
    await tester.pumpAndSettle();
    expect(_inHeader, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('space growing above the name after mount hides it again', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    late void Function(double) setSpace;
    await tester.pumpWidget(
      _page(
        StatefulBuilder(
          builder: (context, setState) {
            setSpace = (v) => setState(() => space = v);
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: space),
                    child: const KGridHeading(title: _name),
                  ),
                ),
                ..._rows(40),
              ],
            );
          },
        ),
      ),
    );
    await _drag(tester, find.byType(CustomScrollView), -250);
    expect(_inHeader, findsOneWidget);
    setSpace(300);
    await tester.pumpAndSettle();
    expect(_inHeader, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
