import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/registry_entries.dart';
import '../../library/ui/selection/selection_bar.dart';
import '../state/nav_history.dart';
import 'desktop_sidebar.dart';
import 'desktop_top_bar.dart';

/// Where the search icon and Ctrl+F / Ctrl+K lead (the Search tab).
const _searchPath = '/search';

/// Wide-window layout: top bar over sidebar (full or rail) and page.
class DesktopShell extends StatefulWidget {
  const DesktopShell({
    super.key,
    required this.navigationShell,
    required this.items,
    required this.history,
  });

  final StatefulNavigationShell navigationShell;

  /// Every nav item in nav order, including pushed, child and placeholder ones.
  final List<NavItem> items;
  final NavHistory history;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  bool _expanded = true;

  /// Item whose page the location is in: the longest matching path among the
  /// items that navigate. Search and detail pages match nothing (nothing is
  /// marked).
  String? _selectedId(String location) {
    NavItem? best;
    for (final item in widget.items) {
      if (!item.sidebar || item.comingSoon || item.onSelect != null) continue;
      if (!item.containsLocation(location)) continue;
      if (best == null || item.path.length > best.path.length) best = item;
    }
    return best?.id;
  }

  void _select(NavItem item) {
    final onSelect = item.onSelect;
    if (onSelect != null) {
      onSelect(context);
      return;
    }
    if (item.pushed) {
      context.push(item.path);
      return;
    }
    if (item.parentId != null) {
      context.go(item.path);
      return;
    }
    final shell = widget.navigationShell;
    final branch = [
      for (final i in widget.items)
        if (i.isBranch) i,
    ].indexOf(item);
    if (branch < 0) return;
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// Ctrl+F / Ctrl+K open Search. A global key handler rather than a focus
  /// widget: it keeps working after focus moves (dialogs, text fields). It
  /// stays quiet while a dialog or sheet is on top. The check only sees
  /// modals on the root navigator (`showDialog` default, `showKSheet`); a modal
  /// pushed on a branch navigator must use the root navigator too.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.keyF && key != LogicalKeyboardKey.keyK) {
      return false;
    }
    if (!HardwareKeyboard.instance.isControlPressed) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    _openSearch();
    return true;
  }

  void _openSearch() => context.go(_searchPath);

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final location = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context);
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
                  items: [
                    for (final i in widget.items)
                      if (i.sidebar) i,
                  ],
                  selectedId: _selectedId(location),
                  expanded: _expanded,
                  onSelect: _select,
                ),
                Expanded(
                  child: PageHeaderScope(
                    trailing: [
                      IconButton(
                        icon: const Icon(KIcons.search),
                        tooltip: l10n.appSearch,
                        onPressed: _openSearch,
                      ),
                    ],
                    // Selection bar floats above the player bar's place.
                    child: Stack(
                      children: [
                        Positioned.fill(child: shell),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: KSpace.x4,
                          child: Center(child: LibrarySelectionBar()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
