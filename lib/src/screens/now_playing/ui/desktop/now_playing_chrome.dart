import 'now_playing_auto_hide.dart';

/// The auto-hide controller of Now Playing, which also knows how many floating
/// surfaces (the More menu, the sleep timer modal) hold it open. The `V`
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
}
