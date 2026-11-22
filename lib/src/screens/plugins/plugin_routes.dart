import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'repos/repositories_page.dart';
import 'store/store_page.dart';

/// The `plugins` sub-tree of the Settings branch: the store (`?kind=` presets
/// its Loại filter) and its repositories. The page of one plugin is mounted
/// here by the flow that builds it.
GoRoute buildPluginsRoute() => GoRoute(
  path: 'plugins',
  pageBuilder: (_, state) =>
      _page(state, StorePage(kind: state.uri.queryParameters['kind'])),
  routes: [
    GoRoute(
      path: 'repositories',
      pageBuilder: (_, state) => _page(state, const RepositoriesPage()),
    ),
  ],
);

Page<void> _page(GoRouterState state, Widget child) =>
    KDetailPage(key: state.pageKey, child: child);
