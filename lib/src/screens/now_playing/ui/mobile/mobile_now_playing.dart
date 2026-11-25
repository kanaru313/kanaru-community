import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../../lyrics/ui/lyrics_card.dart';
import '../../../../media/domain/cover_files.dart';
import '../../../../media/domain/track_id.dart';
import '../../../../playback/domain/repeat_mode.dart';
import '../../../../playback/state/playing_cover_colors.dart';
import '../../../../playback/state/playback_settings_providers.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/ui/flight_source.dart';
import '../../../../playback/ui/spring_to_rest.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/track_cover.dart';
import '../favorite_button.dart';
import '../now_playing_song_menu.dart';
import '../now_playing_seek_slot.dart';
import 'cover_swiper.dart';
import 'now_playing_button_row.dart';
import 'now_playing_controls.dart';
import 'now_playing_header.dart';
import 'queue_strip.dart'
    show nowPlayingArtistLineHeight, nowPlayingTitleLineHeight;
import 'track_info_card.dart';
import 'now_playing_text_styles.dart';

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
    this.onOpenLyrics,
    required this.flight,
  });

  final VoidCallback onClose;

  /// The Queue button; null leaves it inert.
  final VoidCallback? onQueue;

  /// The lyrics card: opens the lyrics screen; null leaves it inert.
  final VoidCallback? onOpenLyrics;

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
    final infoState = trackId == null
        ? null
        : ref.watch(trackInfoProvider(trackId));
    final info = infoState?.value;
    // Loading only until the first value or error: a track whose row is gone
    // (null) or whose read failed shows empty lines, not a skeleton forever.
    final infoLoading =
        infoState != null && !infoState.hasValue && !infoState.hasError;
    final cover = ref.watch(playingCoverColorsProvider);
    return CoverTintBackground(
      palette: cover.palette,
      loading: cover.isPending,
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
                  onMore: () => unawaited(
                    openNowPlayingSongMenu(
                      context,
                      closeNowPlaying: widget.onClose,
                    ),
                  ),
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
                              _TitleRow(
                                flight: widget.flight,
                                title: info?.title ?? '',
                                artist: info?.artist,
                                trackId: trackId,
                              ),
                              const SizedBox(height: KSpace.x2),
                              const NowPlayingSeekSlot(),
                              NowPlayingControls(flight: widget.flight),
                              const SizedBox(height: KSpace.x5),
                              NowPlayingButtonRow(onQueue: widget.onQueue),
                              const SizedBox(height: KSpace.x5),
                              LyricsCard(onOpen: widget.onOpenLyrics),
                              const SizedBox(height: KSpace.x3),
                              TrackInfoCard(info: info, loading: infoLoading),
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
    final repeat = ref.watch(repeatSettingProvider);
    final wraps = repeat.wrapsQueue;
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    final loaded = trackId == null
        ? null
        : ref.watch(trackInfoProvider(trackId)).value;
    return CoverSwiper(
      entryId: entryId,
      // Previous wraps to the last entry only in plain repeat all.
      hasPrevious:
          index != null &&
          (index > 0 || (repeat == RepeatMode.all && (length ?? 0) > 1)),
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
            seed: loaded?.coverSeed ?? '',
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
    required this.flight,
    required this.title,
    required this.artist,
    required this.trackId,
  });

  /// The text flies to the queue strip from here; the ♥ hides with it.
  final FlightSource flight;
  final String title;
  final String? artist;
  final TrackId? trackId;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final titleStyle = coverTitleStyle(text)
        ?.copyWith(height: nowPlayingTitleLineHeight);
    final artistStyle = coverArtistStyle(text)?.copyWith(
      height: nowPlayingArtistLineHeight,
      color: scheme.onSurfaceVariant,
    );
    // Always two lines high at the current text scale: a song without an
    // artist keeps an empty second line, and the ♥ never sets the height, so
    // the seek bar below never moves between songs.
    final titleExtent = _lineExtent(scaler, titleStyle);
    final artistExtent = _lineExtent(scaler, artistStyle);
    final a = artist;
    return SizedBox(
      height: titleExtent + artistExtent,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              // The flight's text piece covers only the lines drawn (the
              // title, plus the artist when there is one): the flying text
              // centres what it draws in this rect, so it starts and ends
              // exactly on the title. The empty artist slot stays outside.
              child: FlightPieceHost(
                source: flight,
                piece: FlightPiece.text,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OneLine(
                      text: title,
                      style: titleStyle,
                      height: titleExtent,
                    ),
                    if (a != null)
                      _OneLine(
                        text: a,
                        style: artistStyle,
                        height: artistExtent,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (trackId != null)
            // Hidden with the text while the queue sheet flies it, as before.
            ValueListenableBuilder<bool>(
              valueListenable: flight.hidden,
              builder: (context, hidden, child) =>
                  Opacity(opacity: hidden ? 0 : 1, child: child),
              child: FavoriteButton(trackId: trackId!, iconSize: KIconSize.lg),
            ),
        ],
      ),
    );
  }

  /// Height of one line of [style] (its explicit line height) under [scaler].
  static double _lineExtent(TextScaler scaler, TextStyle? style) =>
      scaler.scale(style?.fontSize ?? _fallbackFontSize) * (style?.height ?? 1);

  static const double _fallbackFontSize = 14;
}

/// One line of text, ellipsized, in a box of exactly [height].
class _OneLine extends StatelessWidget {
  const _OneLine({
    required this.text,
    required this.style,
    required this.height,
  });

  final String text;
  final TextStyle? style;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    ),
  );
}
