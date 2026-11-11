import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../../media/domain/cover_files.dart';
import '../../../../media/domain/track_id.dart';
import '../../../../playback/state/cover_providers.dart';
import '../../../../playback/state/playback_settings_providers.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/ui/flight_source.dart';
import '../../../../playback/ui/spring_to_rest.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/track_cover.dart';
import '../favorite_button.dart';
import '../now_playing_seek_slot.dart';
import 'cover_swiper.dart';
import 'lyrics_card_placeholder.dart';
import 'more_sheet.dart';
import 'now_playing_button_row.dart';
import 'now_playing_controls.dart';
import 'now_playing_header.dart';
import 'queue_strip.dart'
    show nowPlayingArtistLineHeight, nowPlayingTitleLineHeight;
import 'track_info_card.dart';

/// Pull of the header, in dp, past which letting go closes the page.
const double nowPlayingCloseDistance = 120;

/// The mobile Now Playing page: header, cover, title, seek, controls, button
/// row, lyrics card and info card, on the cover's tint. It is one scrolling
/// column; it never watches the whole now-playing value, only narrow selects.
class MobileNowPlaying extends ConsumerStatefulWidget {
  const MobileNowPlaying({
    super.key,
    required this.onClose,
    this.onQueue,
    required this.flight,
  });

  final VoidCallback onClose;

  /// The Queue button; null leaves it inert.
  final VoidCallback? onQueue;

  /// The pieces that fly to the queue strip.
  final FlightSource flight;

  @override
  ConsumerState<MobileNowPlaying> createState() => _MobileNowPlayingState();
}

class _MobileNowPlayingState extends ConsumerState<MobileNowPlaying>
    with SingleTickerProviderStateMixin {
  // Unbounded: the spring that brings an unfinished pull back may overshoot.
  late final AnimationController _pull = AnimationController.unbounded(
    vsync: this,
  );

  @override
  void dispose() {
    _pull.dispose();
    super.dispose();
  }

  void _pullUpdate(DragUpdateDetails d) {
    _pull.value = (_pull.value + d.delta.dy).clamp(0, double.infinity);
  }

  void _pullEnd(DragEndDetails _) {
    if (_pull.value > nowPlayingCloseDistance) {
      widget.onClose();
    } else {
      animateSpringTo(context, _pull, 0, KSpring.snappy);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    final info = trackId == null
        ? null
        : ref.watch(trackInfoProvider(trackId)).value;
    final colors = info?.coverKey == null
        ? null
        : ref.watch(coverColorsProvider(info!.coverKey!)).value;
    Color? tint(int i) => colors == null || colors.palette.length <= i
        ? null
        : Color(colors.palette[i]);
    return CoverTintBackground(
      first: tint(0),
      second: tint(1) ?? tint(0),
      child: AnimatedBuilder(
        animation: _pull,
        builder: (context, child) =>
            Transform.translate(offset: Offset(0, _pull.value), child: child),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                NowPlayingHeader(
                  onClose: widget.onClose,
                  onMore: () => showNowPlayingMoreSheet(context),
                  dragHandle: (child) => GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    dragStartBehavior: DragStartBehavior.down,
                    onVerticalDragUpdate: _pullUpdate,
                    onVerticalDragEnd: _pullEnd,
                    child: child,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: KSpace.x2),
                        // Full width: the cover sizes itself from it.
                        _Cover(flight: widget.flight),
                        const SizedBox(height: KSpace.x6),
                        _Padded(
                          child: Column(
                            children: [
                              FlightPieceHost(
                                source: widget.flight,
                                piece: FlightPiece.text,
                                child: _TitleRow(
                                  title: info?.title ?? '',
                                  artist: info?.artist,
                                  trackId: trackId,
                                ),
                              ),
                              const SizedBox(height: KSpace.x2),
                              const NowPlayingSeekSlot(),
                              NowPlayingControls(flight: widget.flight),
                              const SizedBox(height: KSpace.x5),
                              NowPlayingButtonRow(onQueue: widget.onQueue),
                              const SizedBox(height: KSpace.x5),
                              const LyricsCardPlaceholder(),
                              const SizedBox(height: KSpace.x3),
                              TrackInfoCard(info: info),
                              const SizedBox(height: KSpace.x6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: KSpace.x6),
    child: child,
  );
}

class _Cover extends ConsumerWidget {
  const _Cover({required this.flight});

  final FlightSource flight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(
      nowPlayingProvider.select(
        (n) => (n.value?.entryId, n.value?.index, n.value?.length),
      ),
    );
    final (entryId, index, length) = place;
    // Both repeat-all modes wrap the last entry to the first, like Next.
    final wraps = ref.watch(repeatSettingProvider).wrapsQueue;
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    final loaded = trackId == null
        ? null
        : ref.watch(trackInfoProvider(trackId)).value;
    return CoverSwiper(
      entryId: entryId,
      hasPrevious: (index ?? 0) > 0,
      hasNext:
          index != null &&
          ((wraps && (length ?? 0) > 1) || index < (length ?? 0) - 1),
      onPrevious: () => ref.read(playerControllerProvider).previous(),
      onNext: () => ref.read(playerControllerProvider).next(),
      child: NowPlayingCoverBox(
        builder: (context, side) => FlightPieceHost(
          source: flight,
          piece: FlightPiece.cover,
          child: TrackCover(
            coverKey: loaded?.coverKey,
            seed: loaded?.albumKey?.toString() ?? loaded?.title ?? '',
            size: CoverSize.full,
            dimension: side,
          ),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.artist,
    required this.trackId,
  });

  final String title;
  final String? artist;
  final TrackId? trackId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: nowPlayingTitleLineHeight,
                ),
              ),
              if (artist != null)
                Text(
                  artist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: nowPlayingArtistLineHeight,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (trackId != null) FavoriteButton(trackId: trackId!),
      ],
    );
  }
}
