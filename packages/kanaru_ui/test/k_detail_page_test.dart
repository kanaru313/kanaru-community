import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

TransitionRoute<void>? _route;

Widget _app({
  required bool disableAnimations,
  bool instantTheme = false,
  ValueNotifier<bool>? instantNotifier,
}) {
  final base = buildKanaruTheme(brightness: Brightness.light);
  ThemeData themeFor(bool instant) => instant
      ? base.copyWith(
          pageTransitionsTheme: kanaruPageTransitionsTheme(instant: true),
        )
      : base;
  Widget app(bool instant) => MaterialApp(
    theme: themeFor(instant),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).push(
            _route = const KDetailPage(
              key: ValueKey('p'),
              child: Text('content'),
            ).createRoute(context) as TransitionRoute<void>,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  if (instantNotifier == null) return app(instantTheme);
  return ValueListenableBuilder<bool>(
    valueListenable: instantNotifier,
    builder: (_, instant, _) => app(instant),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 40));
}

void main() {
  testWidgets('paints an opaque surface ground under its child', (
    tester,
  ) async {
    useWindow(tester, const Size(500, 900));
    await tester.pumpWidget(_app(disableAnimations: false));
    await _open(tester);
    await tester.pumpAndSettle();
    final surface = Theme.of(tester.element(find.text('content')))
        .colorScheme
        .surface;
    final boxes = tester.widgetList<ColoredBox>(
      find.ancestor(
        of: find.text('content'),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(boxes.map((b) => b.color), contains(surface));
    expect(surface.a, 1.0);
  });

  testWidgets('desktop fades in and does not slide', (tester) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(_app(disableAnimations: false));
    await _open(tester);
    final c = find.ancestor(
      of: find.text('content'),
      matching: find.byType(FadeTransition),
    );
    expect(
      tester.widgetList<FadeTransition>(c).any((f) => f.opacity.value < 1),
      isTrue,
    );
    expect(
      find.ancestor(
        of: find.text('content'),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('mobile slides in from the right', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_app(disableAnimations: false));
    await _open(tester);
    final slide = tester.widget<SlideTransition>(
      find
          .ancestor(
            of: find.text('content'),
            matching: find.byType(SlideTransition),
          )
          .first,
    );
    expect(slide.position.value.dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(slide.position.value.dx, 0);
  });

  for (final mobile in [true, false]) {
    testWidgets(
      'disableAnimations: page is there at once (${mobile ? 'mobile' : 'desktop'})',
      (tester) async {
        useWindow(
          tester,
          mobile ? const Size(400, 800) : const Size(1400, 900),
        );
        await tester.pumpWidget(_app(disableAnimations: true));
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        expect(find.text('content'), findsOneWidget);
        expect(_route!.transitionDuration, Duration.zero);
        expect(_route!.reverseTransitionDuration, Duration.zero);
        expect(
          find
              .byType(SlideTransition)
              .evaluate()
              .where(
                (e) =>
                    find
                        .descendant(
                          of: find.byWidget(e.widget),
                          matching: find.text('content'),
                        )
                        .evaluate()
                        .isNotEmpty &&
                    (e.widget as SlideTransition).position.value.dx != 0,
              ),
          isEmpty,
        );
      },
    );
  }

  testWidgets('instant theme: zero duration, no transition', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(_app(disableAnimations: false, instantTheme: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('content'), findsOneWidget);
    expect(_route!.transitionDuration, Duration.zero);
    expect(
      find.ancestor(
        of: find.text('content'),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('motion turned off while the page is open: Back is instant', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final instant = ValueNotifier(false);
    await tester.pumpWidget(
      _app(disableAnimations: false, instantNotifier: instant),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_route!.reverseTransitionDuration, KMotion.pageOut);
    instant.value = true;
    // MaterialApp animates a theme change; let it finish.
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('content'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('content'), findsNothing);
  });

  testWidgets('motion turned on while the page is open: Back animates', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final instant = ValueNotifier(true);
    await tester.pumpWidget(
      _app(disableAnimations: false, instantNotifier: instant),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    instant.value = false;
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('content'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('content'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('content'), findsNothing);
  });

  testWidgets('the pushed page is a route-scoping semantics node', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app(disableAnimations: true));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final node = tester.getSemantics(
      find
          .ancestor(
            of: find.text('content'),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.scopesRoute == true,
            ),
          )
          .first,
    );
    expect(node, isSemantics(scopesRoute: true));
    handle.dispose();
  });
}
