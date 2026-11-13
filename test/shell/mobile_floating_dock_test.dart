import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/shell/ui/mobile_floating_dock.dart';
import 'package:material_ui/material_ui.dart';

/// Page that shows the bottom media padding it was given.
class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) =>
      Text('pad ${MediaQuery.paddingOf(context).bottom}');
}

Widget _host({
  required double dockHeight,
  bool hidden = false,
  double systemBottom = 0,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(800, 600),
      padding: EdgeInsets.only(bottom: systemBottom),
    ),
    child: MobileFloatingDock(
      hidden: hidden,
      body: const _Probe(),
      dock: SizedBox(key: const Key('dock'), height: dockHeight),
    ),
  ),
);

void main() {
  testWidgets('the page gets the dock height on top of the system inset', (
    tester,
  ) async {
    await tester.pumpWidget(_host(dockHeight: 72, systemBottom: 24));
    await tester.pump();
    expect(find.text('pad 96.0'), findsOneWidget);
    // The dock sits on the bottom edge, over the page.
    expect(
      tester.getBottomLeft(find.byKey(const Key('dock'))).dy,
      tester.getBottomLeft(find.byType(MobileFloatingDock)).dy,
    );
  });

  testWidgets('a dock that grows or shrinks updates the page padding', (
    tester,
  ) async {
    await tester.pumpWidget(_host(dockHeight: 72));
    await tester.pump();
    expect(find.text('pad 72.0'), findsOneWidget);

    await tester.pumpWidget(_host(dockHeight: 140));
    await tester.pump();
    expect(find.text('pad 140.0'), findsOneWidget);

    await tester.pumpWidget(_host(dockHeight: 0));
    await tester.pump();
    expect(find.text('pad 0.0'), findsOneWidget);
  });

  testWidgets('a hidden dock (keyboard open) is offstage and adds no padding', (
    tester,
  ) async {
    await tester.pumpWidget(_host(dockHeight: 72, hidden: true));
    await tester.pump();
    expect(find.text('pad 0.0'), findsOneWidget);
    expect(find.byKey(const Key('dock')), findsNothing);
    // Kept in the tree, so the pieces keep their state.
    expect(find.byKey(const Key('dock'), skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(_host(dockHeight: 72));
    await tester.pump();
    expect(find.text('pad 72.0'), findsOneWidget);
    expect(find.byKey(const Key('dock')), findsOneWidget);
  });
}
