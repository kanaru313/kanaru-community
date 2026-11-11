import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the desktop Now Playing shows the cover column next to the side
/// pane (the split view) or the pane alone. Kept for the session, so the
/// choice survives closing and reopening.
class CoverColumnShown extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final coverColumnShownProvider = NotifierProvider<CoverColumnShown, bool>(
  CoverColumnShown.new,
);
