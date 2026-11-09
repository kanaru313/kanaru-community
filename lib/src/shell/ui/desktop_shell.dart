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
    return Scaffold(
      body: Column(
        children: [
          DesktopTopBar(
            history: widget.history,
            onToggleSidebar: () => setState(() => _expanded = !_expanded),
            onHome: () => shell.goBranch(0),
          ),
          Expanded(
            child: Row(
              children: [
                DesktopSidebar(
                  items: widget.items,
                  selectedBranch: shell.currentIndex,
                  expanded: _expanded,
                  onSelect: (branch) =>
                      shell.goBranch(branch, initialLocation: branch == shell.currentIndex),
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
