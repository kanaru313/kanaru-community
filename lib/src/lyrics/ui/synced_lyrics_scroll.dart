import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

/// Where the current line sits in the view: 40 % down from the top.
const double lyricsAnchor = 0.4;

/// The scrolling of the synced lyrics view: keeping the current line at
/// [lyricsAnchor] and telling the user's scrolling from the view's own. The
/// state that mixes it in sets [lineKeys] and [lineIndex] and answers
/// [autoReturnDelay].
///
/// Only [scroll] moves, never an enclosing scrollable. A scroll the view did
/// not start (drag, wheel, trackpad, keyboard) stops auto-scroll and turns
/// [showBack] on; the line comes back through [backToLine] (the pill) or, when
/// [autoReturnDelay] is set, by itself after that long without input.
mixin SyncedLyricsScroll<T extends StatefulWidget> on State<T> {
  final scroll = ScrollController();

  /// One key per line, to find its render object.
  late List<GlobalKey> lineKeys;

  /// The current line, -1 before the first.
  int lineIndex = -1;

  /// True while the user has taken over: the pill is shown and line changes
  /// do not scroll.
  final ValueNotifier<bool> showBack = ValueNotifier(false);

  /// Set while this view moves its own scroll position, so that move is not
  /// taken for the user's.
  bool scrollingItself = false;

  /// Counts this view's own scrolls: an animation replaced by a newer one
  /// completes early and must not clear [scrollingItself] for the newer.
  int _scrollGeneration = 0;
  Timer? _autoReturn;
  double? _viewportHeight;

  /// Seconds without input before the view returns by itself; null = never.
  Duration? get autoReturnDelay;

  bool get paused => showBack.value;

  /// Cancels the timer and the controller; call from `dispose`.
  void disposeScroll() {
    _autoReturn?.cancel();
    showBack.dispose();
    scroll.dispose();
  }

  /// Scrolls so the current line (the first before any) sits at the anchor.
  void reveal({required bool animate}) {
    if (!scroll.hasClients || lineKeys.isEmpty) return;
    final object = lineKeys[lineIndex < 0 ? 0 : lineIndex].currentContext
        ?.findRenderObject();
    if (object == null || !object.attached) return;
    final position = scroll.position;
    final target = RenderAbstractViewport.of(object)
        .getOffsetToReveal(object, lyricsAnchor)
        .offset
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return;
    scrollingItself = true;
    final generation = ++_scrollGeneration;
    if (!animate || MediaQuery.disableAnimationsOf(context)) {
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

  /// Puts the current line back at the anchor after this frame, without a
  /// glide, unless the user has taken over.
  void revealAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !paused) reveal(animate: false);
    });
  }

  /// The user took over: stop auto-scroll, show the pill, start the
  /// auto-return timer when the setting asks for one.
  void takeOver() {
    showBack.value = true;
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
    showBack.value = false;
    reveal(animate: true);
  }

  /// First layout and window resizes: put the line back without animation.
  void onViewportHeight(double height) {
    if (height == _viewportHeight) return;
    _viewportHeight = height;
    revealAfterLayout();
  }
}
