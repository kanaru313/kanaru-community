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
/// [index] the row's place in it. With [showNumber] the track number
/// comes before the cover (album pages); with [showDetected] a song with a
/// detected language carries a small "auto-detected" tag after its title.
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
        prefix: showNumber ? _TrackNumber(number: info.trackNo) : null,
        leading: _SongCover(info: info, current: current),
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
  const _SongCover({required this.info, required this.current});

  final TrackInfo info;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10);
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
      ],
    );
  }
}

/// Track number before the cover (album pages), empty when the file has no
/// track number. Right-aligned in at least the prefix width on one line; the
/// card's prefix FittedBox scales it down when a long number or a large text
/// size makes it wider, so it never wraps or overflows.
class _TrackNumber extends StatelessWidget {
  const _TrackNumber({required this.number});

  final int? number;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: KMediaCard.prefixWidth),
    child: Text(
      number == null ? '' : '$number',
      textAlign: TextAlign.right,
      maxLines: 1,
      softWrap: false,
      // The card sets its soft colour (the tint-aware one) on IconTheme, not
      // on the text style; this reads it from there. Depends on KMediaCard
      // keeping that IconTheme around its content.
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: IconTheme.of(context).color),
    ),
  );
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
