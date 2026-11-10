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
  final _panelSurfaces = <PanelSurface>[];
  final _startupHooks = <StartupHook>[];
  final _flushHooks = <FlushHook>[];
  final _beforeExitHooks = <FlushHook>[];
  final _l10nDelegates = <LocalizationsDelegate<Object?>>[];
  LicenseService _licenseService = const FreeLicenseService();
  bool _licenseServiceSet = false;

  /// All routes, including those of nav items.
  List<RouteBase> get routes => List.unmodifiable(_routes);

  /// Nav items by ascending `order`; ties keep registration order.
  List<NavItem> get navItems => _byOrder(_navItems, (n) => n.order);

  /// Nav items that are shell tabs ([NavItem.isBranch]: not pushed, not a child
  /// of another item, not coming soon, no `onSelect`), in nav order. One shell
  /// branch each.
  List<NavItem> get branchNavItems =>
      List.unmodifiable(navItems.where((n) => n.isBranch));

  List<SettingsSection> get settingsSections =>
      _byOrder(_settingsSections, (s) => s.order);

  List<TopBarAction> get topBarActions =>
      _byOrder(_topBarActions, (a) => a.order);

  List<PanelSurface> get panelSurfaces =>
      _byOrder(_panelSurfaces, (p) => p.order);

  /// The surface registered under [id], or null.
  PanelSurface? panelSurface(String id) {
    for (final p in _panelSurfaces) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<StartupHook> get startupHooks => List.unmodifiable(_startupHooks);
  List<FlushHook> get flushHooks => List.unmodifiable(_flushHooks);
  List<FlushHook> get beforeExitHooks => List.unmodifiable(_beforeExitHooks);
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
    if (route is GoRoute &&
        _routes.any((r) => r is GoRoute && r.path == route.path)) {
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
    final parentId = item.parentId;
    if (parentId != null) {
      final parent = _navItems.where((n) => n.id == parentId).firstOrNull;
      if (parent == null) {
        throw StateError(
          'Nav item "${item.id}" names parent "$parentId", which is not registered '
          '(register the parent first)',
        );
      }
      if (parent.pushed || parent.parentId != null || !parent.isBranch) {
        throw StateError(
          'Nav item "${item.id}": parent "$parentId" must be a tab item',
        );
      }
      if (item.mobileTab) {
        throw StateError(
          'Child nav item "${item.id}" must have mobileTab: false',
        );
      }
      if (item.pushed) {
        throw StateError('Child nav item "${item.id}" cannot be pushed');
      }
    }
    if ((item.comingSoon || item.onSelect != null) && item.pushed) {
      throw StateError(
        'Nav item "${item.id}": comingSoon/onSelect cannot be pushed',
      );
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

  /// Throws [StateError] for a second surface with the same id.
  void addPanelSurface(PanelSurface surface) {
    if (_panelSurfaces.any((p) => p.id == surface.id)) {
      throw StateError('Duplicate panel surface id "${surface.id}"');
    }
    _panelSurfaces.add(surface);
  }

  void addStartupHook(StartupHook hook) => _startupHooks.add(hook);

  /// Adds work to run when the app goes to the background or exits (after the
  /// settings store is flushed). Hooks run in registration order; one that
  /// throws does not stop the others.
  void addFlushHook(FlushHook hook) => _flushHooks.add(hook);

  /// Adds work that runs only on exit, before the normal flush (for example
  /// pausing playback so nothing advances during the flush). Same shape as a
  /// flush hook; one that throws or hangs is logged and does not block. All
  /// before-exit hooks share half of the exit cap; a hook cut by that limit
  /// keeps running in the background, so it must be safe to leave running.
  void addBeforeExitHook(FlushHook hook) => _beforeExitHooks.add(hook);
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
