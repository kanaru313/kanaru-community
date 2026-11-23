import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../../media/domain/track_id.dart';
import '../../../platform/domain/setting.dart';
import '../../../platform/state/settings_providers.dart';
import '../../data/info/song_details_query.dart';
import '../../domain/info/song_details.dart';

/// Live details of one track for the info page; lives as long as the page.
/// Null while the track is gone, hidden or remote.
final songDetailsProvider = StreamProvider.autoDispose
    .family<SongDetails?, TrackId>(
      (ref, id) => watchSongDetails(ref.watch(appDatabaseProvider), id),
    );

/// Settings key `library.song_info_show_empty`: the eye button of the info
/// page, showing rows that have no value. Off by default.
final Setting<bool> songInfoShowEmptySetting = Setting(
  'library.song_info_show_empty',
  false,
  decode: (json) =>
      json is bool ? json : throw const FormatException('not a bool'),
  encode: (v) => v,
);

final songInfoShowEmptyProvider = settingNotifierProvider(
  songInfoShowEmptySetting,
);
