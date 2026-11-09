import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../extension/state/registry_entries.dart';

/// Phone and tablet layout: page above an icon-only bottom bar.
class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.navigationShell, required this.items});

  final StatefulNavigationShell navigationShell;

  /// Tab nav items in branch order (pushed pages are not shell branches).
  final List<NavItem> items;

  @override
  Widget build(BuildContext context) {
    // Branch index of each tab; items that are not tabs have no bar entry.
    final tabs = [
      for (var i = 0; i < items.length; i++)
        if (items[i].mobileTab) i,
    ];
    final selected = tabs.indexOf(navigationShell.currentIndex);
    return Scaffold(
      body: SafeArea(bottom: false, child: navigationShell),
      // A branch that is not a tab has no bar entry, hence no bar.
      bottomNavigationBar: selected < 0
          ? null
          : NavigationBar(
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
    );
  }
}
