import 'package:go_router/go_router.dart';

import '../extension/state/extension_registry.dart';
import '../shell/ui/app_shell.dart';

/// Builds the router from what the registry holds. Nav items that are tabs get
/// one shell branch each (in nav order) holding the route at the item's path.
/// Every other route (pushed nav items such as Settings, detail pages with
/// path parameters, Pro routes) is a top-level route on the root navigator,
/// pushed above the shell so system back returns to where it came from.
/// Nothing is hardcoded here.
GoRouter buildRouter(ExtensionRegistry registry) {
  final tabs = registry.branchNavItems;
  if (tabs.isEmpty) {
    throw StateError('No tab nav items registered; the app needs at least one page');
  }
  final goRoutes = registry.routes;
  for (final item in registry.navItems) {
    if (!goRoutes.whereType<GoRoute>().any((r) => r.path == item.path)) {
      throw StateError('Nav item "${item.id}" has no route at "${item.path}"');
    }
  }
  final claimed = <RouteBase>{};
  final branches = <StatefulShellBranch>[];
  for (final item in tabs) {
    final route = goRoutes.whereType<GoRoute>().firstWhere((r) => r.path == item.path);
    claimed.add(route);
    branches.add(StatefulShellBranch(routes: [route]));
  }

  return GoRouter(
    initialLocation: tabs.first.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: branches,
      ),
      ...goRoutes.where((r) => !claimed.contains(r)),
    ],
  );
}
