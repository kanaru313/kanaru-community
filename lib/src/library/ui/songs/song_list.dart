import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/selection_providers.dart';
import '../../state/browse/song_list_providers.dart';
import '../../state/browse/track_window.dart';
import '../browse/library_list_scaffold.dart';
import '../menus/menu_origin.dart';
import '../selection/selection_inset.dart';
import '../selection/selection_shortcuts.dart';
import 'song_row_placeholder.dart';
import 'song_tile.dart';

/// Windowed list of the songs of a scope, in a sort, narrowed by a filter.
///
/// Ids come from [songIdsProvider]; rows are read a page at a time by a
/// [TrackWindow] for the range the list has built (cache extent included).
/// A row is cached by track id, so the tile painted at `i` is always
/// `window.ids[i]` and a tap plays exactly that track, also while a scan
/// reorders the list under the user's finger.
///
/// [leadingSlivers] come first in the same scroll view (the folder page puts
/// its sub-folders there). While the page is the one on screen, the list
/// registers its ids as the target of "select all"; an offstage page does not.
class SongList extends StatelessWidget {
  const SongList({
    super.key,
    required this.scope,
    required this.sort,
    required this.filter,
    required this.playContext,
    this.showNumber = false,
    this.leadingSlivers = const [],
  });

  final SongScope scope;
  final SortSpec sort;
  final String filter;
  final PlayContext playContext;
  final bool showNumber;
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      ...leadingSlivers,
      SongSlivers(
        scope: scope,
        sort: sort,
        filter: filter,
        playContext: playContext,
        showNumber: showNumber,
      ),
      const SelectionInsetSliver(),
    ],
  );
}

/// The rows of a song list as one sliver, for pages that put them in a scroll
/// view of their own (album and artist pages, with a header and a sticky bar
/// before them). Owns the [TrackWindow], the select-all registration and the
/// failed-page retry rows, exactly as [SongList] describes.
class SongSlivers extends ConsumerStatefulWidget {
  const SongSlivers({
    super.key,
    required this.scope,
    required this.sort,
    required this.filter,
    required this.playContext,
    this.showNumber = false,
    this.showDetected = false,
  });

  final SongScope scope;
  final SortSpec sort;
  final String filter;
  final PlayContext playContext;
  final bool showNumber;
  final bool showDetected;

  @override
  ConsumerState<SongSlivers> createState() => _SongSliversState();
}

class _SongSliversState extends ConsumerState<SongSlivers> {
  late final TrackWindow _window = TrackWindow(
    load: (ids) => ref.read(trackRowLoaderProvider)(ids),
    onChanged: () {
      if (mounted) setState(() {});
    },
  );
  late final ActiveTrackList _active;

  /// Ctrl+A while this list is the one on screen.
  late final SelectAllShortcut _selectAll;

  /// The id list last handed to the window.
  List<TrackId>? _fed;

  /// Scope the window's ids belong to.
  SongScope? _scope;

  /// The id list last registered as the select-all target.
  List<TrackId>? _registered;

  @override
  void initState() {
    super.initState();
    _active = ref.read(activeTrackListProvider.notifier);
    _selectAll = SelectAllShortcut(
      context,
      ProviderScope.containerOf(context, listen: false),
    );
  }

  @override
  void dispose() {
    final registered = _registered;
    _selectAll.detach();
    _window.dispose();
    if (registered != null) {
      // Not while the tree is being torn down: listeners rebuild widgets.
      Future.microtask(() => _active.clear(registered));
    }
    super.dispose();
  }

  void _syncActive(bool current) {
    if (current) {
      _selectAll.attach();
    } else {
      _selectAll.detach();
    }
    final ids = _window.ids;
    if (current && !identical(_registered, ids)) {
      _registered = ids;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(_registered, ids)) _active.set(ids);
      });
    } else if (!current && _registered != null) {
      final old = _registered!;
      _registered = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => _active.clear(old));
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (scope: widget.scope, sort: widget.sort, filter: widget.filter);
    if (_scope != widget.scope) {
      // Other tracks altogether: never show (or play) the old scope's rows
      // while the new ids load.
      _scope = widget.scope;
      _fed = null;
      _window.setIds(const []);
    }
    final fresh = ref.watch(songIdsProvider(key)).value;
    if (fresh != null && !identical(fresh, _fed)) {
      _fed = fresh;
      _window.setIds(fresh);
    }
    // A cover or title changed while the order stayed.
    ref.listen(songRowsRevisionProvider, (_, next) {
      if (next.hasValue) _window.invalidate();
    });
    _syncActive(
      (ModalRoute.isCurrentOf(context) ?? true) &&
          TickerMode.valuesOf(context).enabled,
    );

    final ids = _window.ids;
    final extent = KMediaCard.extentOf(MediaQuery.textScalerOf(context));
    final gutter = libraryRowGutter(context);
    final origin = MenuOrigin.ofScope(widget.scope);
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x4),
          sliver: SliverFixedExtentList(
            itemExtent: extent,
            delegate: _WindowDelegate(
              count: ids.length,
              onLayout: _window.viewport,
              builder: (context, i) {
                final info = _window.rowAt(i);
                if (info == null) {
                  return _window.isFailed(i)
                      ? SongRowFailed(
                          extent: extent,
                          onRetry: _window.invalidate,
                        )
                      : const SongRowPlaceholder();
                }
                return SongTile(
                  info: info,
                  index: i,
                  ids: ids,
                  playContext: widget.playContext,
                  showNumber: widget.showNumber,
                  showDetected: widget.showDetected,
                  origin: origin,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Builds rows lazily and reports the range it built after each layout, which
/// is what the window reads pages for.
class _WindowDelegate extends SliverChildBuilderDelegate {
  _WindowDelegate({
    required int count,
    required this.onLayout,
    required NullableIndexedWidgetBuilder builder,
  }) : super(builder, childCount: count, addAutomaticKeepAlives: false);

  final void Function(int first, int last) onLayout;

  @override
  void didFinishLayout(int firstIndex, int lastIndex) =>
      onLayout(firstIndex, lastIndex);
}
