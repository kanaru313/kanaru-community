import 'package:material_ui/material_ui.dart';

import '../../../media/domain/track_info.dart';
import '../../../playback/domain/queue_state.dart';
import '../../../playback/ui/playback_time_label.dart';
import 'favorite_button.dart';

/// End of a desktop queue row: duration over ♥. Matches `QueueRowTrailing`.
Widget queueRowTrailing(BuildContext context, QueueItem item, TrackInfo? info) {
  final ms = info?.durationMs;
  return SizedBox(
    width: 56,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ms == null ? '' : formatClock(Duration(milliseconds: ms)),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        FavoriteButton(trackId: item.trackId, iconSize: 18),
      ],
    ),
  );
}
