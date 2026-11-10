import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';

class _Ext implements KanaruExtension {
  _Ext(this.id, [this.onRegister]);
  @override
  final String id;
  final void Function(ExtensionRegistry r)? onRegister;
  @override
  void register(ExtensionRegistry registry) => onRegister?.call(registry);
}

NavItem _nav(
  String id,
  int order, {
  String? parentId,
  bool mobileTab = true,
  bool pushed = false,
  bool comingSoon = false,
  void Function(BuildContext)? onSelect,
}) => NavItem(
  id: id,
  path: '/$id',
  icon: KIcons.placeholder,
  selectedIcon: KIcons.placeholder,
  label: (_) => id,
  order: order,
  parentId: parentId,
  mobileTab: mobileTab,
  pushed: pushed,
  comingSoon: comingSoon,
  onSelect: onSelect,
);

void main() {
  test('nav items sort by order, ties keep registration order', () {
    final r = ExtensionRegistry()
      ..install([
        _Ext(
          'a',
          (r) => r
            ..addNavItem(_nav('c', 30))
            ..addNavItem(_nav('b1', 20))
            ..addNavItem(_nav('b2', 20)),
        ),
        _Ext('b', (r) => r.addNavItem(_nav('a', 10))),
      ]);
    expect(r.navItems.map((n) => n.id), ['a', 'b1', 'b2', 'c']);
  });

  test('extensions register in the given order', () {
    final seen = <String>[];
    ExtensionRegistry().install([
      _Ext('one', (_) => seen.add('one')),
      _Ext('two', (_) => seen.add('two')),
    ]);
    expect(seen, ['one', 'two']);
  });

  test('duplicate extension id throws StateError', () {
    expect(
      () => ExtensionRegistry().install([_Ext('x'), _Ext('x')]),
      throwsStateError,
    );
  });

  test('duplicate nav item id throws StateError', () {
    final r = ExtensionRegistry()..addNavItem(_nav('a', 1));
    expect(() => r.addNavItem(_nav('a', 2)), throwsStateError);
  });

  test('duplicate nav item path throws StateError', () {
    final r = ExtensionRegistry()..addNavItem(_nav('a', 1));
    final clash = NavItem(
      id: 'b',
      path: '/a',
      icon: KIcons.placeholder,
      selectedIcon: KIcons.placeholder,
      label: (_) => 'b',
      order: 2,
    );
    expect(() => r.addNavItem(clash), throwsStateError);
  });

  test('duplicate GoRoute path throws StateError', () {
    final r = ExtensionRegistry()
      ..addRoute(GoRoute(path: '/x', builder: (_, _) => const SizedBox()));
    expect(
      () =>
          r.addRoute(GoRoute(path: '/x', builder: (_, _) => const SizedBox())),
      throwsStateError,
    );
  });

  test(
    'duplicate settings section and top bar action ids throw StateError',
    () {
      final r = ExtensionRegistry()
        ..addSettingsSection(
          SettingsSection(id: 's', order: 1, builder: (_) => const SizedBox()),
        )
        ..addTopBarAction(
          TopBarAction(id: 't', order: 1, builder: (_) => const SizedBox()),
        );
      expect(
        () => r.addSettingsSection(
          SettingsSection(id: 's', order: 2, builder: (_) => const SizedBox()),
        ),
        throwsStateError,
      );
      expect(
        () => r.addTopBarAction(
          TopBarAction(id: 't', order: 2, builder: (_) => const SizedBox()),
        ),
        throwsStateError,
      );
    },
  );

  test('panel surfaces: lookup by id, order, duplicate id throws', () {
    final r = ExtensionRegistry()
      ..addPanelSurface(
        PanelSurface(id: 'b', order: 2, body: (_) => const SizedBox()),
      )
      ..addPanelSurface(
        PanelSurface(id: 'chat', order: 1, body: (_) => const SizedBox()),
      );
    expect(r.panelSurfaces.map((p) => p.id), ['chat', 'b']);
    expect(r.panelSurface('chat')?.id, 'chat');
    expect(r.panelSurface('none'), isNull);
    expect(
      () => r.addPanelSurface(
        PanelSurface(id: 'chat', order: 3, body: (_) => const SizedBox()),
      ),
      throwsStateError,
    );
  });

  test('a second license service throws StateError', () {
    final r = ExtensionRegistry()..setLicenseService(_Granted());
    expect(() => r.setLicenseService(_Granted()), throwsStateError);
  });

  test('branchNavItems leaves out pushed items', () {
    final r = ExtensionRegistry()
      ..addNavItem(_nav('a', 1))
      ..addNavItem(
        NavItem(
          id: 'p',
          path: '/p',
          icon: KIcons.placeholder,
          selectedIcon: KIcons.placeholder,
          label: (_) => 'p',
          order: 2,
          pushed: true,
        ),
      );
    expect(r.branchNavItems.map((n) => n.id), ['a']);
    expect(r.navItems, hasLength(2));
  });

  test('startup hooks keep registration order', () {
    final r = ExtensionRegistry()
      ..addStartupHook((_) async {})
      ..addStartupHook((_) async {});
    expect(r.startupHooks, hasLength(2));
  });

  test('default license service is free; an extension can replace it', () {
    final r = ExtensionRegistry();
    expect(r.licenseService, isA<FreeLicenseService>());
    final granted = _Granted();
    r.setLicenseService(granted);
    expect(r.licenseService, same(granted));
  });

  group('nav item placement', () {
    test('mobileOrder defaults to order', () {
      expect(_nav('a', 7).mobileOrder, 7);
      expect(
        NavItem(
          id: 'b',
          path: '/b',
          icon: KIcons.placeholder,
          selectedIcon: KIcons.placeholder,
          label: (_) => 'b',
          order: 7,
          mobileOrder: 70,
        ).mobileOrder,
        70,
      );
    });

    test('child, coming-soon and onSelect items are not branches', () {
      final r = ExtensionRegistry()
        ..addNavItem(_nav('parent', 10))
        ..addNavItem(_nav('child', 11, parentId: 'parent', mobileTab: false))
        ..addNavItem(_nav('soon', 12, comingSoon: true, mobileTab: false))
        ..addNavItem(_nav('action', 13, onSelect: (_) {}, mobileTab: false))
        ..addNavItem(_nav('tab', 14));
      expect(r.branchNavItems.map((n) => n.id), ['parent', 'tab']);
      expect(r.navItems.map((n) => n.id), [
        'parent',
        'child',
        'soon',
        'action',
        'tab',
      ]);
    });

    test('a child must name a registered tab parent', () {
      final r = ExtensionRegistry()..addNavItem(_nav('p', 1));
      expect(
        () => r.addNavItem(_nav('c', 2, parentId: 'missing', mobileTab: false)),
        throwsStateError,
      );
      expect(
        () => r.addNavItem(_nav('c', 2, parentId: 'p')), // mobileTab stays true
        throwsStateError,
      );
      r.addNavItem(_nav('child', 2, parentId: 'p', mobileTab: false));
      expect(
        () => r.addNavItem(
          _nav('grandchild', 3, parentId: 'child', mobileTab: false),
        ),
        throwsStateError,
      );
    });

    test('a pushed item cannot be a parent', () {
      final r = ExtensionRegistry()
        ..addNavItem(_nav('p', 1, pushed: true, mobileTab: false));
      expect(
        () => r.addNavItem(_nav('c', 2, parentId: 'p', mobileTab: false)),
        throwsStateError,
      );
    });

    test('containsLocation matches the page and its children only', () {
      final item = _nav('lib', 1);
      expect(item.containsLocation('/lib'), isTrue);
      expect(item.containsLocation('/lib/songs'), isTrue);
      expect(item.containsLocation('/library'), isFalse);
    });
  });

  test('flush hooks keep registration order', () {
    Future<void> a(ProviderContainer _) async {}
    Future<void> b(ProviderContainer _) async {}
    final r = ExtensionRegistry()
      ..addFlushHook(a)
      ..addFlushHook(b);
    expect(r.flushHooks, [a, b]);
  });
}

class _Granted implements LicenseService {
  @override
  LicenseStatus statusOf(ProFeature feature) => LicenseStatus.granted;
}
