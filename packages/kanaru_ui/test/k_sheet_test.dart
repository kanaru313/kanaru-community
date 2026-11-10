import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _opener({bool draggable = true}) => Builder(
      builder: (context) => TextButton(
        onPressed: () => showKSheet<void>(
          context,
          draggable: draggable,
          builder: (_) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('content'),
          ),
        ),
        child: const Text('open'),
      ),
    );

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('narrow window uses a bottom sheet ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(_opener(), brightness: brightness, textScale: scale));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('600 dp and wider uses a dialog', (tester) async {
    useWindow(tester, const Size(700, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('scrim tap closes the sheet', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();
    expect(find.text('content'), findsNothing);
  });

  testWidgets('dragging down past the threshold closes the sheet', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('content'), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('content'), findsNothing);
  });

  testWidgets('system Back closes the sheet', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_opener()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('content'), findsNothing);
  });

  testWidgets('keyboard shrinks the sheet room', (tester) async {
    useWindow(tester, const Size(400, 800));
    tester.view.viewInsets = const FakeViewPadding(bottom: 500);
    await tester.pumpWidget(host(Builder(
      builder: (context) => TextButton(
        onPressed: () => showKSheet<void>(
          context,
          fixedHeight: true,
          builder: (_) => const SizedBox.expand(key: Key('body')),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('body'))).height, lessThanOrEqualTo(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fixedHeight applies to the dialog branch', (tester) async {
    useWindow(tester, const Size(700, 800));
    await tester.pumpWidget(host(Builder(
      builder: (context) => TextButton(
        onPressed: () => showKSheet<void>(
          context,
          fixedHeight: true,
          builder: (_) => const Text('short'),
        ),
        child: const Text('open'),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.descendant(of: find.byType(Dialog), matching: find.byType(ConstrainedBox)).last).height, closeTo(680, 1));
  });

  testWidgets('useRootNavigator shows the sheet on the root navigator', (tester) async {
    useWindow(tester, const Size(400, 800));
    final nestedKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(host(Navigator(
      key: nestedKey,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (context) => TextButton(
          onPressed: () => showKSheet<void>(
            context,
            useRootNavigator: true,
            builder: (_) => const Text('content'),
          ),
          child: const Text('open'),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('content'), findsOneWidget);
    // The nested navigator still holds only its page; the sheet went to the root.
    expect(nestedKey.currentState!.canPop(), isFalse);
  });
}
