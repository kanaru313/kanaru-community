import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/registry_entries.dart';
import '../../library/ui/selection/selection_bar.dart';
import '../../playback/state/playback_providers.dart';
import '../state/nav_history.dart';
import '../state/now_playing_panel.dart';
import 'desktop_history_input.dart';
import 'desktop_sidebar.dart';
import 'nav_groups.dart';
import 'desktop_top_bar.dart';
import 'player_bar.dart';

/// Where the search icon and Ctrl+F / Ctrl+K lead (the Search tab).
const _searchPath = '/search';

/// Wide-window layout: top bar over sidebar (full or rail) and page.
class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({
    super.key,
    required this.navigationShell,
    required this.items,
    required this.history,
    this.rightPanel,
  });

  final StatefulNavigationShell navigationShell;

  /// Every nav item in nav order, including pushed, child and placeholder ones.
  final List<NavItem> items;
  final NavHistory history;

  /// Docked panel to the right of the left region (the AI chat). It is a
  /// sibling of the region Now Playing covers, so it stays visible and usable
  /// while Now Playing is open.
  final Widget? rightPanel;

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  bool _expanded = true;
  final FocusNode _historyNode = FocusNode(debugLabel: 'desktop history input');

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
    _historyNode.dispose();
    super.dispose();
  }

  /// Ctrl+F / Ctrl+K open Search. A global key handler rather than a focus
  /// widget: it keeps working after focus moves (dialogs, text fields). It
  /// stays quiet while a dialog or sheet is on top. The check only sees
  /// modals on the root navigator (`showDialog` default, `showKSheet`); a modal
  /// pushed on a branch navigator must use the root navigator too.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_onHistoryKey(event)) return true;
    final key = event.logicalKey;
    if (key != LogicalKeyboardKey.keyF && key != LogicalKeyboardKey.keyK) {
      return false;
    }
    if (!HardwareKeyboard.instance.isControlPressed) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    // The page under Now Playing is hidden: no search from there.
    if (ref.read(nowPlayingPanelProvider).covered) return false;
    _openSearch();
    return true;
  }

  /// History keys the focus tree cannot take. Alt+Left/Right go back and
  /// forward from anywhere in the shell, a text field included (it would
  /// otherwise keep them). Esc is taken here only when nothing inside the
  /// shell is focused; with focus inside, the focus-tree handler decides
  /// (a text field keeps Esc). A dialog, sheet or menu has its own focus
  /// scope, so neither key reaches the history while one is open.
  bool _onHistoryKey(KeyDownEvent event) {
    if (!DesktopHistoryInput.isHistoryKey(event)) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final history = widget.history;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (!DesktopHistoryInput.shellOwnsFocus(_historyNode)) return false;
      if (!history.canGoBack) return false;
      history.back();
      return true;
    }
    if (!DesktopHistoryInput.shellHasFocus(_historyNode)) return false;
    if (key == LogicalKeyboardKey.arrowRight) {
      if (history.canGoForward) history.forward();
    } else if (history.canGoBack) {
      history.back();
    }
    return true;
  }

  void _openSearch() => context.go(_searchPath);

  Widget _leftRegion(
    AppLocalizations l10n,
    StatefulNavigationShell shell,
    String location,
  ) {
    final hasTrack = ref.watch(hasCurrentTrackProvider);
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              DesktopSidebar(
                items: [
                  for (final i in widget.items)
                    if (i.sidebar) i,
                ],
                selectedId: selectedNavId(widget.items, location),
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
        if (hasTrack) const PlayerBar(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    final location = GoRouterState.of(context).uri.path;
    final l10n = AppLocalizations.of(context);
    final covered = ref.watch(nowPlayingPanelProvider.select((s) => s.covered));
    return Scaffold(
      body: DesktopHistoryInput(
        history: widget.history,
        focusNode: _historyNode,
        child: Column(
          children: [
            DesktopTopBar(
              history: widget.history,
              onToggleSidebar: () => setState(() => _expanded = !_expanded),
              onHome: () => context.go('/'),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Offstage keeps the region's state and stops
                        // painting it while Now Playing covers it.
                        Offstage(
                          offstage: covered,
                          // Offstage hides and blocks the pointer; this also
                          // takes the region out of Tab traversal.
                          child: ExcludeFocus(
                            excluding: covered,
                            child: _leftRegion(l10n, shell, location),
                          ),
                        ),
                        // The Now Playing overlay is added here.
                      ],
                    ),
                  ),
                  ?widget.rightPanel,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
