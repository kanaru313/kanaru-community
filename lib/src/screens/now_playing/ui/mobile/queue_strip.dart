import 'dart:ui' show lerpDouble;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../media/domain/cover_files.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/flight_source.dart';
import '../../../../playback/ui/play_pause_button.dart';
import '../../../../playback/ui/track_cover.dart';
import '../../../../playback/ui/transport_buttons.dart';
import 'now_playing_text_styles.dart';

const _stripCoverRadius = BorderRadius.all(Radius.circular(8));
const _nowPlayingCoverRadius = BorderRadius.all(Radius.circular(20));

/// The cover of the strip (and of the flight): grows from the source's size
/// to 72, its corners follow.
class StripCover extends ConsumerWidget {
  const StripCover({super.key, required this.rect, required this.t, this.look});

  final Rect rect;
  final double t;

  /// Look of the surface the flight starts from; null starts like the Now
  /// Playing cover.
  final FlightLook? look;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final info = id == null ? null : ref.watch(trackInfoProvider(id)).value;
    return TrackCover(
      coverKey: info?.coverKey,
      seed: info?.coverSeed ?? '',
      size: rect.width > 120 ? CoverSize.full : CoverSize.thumb,
      dimension: rect.width,
      radius:
          BorderRadius.lerp(
            _stripCoverRadius,
            look?.coverRadius ?? _nowPlayingCoverRadius,
            1 - t,
          ) ??
          _stripCoverRadius,
    );
  }
}

/// Title and artist; the type size follows the flight.
/// Line heights of the title and artist on Now Playing and in the strip. The
/// flying text is laid out in the rect of the Now Playing title block, so the
/// two must agree or the flight overflows that rect by a few pixels.
const double nowPlayingTitleLineHeight = 1.2;
const double nowPlayingArtistLineHeight = 1.3;

/// Style between the strip's ([strip]) and the source's ([from]) at [amount]
/// (0 = strip, 1 = source), line height included.
TextStyle? _lerpFrom(TextStyle? strip, TextStyle from, double amount) =>
    TextStyle.lerp(
      strip?.copyWith(height: strip.height ?? from.height),
      from,
      amount,
    );

class StripText extends ConsumerWidget {
  const StripText({super.key, required this.t, this.look});

  final double t;

  /// Look of the surface the flight starts from; null starts like the Now
  /// Playing text.
  final FlightLook? look;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final info = id == null ? null : ref.watch(trackInfoProvider(id)).value;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final lookTitle = look?.title;
    final lookArtist = look?.artist;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info?.title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // t = 0 is the Now Playing title, t = 1 the strip title.
          style: lookTitle != null
              ? _lerpFrom(stripTitleStyle(text), lookTitle, 1 - t)
              : TextStyle.lerp(
                  stripTitleStyle(text),
                  coverTitleStyle(text),
                  1 - t,
                )?.copyWith(height: nowPlayingTitleLineHeight),
        ),
        if (info?.artist != null)
          Text(
            info!.artist!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (lookArtist != null
                        ? _lerpFrom(stripArtistStyle(text), lookArtist, 1 - t)
                        : TextStyle.lerp(
                            stripArtistStyle(text),
                            coverArtistStyle(text),
                            1 - t,
                          )?.copyWith(height: nowPlayingArtistLineHeight))
                    ?.copyWith(color: scheme.onSurfaceVariant),
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
    iconSize: lerpDouble(KIconSize.lg, KIconSize.xl, 1 - t),
    size: rect.width,
  );
}

class StripNext extends StatelessWidget {
  const StripNext({super.key, required this.t});

  final double t;

  @override
  Widget build(BuildContext context) =>
      NextButton(iconSize: lerpDouble(KIconSize.md, KIconSize.lg, 1 - t));
}
