import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../../media/domain/track_lines.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/ui/playback_time_label.dart' show formatClock;
import '../../../playback/ui/track_cover.dart';
import '../../state/browse/selection_providers.dart';
import '../browse/play_actions.dart';
import '../menus/menu_origin.dart';
import '../menus/open_menu.dart';
import 'song_tile.dart' show SongFavoriteButton;
import 'song_tile_cover.dart' show SongPlayingOverlay;

/// `album • length` under the artist of a song card, whichever parts exist.
String songCardDetail(TrackInfo info) {
  final album = info.album;
  final duration = info.durationMs;
  return [
    if (album != null && album.isNotEmpty) album,
    if (duration != null) formatClock(Duration(milliseconds: duration)),
  ].join(' • ');
}

/// One song of the Songs grid: a filled card with the cover (the heart on its
/// bottom-end corner), the title, the artists and `album • length`. Acts like
/// a song row: tap plays `ids[index]` with the list as the queue (or toggles
/// it while selecting, Shift / Ctrl clicks as in the rows), long press
/// selects, right click / Menu key opens the song menu (the selection menu on
/// one of several selected songs). No swipes and no ⋮, like every grid card.
class SongGridCard extends ConsumerWidget {
  const SongGridCard({
    super.key,
    required this.info,
    required this.index,
    required this.ids,
    required this.playContext,
    this.origin = const MenuOrigin.list(),
  });

  final TrackInfo info;
  final int index;
  final List<TrackId> ids;
  final PlayContext playContext;

  /// The page the grid is on, so the song's menu never links back to it.
  final MenuOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(isCurrentTrackProvider(info.id));
    final selected = ref.watch(isSelectedProvider(info.id));
    final selecting = ref.watch(
      librarySelectionProvider.select((s) => !s.isEmpty),
    );
    return KContextRegion(
      longPressOpens: false,
      onOpen: (at) => _menu(context, ref, viaKeyboard: at == null),
      child: KGridCard(
        filled: true,
        title: info.title,
        subtitle: trackArtistLine(info),
        detail: songCardDetail(info),
        current: current,
        currentLabel: l10n.libraryNowPlaying,
        selected: selected,
        selecting: selecting,
        // Hidden while selecting, so a tap on the corner selects too.
        coverBadge: selecting ? null : SongFavoriteButton(trackId: info.id),
        menuLabel: l10n.libraryMenuMore,
        onMenu: () => _menu(context, ref, viaKeyboard: true),
        onTap: () => _tap(ref, context),
        onLongPress: selected ? null : () => _select(ref),
        coverBuilder: (context, side) => Stack(
          children: [
            TrackCover(
              coverKey: info.coverKey,
              seed: info.coverSeed,
              size: CoverSize.thumb,
              dimension: side,
              radius: KGridCard.filledCoverRadius,
            ),
            if (current)
              const Positioned.fill(
                child: SongPlayingOverlay(radius: KGridCard.filledCoverRadius),
              ),
          ],
        ),
      ),
    );
  }

  void _menu(BuildContext context, WidgetRef ref, {required bool viaKeyboard}) {
    final selection = ref.read(librarySelectionProvider);
    if (selection.set.contains(info.id) && selection.ids.length > 1) {
      unawaited(openSelectionMenu(context, viaKeyboard: viaKeyboard));
      return;
    }
    unawaited(
      openSongMenu(context, info, origin: origin, viaKeyboard: viaKeyboard),
    );
  }

  /// Same rules as a song row's tap.
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

  void _select(WidgetRef ref) {
    HapticFeedback.selectionClick();
    ref.read(librarySelectionProvider.notifier).toggle(info.id);
  }
}

/// A grid cell whose song is still loading (the empty card) or failed to load
/// (the card with a retry button).
class SongGridCardPlaceholder extends StatelessWidget {
  const SongGridCardPlaceholder({super.key, this.onRetry});

  /// Null: still loading.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final retry = onRetry;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: KRadius.sm,
      ),
      child: retry == null
          ? const SizedBox.expand()
          : Center(
              child: KIconButton(
                icon: KIcons.refresh,
                tooltip: AppLocalizations.of(context).libraryRetry,
                onPressed: retry,
              ),
            ),
    );
  }
}
