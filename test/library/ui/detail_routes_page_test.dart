import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/browse/library_routes.dart';
import 'package:kanaru/src/library/ui/playlist_common/playlist_registration.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

const _detailLocations = [
  '/library/albums/a',
  '/library/artists/a',
  '/library/artists/a/albums',
  '/library/artists/a/appears',
  '/library/genres/g',
  '/library/genres/g/artists',
  '/library/genres/g/albums',
  '/library/languages/l',
  '/library/languages/l/artists',
  '/library/languages/l/albums',
  '/playlists/favorites',
  '/playlists/some-uid',
];

/// The real route tree, with each detail route's page recorded and its heavy
/// content swapped for a stub (the pages need the database to build).
class _Tree {
  final built = <String, Page<void>>{};

  List<RouteBase> routes() {
    final registry = ExtensionRegistry();
    registerPlaylists(registry);
    return [
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      libraryRoute(),
      ...registry.routes,
    ].map(_stub).toList();
  }

  RouteBase _stub(RouteBase r) {
    if (r is! GoRoute) return r;
    final original = r.pageBuilder;
    return GoRoute(
      path: r.path,
      redirect: r.redirect,
      builder: original == null ? r.builder : null,
      pageBuilder: original == null
          ? null
          : (context, state) {
              final page = original(context, state);
              built[state.uri.path] = page;
              return page is KDetailPage
                  ? KDetailPage(
                      key: state.pageKey,
                      child: const Scaffold(body: Text('stub')),
                    )
                  : NoTransitionPage<void>(
                      key: state.pageKey,
                      child: const SizedBox(),
                    );
            },
      routes: r.routes.map(_stub).toList(),
    );
  }
}

Iterable<Page<dynamic>> _pages(WidgetTester tester) =>
    tester.widgetList<Navigator>(find.byType(Navigator)).expand((n) => n.pages);

Future<(GoRouter, _Tree)> _pump(
  WidgetTester tester, {
  bool disableAnimations = false,
}) async {
  final tree = _Tree();
  final router = GoRouter(routes: tree.routes());
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router, tree);
}

void main() {
  for (final location in _detailLocations) {
    testWidgets('$location is a KDetailPage that animates', (tester) async {
      final (router, tree) = await _pump(tester);
      router.push(location);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tree.built[location], isA<KDetailPage>());
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
    });
  }

  testWidgets('a detail page has an opaque surface ground', (tester) async {
    final (router, _) = await _pump(tester);
    router.push(_detailLocations.first);
    await tester.pumpAndSettle();
    // The stub adds no ground, so the nearest ColoredBox above it is the one
    // the detail route paints itself.
    final ground = tester
        .widget<ColoredBox>(
          find
              .ancestor(
                of: find.text('stub'),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;
    final surface = Theme.of(tester.element(find.text('stub')))
        .colorScheme
        .surface;
    expect(ground, surface);
    expect(surface.a, 1.0);
  });

  testWidgets('with animations off a detail push lands in one pump', (
    tester,
  ) async {
    final (router, _) = await _pump(tester, disableAnimations: true);
    router.push(_detailLocations.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(_pages(tester).whereType<KDetailPage>(), isNotEmpty);
    expect(find.text('stub'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
