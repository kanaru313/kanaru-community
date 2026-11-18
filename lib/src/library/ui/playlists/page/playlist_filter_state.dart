import 'package:flutter/widgets.dart';

import '../../browse/filter_debouncer.dart';
import 'playlist_edit_mode.dart' show SavedFilter;

/// The filter of a playlist page: whether its field is open and what it holds
/// (the debounced text the rows use). Never stored. [onChanged] is the host's
/// `setState`.
class PlaylistFilterState {
  PlaylistFilterState({required this.onChanged});

  final VoidCallback onChanged;
  final TextEditingController controller = TextEditingController();
  final FilterDebouncer _debounce = FilterDebouncer();

  bool open = false;

  /// What the rows are narrowed by.
  String text = '';

  /// A keystroke in the field: the rows follow after a pause. [alive] says
  /// whether the host still stands.
  void typed(String value, bool Function() alive) => _debounce(value, (v) {
    if (!alive()) return;
    text = v;
    onChanged();
  });

  void toggle() => open ? close() : _set(open: true, value: text);

  void close() => _set(open: false, value: '');

  SavedFilter save() => (open: open, text: controller.text);

  void restore(SavedFilter saved) => _set(open: saved.open, value: saved.text);

  void _set({required bool open, required String value}) {
    _debounce.cancel();
    this.open = open;
    text = value;
    if (controller.text != value) controller.text = value;
    onChanged();
  }

  void dispose() {
    _debounce.cancel();
    controller.dispose();
  }
}
