import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/registry_entries.dart';
import '../../library/ui/selection/selection_bar.dart';
import '../../playback/state/playback_providers.dart';
import '../../playback/state/player_ready.dart';
import '../state/nav_history.dart';
import '../state/right_panel.dart';
import '../../playback/state/now_playing_panel.dart';
import 'desktop_history_input.dart';
import 'desktop_playback_keys.dart';
import 'desktop_now_playing_overlay.dart';
import 'desktop_sidebar.dart';
import 'nav_groups.dart';
import 'desktop_top_bar.dart';
import 'player_bar.dart';
import 'right_panel/right_panel_host.dart';

/// Narrowest left part that keeps the full 240 dp sidebar.
const double desktopFullSidebarMinWidth = 1000;

/// Where the search icon and Ctrl+F / Ctrl+K lead (the Search tab).
const _searchPath = '/search';

/// Wide-window layout: top bar over sidebar (full or rail) and page.
class DesktopShell extends ConsumerStatefulWidget {
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
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell> {
  bool _expanded = true;

  /// Location of the last build, to close Now Playing when it changes.
  String? _lastLocation;

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
    if (event is! KeyDownEvent) {
      return event is KeyRepeatEvent && _onPlaybackKey(event);
    }
    if (_onHistoryKey(event)) return true;
    final key = event.logicalKey;
    if (!HardwareKeyboard.instance.isControlPressed) {
      return _onPlaybackKey(event);
    }
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    if (_onPanelKey(key)) return true;
    if (key != LogicalKeyboardKey.keyF && key != LogicalKeyboardKey.keyK) {
      return _onPlaybackKey(event);
    }
    // The page under Now Playing is hidden: no search from there.
    if (ref.read(nowPlayingPanelProvider).covered) return false;
    _openSearch();
    return true;
  }

  /// Transport keys (Space, arrows, Ctrl+S) while nobody inside the shell is
  /// focused. With focus inside, the widget below gets them first and the
  /// shell's focus handler takes what is left (a slider keeps its arrows); a
  /// dialog, sheet or menu owns its keys.
  bool _onPlaybackKey(KeyEvent event) {
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    if (!DesktopHistoryInput.shellOwnsFocus(_historyNode)) return false;
    return _onFocusedKey(event);
  }

  bool _onFocusedKey(KeyEvent event) =>
      handleDesktopPlaybackKey(event, ref.read(playerControllerProvider));

  /// Ctrl+Shift+Q toggles the queue panel, Ctrl+J the chat (when this build
  /// has one). Both work while Now Playing is open: the panel stays usable.
  bool _onPanelKey(LogicalKeyboardKey key) {
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final RightPanelKind kind;
    if (key == LogicalKeyboardKey.keyQ && shift) {
      kind = RightPanelKind.queue;
    } else if (key == LogicalKeyboardKey.keyJ && !shift) {
      if (ref.read(chatPanelSurfaceProvider) == null) return false;
      kind = RightPanelKind.chat;
    } else {
      return false;
    }
    ref.read(rightPanelProvider.notifier).toggle(kind);
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
      if (_closeNowPlaying()) return true;
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

  /// Going to another page closes Now Playing (after the frame: the panel
  /// state cannot change while the shell builds).
  void _closeOnNavigation(String location) {
    final changed = _lastLocation != null && _lastLocation != location;
    _lastLocation = location;
    if (!changed || !ref.read(nowPlayingPanelProvider).open) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(nowPlayingPanelProvider.notifier).close();
    });
  }

  /// Back (Esc with no focus, the mouse Back button) closes Now Playing
  /// before it walks the history. True when it did.
  bool _closeNowPlaying() {
    if (!ref.read(nowPlayingPanelProvider).open) return false;
    ref.read(nowPlayingPanelProvider.notifier).close();
    return true;
  }

  void _openSearch() => context.go(_searchPath);

  Widget _leftRegion(
    AppLocalizations l10n,
    StatefulNavigationShell shell,
    String location,
  ) {
    final hasTrack = ref.watch(hasCurrentTrackProvider);
    return LayoutBuilder(
      builder: (context, box) => _leftColumn(
        l10n,
        shell,
        location,
        hasTrack,
        // Under 1000 dp (the right panel is open) the sidebar is a rail
        // whatever the top bar toggle says.
        expanded: _expanded && box.maxWidth >= desktopFullSidebarMinWidth,
      ),
    );
  }

  Widget _leftColumn(
    AppLocalizations l10n,
    StatefulNavigationShell shell,
    String location,
    bool hasTrack, {
    required bool expanded,
  }) {
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
                expanded: expanded,
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
    final panelOpen = ref.watch(rightPanelProvider) != RightPanelKind.closed;
    _closeOnNavigation(location);
    return Scaffold(
      body: DesktopHistoryInput(
        history: widget.history,
        focusNode: _historyNode,
        interceptBack: _closeNowPlaying,
        onKey: _onFocusedKey,
        child: LayoutBuilder(
          builder: (context, box) => Column(
            children: [
              DesktopTopBar(
                history: widget.history,
                // The left part under 1000 dp is a rail whatever the toggle
                // says, so the toggle is dimmed instead of flipping silently.
                onToggleSidebar:
                    box.maxWidth - (panelOpen ? rightPanelWidth : 0) <
                        desktopFullSidebarMinWidth
                    ? null
                    : () => setState(() => _expanded = !_expanded),
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
                          // Covers the region above, player bar's place
                          // included; never the right panel.
                          const DesktopNowPlayingOverlay(),
                        ],
                      ),
                    ),
                    const _RightPanelGate(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The right panel, held back while it would read the player before the shell
/// created it: a panel saved open on the queue builds a body that watches the
/// queue, and that would create the player during the first build. Until the
/// player exists an empty box of the panel's size stands in (no layout jump).
class _RightPanelGate extends ConsumerWidget {
  const _RightPanelGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting =
        ref.watch(rightPanelProvider) == RightPanelKind.queue &&
        !ref.watch(playerCreatedProvider);
    if (!waiting) return const RightPanelHost();
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: const SizedBox(width: rightPanelWidth),
    );
  }
}
