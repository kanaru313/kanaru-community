import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../media/domain/cover_files.dart';
import '../../../../media/domain/track_id.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/play_pause_button.dart';
import '../../../../playback/ui/playback_time_label.dart';
import '../../../../playback/ui/track_cover.dart';
import '../../../../playback/ui/transport_buttons.dart';
import '../now_playing_seek_slot.dart';
import '../track_navigation.dart';
import 'now_playing_auto_hide.dart';

/// Style of the title under the cover.
TextStyle? desktopTitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineSmall
        ?.copyWith(fontSize: 26, fontWeight: FontWeight.bold);

/// Style of the artist and album lines.
TextStyle? desktopLineStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge;

/// First column of the split body: the cover, title with artist and album,
/// the seek slot, and elapsed | previous, play, next | total. It keeps the
/// header shown while the pointer is on it.
///
/// It is a block of fixed height ([SplitMetrics.blockHeight]) centred in the
/// column, so nothing moves when a title wraps or the album arrives late; a
/// window too short even for the smallest cover scales the block down.
class DesktopTrackColumn extends ConsumerWidget {
  const DesktopTrackColumn({
    super.key,
    required this.chrome,
    required this.metrics,
  });

  final AutoHideController chrome;
  final SplitMetrics metrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    if (trackId == null) return const SizedBox.shrink();
    final scaler = MediaQuery.textScalerOf(context);
    final textReserve = splitTextReserve(
      scaler,
      titleStyle: desktopTitleStyle(context),
      lineStyle: desktopLineStyle(context),
    );
    return AutoHidePin(
      controller: chrome,
      child: Padding(
        padding: splitColumnPadding,
        child: Center(
          child: FittedBox(
            child: SizedBox(
              width: metrics.innerWidth,
              height: metrics.blockHeight,
              child: Column(
                children: [
                  _Artwork(trackId: trackId, side: metrics.coverSide),
                  const SizedBox(height: splitCoverGap),
                  SizedBox(
                    height: textReserve,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _TitleBlock(trackId: trackId),
                    ),
                  ),
                  const SizedBox(height: splitSeekGap),
                  const NowPlayingSeekSlot(),
                  const SizedBox(height: splitTransportGap),
                  const _TransportRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends ConsumerWidget {
  const _Artwork({required this.trackId, required this.side});

  final TrackId trackId;
  final double side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(trackInfoProvider(trackId)).value;
    final radius = BorderRadius.circular(32);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TrackCover(
        coverKey: info?.coverKey,
        seed: info?.albumKey?.toString() ?? info?.title ?? '',
        size: CoverSize.full,
        dimension: side,
        radius: radius,
      ),
    );
  }
}

/// Title (two lines at most), then artist and album, each behind a small icon
/// and a link to its library page.
class _TitleBlock extends ConsumerWidget {
  const _TitleBlock({required this.trackId});

  final TrackId trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(trackInfoProvider(trackId)).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          info?.title ?? '',
          maxLines: splitTitleLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: desktopTitleStyle(context),
        ),
        if (info != null && canGoToArtist(info)) ...[
          const SizedBox(height: splitLineGap),
          _Line(
            icon: KIcons.artists,
            text: trackArtistNames(info).join(', '),
            onTap: () => goToArtist(context, info),
          ),
        ],
        if (info != null && info.album != null) ...[
          const SizedBox(height: splitLineGap),
          _Line(
            icon: KIcons.album,
            text: info.album!,
            onTap: canGoToAlbum(info) ? () => goToAlbum(context, info) : null,
          ),
        ],
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, required this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: KSpace.x2,
      children: [
        Icon(icon, size: splitLineIconSize, color: scheme.onSurfaceVariant),
        Flexible(
          child: InkWell(
            borderRadius: KRadius.xs,
            onTap: onTap,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: desktopLineStyle(context)
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

/// Elapsed at the start, the transport buttons in the middle, total at the end.
class _TransportRow extends StatelessWidget {
  const _TransportRow();

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Row(
        children: [
          Expanded(
            // A large text scale shrinks the label, not the buttons.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: PlaybackTimeLabel(),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 20,
            children: [
              PreviousButton(iconSize: 28),
              PlayPauseButton(iconSize: 36),
              NextButton(iconSize: 28),
            ],
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: PlaybackTimeLabel(total: true),
            ),
          ),
        ],
      ),
    );
  }
}
