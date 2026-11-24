import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Where the current line sits in the view: 40 % down from the top.
const double lyricsAnchor = 0.4;

/// Lines short of the target a far glide jumps to before gliding the rest:
/// close enough to be built, far enough to read as movement.
const int _approachLines = 3;

/// The scrolling of the synced lyrics view: keeping the current line at
/// [lyricsAnchor] and telling the user's scrolling from the view's own. The
/// state that mixes it in sets [lineIndex], answers [lineCount],
/// [builtLine] and [autoReturnDelay], and gives [listController] to its lazy
/// list.
///
/// Only the lines near the viewport exist. A line that is built is revealed
/// through its render object, so the glide is exact; one that is not (a seek
/// or a return from far away) is reached through [listController], which
/// jumps on estimated heights and corrects them as the lines lay out, without
/// building the lines in between.
///
/// Only [scroll] moves, never an enclosing scrollable. A scroll the view did
/// not start (drag, wheel, trackpad, keyboard) stops auto-scroll and turns
/// [paused] on; the line comes back through [backToLine] (the back button) or,
/// when [autoReturnDelay] is set, by itself after that long without input.
mixin SyncedLyricsScroll<T extends StatefulWidget> on State<T> {
  final scroll = ScrollController();
  final listController = ListController();

  /// The current line, -1 before the first.
  int lineIndex = -1;

  /// True while the user has taken over: the back button is shown and line
  /// changes do not scroll.
  bool _paused = false;

  /// Which way the current line lies from the anchor while the user has the
  /// scroll (the back button's arrow); none otherwise. Notifies only on a
  /// change, so a scroll does not rebuild anything unless the arrow flips.
  final ValueNotifier<KLocateSide> locateSide = ValueNotifier(KLocateSide.none);

  /// Set while this view moves its own scroll position, so that move is not
  /// taken for the user's.
  bool scrollingItself = false;

  /// Counts this view's own scrolls: an animation replaced by a newer one
  /// completes early and must not clear [scrollingItself] for the newer.
  int _scrollGeneration = 0;
  Timer? _autoReturn;
  double? _viewportHeight;

  /// Number of lines in the list.
  int get lineCount;

  /// The element of line [index] when it is built (near the viewport), else
  /// null.
  BuildContext? builtLine(int index);

  /// Seconds without input before the view returns by itself; null = never.
  Duration? get autoReturnDelay;

  bool get paused => _paused;

  int get _target => lineIndex < 0 ? 0 : lineIndex;

  /// Cancels the timer and the controllers; call from `dispose`.
  void disposeScroll() {
    _autoReturn?.cancel();
    locateSide.dispose();
    listController.dispose();
    scroll.dispose();
  }

  RenderObject? _renderOf(int index) {
    final object = builtLine(index)?.findRenderObject();
    return object != null && object.attached ? object : null;
  }

  /// Scrolls so the current line (the first before any) sits at the anchor.
  void reveal({required bool animate}) => _reveal(animate: animate);

  void _reveal({required bool animate, bool approached = false}) {
    if (!scroll.hasClients || lineCount == 0 || !listController.isAttached) {
      return;
    }
    final index = _target;
    final instant = !animate || MediaQuery.disableAnimationsOf(context);
    final object = _renderOf(index);
    if (object == null) {
      _revealUnbuilt(index, instant: instant || approached);
      return;
    }
    final position = scroll.position;
    final target = RenderAbstractViewport.of(object)
        .getOffsetToReveal(object, lyricsAnchor)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;
    scrollingItself = true;
    final generation = ++_scrollGeneration;
    if (instant) {
      scroll.jumpTo(target);
      scrollingItself = false;
      return;
    }
    scroll
        .animateTo(target, duration: KMotion.normal, curve: KMotion.emphasized)
        .whenComplete(() {
          if (generation != _scrollGeneration) return;
          scrollingItself = false;
        });
  }

  /// The line is far from the viewport. Instant: jump onto it. Otherwise jump
  /// a few lines short of it, on the side the view comes from, and glide the
  /// rest on the next frame once the line is built.
  void _revealUnbuilt(int index, {required bool instant}) {
    var jumpTo = index;
    if (!instant) {
      final range = listController.visibleRange;
      final fromBelow = range != null && index < range.$1;
      jumpTo = (fromBelow ? index + _approachLines : index - _approachLines)
          .clamp(0, lineCount - 1);
    }
    final generation = ++_scrollGeneration;
    scrollingItself = true;
    listController.jumpToItem(
      index: jumpTo,
      scrollController: scroll,
      alignment: lyricsAnchor,
    );
    // The list corrects its estimates in the next layout and may move the
    // position again: that is still this view's own scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _scrollGeneration) return;
      scrollingItself = false;
      if (!instant && !paused) _reveal(animate: true, approached: true);
    });
  }

  /// Puts the current line back at the anchor after this frame, without a
  /// glide, unless the user has taken over.
  void revealAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !paused) reveal(animate: false);
    });
  }

  /// Sets [locateSide] from where the current line would sit at the anchor
  /// against the scroll position now; cheap, called on scroll and line change.
  /// A line that is not built lies beyond the visible range, so its side
  /// comes from its index alone.
  void updateDirection() {
    if (!paused) {
      locateSide.value = KLocateSide.none;
      return;
    }
    if (!scroll.hasClients || lineCount == 0) return;
    final index = _target;
    final object = _renderOf(index);
    if (object == null) {
      final range = listController.isAttached
          ? listController.visibleRange
          : null;
      if (range == null) return;
      if (index < range.$1) locateSide.value = KLocateSide.above;
      if (index > range.$2) locateSide.value = KLocateSide.below;
      return;
    }
    final target = RenderAbstractViewport.of(object)
        .getOffsetToReveal(object, lyricsAnchor)
        .offset;
    locateSide.value = target >= scroll.position.pixels
        ? KLocateSide.below
        : KLocateSide.above;
  }

  /// The user took over: stop auto-scroll, show the back button, start the
  /// auto-return timer when the setting asks for one.
  void takeOver() {
    _paused = true;
    updateDirection();
    _autoReturn?.cancel();
    final delay = autoReturnDelay;
    _autoReturn = delay == null
        ? null
        : Timer(delay, () {
            _autoReturn = null;
            if (mounted) backToLine();
          });
  }

  /// Scroll listener: a scroll the view did not start itself is the user's.
  bool onScrollUpdate(ScrollUpdateNotification notification) {
    final byUser = notification.dragDetails != null || !scrollingItself;
    if (notification.depth == 0 && byUser) takeOver();
    if (notification.depth == 0 && paused) updateDirection();
    return false;
  }

  /// Wheel and trackpad input, seen before the scrollable applies it (it
  /// would otherwise find a glide of ours still running).
  void onPointerInput(PointerEvent event) {
    if (event is! PointerScrollEvent && event is! PointerPanZoomUpdateEvent) {
      return;
    }
    // A glide of our own would fight the wheel: stop it first. (A drag
    // replaces the glide by itself.)
    if (scrollingItself && scroll.hasClients) {
      _scrollGeneration++;
      scrollingItself = false;
      scroll.position.hold(() {}).cancel();
    }
    takeOver();
  }

  /// Gives the view back to the song: glides to the current line.
  void backToLine() {
    _autoReturn?.cancel();
    _autoReturn = null;
    _paused = false;
    locateSide.value = KLocateSide.none;
    reveal(animate: true);
  }

  /// First layout and window resizes: put the line back without animation.
  void onViewportHeight(double height) {
    if (height == _viewportHeight) return;
    _viewportHeight = height;
    revealAfterLayout();
  }
}
