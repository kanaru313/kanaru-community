import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/state/now_playing_panel.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/ui/flight_source.dart';
import 'mobile/lyrics_screen_route.dart';
import 'mobile/mobile_now_playing.dart';
import 'mobile/queue_sheet.dart';

/// The `/now-playing` route. On the mobile shell it is the full-screen page.
/// If it is built at desktop width (the window was widened, or the route was
/// opened by hand) it hands over to the desktop panel and leaves, once.
/// With no track left (the only entry was removed) it also leaves.
class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage> {
  /// Set when the page started leaving, so a resize drag across the width
  /// limit, or two reasons to leave at once, act only once.
  bool _leaving = false;

  /// The cover, title and buttons that fly to the queue strip.
  final FlightSource _flight = FlightSource()
    ..look = const FlightLook(coverRadius: KRadius.sm);

  @override
  void dispose() {
    // The page went away by another way than `_pop` (a location change): the
    // lyrics screen above it must not stay on its own. Removing a route while
    // the tree is being torn down is not safe, so it waits for the frame.
    final lyrics = _lyricsRoute;
    if (lyrics != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => closeLyricsScreen(lyrics, animated: false),
      );
    }
    _flight.dispose();
    super.dispose();
  }

  /// The open lyrics screen, if any.
  LyricsScreenRoute? _lyricsRoute;

  void _openLyrics() {
    if (_lyricsRoute?.isActive ?? false) return;
    _lyricsRoute = showLyricsScreen(context);
  }

  void _pop() {
    // The lyrics screen sits above this page: remove it first, so the pop
    // below always takes `/now-playing` and never the lyrics route.
    final lyrics = _lyricsRoute;
    if (lyrics != null) closeLyricsScreen(lyrics, animated: false);
    _lyricsRoute = null;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  /// The user closed the page (chevron, pull, back).
  void _close() {
    if (_leaving) return;
    _leaving = true;
    _pop();
  }

  /// Leaves because of what the build found (desktop width, no track): after
  /// the frame, once.
  void _leaveAfterFrame({bool toDesktopPanel = false}) {
    if (_leaving) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (toDesktopPanel) {
        ref.read(nowPlayingPanelProvider.notifier).open();
      }
      _pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Null while the player has not answered yet: do not leave on that.
    final hasTrack = ref.watch(
      nowPlayingProvider.select(
        (n) => n.hasValue ? n.requireValue.hasTrack : null,
      ),
    );
    if (FormFactor.of(context) == FormFactor.desktop) {
      _leaveAfterFrame(toDesktopPanel: hasTrack != false);
      return const SizedBox.shrink();
    }
    if (hasTrack == false) {
      _leaveAfterFrame();
      return const SizedBox.shrink();
    }
    return MobileNowPlaying(
      onClose: _close,
      flight: _flight,
      onQueue: () => showQueueSheet(context, from: _flight),
      onOpenLyrics: _openLyrics,
    );
  }
}
