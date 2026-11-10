import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/database.dart' show AppDatabase;
import '../../../database/state/database_providers.dart';
import '../../../media/domain/track_id.dart';
import '../../data/browse/menu_queries.dart';
import '../../data/browse/throttled_query.dart';
import 'song_list_providers.dart';

/// What is selected, in selection order, with an index for O(1) lookups.
/// Never mutated: every change builds a new state.
class SelectionState {
  const SelectionState({
    this.ids = const [],
    this.set = const {},
    this.anchor,
    this.expanded = false,
  });

  final List<TrackId> ids;

  /// The members of [ids].
  final Set<TrackId> set;

  /// Where a Shift-range starts: the last track toggled on.
  final TrackId? anchor;

  /// The selection panel is open.
  final bool expanded;

  bool get isEmpty => ids.isEmpty;
}

/// The song selection. Lives as long as the app, so it survives page changes.
class LibrarySelection extends Notifier<SelectionState> {
  @override
  SelectionState build() => const SelectionState();

  bool contains(TrackId id) => state.set.contains(id);

  /// Adds [id], or removes it when selected.
  void toggle(TrackId id) {
    if (state.set.contains(id)) return remove(id);
    state = SelectionState(
      ids: [...state.ids, id],
      set: {...state.set, id},
      anchor: id,
      expanded: state.expanded,
    );
  }

  /// Adds the unselected ones of [ids] in order; the last becomes the anchor.
  void addRange(Iterable<TrackId> ids) {
    final fresh = <TrackId>[];
    final set = {...state.set};
    for (final id in ids) {
      if (set.add(id)) fresh.add(id);
    }
    if (fresh.isEmpty) return;
    state = SelectionState(
      ids: [...state.ids, ...fresh],
      set: set,
      anchor: fresh.last,
      expanded: state.expanded,
    );
  }

  /// Shift-click: adds every track of [order] between the anchor and [to]
  /// (both included). Without an anchor in [order] it adds [to] alone.
  void selectRangeTo(List<TrackId> order, TrackId to) {
    final end = order.indexOf(to);
    if (end < 0) return;
    final anchor = state.anchor;
    final start = anchor == null ? -1 : order.indexOf(anchor);
    if (start < 0) return addRange([to]);
    final lo = start < end ? start : end;
    final hi = start < end ? end : start;
    addRange(order.sublist(lo, hi + 1));
    // Keep the anchor on the clicked row, so the next range grows from it.
    state = SelectionState(
      ids: state.ids,
      set: state.set,
      anchor: to,
      expanded: state.expanded,
    );
  }

  /// Replaces the selection with [ids] (deduplicated, order kept). The panel
  /// and Ctrl+A use [addRange] instead, so picks from other screens stay; this
  /// is the replace-all primitive for callers that mean to start over.
  void selectAll(Iterable<TrackId> ids) {
    final set = <TrackId>{};
    final list = <TrackId>[];
    for (final id in ids) {
      if (set.add(id)) list.add(id);
    }
    state = list.isEmpty
        ? const SelectionState()
        : SelectionState(
            ids: list,
            set: set,
            anchor: list.last,
            expanded: state.expanded,
          );
  }

  void remove(TrackId id) => removeAll([id]);

  /// Removes [ids]; an emptied selection closes the panel.
  void removeAll(Iterable<TrackId> ids) {
    final drop = {
      for (final id in ids)
        if (state.set.contains(id)) id,
    };
    if (drop.isEmpty) return;
    final list = [
      for (final id in state.ids)
        if (!drop.contains(id)) id,
    ];
    if (list.isEmpty) {
      state = const SelectionState();
      return;
    }
    state = SelectionState(
      ids: list,
      set: {...state.set}..removeAll(drop),
      anchor: drop.contains(state.anchor) ? null : state.anchor,
      expanded: state.expanded,
    );
  }

  /// Moves the track at [from] so that it ends at index [to] of the new
  /// order (the index after removal, as `ReorderableListView` callers pass
  /// it once they subtract one when moving down). Throws [RangeError] for an
  /// index outside the list.
  void reorder(int from, int to) {
    RangeError.checkValidIndex(from, state.ids, 'from');
    RangeError.checkValidIndex(to, state.ids, 'to');
    final next = [...state.ids];
    next.insert(to, next.removeAt(from));
    state = SelectionState(
      ids: next,
      set: state.set,
      anchor: state.anchor,
      expanded: state.expanded,
    );
  }

  void clear() {
    if (!state.isEmpty || state.expanded) state = const SelectionState();
  }

  /// Opens or closes the panel; it only opens with something selected.
  void setExpanded(bool value) {
    final open = value && !state.isEmpty;
    if (open == state.expanded) return;
    state = SelectionState(
      ids: state.ids,
      set: state.set,
      anchor: state.anchor,
      expanded: open,
    );
  }
}

final librarySelectionProvider =
    NotifierProvider<LibrarySelection, SelectionState>(LibrarySelection.new);

final hasSelectionProvider = Provider<bool>(
  (ref) => ref.watch(librarySelectionProvider.select((s) => !s.isEmpty)),
);

/// Whether [id] is selected; a tile rebuilds only when its own answer flips.
final isSelectedProvider = Provider.family<bool, TrackId>(
  (ref, id) =>
      ref.watch(librarySelectionProvider.select((s) => s.set.contains(id))),
  isAutoDispose: true,
);

/// The ordered ids of the song list on screen, for "select all"; null when
/// no list is registered (its page is not the current one).
class ActiveTrackList extends Notifier<List<TrackId>?> {
  @override
  List<TrackId>? build() => null;

  void set(List<TrackId> ids) {
    if (ref.mounted) state = ids;
  }

  /// Clears only when [ids] is still the registered list, so a page that
  /// closes late cannot drop the list of the page that replaced it. A page
  /// that is torn down after the container is gone has nothing to clear.
  void clear(List<TrackId> ids) {
    if (ref.mounted && identical(state, ids)) state = null;
  }
}

final activeTrackListProvider =
    NotifierProvider<ActiveTrackList, List<TrackId>?>(ActiveTrackList.new);

/// Total length of the selection.
class SelectionSummary {
  const SelectionSummary({required this.durationMs});
  final int durationMs;
}

/// Reads the duration of a selection; tests replace it to count reads.
final selectionDurationReaderProvider =
    Provider<
      Future<({int durationMs, List<TrackId> absent})> Function(
        AppDatabase db,
        List<TrackId> ids,
      )
    >((ref) => selectionDuration);

/// Duration of the selection, recomputed shortly after it stops changing and
/// again after the library changed (a scan, an exclusion), at most once per
/// refresh interval and never sooner than the last read took, like the other
/// library readers. Tracks that are no longer visible are dropped from the
/// selection.
final selectionSummaryProvider = StreamProvider.autoDispose<SelectionSummary>((
  ref,
) {
  final ids = ref.watch(librarySelectionProvider.select((s) => s.ids));
  final db = ref.watch(appDatabaseProvider);
  final read = ref.read(selectionDurationReaderProvider);
  var disposed = false;
  var first = true;
  ref.onDispose(() => disposed = true);
  return throttledQuery(
    db,
    {db.tracks},
    () async {
      if (first) {
        first = false;
        // Coalesces a burst of toggles into one query.
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      if (disposed) return const SelectionSummary(durationMs: 0);
      final result = await read(db, ids);
      if (disposed) return const SelectionSummary(durationMs: 0);
      if (result.absent.isNotEmpty) {
        ref.read(librarySelectionProvider.notifier).removeAll(result.absent);
      }
      return SelectionSummary(durationMs: result.durationMs);
    },
    interval: ref.watch(browseRefreshIntervalProvider),
    equals: (a, b) => a.durationMs == b.durationMs,
  );
});
