import 'package:flutter/services.dart';
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
import 'chat_host_shell.dart';
import 'mobile_floating_dock.dart';
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

  /// Shell branches in branch order: the tabs plus non-tab branches such as
  /// Settings (pushed pages are not branches).
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
    String location,
  ) {
    ref.read(mobileSidebarOpenProvider.notifier).close();
    // The highlighted item at its root page only closes the sidebar; with a
    // detail pushed over it (a push keeps the base location, so the item stays
    // highlighted) it goes back to the root.
    if (item.id == current && _atItemRoot(item, location)) return;
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

  /// Whether the visible page is [item]'s own root: at its path and with no
  /// page pushed over it on the current branch.
  bool _atItemRoot(NavItem item, String location) {
    final atPath = item.parentId != null
        ? location == item.path
        : item.atRoot(location);
    final pushed =
        _branchNavigator(navigationShell.currentIndex)?.canPop() ?? false;
    return atPath && !pushed;
  }

  /// The navigator of the branch at [index] (null before it is built).
  NavigatorState? _branchNavigator(int index) =>
      navigationShell.route.branches[index].navigatorKey.currentState;

  /// Whether Back is the shell's to end, not the branch navigator's: in a tab
  /// other than Home, at one of its roots, or inside it with no page to pop
  /// (a detail opened with `go`).
  bool _leavesTab(int home, String location) {
    final current = navigationShell.currentIndex;
    if (home < 0 || current == home || current >= items.length) return false;
    final item = items[current];
    if (item.atRoot(location)) return true;
    return item.containsLocation(location) &&
        !(_branchNavigator(current)?.canPop() ?? false);
  }

  /// The shell ends Back for every tab, in this order (it acts only while the
  /// shell is the top route; the sidebar, a deeper listener, sees Back first):
  ///
  /// 1. The branch navigator pops first: an open filter or popover (a
  ///    `PopScope(canPop: false)`), a Folders level, a pushed page.
  /// 2. In a tab other than Home: at a root the tab goes to Home; inside the
  ///    tab (a page opened with `go`) it goes to the tab's own page (Library
  ///    redirects to its last list).
  /// 3. At Home the app exits. This is done here, not left to the system: a
  ///    hidden branch that still has a pushed page keeps go_router's Back
  ///    claim, which would swallow Back at Home.
  Future<bool> _onBack(BuildContext context) async {
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final home = items.indexWhere((i) => i.path == '/');
    final current = navigationShell.currentIndex;
    if (home < 0 || current >= items.length) return false;
    final location = GoRouterState.of(context).uri.path;
    final router = GoRouter.of(context);
    final item = items[current];
    final atHome = current == home;
    if (!atHome && !item.containsLocation(location)) return false;
    final popped =
        await (_branchNavigator(current)?.maybePop() ?? Future.value(false));
    if (popped) return true;
    if (atHome) {
      await SystemNavigator.pop();
    } else if (item.atRoot(location)) {
      navigationShell.goBranch(home, initialLocation: true);
    } else {
      router.go(item.path);
    }
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasTrack = ref.watch(hasCurrentTrackProvider);
    final flight = ref.watch(miniPlayerFlightProvider);
    // Extension actions for the header (Pro's own, next to the built-in AI
    // button).
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
    final settings = sidebarItems.where((i) => i.footer).firstOrNull;
    // Settings is a full-screen branch: no dock, no tab-style header actions.
    final inSettings = settings != null && settings.containsLocation(location);
    final homeBranch = items.indexWhere((i) => i.path == '/');
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
    final sidebarOpen = ref.watch(mobileSidebarOpenProvider);
    final shellTakesBack = _leavesTab(homeBranch, location);
    // With predictive back enabled Android hands Back to Flutter only when the
    // framework says it can handle it, and no navigator can pop at a branch
    // root or at a page opened with `go`. The PopScope makes the route report
    // that; the listener below answers first on a normal Back, so the action
    // never runs twice.
    return PopScope(
      canPop: !(shellTakesBack || sidebarOpen),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (sidebarOpen) {
          ref.read(mobileSidebarOpenProvider.notifier).close();
        } else {
          _onBack(context);
        }
      },
      child: BackButtonListener(
        onBackButtonPressed: () => _onBack(context),
        child: PageHeaderScope(
          // Settings root: a back to Home replaces the menu button, which is
          // also what keeps the sidebar closed there.
          leading: inSettings
              ? KIconButton(
                  icon: KIcons.back,
                  tooltip: l10n.tooltipBack,
                  onPressed: () => homeBranch < 0
                      ? context.go('/')
                      : navigationShell.goBranch(
                          homeBranch,
                          initialLocation: true,
                        ),
                )
              : KIconButton(
                  icon: KIcons.sidebarToggle,
                  tooltip: l10n.playbackSidebarOpen,
                  onPressed: ref.read(mobileSidebarOpenProvider.notifier).open,
                ),
          trailing: [
            if (!inSettings)
              KIconButton(
                icon: KIcons.ai,
                tooltip: l10n.appAiChat,
                onPressed: () => openChatPage(GoRouter.of(context)),
              ),
            if (!inSettings)
              for (final a in aiActions) a.builder(context),
          ],
          rootTrailing: [
            if (settings != null && !inSettings)
              KIconButton(
                icon: KIcons.settings,
                tooltip: settings.label(context),
                onPressed: () =>
                    _select(context, ref, settings, current, location),
              ),
          ],
          child: MobilePushLayout(
            sidebar: MobileSidebar(
              items: listed,
              selectedId: current,
              onSelect: (item) =>
                  _select(context, ref, item, current, location),
            ),
            content: Scaffold(
              // The selection bar slot and the mini player float over the page
              // (selection bar above the mini player); only the bar below is
              // the scaffold's. A branch that is not a tab has no bar entry.
              body: MobileFloatingDock(
                hidden: MediaQuery.viewInsetsOf(context).bottom > 0,
                body: SafeArea(bottom: false, child: navigationShell),
                dock: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!inSettings) selectionBar,
                    if (hasTrack && !inSettings)
                      MiniPlayer(
                        flight: flight,
                        onOpen:
                            onOpenNowPlaying ??
                            () => context.push(nowPlayingPath),
                        onOpenQueue:
                            onOpenQueue ??
                            () => showQueueSheet(context, from: flight),
                      ),
                  ],
                ),
              ),
              bottomNavigationBar: selected < 0
                  ? null
                  : NavigationBar(
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
            ),
          ),
        ),
      ),
    );
  }
}
