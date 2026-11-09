import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../extension/state/extension_providers.dart';
import '../state/nav_history.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';

/// Frame around every page. The single place that picks Desktop or Mobile.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  NavHistory? _history;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _history ??= NavHistory(GoRouter.of(context));
  }

  @override
  void dispose() {
    _history?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(extensionRegistryProvider);
    return switch (FormFactor.of(context)) {
      FormFactor.desktop => DesktopShell(
          navigationShell: widget.navigationShell,
          items: registry.navItems,
          history: _history!,
        ),
      FormFactor.mobile => MobileShell(
          navigationShell: widget.navigationShell,
          items: registry.branchNavItems,
        ),
    };
  }
}
