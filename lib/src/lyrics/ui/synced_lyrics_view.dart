import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/state/playback_providers.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import '../state/playing_lyrics_providers.dart';
import 'back_to_line_button.dart';
import 'lyrics_line.dart';
import 'synced_lyrics_scroll.dart';

final _log = Logger('lyrics_view');

/// Share of the height the top and bottom edges fade over.
const double _edgeFade = 0.12;

/// Synced lyrics that follow playback: the current line is highlighted and
/// kept at [lyricsAnchor]; a scroll by hand stops that and shows the pill
/// "Về dòng đang hát"; pressing a line seeks to it.
///
/// A position tick costs nothing here: [playingLyricsLineProvider] notifies
/// only when the line changes, and that flips two per-line notifiers, so two
/// lines rebuild and nothing else. Every line is built (lyrics are capped),
/// so any line can be scrolled to. Only this view's own scroll moves, never
/// an enclosing one. The view is built for one [Lyrics] of one queue entry:
/// the owner keys it by them.
class SyncedLyricsView extends ConsumerStatefulWidget {
  const SyncedLyricsView({
    super.key,
    required this.lyrics,
    required this.lineSize,
    required this.sidePadding,
    required this.viewportHeight,
    required this.dim,
    required this.align,
    required this.autoReturn,
  });

  final Lyrics lyrics;

  /// Font size of a line, with the user's font scale applied.
  final double lineSize;
  final double sidePadding;

  /// Height of the area, for the room above and below the lines.
  final double viewportHeight;
  final LyricsDim dim;
  final LyricsAlign align;
  final LyricsAutoReturn autoReturn;

  @override
  ConsumerState<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends ConsumerState<SyncedLyricsView>
    with SyncedLyricsScroll<SyncedLyricsView> {
  late final List<ValueNotifier<bool>> _current;

  @override
  Duration? get autoReturnDelay => widget.autoReturn.delay;

  @override
  void initState() {
    super.initState();
    final count = widget.lyrics.lines.length;
    lineKeys = List.generate(count, (_) => GlobalKey());
    _current = List.generate(count, (_) => ValueNotifier(false));
    _setIndex(ref.read(playingLyricsLineProvider));
    revealAfterLayout();
  }

  @override
  void didUpdateWidget(SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportHeight != widget.viewportHeight) {
      onViewportHeight(widget.viewportHeight);
    }
    // Sizes changed (font scale setting): lines may have grown or shrunk.
    if (oldWidget.lineSize != widget.lineSize) revealAfterLayout();
  }

  @override
  void dispose() {
    disposeScroll();
    for (final notifier in _current) {
      notifier.dispose();
    }
    super.dispose();
  }

  void _setIndex(int index) {
    if (index >= _current.length) index = _current.length - 1;
    if (lineIndex >= 0) _current[lineIndex].value = false;
    lineIndex = index;
    if (index >= 0) _current[index].value = true;
  }

  void _onLineChanged(int index) {
    if (index == lineIndex) return;
    _setIndex(index);
    if (!paused) reveal(animate: true);
  }

  void _seek(int index) {
    // Pressing a line gives the view back to the song at once; the seek
    // lands a moment later and the provider then agrees.
    _setIndex(index);
    backToLine();
    unawaited(
      ref
          .read(playerControllerProvider)
          .seek(widget.lyrics.lines[index].time)
          .catchError((Object error, StackTrace stack) {
            _log.warning('seek from a lyric line failed', error, stack);
            // The song did not move: highlight the line it is really on.
            if (mounted) _setIndex(ref.read(playingLyricsLineProvider));
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.lyrics;
    ref.listen<int>(playingLyricsLineProvider, (_, i) => _onLineChanged(i));
    final height = widget.viewportHeight;
    final side = (widget.sidePadding - lyricsLineInset).clamp(
      0.0,
      double.infinity,
    );
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerSignal: onPointerInput,
              onPointerPanZoomUpdate: onPointerInput,
              child: NotificationListener<ScrollUpdateNotification>(
                onNotification: onScrollUpdate,
                // Desktop platforms give every scrollable a scrollbar that
                // fades in and out on each scroll; auto-scroll would flash it
                // at every line. Wheel, touch and trackpad still work.
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xFF000000),
                        Color(0xFF000000),
                        Color(0x00000000),
                      ],
                      stops: [0, _edgeFade, 1 - _edgeFade, 1],
                    ).createShader(rect),
                    child: SingleChildScrollView(
                      controller: scroll,
                      // Room above and below so the first and last lines can
                      // reach the anchor.
                      padding: EdgeInsets.fromLTRB(
                        side,
                        height * lyricsAnchor,
                        side,
                        height * (1 - lyricsAnchor),
                      ),
                      // One cached layer for the column: a scroll moves it
                      // instead of walking every line again.
                      child: RepaintBoundary(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < lyrics.lines.length; i++)
                              LyricsLine(
                                key: lineKeys[i],
                                line: lyrics.lines[i],
                                current: _current[i],
                                onTap: () => _seek(i),
                                size: widget.lineSize,
                                dim: widget.dim,
                                align: widget.align,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: KSpace.x4,
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: showBack,
                builder: (context, visible, _) =>
                    BackToLineButton(visible: visible, onPressed: backToLine),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
