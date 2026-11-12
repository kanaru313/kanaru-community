import 'package:material_ui/material_ui.dart';

import '../../../media/domain/track_info.dart';
import '../../../playback/domain/queue_state.dart';
import 'favorite_button.dart';

/// The ♥ under a desktop queue row's duration. Matches `QueueRowTrailing`.
Widget queueRowTrailing(
  BuildContext context,
  QueueItem item,
  TrackInfo? info,
) => FavoriteButton(trackId: item.trackId, iconSize: 18);
