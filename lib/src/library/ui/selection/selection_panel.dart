import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../database/state/database_providers.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../state/browse/selection_providers.dart';
import '../../state/browse/song_list_providers.dart';
import '../../state/browse/track_window.dart';
import '../browse/library_labels.dart';
import '../browse/play_actions.dart';
import '../menus/open_menu.dart';
import '../songs/song_row_placeholder.dart';
import 'selection_back.dart';
import 'selection_row.dart';

/// The floating panel of the selected songs, in both shells' selection slot.
///
/// Top row: clear, `N songs` (and the length when open), then play all,
/// edit and add to playlist (not built: dimmed), the selection's menu, select
/// all songs of the screen, and open / collapse. Open, it lists the selected
/// songs in play order, which can be dragged to reorder.
class SelectionPanel extends ConsumerWidget {
  const SelectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final expanded = ref.watch(
      librarySelectionProvider.select((s) => s.expanded),
    );
    final count = ref.watch(
      librarySelectionProvider.select((s) => s.ids.length),
    );
    final extent = KMediaCard.extentOf(MediaQuery.textScalerOf(context));
    return SelectionBackScope(
      child: KSelectionPanel(
        semanticLabel: l10n.libraryPanelLabel,
        expanded: expanded,
        bodyHeight: count * extent,
        header: const _PanelHeader(),
        body: expanded ? const _SelectedList() : null,
      ),
    );
  }
}

class _PanelHeader extends ConsumerWidget {
  const _PanelHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final selection = ref.read(librarySelectionProvider.notifier);
    final expanded = ref.watch(
      librarySelectionProvider.select((s) => s.expanded),
    );
    final count = ref.watch(
      librarySelectionProvider.select((s) => s.ids.length),
    );
    // Also watched while collapsed: it is what drops tracks that vanished.
    final duration = ref.watch(selectionSummaryProvider).value?.durationMs;
    final canSelectAll = ref.watch(
      activeTrackListProvider.select((ids) => ids != null && ids.isNotEmpty),
    );
    return SizedBox(
      height: KSelectionPanel.headerHeight,
      child: Row(
        children: [
          _Button(
            icon: KIcons.cancel,
            tooltip: l10n.libraryPanelClear,
            onPressed: selection.clear,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.librarySongCount(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                if (expanded && duration != null)
                  Text(
                    formatTotalDuration(l10n, duration),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          _Button(
            icon: KIcons.playCircle,
            tooltip: l10n.libraryPanelPlayAll,
            onPressed: () => _playAll(ref, context, l10n),
          ),
          // Not built yet: dimmed and inert.
          _Button(
            icon: KIcons.edit,
            tooltip: '${l10n.libraryPanelEdit} · ${l10n.appComingSoon}',
          ),
          _Button(
            icon: KIcons.playlistAdd,
            tooltip:
                '${l10n.libraryPanelAddToPlaylist} · ${l10n.appComingSoon}',
          ),
          ViaKeyboardTracker(
            builder: (context, viaKeyboard) => _Button(
              icon: KIcons.moreVert,
              tooltip: l10n.libraryPanelMore,
              onPressed: () =>
                  openSelectionMenu(context, viaKeyboard: viaKeyboard()),
            ),
          ),
          _Button(
            icon: KIcons.selectAll,
            tooltip: l10n.libraryPanelSelectAll,
            onPressed: canSelectAll
                ? () => selection.addRange(
                    ref.read(activeTrackListProvider) ?? const [],
                  )
                : null,
          ),
          _Button(
            icon: expanded ? KIcons.collapse : KIcons.expand,
            tooltip: expanded
                ? l10n.libraryPanelCollapse
                : l10n.libraryPanelExpand,
            onPressed: () => selection.setExpanded(!expanded),
          ),
        ],
      ),
    );
  }

  /// Replaces the queue with the selection, in the order of the panel. The
  /// selection stays. Tracks that are no longer in the library are dropped
  /// first (from the selection too), so they are never played.
  Future<void> _playAll(
    WidgetRef ref,
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final selection = ref.read(librarySelectionProvider.notifier);
    var ids = ref.read(librarySelectionProvider).ids;
    try {
      final measured = await ref.read(selectionDurationReaderProvider)(
        ref.read(appDatabaseProvider),
        ids,
      );
      if (measured.absent.isNotEmpty) {
        selection.removeAll(measured.absent);
        final gone = measured.absent.toSet();
        ids = [
          for (final id in ids)
            if (!gone.contains(id)) id,
        ];
      }
    } on Object catch (e, s) {
      Logger('library.selection')
          .warning('checking the selection failed', e, s);
    }
    if (!context.mounted) return;
    if (ids.isEmpty) {
      showAppSnackBar(context, l10n.librarySelectionGone);
      return;
    }
    await playAll(
      ref,
      context,
      ids,
      PlayContext(
        PlayContextKind.selection,
        label: l10n.librarySongCount(ids.length),
      ),
    );
  }
}

/// An icon button of the top row: 40 wide so seven fit beside the count on a
/// phone, 48 tall.
class _Button extends StatelessWidget {
  const _Button({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    iconSize: 22,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
  );
}

/// The selected songs as a reorderable list. Exists only while the panel is
/// open: its rows come from a [TrackWindow] over the selection ids, a page at
/// a time, so a selection of thousands loads only the rows in view.
class _SelectedList extends ConsumerStatefulWidget {
  const _SelectedList();

  @override
  ConsumerState<_SelectedList> createState() => _SelectedListState();
}

class _SelectedListState extends ConsumerState<_SelectedList> {
  late final TrackWindow _window = TrackWindow(
    load: (ids) => ref.read(trackRowLoaderProvider)(ids),
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  final ScrollController _scroll = ScrollController();
  List<TrackId>? _fed;
  int _first = 1 << 30;
  int _last = -1;
  double _extent = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _window.dispose();
    super.dispose();
  }

  /// A scroll builds rows without rebuilding this state, so the rows now in
  /// view (fixed height, two spare rows each side) are reported from the
  /// scroll position.
  void _onScroll() {
    if (!_scroll.hasClients || _extent <= 0) return;
    final position = _scroll.position;
    if (!position.hasViewportDimension) return;
    final first = (position.pixels / _extent).floor() - 2;
    final last =
        ((position.pixels + position.viewportDimension) / _extent).ceil() + 2;
    _window.viewport(math.max(first, 0), last);
  }

  @override
  Widget build(BuildContext context) {
    final ids = ref.watch(librarySelectionProvider.select((s) => s.ids));
    if (!identical(ids, _fed)) {
      _fed = ids;
      _window.setIds(ids);
    }
    final extent = KMediaCard.extentOf(MediaQuery.textScalerOf(context));
    _extent = extent;
    _first = 1 << 30;
    _last = -1;
    // The rows built this frame are the range the window reads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _last >= 0) _window.viewport(_first, _last);
    });
    final sideInset = FormFactor.of(context) == FormFactor.desktop
        ? KSpace.x2
        : 0.0;
    return ReorderableListView.builder(
      scrollController: _scroll,
      buildDefaultDragHandles: false,
      itemExtent: extent,
      // Flat rows (mobile) pad themselves; desktop cards sit inside a small
      // inset.
      padding: EdgeInsets.fromLTRB(sideInset, 0, sideInset, KSpace.x2),
      itemCount: ids.length,
      // `to` is already the index after the moved row left its place.
      onReorderItem: (from, to) =>
          ref.read(librarySelectionProvider.notifier).reorder(from, to),
      itemBuilder: (context, i) {
        _first = math.min(_first, i);
        _last = math.max(_last, i);
        final info = _window.rowAt(i);
        return KeyedSubtree(
          key: ValueKey(ids[i]),
          child: info == null
              ? SongRowPlaceholder(extent: extent)
              : SelectedSongRow(info: info, index: i),
        );
      },
    );
  }
}
