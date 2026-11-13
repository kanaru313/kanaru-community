import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../../media/domain/track_lines.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/ui/track_cover.dart';
import '../../state/browse/selection_providers.dart';
import '../../state/favorites_providers.dart';
import '../browse/library_labels.dart';
import '../browse/play_actions.dart';
import '../menus/menu_origin.dart';
import '../menus/more_button.dart';
import '../menus/open_menu.dart';
import '../selection/selection_shortcuts.dart';

final _log = Logger('library.song_tile');

/// One song row of every song list: cover, title / artists / `album • year`,
/// duration over the heart. Tap plays `ids[index]` with the list as the
/// queue. The tile watches only its own answers (is it playing, is it a
/// favourite), so a change elsewhere rebuilds nothing else.
///
/// [ids] is the list the row belongs to, as the list currently holds it, and
/// [index] the row's place in it. With [showNumber] the track number is a
/// badge in the cover's end-bottom corner (album pages); with [showDetected] a
/// song with a detected language carries a small "auto-detected" tag after its
/// title.
class SongTile extends ConsumerWidget {
  const SongTile({
    super.key,
    required this.info,
    required this.index,
    required this.ids,
    required this.playContext,
    this.showNumber = false,
    this.showDetected = false,
    this.origin = const MenuOrigin.list(),
  });

  final TrackInfo info;
  final int index;
  final List<TrackId> ids;
  final PlayContext playContext;
  final bool showNumber;

  /// Tags a song whose language was detected, not read from a tag (language
  /// pages).
  final bool showDetected;

  /// The page the list is on, so the song's menu never links back to it.
  final MenuOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(isCurrentTrackProvider(info.id));
    final selected = ref.watch(isSelectedProvider(info.id));
    final duration = info.durationMs;
    void menu({bool viaKeyboard = false}) =>
        openSongMenu(context, info, origin: origin, viaKeyboard: viaKeyboard);
    // Long press on a song selects it (the menu has ⋮, right click, Menu).
    return KContextRegion(
      longPressOpens: false,
      // Right click on one of several selected songs is about the selection.
      onOpen: (at) {
        final selection = ref.read(librarySelectionProvider);
        if (selection.set.contains(info.id) && selection.ids.length > 1) {
          openSelectionMenu(context, viaKeyboard: at == null);
        } else {
          menu(viaKeyboard: at == null);
        }
      },
      child: KMediaCard(
        title: info.title,
        titleLabel: showDetected && info.languageDetected
            ? l10n.libraryAutoDetectedTag
            : null,
        line2: trackArtistLine(info),
        line3: trackAlbumLine(info),
        leading: _SongCover(
          info: info,
          current: current,
          number: showNumber && !selected && (info.trackNo ?? 0) > 0
              ? info.trackNo
              : null,
        ),
        top: duration == null ? null : Text(formatClock(duration)),
        bottom: SongFavoriteButton(trackId: info.id),
        trailing: LibraryMoreButton(onPressed: menu),
        current: current,
        currentLabel: l10n.libraryNowPlaying,
        selected: selected,
        onLongPress: selected ? null : () => _select(ref),
        onTap: () => _tap(ref, context),
      ),
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

class _SongCover extends StatelessWidget {
  const _SongCover({required this.info, required this.current, this.number});

  final TrackInfo info;
  final bool current;

  /// Track number badge in the bottom end corner; null shows none.
  final int? number;

  @override
  Widget build(BuildContext context) {
    const radius = KMediaCard.coverRadius;
    return Stack(
      children: [
        TrackCover(
          coverKey: info.coverKey,
          seed: info.albumKey?.encode() ?? info.title,
          size: CoverSize.thumb,
          dimension: KMediaCard.coverSize,
          radius: radius,
        ),
        if (current)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.scrim
                    .withValues(alpha: 0.45),
                borderRadius: radius,
              ),
              child: Center(
                child: _PlayingMark(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        if (number != null)
          PositionedDirectional(
            key: songTileBadgeKey,
            end: _badgeInset,
            bottom: _badgeInset,
            child: _NumberBadge(number: number!),
          ),
      ],
    );
  }
}

const double _badgeInset = 4;

/// Key of the track number badge (tests find it by this).
const Key songTileBadgeKey = ValueKey('song-tile-number-badge');

/// Track number pill on a cover: round for one digit, wider for more.
/// Text scale is clamped so the badge stays inside the 56 dp cover.
class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final style = theme.textTheme.labelSmall!.copyWith(
      color: Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final height = scaler.scale(style.fontSize ?? 11) * (style.height ?? 1.3);
    // Not excluded: the number is read once, as text of the merged row.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.scrim.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(height),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: height, minHeight: height),
        child: Padding(
          // Round for one digit; more digits get side room.
          padding: EdgeInsets.symmetric(horizontal: number > 9 ? 3 : 0),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              '$number',
              maxLines: 1,
              softWrap: false,
              textScaler: scaler,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

/// Equalizer bars; the only part of a tile that watches play / pause.
class _PlayingMark extends ConsumerWidget {
  const _PlayingMark({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      KEqualizerIcon(playing: ref.watch(isPlayingProvider), color: color);
}

/// The ♥ of a song row: filled for a favourite, toggles on press. Watches
/// only its own answer.
class SongFavoriteButton extends ConsumerWidget {
  const SongFavoriteButton({super.key, required this.trackId});

  final TrackId trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorite = ref.watch(isFavoriteProvider(trackId));
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: favorite ? l10n.libraryFavoriteRemove : l10n.libraryFavoriteAdd,
      isSelected: favorite,
      onPressed: () => _toggle(ref, context),
      iconSize: 20,
      // Default 48 dp tap target; the card lets this slot reach into the row.
      icon: const Icon(KIcons.heart),
      selectedIcon: Icon(KIcons.heartFilled, color: scheme.primary),
    );
  }

  Future<void> _toggle(WidgetRef ref, BuildContext context) async {
    final message = AppLocalizations.of(context).libraryFavoriteFailed;
    try {
      await ref.read(favoritesControllerProvider).toggle(trackId);
    } on Object catch (e, s) {
      _log.warning('toggling favorite of $trackId failed', e, s);
      if (context.mounted) showAppSnackBar(context, message);
    }
  }
}
