import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/playlists/playlist_models.dart';
import '../../../library/ui/add_to_playlist/add_to_playlist.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/state/queue_view_provider.dart';

/// Opens the "add to playlist" picker for the track that is playing.
Future<void> addCurrentToPlaylist(BuildContext context, TrackInfo info) =>
    showAddToPlaylist(
      context,
      AddToPlaylistRequest(tracks: [info.id], sourceLabel: info.title),
    );

/// Opens the picker with the whole queue, in play order, repeats kept. The ids
/// are taken now: a queue that changes while the picker is open does not
/// change what is saved. An empty queue does nothing.
Future<void> saveQueueToPlaylist(BuildContext context, WidgetRef ref) {
  final items = ref.read(queueViewProvider).value?.items;
  if (items == null || items.isEmpty) return Future.value();
  return showAddToPlaylist(
    context,
    AddToPlaylistRequest(
      tracks: [for (final i in items) i.trackId],
      sourceLabel: AppLocalizations.of(context).plAddSourceQueue,
    ),
  );
}
