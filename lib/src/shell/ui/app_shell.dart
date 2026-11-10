import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../extension/state/extension_providers.dart';
import '../../playback/state/playback_providers.dart';
import '../state/nav_history.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';
import 'playback_notice_listener.dart';

/// Frame around every page. The single place that picks Desktop or Mobile.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  NavHistory? _history;
  bool _playerStarted = false;

  @override
  void initState() {
    super.initState();
    // Create the player once the shell is up (both shells), so the saved
    // session and the system media controls start at launch, not on the first
    // tap on a mini player. After the first frame: building a provider with
    // side effects is not allowed while widgets build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(playerControllerProvider);
      setState(() => _playerStarted = true);
    });
  }

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
    return PlaybackNoticeListener(
      enabled: _playerStarted,
      child: switch (FormFactor.of(context)) {
        FormFactor.desktop => DesktopShell(
          navigationShell: widget.navigationShell,
          items: registry.navItems,
          history: _history!,
        ),
        FormFactor.mobile => MobileShell(
          navigationShell: widget.navigationShell,
          items: registry.branchNavItems,
          sidebarItems: registry.navItems,
        ),
      },
    );
  }
}
