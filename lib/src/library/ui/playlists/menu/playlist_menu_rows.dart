import 'package:intl/intl.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/play_context.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/custom_cover_providers.dart' show CustomCoverKind;
import '../../add_to_playlist/add_to_playlist.dart';
import '../../browse/library_labels.dart';
import '../../covers/pick_custom_cover.dart';
import '../../m3u/m3u_entry_points.dart';
import '../../menus/menu_model.dart';
import '../../playlist_common/playlist_labels.dart';
import 'playlist_menu_actions.dart';

/// A date as the menu shows it (the head's "edited" line, the name of a copy
/// of Favorites).
String playlistMenuDate(AppLocalizations l10n, DateTime date) =>
    DateFormat.yMd(l10n.localeName).format(date);

/// The play context of the songs a playlist menu starts.
PlayContext playlistPlayContext(AppLocalizations l10n, PlaylistSummary s) =>
    PlayContext(
      s.isFavorites ? PlayContextKind.favorites : PlayContextKind.playlist,
      ref: s.uid,
      label: playlistDisplayName(l10n, s),
    );

/// The head of a playlist menu: the playlist's list row (cover, name, counts,
/// description on one line, on desktop "Edited" plus the date without one). Only a
/// playlist with a cover of its own (not Favorites) gets the change-cover
/// button.
MenuHeader playlistMenuHeader(
  PlaylistSummary summary,
  AppLocalizations l10n, {
  required bool desktop,
}) {
  final count = summary.trackCount;
  final note = summary.description.isNotEmpty
      ? summary.description
      : desktop
      ? l10n.playlistEditedOn(
          playlistMenuDate(
            l10n,
            DateTime.fromMillisecondsSinceEpoch(summary.updatedAt),
          ),
        )
      : null;
  return MenuHeader(
    image: MenuImage.playlist,
    itemKey: summary.uid,
    autoCoverKeys: summary.autoCoverKeys,
    title: playlistDisplayName(l10n, summary),
    subtitle: count > 0
        ? l10n.libraryAlbumStats(count, minutesOf(summary.durationMs))
        : l10n.playlistTrackCount(0),
    note: note,
    action: summary.isFavorites
        ? null
        : MenuTrailingSpec(
            icon: KIcons.imageEdit,
            tooltip: l10n.playlistMenuChangeCover,
            action: MenuAction.run(
              (ctx) =>
                  pickCustomCover(ctx, CustomCoverKind.playlist, summary.uid),
            ),
          ),
  );
}

/// What "Add to playlist…" hands the picker: the playable songs captured when
/// the menu opened, named after the playlist, which is left out of the list.
AddToPlaylistRequest playlistCopyRequest(
  PlaylistDetail detail,
  AppLocalizations l10n,
) => AddToPlaylistRequest(
  tracks: detail.playableIds,
  sourceLabel: l10n.playlistPickerFrom(
    playlistDisplayName(l10n, detail.summary),
  ),
  excludePlaylistUid: detail.summary.uid,
);

/// "Add to playlist…" (shared with Favorites): copies the playable songs to
/// other playlists; disabled when none can be played.
MenuItemSpec playlistCopyToRow(PlaylistDetail detail, AppLocalizations l10n) {
  final request = playlistCopyRequest(detail, l10n);
  return MenuItemSpec(
    MenuItemId.playlist,
    icon: KIcons.playlistAdd,
    title: l10n.playlistMenuCopyTo,
    hint: l10n.playlistMenuCopyToHint(request.tracks.length),
    enabled: request.tracks.isNotEmpty,
    action: MenuAction.run((ctx) => showAddToPlaylist(ctx, request)),
  );
}

/// "Remove missing songs" with the uids captured when the menu opened, so a
/// scan that marks another entry missing meanwhile leaves it alone.
MenuItemSpec playlistRemoveMissingRow(
  PlaylistDetail detail,
  AppLocalizations l10n,
) {
  final uids = [
    for (final e in detail.entries)
      if (!e.available) e.uid,
  ];
  return MenuItemSpec(
    MenuItemId.playlistRemoveMissing,
    icon: KIcons.musicOff,
    title: l10n.playlistMenuRemoveUnavailable,
    subtitle: l10n.playlistMenuRemoveUnavailableHint(uids.length),
    action: MenuAction.run(
      (ctx) => removeMissingEntries(ctx, detail.summary.uid, uids),
    ),
  );
}

/// The two M3U export rows; [relative] false = absolute paths only.
List<MenuItemSpec> playlistExportRows(
  PlaylistDetail detail,
  AppLocalizations l10n, {
  required bool withRelative,
}) {
  final uid = detail.summary.uid;
  final empty = detail.entries.isEmpty;
  return [
    MenuItemSpec(
      MenuItemId.playlistExportM3u,
      icon: KIcons.fileExport,
      title: l10n.playlistMenuExportM3u,
      subtitle: l10n.playlistMenuExportM3uHint,
      enabled: !empty,
      soon: !m3uAvailable,
      action: MenuAction.run((ctx) => exportM3u(ctx, uid, relative: false)),
    ),
    if (withRelative)
      MenuItemSpec(
        MenuItemId.playlistExportM3uRelative,
        icon: KIcons.fileExport,
        title: l10n.playlistMenuExportM3uRelative,
        hint: l10n.playlistMenuExportM3uRelativeHint,
        enabled: !empty,
        soon: !m3uAvailable,
        action: MenuAction.run((ctx) => exportM3u(ctx, uid, relative: true)),
      ),
  ];
}
