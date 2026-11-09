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
  bool _licenseServiceSet = false;

  /// All routes, including those of nav items.
  List<RouteBase> get routes => List.unmodifiable(_routes);

  /// Nav items by ascending `order`; ties keep registration order.
  List<NavItem> get navItems => _byOrder(_navItems, (n) => n.order);

  /// Nav items that are shell tabs (not [NavItem.pushed]), in nav order. One
  /// shell branch each.
  List<NavItem> get branchNavItems =>
      List.unmodifiable(navItems.where((n) => !n.pushed));

  List<SettingsSection> get settingsSections =>
      _byOrder(_settingsSections, (s) => s.order);

  List<TopBarAction> get topBarActions => _byOrder(_topBarActions, (a) => a.order);

  List<StartupHook> get startupHooks => List.unmodifiable(_startupHooks);
  List<LocalizationsDelegate<Object?>> get l10nDelegates =>
      List.unmodifiable(_l10nDelegates);

  /// The one license service; only one extension may set it.
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

  /// Throws [StateError] when a [GoRoute] with the same path exists: go_router
  /// would silently match the first one, so a later extension could not
  /// replace a route, only be hidden by it.
  void addRoute(RouteBase route) {
    if (route is GoRoute && _routes.any((r) => r is GoRoute && r.path == route.path)) {
      throw StateError('Duplicate route path "${route.path}"');
    }
    _routes.add(route);
  }

  void addNavItem(NavItem item) {
    if (_navItems.any((n) => n.id == item.id)) {
      throw StateError('Duplicate nav item id "${item.id}"');
    }
    if (_navItems.any((n) => n.path == item.path)) {
      throw StateError('Duplicate nav item path "${item.path}"');
    }
    _navItems.add(item);
  }

  void addSettingsSection(SettingsSection section) {
    if (_settingsSections.any((s) => s.id == section.id)) {
      throw StateError('Duplicate settings section id "${section.id}"');
    }
    _settingsSections.add(section);
  }

  void addTopBarAction(TopBarAction action) {
    if (_topBarActions.any((a) => a.id == action.id)) {
      throw StateError('Duplicate top bar action id "${action.id}"');
    }
    _topBarActions.add(action);
  }

  void addStartupHook(StartupHook hook) => _startupHooks.add(hook);
  void addL10nDelegate(LocalizationsDelegate<Object?> delegate) =>
      _l10nDelegates.add(delegate);
  void setLicenseService(LicenseService service) {
    if (_licenseServiceSet) throw StateError('License service already set');
    _licenseServiceSet = true;
    _licenseService = service;
  }

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
