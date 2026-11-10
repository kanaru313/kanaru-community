import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_providers.dart';
import '../../extension/state/registry_entries.dart';
import '../../library/ui/selection/selection_bar.dart';
import '../../playback/state/mini_player_flight.dart';
import '../../playback/state/playback_providers.dart';
import '../../playback/ui/mini_player.dart';
import '../../screens/now_playing/now_playing_path.dart';
import '../../screens/now_playing/ui/mobile/queue_sheet.dart';
import '../state/mobile_sidebar_state.dart';
import 'mobile_push_layout.dart';
import 'mobile_sidebar.dart';
import 'nav_groups.dart';

/// Phone and tablet layout: page above the mini player and an icon-only
/// bottom bar, with a push sidebar behind the content.
class MobileShell extends ConsumerWidget {
  const MobileShell({
    super.key,
    required this.navigationShell,
    required this.items,
    this.sidebarItems = const [],
    this.selectionBar = const LibrarySelectionBar(),
    this.onOpenNowPlaying,
    this.onOpenQueue,
  });

  final StatefulNavigationShell navigationShell;

  /// Tab nav items in branch order (pushed pages are not shell branches).
  final List<NavItem> items;

  /// Every nav item in nav order; the sidebar lists those with `sidebar`.
  final List<NavItem> sidebarItems;

  /// Slot above the bottom bar (above the mini player). The library's
  /// selection bar; replaceable so the shell can be tested with a stand-in.
  final Widget selectionBar;

  /// Mini player: tap or swipe up. Null opens the Now Playing route.
  final VoidCallback? onOpenNowPlaying;

  /// Mini player: long press. Null opens the queue sheet.
  final VoidCallback? onOpenQueue;

  void _select(
    BuildContext context,
    WidgetRef ref,
    NavItem item,
    String? current,
  ) {
    ref.read(mobileSidebarOpenProvider.notifier).close();
    // The highlighted item only closes the sidebar.
    if (item.id == current) return;
    final onSelect = item.onSelect;
    if (onSelect != null) {
      onSelect(context);
    } else if (item.pushed) {
      context.push(item.path);
    } else if (item.parentId != null) {
      context.go(item.path);
    } else {
      final branch = items.indexOf(item);
      if (branch >= 0) navigationShell.goBranch(branch, initialLocation: true);
    }
  }

  /// Back at the root of a tab other than Home goes to Home. It acts only
  /// while the shell is the top route and has no child page open; the sidebar
  /// (a deeper listener) and the router's own pop see Back first or after.
  Future<bool> _onBack(BuildContext context) async {
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final home = items.indexWhere((i) => i.path == '/');
    final current = navigationShell.currentIndex;
    if (home < 0 || current == home || current >= items.length) return false;
    final atRoot = GoRouterState.of(context).uri.path == items[current].path;
    if (!atRoot) return false;
    navigationShell.goBranch(home, initialLocation: true);
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasTrack = ref.watch(hasCurrentTrackProvider);
    final flight = ref.watch(miniPlayerFlightProvider);
    final aiActions = [
      for (final a in ref.watch(extensionRegistryProvider).topBarActions)
        if (a.id == 'ai') a,
    ];
    final location = GoRouterState.of(context).uri.path;
    final listed = [
      for (final i in sidebarItems)
        if (i.sidebar) i,
    ];
    final current = selectedNavId(listed, location);
    final settings = sidebarItems
        .where((i) => i.footer && i.pushed)
        .firstOrNull;
    // Branch index of each tab; items that are not tabs have no bar entry.
    // Bar order follows `mobileOrder`; ties keep branch order (stable sort).
    final tabs =
        [
          for (var i = 0; i < items.length; i++)
            if (items[i].mobileTab) i,
        ]..sort((a, b) {
          final byOrder = items[a].mobileOrder.compareTo(items[b].mobileOrder);
          return byOrder != 0 ? byOrder : a.compareTo(b);
        });
    final selected = tabs.indexOf(navigationShell.currentIndex);
    return BackButtonListener(
      onBackButtonPressed: () => _onBack(context),
      child: PageHeaderScope(
        leading: IconButton(
          icon: const Icon(KIcons.sidebarToggle),
          tooltip: l10n.playbackSidebarOpen,
          onPressed: ref.read(mobileSidebarOpenProvider.notifier).open,
        ),
        // A registered action (Pro chat) replaces the placeholder.
        trailing: [
          if (aiActions.isEmpty)
            IconButton(
              icon: const Icon(KIcons.ai),
              tooltip: '${l10n.appAiChat} · ${l10n.appComingSoon}',
              onPressed: null,
            ),
          for (final a in aiActions) a.builder(context),
        ],
        rootTrailing: [
          if (settings != null)
            IconButton(
              icon: const Icon(KIcons.settings),
              tooltip: settings.label(context),
              onPressed: () => context.push(settings.path),
            ),
        ],
        child: MobilePushLayout(
          sidebar: MobileSidebar(
            items: listed,
            selectedId: current,
            onSelect: (item) => _select(context, ref, item, current),
          ),
          content: Scaffold(
            body: SafeArea(bottom: false, child: navigationShell),
            // The selection bar slot sits above the mini player and the bar.
            // A branch that is not a tab has no bar entry, hence no bar.
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                selectionBar,
                if (hasTrack)
                  MiniPlayer(
                    flight: flight,
                    onOpen:
                        onOpenNowPlaying ?? () => context.push(nowPlayingPath),
                    onOpenQueue:
                        onOpenQueue ??
                        () => showQueueSheet(context, from: flight),
                  ),
                if (selected >= 0)
                  NavigationBar(
                    selectedIndex: selected,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysHide,
                    onDestinationSelected: (tab) => navigationShell.goBranch(
                      tabs[tab],
                      initialLocation: tab == selected,
                    ),
                    destinations: [
                      for (final branch in tabs)
                        NavigationDestination(
                          icon: Icon(items[branch].icon),
                          selectedIcon: Icon(items[branch].selectedIcon),
                          label: items[branch].label(context),
                          tooltip: items[branch].label(context),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
