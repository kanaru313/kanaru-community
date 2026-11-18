import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/play_context.dart';
import '../../../domain/playlists/playlist_ids.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../browse/library_list_scaffold.dart';
import '../../menus/menu_model.dart' show MenuItemSpec;
import '../../menus/menu_origin.dart';
import '../../songs/song_tile.dart';
import 'playlist_shown_entries.dart';

/// What the rows of a playlist page ask the page to do.
class PlaylistRowActions {
  const PlaylistRowActions({
    required this.menuExtras,
    required this.missingMenu,
    required this.removeMissing,
    required this.removeInEditMode,
    required this.onReorderStart,
    required this.onReorderItem,
  });

  /// The group of the song menu of the row at [index] of the shown rows.
  final List<MenuItemSpec> Function(PlaylistEntryView entry, int index)
  menuExtras;

  /// Opens the menu of a missing row.
  final Future<void> Function(
    PlaylistEntryView entry, {
    required bool viaKeyboard,
  })
  missingMenu;

  /// The ✕ of a missing row in normal mode.
  final void Function(PlaylistEntryView entry) removeMissing;

  /// Swipe, ✕ or Delete on an edit-mode row; false = the row springs back.
  final Future<bool> Function(PlaylistEntryView entry) removeInEditMode;

  /// A drag began on the row at this index of the shown rows.
  final void Function(int index) onReorderStart;

  /// Final drop: the row went from `oldIndex` to `newIndex` (no further
  /// adjustment needed).
  final void Function(int oldIndex, int newIndex) onReorderItem;
}

/// The rows of a playlist: an ordinary song row for each available entry and
/// a dashed "not in library" row for each missing one. One reorderable sliver
/// in both modes, so turning edit mode on or off remounts no row; only in
/// edit mode do rows carry a drag handle (the callbacks are then ignored by
/// the page when it is not editing).
///
/// Every index here (`KDragHandle.index`, the drag callbacks) is an index
/// into [shown]`.rows`. `SongTile.index` is the place among the playable
/// ones, for the play queue only.
class PlaylistRowsSliver extends StatelessWidget {
  const PlaylistRowsSliver({
    super.key,
    required this.uid,
    required this.shown,
    required this.playContext,
    required this.editing,
    required this.actions,
  });

  final String uid;
  final ShownEntries shown;
  final PlayContext playContext;
  final bool editing;
  final PlaylistRowActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gutter = libraryRowGutter(context);
    final origin = MenuOrigin.playlist(uid);
    final isFavorites = uid == PlaylistUids.favorites;
    final removeLabel = isFavorites
        ? l10n.playlistMenuRemoveFavorite
        : l10n.playlistMenuRemoveEntry;
    SongTileEdit? editOf(PlaylistEntryView entry, int i) => editing
        ? SongTileEdit(
            handle: KDragHandle(
              index: i,
              semanticLabel: l10n.playlistDragHandle,
            ),
            removeLabel: removeLabel,
            onRemove: () => actions.removeInEditMode(entry),
          )
        : null;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x4),
      sliver: SliverReorderableList(
        itemExtent: KMediaCard.extentOf(MediaQuery.textScalerOf(context)),
        itemCount: shown.rows.length,
        onReorderStart: (i) {
          if (editing) actions.onReorderStart(i);
        },
        onReorderItem: (from, to) {
          if (editing) actions.onReorderItem(from, to);
        },
        itemBuilder: (context, i) {
          final entry = shown.rows[i];
          // Keyed by entry: a row whose index now holds another entry
          // starts over, so a swipe never acts on the wrong one.
          if (!entry.available) {
            return SongTile(
              key: ValueKey(entry.uid),
              info: entry.info,
              index: 0,
              ids: shown.playable,
              playContext: playContext,
              origin: origin,
              unavailable: true,
              edit: editOf(entry, i),
              onRemove: () => actions.removeMissing(entry),
              onMenu: editing
                  ? null
                  : ({required viaKeyboard}) =>
                        actions.missingMenu(entry, viaKeyboard: viaKeyboard),
            );
          }
          return SongTile(
            key: ValueKey(entry.uid),
            info: entry.info,
            index: shown.playableIndex[i],
            ids: shown.playable,
            playContext: playContext,
            origin: origin,
            markCurrent: shown.firstOfTrack.contains(entry.uid),
            edit: editOf(entry, i),
            menuExtras: editing ? const [] : actions.menuExtras(entry, i),
            menuFavoriteRow: !isFavorites,
          );
        },
      ),
    );
  }
}
