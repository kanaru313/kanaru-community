import 'now_playing_auto_hide.dart';

/// The auto-hide controller of Now Playing, which also knows how many floating
/// surfaces (the ⋮ song menu, the sleep timer modal) hold it open. The `V`
/// shortcut ignores keys that come from a floating surface, but not while the
/// pointer merely rests on the header (that pins too).
class NowPlayingChrome extends AutoHideController {
  int _floating = 0;

  /// A floating surface is open.
  bool get hasFloating => _floating > 0;

  /// Keeps the header shown until the matching [unpinFloating].
  void pinFloating() {
    _floating++;
    pin();
  }

  void unpinFloating() {
    if (_floating == 0) return;
    _floating--;
    unpin();
  }

  /// Runs [body] (a floating surface) with the header pinned. [stillOwned]
  /// tells whether the caller is still in the tree afterwards: one that left
  /// (Now Playing closed) leaves the controller alone, the screen disposes it.
  Future<T> whilePinned<T>(
    Future<T> Function() body, {
    required bool Function() stillOwned,
  }) async {
    pinFloating();
    try {
      return await body();
    } finally {
      if (stillOwned()) unpinFloating();
    }
  }
}
