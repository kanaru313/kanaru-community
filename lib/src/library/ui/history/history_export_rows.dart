import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../m3u/m3u_entry_points.dart';
import '../menus/menu_model.dart';

/// The M3U export rows of a list of songs that is not a playlist (History,
/// Most played): paths absolute, then relative, as a playlist's menu offers
/// them. The file is named [name]; [tracks] is read when a row is chosen.
/// [enabled] false dims both (nothing to write, or the list is reloading);
/// they are "coming soon" where no file dialog exists.
List<MenuItemSpec> trackListExportRows(
  AppLocalizations l10n, {
  required String name,
  required Future<List<TrackId>> Function() tracks,
  required bool enabled,
}) => [
  MenuItemSpec(
    MenuItemId.playlistExportM3u,
    icon: KIcons.fileExport,
    title: l10n.playlistMenuExportM3u,
    subtitle: l10n.playlistMenuExportM3uHint,
    enabled: enabled,
    soon: !m3uAvailable,
    action: MenuAction.run(
      (ctx) =>
          exportM3uTracks(ctx, name: name, tracks: tracks, relative: false),
    ),
  ),
  MenuItemSpec(
    MenuItemId.playlistExportM3uRelative,
    icon: KIcons.fileExport,
    title: l10n.playlistMenuExportM3uRelative,
    hint: l10n.playlistMenuExportM3uRelativeHint,
    enabled: enabled,
    soon: !m3uAvailable,
    action: MenuAction.run(
      (ctx) => exportM3uTracks(ctx, name: name, tracks: tracks, relative: true),
    ),
  ),
];
