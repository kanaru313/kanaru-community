import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/play_context.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/ui/track_cover.dart';
import '../../state/favorites_providers.dart';
import '../browse/library_labels.dart';
import '../browse/play_actions.dart';

final _log = Logger('library.song_tile');

/// The artist line of a track: every artist of the tag in order, else the
/// single artist field.
String songArtistLine(TrackInfo info) {
  if (info.artists.isNotEmpty) return info.artists.join(', ');
  return info.artist ?? '';
}

/// `album • year`, whichever parts exist.
String songAlbumLine(TrackInfo info) {
  final album = info.album;
  final year = info.year;
  return [
    if (album != null && album.isNotEmpty) album,
    if (year != null) '$year',
  ].join(' • ');
}

/// One song row of every song list: cover, title / artists / `album • year`,
/// duration over the heart. Tap plays `ids[index]` with the list as the
/// queue. The tile watches only its own answers (is it playing, is it a
/// favourite), so a change elsewhere rebuilds nothing else.
///
/// [ids] is the list the row belongs to, as the list currently holds it, and
/// [index] the row's place in it. With [showNumber] the cover gives way to
/// the track number (album pages).
class SongTile extends ConsumerWidget {
  const SongTile({
    super.key,
    required this.info,
    required this.index,
    required this.ids,
    required this.playContext,
    this.showNumber = false,
  });

  final TrackInfo info;
  final int index;
  final List<TrackId> ids;
  final PlayContext playContext;
  final bool showNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(isCurrentTrackProvider(info.id));
    final favorite = ref.watch(isFavoriteProvider(info.id));
    final duration = info.durationMs;
    return KMediaCard(
      title: info.title,
      line2: songArtistLine(info),
      line3: songAlbumLine(info),
      leading: showNumber
          ? _NumberColumn(number: info.trackNo, current: current)
          : _SongCover(info: info, current: current),
      top: duration == null ? null : Text(formatClock(duration)),
      bottom: _FavoriteButton(
        favorite: favorite,
        addLabel: l10n.libraryFavoriteAdd,
        removeLabel: l10n.libraryFavoriteRemove,
        onPressed: () => _toggleFavorite(ref, context),
      ),
      current: current,
      currentLabel: l10n.libraryNowPlaying,
      onTap: () => playFrom(ref, context, ids, index, playContext),
    );
  }

  Future<void> _toggleFavorite(WidgetRef ref, BuildContext context) async {
    final message = AppLocalizations.of(context).libraryFavoriteFailed;
    try {
      await ref.read(favoritesControllerProvider).toggle(info.id);
    } on Object catch (e, s) {
      _log.warning('toggling favorite of ${info.id} failed', e, s);
      if (context.mounted) showAppSnackBar(context, message);
    }
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

class _NumberColumn extends StatelessWidget {
  const _NumberColumn({required this.number, required this.current});

  final int? number;
  final bool current;

  @override
  Widget build(BuildContext context) {
    if (current) return const _PlayingMark();
    return Text(
      number == null ? '' : '$number',
      style: Theme.of(context).textTheme.titleSmall,
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

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.favorite,
    required this.addLabel,
    required this.removeLabel,
    required this.onPressed,
  });

  final bool favorite;
  final String addLabel;
  final String removeLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: favorite ? removeLabel : addLabel,
      isSelected: favorite,
      onPressed: onPressed,
      iconSize: 20,
      // Default 48 dp tap target; the card lets this slot reach into the row.
      icon: const Icon(KIcons.heart),
      selectedIcon: Icon(KIcons.heartFilled, color: scheme.primary),
    );
  }
}
