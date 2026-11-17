import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../media/domain/cover_files.dart';
import '../../media/domain/track_id.dart';
import '../state/track_info_providers.dart';
import 'flight_source.dart';
import 'track_cover.dart';

/// Cover and two text lines of the mini player, in the size of a song row.
///
/// The text scale is capped so the two lines always fit the fixed card height
/// ([maxTextScale]).
class MiniPlayerBody extends ConsumerWidget {
  const MiniPlayerBody({
    super.key,
    required this.trackId,
    required this.flight,
    required this.cardHeight,
  });

  final TrackId trackId;
  final FlightSource? flight;

  /// Height of the card this body sits in.
  final double cardHeight;

  /// Largest text scale at which a title and an artist line still fit
  /// [cardHeight] with [KSpace.x1] of room above and below.
  static double maxTextScale(double cardHeight) =>
      (cardHeight - 2 * KSpace.x1) /
      ((KMediaCardMetrics.titleSize + KMediaCardMetrics.lineSize) *
          KMediaCardMetrics.lineHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(trackInfoProvider(trackId)).value;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget wrap(FlightPiece piece, Widget child) => flight == null
        ? child
        : FlightPieceHost(source: flight!, piece: piece, child: child);
    return Padding(
      padding: const EdgeInsets.only(left: KSpace.x2),
      child: Row(
        spacing: KSpace.x3,
        children: [
          wrap(
            FlightPiece.cover,
            TrackCover(
              coverKey: info?.coverKey,
              seed: info?.coverSeed ?? '',
              size: CoverSize.thumb,
              dimension: KMediaCard.coverSize,
              radius: KMediaCard.coverRadius,
            ),
          ),
          Expanded(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: maxTextScale(cardHeight),
              child: wrap(
                FlightPiece.text,
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info?.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KMediaCardMetrics.titleStyle(text),
                    ),
                    if (info?.artist != null)
                      Text(
                        info!.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KMediaCardMetrics.lineStyle(text)
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
