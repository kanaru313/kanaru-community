import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/list_view_prefs.dart';
import '../../domain/browse/sort_order.dart';

/// Settings key `library.playlist_track_sorts`: `{uid: [{by, desc}, ...]}`.
/// A corrupt entry is dropped (the playlist then uses the default); anything
/// that is not a map falls back to no entries.
final Setting<Map<String, SortOrder>> playlistTrackSortsSetting = Setting(
  'library.playlist_track_sorts',
  const {},
  decode: (json) {
    if (json is! Map) throw const FormatException('track sorts: not a map');
    final fallback = defaultSortOf(BrowseList.playlistTracks);
    final out = <String, SortOrder>{};
    for (final e in json.entries) {
      final key = e.key;
      if (key is! String) continue;
      final order = sortOrderFromJson(
        BrowseList.playlistTracks,
        e.value,
        fallback: fallback,
      );
      // A corrupt entry decodes to the default, which is the same as absent.
      if (order != fallback) out[key] = order;
    }
    return out;
  },
  encode: (m) => {for (final e in m.entries) e.key: sortOrderToJson(e.value)},
);

final _storedSortsProvider = settingNotifierProvider(playlistTrackSortsSetting);

/// Track sort each playlist remembers, by playlist uid. A playlist without an
/// entry uses the default (playlist order). The filter text is not kept.
/// Reading and writing go through the setting's own notifier.
class PlaylistTrackSortsNotifier extends Notifier<Map<String, SortOrder>> {
  @override
  Map<String, SortOrder> build() => ref.watch(_storedSortsProvider);

  /// Remembers [order] for playlist [uid].
  Future<void> set(String uid, SortOrder order) => ref
      .read(_storedSortsProvider.notifier)
      .set({...ref.read(_storedSortsProvider), uid: order});

  /// Back to the default ("Đặt lại"). No write when nothing was remembered.
  Future<void> reset(String uid) {
    final current = ref.read(_storedSortsProvider);
    if (!current.containsKey(uid)) return Future.value();
    return ref
        .read(_storedSortsProvider.notifier)
        .set({...current}..remove(uid));
  }

  /// Drops the entry of a deleted playlist.
  Future<void> forget(String uid) => reset(uid);
}

final playlistTrackSortsProvider =
    NotifierProvider<PlaylistTrackSortsNotifier, Map<String, SortOrder>>(
      PlaylistTrackSortsNotifier.new,
    );

/// Sort in use on one playlist page: its remembered order, else the default.
final playlistTrackSortProvider = Provider.autoDispose
    .family<SortOrder, String>(
      (ref, uid) =>
          ref.watch(playlistTrackSortsProvider.select((m) => m[uid])) ??
          defaultSortOf(BrowseList.playlistTracks),
    );
