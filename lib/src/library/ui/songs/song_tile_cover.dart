import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/ui/track_cover.dart';

/// The cover of a song row: the picture, the playing mark over it and the
/// track number badge.
class SongTileCover extends StatelessWidget {
  const SongTileCover({
    super.key,
    required this.info,
    required this.current,
    this.number,
    this.rank,
    this.missing = false,
  });

  final TrackInfo info;
  final bool current;

  /// Track number badge in the bottom end corner; null shows none.
  final int? number;

  /// Place in a ranking: a badge in the same corner as [number] (which it
  /// replaces); the first [topRanks] have the `primary` fill.
  final int? rank;

  /// The song's file is gone: a placeholder cover in place of the picture,
  /// the badge rules unchanged.
  final bool missing;

  /// Ranks that get the emphasised badge.
  static const int topRanks = 3;

  @override
  Widget build(BuildContext context) {
    const radius = KMediaCard.coverRadius;
    return Stack(
      children: [
        if (missing)
          KCover(
            image: null,
            size: KMediaCard.coverSize,
            placeholderSeed: info.coverSeed,
            placeholderIcon: KIcons.musicOff,
            radius: radius,
          )
        else
          TrackCover(
            coverKey: info.coverKey,
            seed: info.coverSeed,
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
        if (rank != null)
          PositionedDirectional(
            key: songTileBadgeKey,
            end: _badgeInset,
            bottom: _badgeInset,
            child: _NumberBadge(number: rank!, top: rank! <= topRanks),
          )
        else if (number != null)
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
  const _NumberBadge({required this.number, this.top = false});

  final int number;

  /// A top rank: `primary` fill, `onPrimary` text.
  final bool top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final style = theme.textTheme.labelSmall!.copyWith(
      color: top ? theme.colorScheme.onPrimary : Colors.white,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final height = scaler.scale(style.fontSize ?? 11) * (style.height ?? 1.3);
    // Not excluded: the number is read once, as text of the merged row.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: top
            ? theme.colorScheme.primary
            : theme.colorScheme.scrim.withValues(alpha: 0.55),
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
