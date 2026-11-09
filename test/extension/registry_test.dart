import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';

class _Ext implements KanaruExtension {
  _Ext(this.id, [this.onRegister]);
  @override
  final String id;
  final void Function(ExtensionRegistry r)? onRegister;
  @override
  void register(ExtensionRegistry registry) => onRegister?.call(registry);
}

NavItem _nav(String id, int order) => NavItem(
      id: id,
      path: '/$id',
      icon: Icons.circle,
      selectedIcon: Icons.circle,
      label: (_) => id,
      order: order,
    );

void main() {
  test('nav items sort by order, ties keep registration order', () {
    final r = ExtensionRegistry()
      ..install([
        _Ext('a', (r) => r
          ..addNavItem(_nav('c', 30))
          ..addNavItem(_nav('b1', 20))
          ..addNavItem(_nav('b2', 20))),
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
}

class _Granted implements LicenseService {
  @override
  LicenseStatus statusOf(ProFeature feature) => LicenseStatus.granted;
}
