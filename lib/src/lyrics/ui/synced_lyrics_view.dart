import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/track_id.dart';
import '../../playback/state/playback_providers.dart';
import '../domain/lyrics.dart';
import '../domain/lyrics_display_prefs.dart';
import '../state/playing_lyrics_providers.dart';
import '../state/translation/translation_layout_provider.dart';
import 'lyrics_line.dart';
import 'synced_lyrics_scroll.dart';
import 'synced_lyrics_translation.dart';
import 'translation/line_translation.dart';
import 'translation/shown_translation.dart';

final _log = Logger('lyrics_view');

/// Share of the height the top and bottom edges fade over.
const double _edgeFade = 0.12;

/// Synced lyrics that follow playback: the current line is highlighted and
/// kept at [lyricsAnchor]; a scroll by hand stops that and shows the round
/// button "Về dòng đang hát"; pressing a line seeks to it.
///
/// A position tick costs nothing here: [playingLyricsLineProvider] notifies
/// only when the line changes, and that moves one shared index, so two lines
/// rebuild and nothing else. Lines are built lazily, only near the viewport
/// (a file may hold thousands); [SyncedLyricsScroll] reaches a line that is
/// not built yet. Only this view's own scroll moves, never an enclosing one. The view is built for one [Lyrics] of one queue entry:
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
    this.trackId,
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

  /// The track whose translation the lines show; null shows none. Watching
  /// it is what asks for the translation, so it is only watched while
  /// translation is on.
  final TrackId? trackId;

  @override
  ConsumerState<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends ConsumerState<SyncedLyricsView>
    with SyncedLyricsScroll<SyncedLyricsView> {
  /// The current line, shared by every built line.
  final ValueNotifier<int> _active = ValueNotifier(-1);

  /// The elements of the lines built now (near the viewport), by index.
  final Map<int, BuildContext> _built = {};

  @override
  Duration? get autoReturnDelay => widget.autoReturn.delay;

  @override
  int get lineCount => widget.lyrics.lines.length;

  @override
  BuildContext? builtLine(int index) => _built[index];

  @override
  void initState() {
    super.initState();
    _setIndex(ref.read(playingLyricsLineProvider));
    revealAfterLayout();
  }

  @override
  void didUpdateWidget(SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewportHeight != widget.viewportHeight) {
      onViewportHeight(widget.viewportHeight);
    }
    // Sizes changed (font scale setting): lines may have grown or shrunk,
    // the measured heights of lines not on screen are stale.
    if (oldWidget.lineSize != widget.lineSize) {
      if (listController.isAttached) listController.invalidateAllExtents();
      revealAfterLayout();
    }
  }

  @override
  void dispose() {
    disposeScroll();
    _active.dispose();
    super.dispose();
  }

  bool _reanchoring = false;

  /// A translation arrived, changed or went away: lines changed height, the
  /// measured heights of those not on screen are stale and the current line
  /// may have left the anchor. Once per frame, however many lines changed;
  /// never animates (the text size does not change, only what is under it).
  void _reanchor() {
    if (_reanchoring) return;
    _reanchoring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reanchoring = false;
      if (!mounted) return;
      if (listController.isAttached) listController.invalidateAllExtents();
      revealAfterLayout();
    });
  }

  void _setIndex(int index) {
    if (index >= lineCount) index = lineCount - 1;
    lineIndex = index;
    _active.value = index;
  }

  void _onLineChanged(int index) {
    if (index == lineIndex) return;
    _setIndex(index);
    if (paused) {
      updateDirection();
    } else {
      reveal(animate: true);
    }
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

  /// Height of a one-row line before it is measured: the text row plus the
  /// line's own padding; set in build, read by the list during layout.
  /// Wrapped lines are measured when they lay out.
  double _estimatedLine = 0;

  /// Height of the credit line after the lyrics before it is measured.
  static const double _estimatedCredit = KSpace.x4 + 16;

  double _estimateExtent(int? index, double crossAxisExtent) =>
      index == lineCount ? _estimatedCredit : _estimatedLine;

  Widget _line(int i, TrackId? id, TranslationLayout? layout) {
    Widget make(LineTranslation? translation) => LyricsLine(
      index: i,
      line: widget.lyrics.lines[i],
      active: _active,
      onTap: () => _seek(i),
      size: widget.lineSize,
      dim: widget.dim,
      align: widget.align,
      translation: translation,
    );
    return translatedLine(
      trackId: id,
      layout: layout,
      line: widget.lyrics.lines[i],
      make: make,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.lyrics;
    ref.listen<int>(playingLyricsLineProvider, (_, i) => _onLineChanged(i));
    final height = widget.viewportHeight;
    final id = widget.trackId;
    final layout = id == null ? null : ref.watch(translationLayoutProvider(id));
    if (id != null && layout != null) {
      watchTranslationHeights(ref, id, _reanchor);
      ref.listen(translationLayoutProvider(id), (_, _) => _reanchor());
    }
    final scaler = MediaQuery.textScalerOf(context);
    _estimatedLine =
        scaler.scale(widget.lineSize) * 1.3 +
        2 * KSpace.x2 +
        KSpace.x1 +
        (layout == null ? 0 : scaler.scale(widget.lineSize * 0.62) * 1.3);
    final side = (widget.sidePadding - lyricsLineInset).clamp(
      0.0,
      double.infinity,
    );
    return TranslationPresence(
      trackId: id,
      active: layout != null,
      child: Material(
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
                      child: SuperListView.builder(
                        controller: scroll,
                        listController: listController,
                        extentEstimation: _estimateExtent,
                        // Each line has its own repaint boundary, and nothing
                        // off screen is worth keeping.
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: false,
                        // Room above and below so the first and last lines can
                        // reach the anchor.
                        padding: EdgeInsets.fromLTRB(
                          side,
                          height * lyricsAnchor,
                          side,
                          height * (1 - lyricsAnchor),
                        ),
                        // With translation on, one more item: the credit line.
                        itemCount:
                            lyrics.lines.length + (layout == null ? 0 : 1),
                        itemBuilder: (context, i) {
                          if (i == lyrics.lines.length) {
                            return translationCreditItem(
                              id!,
                              centered: widget.align == LyricsAlign.center,
                            );
                          }
                          return _BuiltLine(
                            index: i,
                            built: _built,
                            child: _line(i, id, layout),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: KSpace.x4,
              bottom: KSpace.x4,
              child: ValueListenableBuilder<KLocateSide>(
                valueListenable: locateSide,
                builder: (context, side, _) => KLocateButton(
                  side: side,
                  tooltip: AppLocalizations.of(context).lyricsBackToLine,
                  onPressed: backToLine,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Records its element in [built] under [index] while it is mounted, so the
/// view finds the render object of a built line without a key per line.
class _BuiltLine extends StatefulWidget {
  const _BuiltLine({
    required this.index,
    required this.built,
    required this.child,
  });

  final int index;
  final Map<int, BuildContext> built;
  final Widget child;

  @override
  State<_BuiltLine> createState() => _BuiltLineState();
}

class _BuiltLineState extends State<_BuiltLine> {
  @override
  void initState() {
    super.initState();
    widget.built[widget.index] = context;
  }

  @override
  void didUpdateWidget(_BuiltLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.built != widget.built) {
      _forget(oldWidget);
      widget.built[widget.index] = context;
    }
  }

  @override
  void dispose() {
    _forget(widget);
    super.dispose();
  }

  void _forget(_BuiltLine of) {
    if (identical(of.built[of.index], context)) of.built.remove(of.index);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
