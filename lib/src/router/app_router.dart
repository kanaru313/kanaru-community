import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../extension/state/extension_registry.dart';
import '../screens/first_run/state/first_run_gate.dart';
import '../shell/ui/app_shell.dart';

/// Builds the router from what the registry holds. Nav items that are tabs
/// get one shell branch each (in nav order) holding the route at the item's
/// path. A child nav item ([NavItem.parentId]) has its route nested under its
/// parent's route. Every other route (pushed nav items such as Settings, detail
/// pages with path parameters, Pro routes) is a top-level route on the root
/// navigator, pushed above the shell so system back returns to where it came
/// from. Nothing is hardcoded here.
///
/// While [firstRunRequired] returns true every location redirects to
/// [firstRunPath]; [refresh] must notify when its answer changes. Throws
/// [StateError] when it is true at build time and no route serves
/// [firstRunPath] (the redirect would otherwise loop on an error page).
GoRouter buildRouter(
  ExtensionRegistry registry, {
  bool Function()? firstRunRequired,
  Listenable? refresh,
}) {
  final tabs = registry.branchNavItems;
  if (tabs.isEmpty) {
    throw StateError(
      'No tab nav items registered; the app needs at least one page',
    );
  }
  final goRoutes = registry.routes;
  for (final item in registry.navItems) {
    // Items that only run an action or are placeholders need no page.
    if (item.comingSoon || item.onSelect != null) continue;
    final parentId = item.parentId;
    if (parentId == null) {
      if (_findRoute(goRoutes, item.path, '') == null) {
        throw StateError(
          'Nav item "${item.id}" has no route at "${item.path}"',
        );
      }
      continue;
    }
    final parent = registry.navItems.where((n) => n.id == parentId).firstOrNull;
    final parentRoute = parent == null
        ? null
        : _findRoute(goRoutes, parent.path, '');
    if (parent == null) {
      throw StateError(
        'Nav item "${item.id}" names unknown parent "$parentId"',
      );
    }
    if (parentRoute == null) {
      throw StateError(
        'Nav item "${item.id}": its parent "$parentId" has no route at '
        '"${parent.path}"',
      );
    }
    if (_findRoute(parentRoute.routes, item.path, parent.path) == null) {
      throw StateError(
        'Nav item "${item.id}" has no route at "${item.path}" nested under '
        'the route of its parent "$parentId"',
      );
    }
  }
  final claimed = <RouteBase>{};
  final branches = <StatefulShellBranch>[];
  for (final item in tabs) {
    final route = goRoutes.whereType<GoRoute>().firstWhere(
      (r) => r.path == item.path,
      orElse: () =>
          throw StateError('Tab "${item.id}" route must be top-level'),
    );
    claimed.add(route);
    branches.add(StatefulShellBranch(routes: [route]));
  }

  final hasFirstRunRoute = _findRoute(goRoutes, firstRunPath, '') != null;
  if ((firstRunRequired?.call() ?? false) && !hasFirstRunRoute) {
    throw StateError(
      'First-run setup is required but no route serves "$firstRunPath"',
    );
  }

  return GoRouter(
    initialLocation: tabs.first.path,
    refreshListenable: refresh,
    redirect: firstRunRequired == null
        ? null
        : (context, state) {
            final required = firstRunRequired();
            final atFirstRun = state.uri.path == firstRunPath;
            if (required && !atFirstRun && hasFirstRunRoute) {
              return firstRunPath;
            }
            if (!required && atFirstRun) return '/';
            return null;
          },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: branches,
      ),
      ...goRoutes.where((r) => !claimed.contains(r)),
    ],
  );
}

/// Route whose path, joined with its ancestors' paths, equals [target].
GoRoute? _findRoute(List<RouteBase> routes, String target, String prefix) {
  for (final route in routes) {
    if (route is GoRoute) {
      final full = _join(prefix, route.path);
      if (full == target) return route;
      final nested = _findRoute(route.routes, target, full);
      if (nested != null) return nested;
    } else {
      final nested = _findRoute(route.routes, target, prefix);
      if (nested != null) return nested;
    }
  }
  return null;
}

String _join(String prefix, String path) {
  if (path.startsWith('/')) return path;
  return prefix.endsWith('/') ? '$prefix$path' : '$prefix/$path';
}
