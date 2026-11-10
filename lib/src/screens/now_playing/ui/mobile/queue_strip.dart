import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../media/domain/cover_files.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/play_pause_button.dart';
import '../../../../playback/ui/track_cover.dart';
import '../../../../playback/ui/transport_buttons.dart';

/// The cover of the strip (and of the flight): grows from the source's size
/// to 72, its corners follow.
class StripCover extends ConsumerWidget {
  const StripCover({super.key, required this.rect, required this.t});

  final Rect rect;
  final double t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final info = id == null ? null : ref.watch(trackInfoProvider(id)).value;
    return TrackCover(
      coverKey: info?.coverKey,
      seed: info?.albumKey?.toString() ?? info?.title ?? '',
      size: rect.width > 120 ? CoverSize.full : CoverSize.thumb,
      dimension: rect.width,
      radius: BorderRadius.circular(8 + 12 * (1 - t)),
    );
  }
}

/// Title and artist; the type size follows the flight.
/// Line heights of the title and artist on Now Playing and in the strip. The
/// flying text is laid out in the rect of the Now Playing title block, so the
/// two must agree or the flight overflows that rect by a few pixels.
const double nowPlayingTitleLineHeight = 1.2;
const double nowPlayingArtistLineHeight = 1.3;

class StripText extends ConsumerWidget {
  const StripText({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final info = id == null ? null : ref.watch(trackInfoProvider(id)).value;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info?.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium?.copyWith(
            fontSize: 16 + 6 * (1 - t),
            fontWeight: FontWeight.w700,
            height: nowPlayingTitleLineHeight,
          ),
        ),
        if (info?.artist != null)
          Text(
            info!.artist!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(
              fontSize: 13 + 2 * (1 - t),
              height: nowPlayingArtistLineHeight,
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Play/pause of the strip: 56 dp with a light fill.
class StripPlay extends StatelessWidget {
  const StripPlay({super.key, required this.rect, required this.t});

  final Rect rect;
  final double t;

  @override
  Widget build(BuildContext context) => PlayPauseButton(
    filled: true,
    iconSize: 28 + 8 * (1 - t),
    size: rect.width,
  );
}

class StripNext extends StatelessWidget {
  const StripNext({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) => NextButton(iconSize: 28 + 4 * (1 - t));
}
