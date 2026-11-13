import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/state/browse/selection_providers.dart';
import '../../../playback/domain/queue_state.dart';
import '../../../playback/state/queue_view_provider.dart';

/// Picks queue entries into the app-wide song selection, and remembers the
/// anchor of a Shift range: the **entry** (not the track) last selected from
/// the queue, because a track can be queued several times and the range runs
/// over queue positions.
///
/// The state is that anchor's entry id. It is checked when a range is asked
/// for, not when the selection changes: an anchor is ignored once the
/// selection is empty, its track is no longer selected, or its entry left the
/// queue, so a range never starts from a stale row.
class QueueSelection extends Notifier<int?> {
  @override
  int? build() => null;

  List<QueueItem> get _items =>
      ref.read(queueViewProvider).value?.items ?? const [];

  /// Selects the track of [item] (or deselects it when selected) and, when it
  /// ends up selected, makes [item] the anchor.
  void toggle(QueueItem item) {
    final selection = ref.read(librarySelectionProvider.notifier);
    final was = selection.contains(item.trackId);
    selection.toggle(item.trackId);
    if (!was) state = item.entryId;
  }

  /// Selects the tracks of every entry between the anchor and [item] (both
  /// included), by their current positions; [item] becomes the anchor. Without
  /// a usable anchor it only selects [item].
  void rangeTo(QueueItem item) {
    final items = _items;
    final anchor = state;
    final selection = ref.read(librarySelectionProvider.notifier);
    var from = anchor == null
        ? -1
        : items.indexWhere((i) => i.entryId == anchor);
    if (from >= 0 && !selection.contains(items[from].trackId)) from = -1;
    final to = items.indexWhere((i) => i.entryId == item.entryId);
    if (from < 0 || to < 0) {
      selection.addRange([item.trackId]);
    } else {
      final lo = from < to ? from : to;
      final hi = from < to ? to : from;
      selection.addRange([
        for (final i in items.sublist(lo, hi + 1)) i.trackId,
      ]);
    }
    state = item.entryId;
  }

  /// Selects the current song (the header's "Select several"). Does nothing
  /// when no song is current.
  void selectCurrent() {
    final view = ref.read(queueViewProvider).value;
    final current = view?.current;
    if (view == null || current == null) return;
    final item = view.items[current];
    ref.read(librarySelectionProvider.notifier).addRange([item.trackId]);
    state = item.entryId;
  }
}

final queueSelectionProvider = NotifierProvider<QueueSelection, int?>(
  QueueSelection.new,
);
