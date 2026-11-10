import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/state/now_playing_panel.dart';
import '../../screens/now_playing/ui/desktop/desktop_now_playing.dart';

/// Slide duration and curve of Now Playing coming up from the bottom edge.
/// They are the old app's (the one place that keeps a timed curve over a
/// spring).
const Duration nowPlayingSlideDuration = Duration(milliseconds: 500);
const Curve nowPlayingSlideCurve = Cubic(0.65, 0.05, 0.36, 1);

/// Puts the desktop Now Playing over the left region of [DesktopShell] (the
/// sidebar, the page and the player bar's place), under the top bar. It is a
/// child of the shell's left column, so the right panel (queue or chat) is never
/// covered.
///
/// The screen exists only while the panel is open or sliding out, never kept
/// hidden: a hidden subtree would keep its tickers and per-tick rebuilds
/// running. A new screen per opening also means it always takes focus, which
/// Esc relies on.
///
/// Once the slide-in has finished the panel reports `covered`, and the shell
/// stops painting the region under it (its state is kept); the moment the
/// screen starts to leave, `covered` is cleared in the same frame, so the
/// region is drawn again under the leaving screen. Under reduced motion both
/// happen at once.
class DesktopNowPlayingOverlay extends ConsumerStatefulWidget {
  const DesktopNowPlayingOverlay({super.key});

  @override
  ConsumerState<DesktopNowPlayingOverlay> createState() =>
      _DesktopNowPlayingOverlayState();
}

class _DesktopNowPlayingOverlayState
    extends ConsumerState<DesktopNowPlayingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: nowPlayingSlideDuration,
  )..addStatusListener(_onStatus);
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: nowPlayingSlideCurve));
  late final NowPlayingPanel _panel = ref.read(
    nowPlayingPanelProvider.notifier,
  );

  /// What had focus before opening, to give it back when the screen is gone.
  FocusNode? _previousFocus;

  @override
  void initState() {
    super.initState();
    if (ref.read(nowPlayingPanelProvider).open) {
      _previousFocus = FocusManager.instance.primaryFocus;
      _controller.value = 1;
      // Built already open (the window just got wide): covered after this
      // frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _cover());
    }
  }

  /// Marks the region as covered, if the screen is still fully up.
  void _cover() {
    if (mounted &&
        _controller.isCompleted &&
        ref.read(nowPlayingPanelProvider).open) {
      _panel.setCovered(true);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _cover();
    if (status == AnimationStatus.dismissed) {
      final previous = _previousFocus;
      _previousFocus = null;
      if (previous != null && previous.context != null) previous.requestFocus();
    }
    // The screen is added or removed when the animation starts or ends.
    if (status != AnimationStatus.forward) setState(() {});
  }

  void _onOpenChanged(bool open) {
    if (open) {
      _previousFocus ??= FocusManager.instance.primaryFocus;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
        setState(() {});
        // The screen exists after this frame; then it covers.
        WidgetsBinding.instance.addPostFrameCallback((_) => _cover());
        return;
      }
      _controller.forward();
    } else {
      // Drawn again at once; the screen leaves over it.
      _panel.setCovered(false);
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 0;
      } else {
        _controller.reverse();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      nowPlayingPanelProvider.select((s) => s.open),
      (_, open) => _onOpenChanged(open),
    );
    final open = ref.watch(nowPlayingPanelProvider.select((s) => s.open));
    if (!open && _controller.isDismissed) return const SizedBox.shrink();
    return SlideTransition(
      position: _slide,
      // Opaque to pointers, so nothing reaches the region underneath.
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: const DesktopNowPlaying(),
      ),
    );
  }
}
