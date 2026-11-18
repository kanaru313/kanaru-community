import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/browse/detail_expand_providers.dart';
import '../../browse/library_labels.dart';
import '../../browse/play_shuffle_buttons.dart';
import '../../menus/more_button.dart';
import '../../playlist_common/playlist_cover.dart';
import '../../playlist_common/playlist_labels.dart';
import '../menu/playlist_menu.dart';
import 'playlist_shown_entries.dart';

/// Top of a playlist page (the left column on a wide page): cover, name,
/// `N songs · length` (a line with a heart for Favorites),
/// `[▶ Play] [shuffle] [⋮]` and the description. The wide column shows the cover as a framed card over a
/// washed backdrop. The cover has no action of its own.
///
/// While [editing] they and ⋮ are off.
///
/// Play and shuffle are served by the page ([onPlay]); while it serves one
/// ([serving]) both are off. The state lives above the layout, so a resize
/// that rebuilds this widget drops nothing.
class PlaylistHero extends ConsumerWidget {
  const PlaylistHero({
    super.key,
    required this.detail,
    required this.serving,
    required this.onPlay,
    this.editing = false,
  });

  final PlaylistDetail detail;
  final bool serving;
  final void Function({required bool shuffle}) onPlay;

  /// Edit mode: Play, shuffle and ⋮ are off.
  final bool editing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = detail.summary;
    final uid = summary.uid;
    final totals = playlistTotals(detail);
    final canPlay =
        detail.entries.any((e) => e.available) && !serving && !editing;
    final pageKey = 'playlist:$uid';
    final expanded = ref.watch(
      detailDescriptionExpandedProvider.select((s) => s.contains(pageKey)),
    );
    final description = summary.description;
    return KDetailHero(
      framedCover: true,
      coverBuilder: (context, side, radius) => PlaylistCover(
        uid: uid,
        autoCoverKeys: summary.autoCoverKeys,
        dimension: side,
        radius: radius,
      ),
      title: playlistDisplayName(l10n, summary),
      line2: KDetailLine(
        text: detail.entries.isNotEmpty
            ? '${l10n.librarySongCount(totals.count)} · '
                  '${formatTotalDuration(l10n, totals.durationMs)}'
            : l10n.playlistTrackCount(0),
      ),
      line3: summary.isFavorites ? l10n.plScreensFavoritesLine : null,
      line3Semantics: summary.isFavorites
          ? l10n.plScreensFavoritesLineSemantics
          : null,
      // The same filled heart and colour as the favourite toggle on a song.
      line3Trailing: summary.isFavorites
          ? Icon(
              KIcons.heartFilled,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      actions: PlayShuffleButtons(
        compact: false,
        labelled: true,
        playLabel: l10n.libraryPlay,
        onPlay: canPlay ? () => onPlay(shuffle: false) : null,
        onShuffle: canPlay ? () => onPlay(shuffle: true) : null,
        trailing: [
          if (editing)
            // The same box as the live button, off.
            KIconButton(
              tooltip: l10n.libraryMenuMore,
              size: KIconSize.md,
              padding: const EdgeInsets.all(KSpace.x3),
              onPressed: null,
              icon: KIcons.moreVert,
            )
          else
            LibraryMoreButton(
              large: true,
              onPressed: ({required viaKeyboard}) => unawaited(
                openPlaylistMenu(
                  context,
                  uid,
                  onOwnPage: true,
                  pageRoute: ModalRoute.of(context),
                  viaKeyboard: viaKeyboard,
                ),
              ),
            ),
        ],
      ),
      description: summary.isFavorites || description.trim().isEmpty
          ? null
          : KDetailDescription(
              text: description,
              expanded: expanded,
              onExpandedChanged: (v) => ref
                  .read(detailDescriptionExpandedProvider.notifier)
                  .set(pageKey, v),
              moreLabel: l10n.libraryShowMore,
              lessLabel: l10n.libraryShowLess,
            ),
    );
  }
}
