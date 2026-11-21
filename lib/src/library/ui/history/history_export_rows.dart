import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../m3u/m3u_entry_points.dart';
import '../menus/menu_model.dart';

/// The M3U export row of a list of songs that is not a playlist (History,
/// Most played): one row, absolute paths. The file is named [name] ([fallback]
/// when that holds nothing a file name can); [tracks] is read when the row is
/// chosen. [enabled] false dims it (nothing to write, or the list is
/// reloading); it is "coming soon" where no file dialog exists.
MenuItemSpec trackListExportRow(
  AppLocalizations l10n, {
  required String name,
  required String fallback,
  required Future<List<TrackId>> Function() tracks,
  required bool enabled,
}) => MenuItemSpec(
  MenuItemId.playlistExportM3u,
  icon: KIcons.fileExport,
  title: l10n.historyMenuExportM3u,
  enabled: enabled,
  soon: !m3uAvailable,
  action: MenuAction.run(
    (ctx) => exportM3uTracks(
      ctx,
      name: name,
      fallback: fallback,
      tracks: tracks,
      relative: false,
    ),
  ),
);
