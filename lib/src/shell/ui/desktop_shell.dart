import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../extension/state/registry_entries.dart';
import '../state/nav_history.dart';
import 'desktop_sidebar.dart';
import 'desktop_top_bar.dart';

/// Wide-window layout: top bar over sidebar (full or rail) and page.
class DesktopShell extends StatefulWidget {
  const DesktopShell({
    super.key,
    required this.navigationShell,
    required this.items,
    required this.history,
  });

  final StatefulNavigationShell navigationShell;
  /// Every nav item in nav order, including pushed ones (Settings).
  final List<NavItem> items;
  final NavHistory history;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    // Shell branches are the items that are not pushed pages, in nav order.
    final tabs = [for (final i in widget.items) if (!i.pushed) i];
    return Scaffold(
      body: Column(
        children: [
          DesktopTopBar(
            history: widget.history,
            onToggleSidebar: () => setState(() => _expanded = !_expanded),
            onHome: () => context.go('/'),
          ),
          Expanded(
            child: Row(
              children: [
                DesktopSidebar(
                  items: widget.items,
                  selectedIndex: widget.items.indexOf(tabs[shell.currentIndex]),
                  expanded: _expanded,
                  onSelect: (index) {
                    final item = widget.items[index];
                    if (item.pushed) {
                      context.push(item.path);
                      return;
                    }
                    final branch = tabs.indexOf(item);
                    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
                  },
                ),
                Expanded(child: shell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
