import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/playback_views.dart';
import '../../state/playback_providers.dart';
import '../../state/queue_row_infos.dart';
import '../../state/queue_view_provider.dart';
import 'queue_locate_button.dart';
import 'queue_remove_action.dart';
import 'queue_scroll_controller.dart';
import 'queue_row.dart';
import 'queue_row_hooks.dart';
import 'queue_swipe_remove.dart';

/// Rows of room kept below the last row, so the locate button never covers it.
const double queueListBottomPadding = 72;

/// Rows loaded beyond each edge of the viewport.
const int queueInfoMargin = 50;

/// The queue as one flat, reorderable list in play order.
///
/// Rows have a fixed extent and are keyed by entry id; a drop is resolved by
/// that id, so an auto-advance or an edit during the drag cannot move the
/// wrong entry. The list opens scrolled to the current row. [onEmptied] runs
/// when the last entry is removed.
class QueueList extends ConsumerWidget {
  const QueueList({
    super.key,
    required this.size,
    this.favorite,
    this.menu,
    this.onEmptied,
  });

  final QueueRowSize size;
  final QueueRowFavorite? favorite;
  final QueueRowMenu? menu;
  final VoidCallback? onEmptied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(queueViewProvider).value;
    if (view == null) return const SizedBox.shrink();
    return _QueueListBody(
      view: view,
      extent: KMediaCard.extentOf(MediaQuery.textScalerOf(context)),
      size: size,
      favorite: favorite,
      menu: menu,
      onEmptied: onEmptied,
    );
  }
}

class _QueueListBody extends ConsumerStatefulWidget {
  const _QueueListBody({
    required this.view,
    required this.extent,
    required this.size,
    required this.favorite,
    required this.menu,
    required this.onEmptied,
  });

  final QueueView view;

  /// Row height (`KMediaCard.extentOf` for the text scale in effect).
  final double extent;
  final QueueRowSize size;
  final QueueRowFavorite? favorite;
  final QueueRowMenu? menu;
  final VoidCallback? onEmptied;

  @override
  ConsumerState<_QueueListBody> createState() => _QueueListBodyState();
}

class _QueueListBodyState extends ConsumerState<_QueueListBody> {
  late final ScrollController _scroll = QueueScrollController(
    initialScrollOffset: widget.view.current == null
        ? 0
        : queueOffsetFor(widget.view.current!, widget.extent),
  )..addListener(_loadWindow);
  final _locate = GlobalKey<QueueLocateButtonState>();
  int? _dragged;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWindow());
  }

  @override
  void didUpdateWidget(_QueueListBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extent != widget.extent) {
      // The rows changed height (text scale): the old offset points at other
      // rows, so keep the current one in view.
      WidgetsBinding.instance.addPostFrameCallback((_) => _reanchor());
    } else if (oldWidget.view != widget.view) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadWindow());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls to the current row (or the top) after the row height changed.
  void _reanchor() {
    if (!mounted) return;
    if (_scroll.hasClients) {
      final cur = widget.view.current;
      final max = _scroll.position.maxScrollExtent;
      _scroll.jumpTo(
        cur == null ? 0 : queueOffsetFor(cur, widget.extent).clamp(0, max),
      );
    }
    _loadWindow();
  }

  /// Asks for the infos of the rows in view plus a margin: O(1) from the
  /// scroll offset because every row has the same height.
  void _loadWindow() {
    if (!mounted) return;
    final items = widget.view.items;
    if (items.isEmpty) return;
    final extent = widget.extent;
    final pos = _scroll.hasClients ? _scroll.position : null;
    final offset = pos?.pixels ?? _scroll.initialScrollOffset;
    final viewport = pos?.viewportDimension ?? 800;
    final first = ((offset / extent).floor() - queueInfoMargin).clamp(
      0,
      items.length,
    );
    final last = (((offset + viewport) / extent).ceil() + queueInfoMargin)
        .clamp(first, items.length);
    ref.read(queueRowInfosProvider.notifier).ensure([
      for (var i = first; i < last; i++) items[i].trackId,
    ]);
  }

  void _drop(int oldIndex, int newIndex) {
    final id = _dragged;
    _dragged = null;
    if (id == null) return;
    final items = widget.view.items;
    // The list may have changed while dragging: find the entry by its id.
    final from = oldIndex < items.length && items[oldIndex].entryId == id
        ? oldIndex
        : items.indexWhere((i) => i.entryId == id);
    if (from < 0) return;
    if (newIndex == from) return;
    ref.read(playerControllerProvider).move(id, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final size = widget.size;
    return _buildList(view, size);
  }

  Widget _buildList(QueueView view, QueueRowSize size) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _locate.currentState?.recompute();
        _loadWindow();
        return false;
      },
      child: Stack(
        children: [
          ReorderableListView.builder(
            scrollController: _scroll,
            itemExtent: widget.extent,
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.only(bottom: queueListBottomPadding),
            itemCount: view.items.length,
            onReorderStart: (i) => _dragged = view.items[i].entryId,

            onReorderItem: _drop,
            itemBuilder: (context, i) {
              final item = view.items[i];
              final cur = view.current;
              Future<bool> remove() => removeQueueEntries(
                context,
                ref.read(playerControllerProvider),
                {item.entryId},
                title: ref.read(queueRowInfosProvider)[item.trackId]?.title,
                onEmptied: widget.onEmptied,
              );
              return QueueSwipeRemove(
                key: ValueKey(item.entryId),
                onRemove: remove,
                child: QueueRow(
                  item: item,
                  index: i,
                  size: size,
                  role: cur == null || i > cur
                      ? QueueRowRole.upcoming
                      : i == cur
                      ? QueueRowRole.current
                      : QueueRowRole.played,
                  favorite: widget.favorite,
                  menu: widget.menu,
                  onRemove: remove,
                ),
              );
            },
          ),
          Positioned(
            right: KSpace.x4,
            bottom: KSpace.x4,
            child: QueueLocateButton(
              key: _locate,
              controller: _scroll,
              currentIndex: view.current,
              extent: widget.extent,
            ),
          ),
        ],
      ),
    );
  }
}
