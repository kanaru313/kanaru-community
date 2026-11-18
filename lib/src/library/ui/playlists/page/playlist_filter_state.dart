import 'package:flutter/widgets.dart';

import '../../browse/filter_debouncer.dart';
import 'playlist_edit_mode.dart' show SavedFilter;

/// The filter of a playlist page: whether its field is open and what it holds
/// (the debounced text the rows use). Never stored. Owned by the page (its
/// Back / Esc chain reads it); the songs part listens and rebuilds.
class PlaylistFilterState extends ChangeNotifier {
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
    notifyListeners();
  });

  void toggle() => open ? close() : _set(open: true, value: text);

  void close() => _set(open: false, value: '');

  /// The list under the filter emptied: it has nothing to narrow, so the
  /// filter goes (after the frame, as it is called from a build).
  void closeWhenEmpty({required bool empty, required bool Function() alive}) {
    if (!empty || !(open || text.isNotEmpty)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (alive()) close();
    });
  }

  SavedFilter save() => (open: open, text: controller.text);

  void restore(SavedFilter saved) => _set(open: saved.open, value: saved.text);

  void _set({required bool open, required String value}) {
    _debounce.cancel();
    this.open = open;
    text = value;
    if (controller.text != value) controller.text = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce.cancel();
    controller.dispose();
    super.dispose();
  }
}
