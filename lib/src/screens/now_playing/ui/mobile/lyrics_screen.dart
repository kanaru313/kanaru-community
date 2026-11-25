import 'dart:async';

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../lyrics/state/playing_lyrics_providers.dart';
import '../../../../lyrics/ui/lyrics_body.dart';
import '../../../../lyrics/ui/lyrics_for_track_modal.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/playing_cover_colors.dart';
import '../../../../playback/ui/play_pause_button.dart';
import '../../../../playback/ui/playback_time_label.dart';
import '../../../../playback/ui/spring_to_rest.dart';
import '../../../../playback/ui/transport_buttons.dart';
import '../now_playing_seek_slot.dart';
import 'lyrics_screen_header.dart';
import 'lyrics_screen_route.dart';

/// Pull of the screen, in dp, past which letting go closes it.
const double lyricsScreenCloseDistance = 100;

/// The mobile lyrics screen: header, the lyrics, and a footer with the seek
/// bar and the transport buttons, on the cover's tint. It closes with ⌄,
/// Back, a pull down on the header or footer, or a pull down at the top of
/// the lyrics; scrolling the lyrics never closes it. With no track left it
/// closes itself.
class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key, required this.route});

  final LyricsScreenRoute route;

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen>
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

  void _close() => closeLyricsScreen(widget.route);

  void _openChoice() {
    final id = ref.read(playingLyricsProvider).trackId;
    if (id == null) return;
    unawaited(showLyricsForTrack(context, id, followsPlaying: true));
  }

  void _pullBy(double dy) {
    _pull.value = (_pull.value + dy).clamp(0, double.infinity);
  }

  void _pullEnd() {
    if (_pull.value > lyricsScreenCloseDistance) {
      _close();
    } else {
      animateSpringTo(context, _pull, 0, KSpring.gentle);
    }
  }

  /// A drag past the top of the lyrics (not a scroll) pulls the screen.
  bool _onBodyScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        n.dragDetails != null) {
      _pullBy(-n.overscroll);
    } else if (n is ScrollUpdateNotification &&
        n.dragDetails != null &&
        _pull.value > 0) {
      // Dragging back up gives the pull back before the text scrolls.
      _pullBy(-(n.scrollDelta ?? 0));
    } else if (n is ScrollEndNotification && _pull.value > 0) {
      _pullEnd();
    }
    return false;
  }

  Widget _handle(Widget child) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    dragStartBehavior: DragStartBehavior.down,
    onVerticalDragUpdate: (d) => _pullBy(d.delta.dy),
    onVerticalDragEnd: (_) => _pullEnd(),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    // No track left (the only entry was removed): nothing to show.
    ref.listen(
      nowPlayingProvider.select(
        (n) => n.hasValue ? n.requireValue.hasTrack : null,
      ),
      (_, hasTrack) {
        if (hasTrack == false) _close();
      },
    );
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
                _handle(LyricsScreenHeader(onClose: _close)),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onBodyScroll,
                    child: LyricsBody(
                      surface: KLyricsSurface.screen,
                      onOpenChoice: _openChoice,
                    ),
                  ),
                ),
                _handle(const _Footer()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Seek bar, then `elapsed · Previous · Play/Pause (64) · Next · total`.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(KSpace.x6, KSpace.x2, KSpace.x6, KSpace.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NowPlayingSeekSlot(),
          Row(
            children: [
              SizedBox(
                width: KSpace.x9,
                child: PlaybackTimeLabel(
                  textAlign: TextAlign.start,
                  followScrub: true,
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: KSpace.x3,
                    children: [
                      PreviousButton(iconSize: KIconSize.lg),
                      PlayPauseButton(
                        filled: true,
                        iconSize: KIconSize.lg,
                        // The 64 dp filled disc is a size of its own.
                        size: 64,
                      ),
                      NextButton(iconSize: KIconSize.lg),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: KSpace.x9,
                child: PlaybackTimeLabel(total: true, textAlign: TextAlign.end),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
