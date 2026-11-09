import 'package:go_router/go_router.dart';

import '../extension/state/extension_registry.dart';
import '../shell/ui/app_shell.dart';

/// Builds the router from what the registry holds: one shell branch per nav
/// item (in nav order) holding the route at the item's path, plus a last
/// branch for routes that have no nav item. Nothing is hardcoded here.
GoRouter buildRouter(ExtensionRegistry registry) {
  final items = registry.navItems;
  if (items.isEmpty) {
    throw StateError('No nav items registered; the app needs at least one page');
  }
  final goRoutes = registry.routes;
  final claimed = <Object>{};
  final branches = <StatefulShellBranch>[];
  for (final item in items) {
    final route = goRoutes
        .whereType<GoRoute>()
        .where((r) => r.path == item.path)
        .firstOrNull;
    if (route == null) {
      throw StateError('Nav item "${item.id}" has no route at "${item.path}"');
    }
    claimed.add(route);
    branches.add(StatefulShellBranch(routes: [route]));
  }
  final others = goRoutes.where((r) => !claimed.contains(r)).toList();
  if (others.isNotEmpty) branches.add(StatefulShellBranch(routes: others));

  return GoRouter(
    initialLocation: items.first.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: branches,
      ),
    ],
  );
}
