import 'package:material_ui/material_ui.dart';

import '../../../media/domain/track_info.dart';
import '../../domain/queue_state.dart';

/// The ♥ under a row's duration. The playback module cannot import the
/// library, so the host supplies the button (it toggles library favourites).
typedef QueueRowFavorite = Widget Function(
  BuildContext context,
  QueueItem item,
);

/// Opens the row menu. [at] is the global pointer or button position, or null
/// to anchor to the row; [viaKeyboard] tells the host the menu was asked for
/// with the keyboard. The playback module cannot import the library, so the
/// host supplies the menu (it needs "go to album").
typedef QueueRowMenu = void Function(
  BuildContext context,
  QueueItem item,
  TrackInfo? info,
  Offset? at, {
  bool viaKeyboard,
});

/// Which shell the row is for (handle size, long press vs Delete); chosen by the host, not by the window width.
/// The row height comes from `KMediaCard.extentOf`, not from this.
enum QueueRowSize {
  /// Handle 48 dp, long press on the row opens the menu.
  mobile,

  /// Handle 40 dp, Delete removes the row.
  desktop,
}

/// Where a row stands relative to the current entry.
enum QueueRowRole { played, current, upcoming }
