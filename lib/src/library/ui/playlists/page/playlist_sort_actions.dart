import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/browse/list_sort.dart';
import '../../../state/playlists/playlist_prefs_providers.dart';
import '../../browse/list_sort_dialog.dart';
import '../../browse/list_sort_popover.dart';

/// Opens the sort dropdown of playlist [uid]'s page, anchored to [anchor].
///
/// The container is taken now: the sort box is on the root navigator and can
/// outlive the page, whose `ref` is dead by then.
Future<void> openPlaylistSort(
  BuildContext context,
  String uid,
  GlobalKey anchor,
  ListSortGuard guard,
) {
  final container = ProviderScope.containerOf(context);
  final sorts = container.read(playlistTrackSortsProvider.notifier);
  return openListSort(
    context,
    list: BrowseList.playlistTracks,
    anchor: anchor,
    guard: guard,
    read: () => container.read(playlistTrackSortProvider(uid)),
    write: (sort) => sorts.set(uid, sort),
    reset: () => sorts.reset(uid),
  );
}

/// Flips the direction of the stored sort of playlist [uid], from the order
/// at press time, not the last build's: two taps in one frame flip twice.
Future<void> reversePlaylistSort(WidgetRef ref, String uid) => ref
    .read(playlistTrackSortsProvider.notifier)
    .set(uid, ref.read(playlistTrackSortProvider(uid)).reversed());
