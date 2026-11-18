import 'package:flutter/widgets.dart';

import '../../../domain/playlists/playlist_ids.dart';
import 'playlist_edit_mode.dart';
import 'playlist_filter_state.dart';
import 'playlist_reorder.dart';
import 'playlist_shown_entries.dart';

/// The edit-mode and drag glue of a playlist page's songs part, kept apart
/// from its widgets: what edit mode does to the filter, the drag freeze, the
/// drop and the menu's Up / Down. Plain object owned by the host State;
/// [refresh] is the State's `setState`.
class PlaylistEditHost {
  PlaylistEditHost({
    required this.edit,
    required this.filter,
    required this.context,
    required this.uid,
    required this.shown,
    required this.hasEntries,
    required this.refresh,
  }) {
    freeze = ReorderFreeze(onExpired: unfreeze);
    edit.addListener(_onEditChanged);
  }

  final PlaylistEditMode edit;
  final PlaylistFilterState filter;
  final BuildContext Function() context;
  final String Function() uid;

  /// The rows drawn by the last build.
  final ShownEntries Function() shown;
  final bool Function() hasEntries;
  final VoidCallback refresh;

  late final ReorderFreeze freeze;
  SavedFilter? _saved;
  bool _wasEditing = false;

  /// The entry the last drag began on, kept after the freeze ends.
  String? _lastDragUid;

  /// Pointers down on the page: only the last one up can end a drag.
  final Set<int> _pointers = {};

  void dispose() {
    edit.removeListener(_onEditChanged);
    freeze.dispose();
  }

  /// Edit mode began or ended (a drag flag change is none of our business).
  void _onEditChanged() {
    final editing = edit.editing;
    if (editing == _wasEditing) return;
    _wasEditing = editing;
    if (editing) {
      _saved = filter.save();
      filter.close();
      return;
    }
    freeze.release();
    final saved = _saved;
    _saved = null;
    // An emptied list has nothing to narrow: no flash of the field.
    if (saved != null && saved.open && hasEntries()) {
      filter.restore(saved);
    } else {
      refresh();
    }
  }

  void dragStart(int index) {
    final rows = shown().rows;
    if (index < 0 || index >= rows.length) return;
    _lastDragUid = rows[index].uid;
    freeze.start(_lastDragUid!, shown());
    edit.dragging = true;
  }

  /// The dragged row landed at [newIndex] (final, no adjustment). The page
  /// shows the new order and the rows come loose in the same frame. With the
  /// freeze already off, a row at [oldIndex] that is not the one the drag
  /// began on is never moved.
  void drop(int oldIndex, int newIndex) {
    final rows = (freeze.frozen ?? shown()).rows;
    final uid =
        freeze.draggedUid ??
        (oldIndex >= 0 &&
                oldIndex < rows.length &&
                rows[oldIndex].uid == _lastDragUid
            ? _lastDragUid
            : null);
    if (uid != null) {
      final place = afterEntryFor(rows, uid, newIndex);
      if (place != null) {
        moveEntryOnPage(context(), this.uid(), uid, place.after);
      }
    }
    unfreeze();
  }

  void unfreeze() {
    freeze.release();
    if (!context().mounted) return;
    edit.dragging = false;
    refresh();
  }

  /// Menu "Move up / down": the entry is found again by uid in the rows now.
  void step(String entryUid, int delta) {
    if (!context().mounted) return;
    final place = afterEntryForStep(shown().rows, entryUid, delta);
    if (place != null) {
      moveEntryOnPage(context(), uid(), entryUid, place.after);
    }
  }

  void pointerDown(int pointer) => _pointers.add(pointer);

  /// A pointer up or cancel: a drop that moves nothing and a cancelled drag
  /// end in no list callback, so the last pointer up starts the grace timer.
  void pointerGone(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.isEmpty) freeze.armGrace();
  }

  bool get isFavorites => uid() == PlaylistUids.favorites;
}
