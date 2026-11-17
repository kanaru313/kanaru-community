import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kinds of shelf block on the detail pages. The collapsed state is kept per
/// kind, so collapsing "Albums" on one page collapses it on every page.
abstract final class ShelfBlockKind {
  static const albums = 'albums';
  static const appears = 'appears';
  static const artists = 'artists';
}

/// Kinds of shelf block the user collapsed. Kept for the session only (not
/// stored), so leaving a page and coming back finds the block as it was left.
class ShelfBlockCollapsed extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void set(String kind, bool collapsed) {
    if (state.contains(kind) == collapsed) return;
    state = collapsed ? {...state, kind} : ({...state}..remove(kind));
  }
}

final shelfBlockCollapsedProvider =
    NotifierProvider<ShelfBlockCollapsed, Set<String>>(ShelfBlockCollapsed.new);
