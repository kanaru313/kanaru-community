import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'page/plugin_page.dart';
import 'repos/repositories_page.dart';
import 'store/store_page.dart';

/// The `plugins` sub-tree of the Settings branch: the store (`?kind=` presets
/// its Loại filter), its repositories and the page of one installed plugin.
GoRoute buildPluginsRoute() => GoRoute(
  path: 'plugins',
  pageBuilder: (_, state) =>
      _page(state, StorePage(kind: state.uri.queryParameters['kind'])),
  routes: [
    GoRoute(
      path: 'repositories',
      pageBuilder: (_, state) => _page(state, const RepositoriesPage()),
    ),
    GoRoute(
      path: 'p/:installId',
      pageBuilder: (_, state) => _page(
        state,
        PluginPage(
          key: ValueKey(state.pathParameters['installId']),
          installId: state.pathParameters['installId']!,
        ),
      ),
    ),
  ],
);

Page<void> _page(GoRouterState state, Widget child) =>
    KDetailPage(key: state.pageKey, child: child);
