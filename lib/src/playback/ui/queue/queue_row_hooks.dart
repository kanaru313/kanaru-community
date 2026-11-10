import 'package:material_ui/material_ui.dart';

import '../../../media/domain/track_info.dart';
import '../../domain/queue_state.dart';

/// Widget at the end of a desktop row (the host puts duration over ♥ there).
/// [info] is null until the row's info has loaded.
typedef QueueRowTrailing = Widget Function(
  BuildContext context,
  QueueItem item,
  TrackInfo? info,
);

/// Opens the row menu. [at] is the global pointer position, or null to
/// anchor to the row. The playback module cannot import the library, so the
/// host supplies the menu (it needs "go to album").
typedef QueueRowMenu = void Function(
  BuildContext context,
  QueueItem item,
  TrackInfo? info,
  Offset? at,
);

/// Row geometry. Chosen by the host, not by the window width.
enum QueueRowSize {
  mobile(extent: 60, cover: 44, handle: 44),
  desktop(extent: 72, cover: 48, handle: 40);

  const QueueRowSize({
    required this.extent,
    required this.cover,
    required this.handle,
  });

  /// Fixed row height: the list can find a row from the scroll offset.
  final double extent;
  final double cover;
  final double handle;
}

/// Where a row stands relative to the current entry.
enum QueueRowRole { played, current, upcoming }
