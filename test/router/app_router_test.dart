import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/router/app_router.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_settings_store.dart';

class _GateNotifier extends Notifier<bool> {
  _GateNotifier([this.initial = false]);
  final bool initial;
  @override
  bool build() => initial;
  void set(bool value) => state = value;
}

final _gate = NotifierProvider<_GateNotifier, bool>(_GateNotifier.new);

class _Ext implements KanaruExtension {
  _Ext(this.onRegister);
  final void Function(ExtensionRegistry r) onRegister;
  @override
  String get id => 'router-test';
  @override
  void register(ExtensionRegistry r) => onRegister(r);
}

NavItem _item(
  String id,
  String path,
  int order, {
  String? parentId,
  bool mobileTab = true,
}) => NavItem(
  id: id,
  path: path,
  icon: KIcons.placeholder,
  selectedIcon: KIcons.placeholder,
  label: (_) => id,
  order: order,
  parentId: parentId,
  mobileTab: mobileTab,
);

/// A library tab with a nested list route and a welcome page.
KanaruExtension _tabWithChild({bool welcome = true}) => _Ext((r) {
  r
    ..addNavItem(_item('lib', '/lib', 50))
    ..addNavItem(
      _item('songs', '/lib/songs', 51, parentId: 'lib', mobileTab: false),
    )
    ..addRoute(
      GoRoute(
        path: '/lib',
        builder: (_, _) => const Text('lib page'),
        routes: [
          GoRoute(path: 'songs', builder: (_, _) => const Text('songs page')),
        ],
      ),
    );
  if (welcome) {
    r.addRoute(
      GoRoute(
        path: firstRunPath,
        builder: (_, _) => const Text('welcome page'),
      ),
    );
  }
});

Future<ProviderContainer> _pump(
  WidgetTester tester,
  KanaruExtension ext, {
  bool required = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 800);
  addTearDown(tester.view.reset);
  final registry = ExtensionRegistry()..install([...builtInExtensions, ext]);
  final container = ProviderContainer(
    overrides: [
      extensionRegistryProvider.overrideWithValue(registry),
      nativeVersionsProvider.overrideWithValue('bridge test'),
      settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      _gate.overrideWith(() => _GateNotifier(required)),
      firstRunRequiredProvider.overrideWith((ref) => ref.watch(_gate)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const KanaruApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

String _location(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  testWidgets(
    'a child nav item resolves to a nested route and is not a branch',
    (tester) async {
      final registry = ExtensionRegistry()
        ..install([...builtInExtensions, _tabWithChild()]);
      expect(
        registry.branchNavItems.map((n) => n.id),
        isNot(contains('songs')),
      );
      expect(() => buildRouter(registry), returnsNormally);

      final container = await _pump(tester, _tabWithChild());
      container.read(routerProvider).go('/lib/songs');
      await tester.pumpAndSettle();
      expect(find.text('songs page'), findsOneWidget);
    },
  );

  testWidgets('a child nav item without a nested route fails router creation', (
    tester,
  ) async {
    final registry = ExtensionRegistry()
      ..install([
        _Ext((r) {
          r
            ..addNavItem(_item('lib', '/lib', 50))
            ..addNavItem(
              _item(
                'songs',
                '/lib/songs',
                51,
                parentId: 'lib',
                mobileTab: false,
              ),
            )
            ..addRoute(
              GoRoute(path: '/lib', builder: (_, _) => const Text('lib')),
            );
        }),
      ]);
    expect(() => buildRouter(registry), throwsStateError);
  });

  test('a child nav item whose route is top-level, not nested, fails', () {
    final registry = ExtensionRegistry()
      ..install([
        _Ext((r) {
          r
            ..addNavItem(_item('lib', '/lib', 50))
            ..addNavItem(
              _item(
                'songs',
                '/lib/songs',
                51,
                parentId: 'lib',
                mobileTab: false,
              ),
            )
            ..addRoute(
              GoRoute(path: '/lib', builder: (_, _) => const Text('lib')),
            )
            ..addRoute(
              GoRoute(path: '/lib/songs', builder: (_, _) => const Text('s')),
            );
        }),
      ]);
    expect(
      () => buildRouter(registry),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('nested under'),
        ),
      ),
    );
  });

  test('a tab whose route is nested, not top-level, fails', () {
    final registry = ExtensionRegistry()
      ..install([
        _Ext((r) {
          r
            ..addNavItem(_item('a', '/a', 50))
            ..addNavItem(_item('b', '/a/b', 51))
            ..addRoute(
              GoRoute(
                path: '/a',
                builder: (_, _) => const Text('a'),
                routes: [
                  GoRoute(path: 'b', builder: (_, _) => const Text('b')),
                ],
              ),
            );
        }),
      ]);
    expect(
      () => buildRouter(registry),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('must be top-level'),
        ),
      ),
    );
  });

  test('a child whose parent has no route has a clear message', () {
    StateError build(NavItem child, {bool parentRoute = true}) {
      final registry = ExtensionRegistry()
        ..install([
          _Ext((r) {
            r
              ..addNavItem(_item('lib', '/lib', 50))
              ..addNavItem(child);
            if (parentRoute) {
              r.addRoute(
                GoRoute(path: '/lib', builder: (_, _) => const Text('l')),
              );
            }
          }),
        ]);
      try {
        buildRouter(registry);
      } on StateError catch (e) {
        return e;
      }
      throw TestFailure('expected StateError');
    }

    // The registry already refuses a child whose parent is not registered.
    expect(
      () => build(_item('x', '/lib/x', 51, parentId: 'nope', mobileTab: false)),
      throwsStateError,
    );
    expect(
      build(
        _item('x', '/lib/x', 51, parentId: 'lib', mobileTab: false),
        parentRoute: false,
      ).message,
      contains('has no route at "/lib"'),
    );
  });

  testWidgets(
    'first run required redirects every location to the welcome page',
    (tester) async {
      final container = await _pump(tester, _tabWithChild(), required: true);
      expect(_location(container), firstRunPath);
      expect(find.text('welcome page'), findsOneWidget);

      container.read(routerProvider).go('/lib');
      await tester.pumpAndSettle();
      expect(_location(container), firstRunPath);
    },
  );

  testWidgets('finishing first run leaves the welcome page', (tester) async {
    final container = await _pump(tester, _tabWithChild(), required: true);
    expect(_location(container), firstRunPath);

    container.read(_gate.notifier).set(false);
    await tester.pumpAndSettle();
    expect(_location(container), '/');
    expect(find.text('welcome page'), findsNothing);
  });

  testWidgets('first run turning on later redirects the open page', (
    tester,
  ) async {
    final container = await _pump(tester, _tabWithChild());
    expect(_location(container), '/');
    container.read(_gate.notifier).set(true);
    await tester.pumpAndSettle();
    expect(_location(container), firstRunPath);
  });

  test('first run required without a welcome route fails router creation', () {
    final registry = ExtensionRegistry()
      ..install([...builtInExtensions, _tabWithChild(welcome: false)]);
    expect(
      () => buildRouter(registry, firstRunRequired: () => true),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains(firstRunPath),
        ),
      ),
    );
    // Not required: no route needed, no redirect loop possible.
    expect(
      () => buildRouter(registry, firstRunRequired: () => false),
      returnsNormally,
    );
  });
}
