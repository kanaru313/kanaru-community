import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../extension/state/registry_entries.dart';
import '../../library/ui/selection/selection_bar.dart';

/// Phone and tablet layout: page above an icon-only bottom bar.
class MobileShell extends StatelessWidget {
  const MobileShell({
    super.key,
    required this.navigationShell,
    required this.items,
    this.selectionBar = const LibrarySelectionBar(),
  });

  final StatefulNavigationShell navigationShell;

  /// Tab nav items in branch order (pushed pages are not shell branches).
  final List<NavItem> items;

  /// Slot above the bottom bar (above the mini player). The library's
  /// selection bar; replaceable so the shell can be tested with a stand-in.
  final Widget selectionBar;

  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
      body: SafeArea(bottom: false, child: navigationShell),
      // The selection bar slot sits above the bar (and the mini player, once
      // there is one). A branch that is not a tab has no bar entry, hence no bar.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          selectionBar,
          if (selected >= 0)
            NavigationBar(
              selectedIndex: selected,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
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
    );
  }
}
