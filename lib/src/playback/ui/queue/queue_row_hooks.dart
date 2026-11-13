import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/track_id.dart';
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

/// How queue rows take part in the app-wide song selection. The playback
/// module cannot import the library, so the host supplies the state and the
/// actions; a list or row without it has no selection.
class QueueRowSelection {
  const QueueRowSelection({
    required this.isSelected,
    required this.selecting,
    required this.onSelect,
  });

  /// Whether a track is selected. A row watches only its own track, so a
  /// selection change rebuilds just the rows it touches.
  final ProviderListenable<bool> Function(TrackId id) isSelected;

  /// Whether the selection is not empty (a plain tap then toggles).
  final ProviderListenable<bool> selecting;

  /// Toggles the track of [item], or with [range] selects the entries between
  /// the last one picked here and [item].
  final void Function(QueueItem item, {bool range}) onSelect;
}

/// Which shell the row is for (handle size, long press vs Delete); chosen by
/// the host, not by the window width.
/// The row height comes from `KMediaCard.extentOf`, not from this.
enum QueueRowSize {
  /// Handle 48 dp, long press on the row selects it (the menu is on ⋮).
  mobile,

  /// Handle 40 dp, Delete removes the row.
  desktop,
}

/// Where a row stands relative to the current entry.
enum QueueRowRole { played, current, upcoming }
