import 'package:flutter/widgets.dart';

import '../../../domain/browse/list_sort.dart';
import '../../../domain/browse/sort_order.dart';

/// The order shown while editing: the stored one, whatever the page's sort
/// is. Never written to the prefs.
final SortOrder editModeSort = SortOrder.by(SortCriterion.playlistOrder);

/// Edit mode of one playlist page: page-local, never stored. Shared by the
/// header toggle and the songs part of the page.
class PlaylistEditMode extends ChangeNotifier {
  bool _editing = false;
  bool _dragging = false;

  bool get editing => _editing;

  /// A row is being dragged: the toggle waits.
  bool get dragging => _dragging;

  void toggle() => _editing ? exit() : enter();

  void enter() {
    if (_editing) return;
    _editing = true;
    notifyListeners();
  }

  void exit() {
    if (!_editing) return;
    _editing = false;
    _dragging = false;
    notifyListeners();
  }

  set dragging(bool value) {
    if (_dragging == value) return;
    _dragging = value;
    notifyListeners();
  }
}

/// The filter as it was when edit mode began: whether its field was open and
/// what it held.
typedef SavedFilter = ({bool open, String text});
