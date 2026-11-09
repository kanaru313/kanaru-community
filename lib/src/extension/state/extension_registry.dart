import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../domain/license.dart';
import '../kanaru_extension.dart';
import 'registry_entries.dart';

/// Collects contributions from every [KanaruExtension]. Only list-like
/// extension points live here; each list keeps registration order.
class ExtensionRegistry {
  ExtensionRegistry();

  final _extensionIds = <String>{};
  final _routes = <RouteBase>[];
  final _navItems = <NavItem>[];
  final _settingsSections = <SettingsSection>[];
  final _topBarActions = <TopBarAction>[];
  final _startupHooks = <StartupHook>[];
  final _l10nDelegates = <LocalizationsDelegate<Object?>>[];
  LicenseService _licenseService = const FreeLicenseService();

  /// All routes, including those of nav items.
  List<RouteBase> get routes => List.unmodifiable(_routes);

  /// Nav items by ascending `order`; ties keep registration order.
  List<NavItem> get navItems => _byOrder(_navItems, (n) => n.order);

  List<SettingsSection> get settingsSections =>
      _byOrder(_settingsSections, (s) => s.order);

  List<TopBarAction> get topBarActions => _byOrder(_topBarActions, (a) => a.order);

  List<StartupHook> get startupHooks => List.unmodifiable(_startupHooks);
  List<LocalizationsDelegate<Object?>> get l10nDelegates =>
      List.unmodifiable(_l10nDelegates);

  /// The one license service; the last extension that sets it wins.
  LicenseService get licenseService => _licenseService;

  /// Stable sort (ties keep registration order) into an unmodifiable list.
  static List<T> _byOrder<T>(List<T> items, int Function(T) order) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    indexed.sort((a, b) {
      final byOrder = order(a.$2).compareTo(order(b.$2));
      return byOrder != 0 ? byOrder : a.$1.compareTo(b.$1);
    });
    return List.unmodifiable([for (final e in indexed) e.$2]);
  }

  void addRoute(RouteBase route) => _routes.add(route);

  void addNavItem(NavItem item) {
    if (_navItems.any((n) => n.id == item.id)) {
      throw StateError('Duplicate nav item id "${item.id}"');
    }
    _navItems.add(item);
  }

  void addSettingsSection(SettingsSection section) => _settingsSections.add(section);
  void addTopBarAction(TopBarAction action) => _topBarActions.add(action);
  void addStartupHook(StartupHook hook) => _startupHooks.add(hook);
  void addL10nDelegate(LocalizationsDelegate<Object?> delegate) =>
      _l10nDelegates.add(delegate);
  void setLicenseService(LicenseService service) => _licenseService = service;

  /// Registers [extensions] in order. Throws [StateError] on a repeated id.
  void install(Iterable<KanaruExtension> extensions) {
    for (final extension in extensions) {
      if (!_extensionIds.add(extension.id)) {
        throw StateError('Duplicate extension id "${extension.id}"');
      }
      extension.register(this);
    }
  }
}
