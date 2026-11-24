import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../../media/domain/track_lines.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/ui/playback_time_label.dart' show formatClock;
import '../../domain/playlists/playlist_ids.dart';
import '../../state/browse/selection_providers.dart';
import '../../state/favorites_providers.dart';
import '../browse/play_actions.dart';
import '../favorite_toggle.dart';
import '../info/open_song_info.dart';
import '../menus/menu_action_runner.dart';
import '../menus/menu_model.dart' show MenuItemSpec;
import '../menus/menu_origin.dart';
import '../menus/more_button.dart';
import '../menus/open_menu.dart';
import 'song_tile_cover.dart';
import 'song_tile_edit.dart';

export 'song_tile_cover.dart' show songTileBadgeKey;
export 'song_tile_edit.dart' show SongTileEdit;

/// One song row of every song list: cover, title / artists / `album • year`,
/// duration over the heart. Tap plays `ids[index]` with the list as the
/// queue. The tile watches only its own answers (is it playing, is it a
/// favourite), so a change elsewhere rebuilds nothing else.
///
/// [ids] is the list the row belongs to, as the list currently holds it, and
/// [index] the row's place in it. With [showNumber] the track number is a
/// badge in the cover's end-bottom corner (album pages).
class SongTile extends ConsumerWidget {
  const SongTile({
    super.key,
    required this.info,
    required this.index,
    required this.ids,
    required this.playContext,
    this.showNumber = false,
    this.origin = const MenuOrigin.list(),
    this.markCurrent = true,
    this.menuExtras = const [],
    this.menuFavoriteRow = true,
    this.edit,
    this.unavailable = false,
    this.onRemove,
    this.onMenu,
    this.detailLine,
    this.rank,
    this.onDelete,
    this.onUnavailableTap,
  });

  final TrackInfo info;
  final int index;
  final List<TrackId> ids;
  final PlayContext playContext;
  final bool showNumber;

  /// The page the list is on, so the song's menu never links back to it.
  final MenuOrigin origin;

  /// False: never shown as the playing row (a track listed twice marks only
  /// its first row).
  final bool markCurrent;

  /// Rows of the page's own, a group of the song menu (⋮, right click, Menu
  /// key).
  final List<MenuItemSpec> menuExtras;

  /// False leaves the heart row out of the song menu.
  final bool menuFavoriteRow;

  /// Playlist edit mode; null = an ordinary row. While set the row has the
  /// handle and a remove (swipe either way, Delete, ✕ on desktop) and no tap,
  /// long press, menu, heart or ⋮. The widget tree keeps its shape, so turning
  /// it on or off remounts nothing.
  final SongTileEdit? edit;

  /// The file is gone from the library (a playlist entry): dashed, dimmed,
  /// "not in library", not playable, no heart, no swipes. [onRemove] is the ✕.
  final bool unavailable;

  /// Removes an [unavailable] row in normal mode (the ✕ of its action slot).
  final VoidCallback? onRemove;

  /// Replaces the song menu entirely (right click, Menu key). A missing row
  /// ([unavailable]) opens no menu without it.
  final Future<void> Function({required bool viaKeyboard})? onMenu;

  /// Third line in place of `album • year` (a missing row's "not in library"
  /// too): History says when the play began, Most played the play count.
  final String? detailLine;

  /// Place in a ranking, shown as a badge in the cover's bottom-end corner;
  /// the first three are emphasised. Replaces the track number badge.
  final int? rank;

  /// The Delete key on the focused row (outside edit mode, which removes
  /// through its own handle).
  final VoidCallback? onDelete;

  /// A tap on an [unavailable] row (no song to play). Also gives that row a
  /// ⋮ when [onMenu] is set; without it a missing row stays inert.
  final VoidCallback? onUnavailableTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playing = ref.watch(isCurrentTrackProvider(info.id));
    final current = playing && markCurrent && !unavailable;
    final selected = ref.watch(isSelectedProvider(info.id));
    final duration = info.durationMs;
    void menu({bool viaKeyboard = false}) {
      final custom = onMenu;
      if (custom != null) {
        unawaited(custom(viaKeyboard: viaKeyboard));
        return;
      }
      // A missing row has no song to act on: without its own menu, none.
      if (unavailable) return;
      unawaited(
        openSongMenu(
          context,
          info,
          origin: origin,
          viaKeyboard: viaKeyboard,
          playlistGroup: menuExtras,
          favoriteRow: menuFavoriteRow,
        ),
      );
    }

    // Long press on a song selects it (the menu has ⋮, right click, Menu).
    // Swipe left queues it next, right opens its info; both stay on while a
    // selection is active. The row is keyed by track (see the song list), so
    // a swipe cannot outlive the song it began on.
    return _row(context, ref, l10n, current, selected, duration, menu);
  }

  /// Same call and toast as the menu's "Play next" button.
  void _playNext(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    final root = Navigator.of(context, rootNavigator: true).context;
    unawaited(MenuActionRunner(container, root).playNext([info.id]));
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool current,
    bool selected,
    int? duration,
    void Function({bool viaKeyboard}) menu,
  ) {
    final edit = this.edit;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final plain = edit == null && !unavailable;
    final removeLabel =
        origin is PlaylistOrigin &&
            (origin as PlaylistOrigin).uid == PlaylistUids.favorites
        ? l10n.playlistMenuRemoveFavorite
        : l10n.playlistMenuRemoveEntry;
    // One ✕ at most: a missing row's, or the desktop one of an edit row.
    final showEditX = edit != null && (desktop || unavailable);
    final markNumber = showNumber && !selected && (info.trackNo ?? 0) > 0;
    // A missing row that answers a tap and has a menu of its own.
    final reachable =
        unavailable &&
        edit == null &&
        onUnavailableTap != null &&
        onMenu != null;
    return SongTileRemovalScope(
      builder: (context, removal) => KContextRegion(
        longPressOpens: false,
        // Right click on one of several selected songs is about the selection.
        // Edit mode has no menu.
        onOpen: (at) {
          if (edit != null) return;
          final selection = ref.read(librarySelectionProvider);
          if (!unavailable &&
              selection.set.contains(info.id) &&
              selection.ids.length > 1) {
            openSelectionMenu(context, viaKeyboard: at == null);
          } else {
            menu(viaKeyboard: at == null);
          }
        },
        // Inside the region, around the card only: the swipe actions then sit
        // on the card's labelled node, the one a screen reader focuses. The
        // same widgets in every mode: only their arguments change.
        child: _swipe(
          context,
          l10n,
          edit,
          removal,
          CallbackShortcuts(
            bindings: edit == null
                ? {
                    // No key repeat: a held key removes one play.
                    const SingleActivator(
                      LogicalKeyboardKey.delete,
                      includeRepeats: false,
                    ): ?onDelete,
                    // Alt+Enter: the focused row's info, like the swipe.
                    // A missing row consumes the key and does nothing, so it
                    // never reaches the shell fallback.
                    const SingleActivator(
                      LogicalKeyboardKey.enter,
                      alt: true,
                      includeRepeats: false,
                    ): unavailable
                        ? () {}
                        : () => _openInfo(context, viaKeyboard: true),
                  }
                : {
                    // An editing row has no info: consume, do nothing.
                    const SingleActivator(
                      LogicalKeyboardKey.enter,
                      alt: true,
                      includeRepeats: false,
                    ): () {},
                    // No key repeat: a held key removes one entry.
                    const SingleActivator(
                      LogicalKeyboardKey.delete,
                      includeRepeats: false,
                    ): () =>
                        removal.fire(edit),
                  },
            child: KMediaCard(
              title: info.title,
              line2: trackArtistLine(info),
              line3:
                  detailLine ??
                  (unavailable
                      ? l10n.playlistNotInLibrary
                      : trackAlbumLine(info)),
              leading: SongTileCover(
                info: info,
                current: current,
                number: markNumber ? info.trackNo : null,
                rank: rank,
                missing: unavailable,
              ),
              top: duration == null
                  ? null
                  : Text(formatClock(Duration(milliseconds: duration))),
              bottom: plain ? SongFavoriteButton(trackId: info.id) : null,
              onAction: unavailable && edit == null ? onRemove : null,
              actionIcon: KIcons.close,
              actionLabel: removeLabel,
              accessory: edit == null
                  ? null
                  : songTileEditAccessory(
                      edit,
                      showRemove: showEditX,
                      onRemove: () => removal.fire(edit),
                    ),
              trailing: plain || reachable
                  ? LibraryMoreButton(onPressed: menu)
                  : null,
              current: current,
              currentLabel: l10n.libraryNowPlaying,
              selected: selected,
              selecting: ref.watch(
                librarySelectionProvider.select((s) => !s.isEmpty),
              ),
              missing: unavailable,
              editing: edit != null,
              onLongPress: selected || !plain ? null : () => _select(ref),
              onTap: plain
                  ? () => _tap(ref, context)
                  : unavailable && edit == null
                  ? onUnavailableTap
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the info with the same page rows as the tile's menu, so the
  /// info's ⋮ keeps them.
  void _openInfo(BuildContext context, {bool viaKeyboard = false}) => unawaited(
    openSongInfo(
      context,
      info,
      origin: origin,
      playlistGroup: menuExtras,
      favoriteRow: menuFavoriteRow,
      viaKeyboard: viaKeyboard,
    ),
  );

  /// Swipe left queues the song next, right opens its info (both stay on
  /// while a selection is active); in edit mode either way removes the entry;
  /// a missing row has neither.
  Widget _swipe(
    BuildContext context,
    AppLocalizations l10n,
    SongTileEdit? edit,
    SongTileRemoval removal,
    Widget child,
  ) {
    if (edit != null) {
      return KSwipeActions.remove(
        label: edit.removeLabel,
        onRemove: () => removal.run(edit),
        child: child,
      );
    }
    return KSwipeActions.capped(
      enabled: !unavailable,
      end: KSwipeAction(
        icon: KIcons.playlistPlay,
        label: l10n.libraryMenuPlayNext,
        onTrigger: () => _playNext(context),
      ),
      start: KSwipeAction(
        icon: KIcons.info,
        label: l10n.libraryMenuSongInfo,
        // Same page rows as the tile's menu, so the info's ⋮ keeps them.
        onTrigger: () => _openInfo(context),
      ),
      child: child,
    );
  }

  /// A tap or click: with Shift it extends the selection to this row, with
  /// Ctrl / ⌘ or once something is selected it toggles the row, else it plays.
  void _tap(WidgetRef ref, BuildContext context) {
    final selection = ref.read(librarySelectionProvider.notifier);
    switch (songClick(selecting: !ref.read(librarySelectionProvider).isEmpty)) {
      case SongClick.range:
        selection.selectRangeTo(ids, info.id);
      case SongClick.toggle:
        selection.toggle(info.id);
      case SongClick.play:
        playFrom(ref, context, ids, index, playContext);
    }
  }

  /// Long press: starts (or adds to) the selection, with a light tick.
  void _select(WidgetRef ref) {
    HapticFeedback.selectionClick();
    ref.read(librarySelectionProvider.notifier).toggle(info.id);
  }
}

/// The ♥ of a song row: filled for a favourite, toggles on press. Watches
/// only its own answer. A press while a write runs is ignored.
class SongFavoriteButton extends ConsumerStatefulWidget {
  const SongFavoriteButton({super.key, required this.trackId});

  final TrackId trackId;

  @override
  ConsumerState<SongFavoriteButton> createState() => _SongFavoriteButtonState();
}

class _SongFavoriteButtonState extends ConsumerState<SongFavoriteButton>
    with FavoriteToggle {
  @override
  void didUpdateWidget(SongFavoriteButton old) {
    super.didUpdateWidget(old);
    if (old.trackId != widget.trackId) forgetFavoriteWrite();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final favorite = ref.watch(isFavoriteProvider(widget.trackId));
    return KIconButton(
      tooltip: favorite ? l10n.libraryFavoriteRemove : l10n.libraryFavoriteAdd,
      semanticLabel: l10n.libraryFavoriteLabel,
      selected: favorite,
      onPressed: () => toggleFavorite(widget.trackId),
      size: KIconSize.sm,
      // The card's right column places this slot against the duration.
      padding: const EdgeInsets.all(KSpace.x2),
      icon: KIcons.heart,
      selectedIcon: KIcons.heartFilled,
    );
  }
}
