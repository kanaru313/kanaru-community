import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../ai/ui/play_context_label_sync.dart';
import '../../extension/state/extension_providers.dart';
import '../../playback/state/now_playing_panel.dart';
import '../../playback/state/app_cover_seed.dart';
import '../../playback/state/playback_providers.dart';
import '../../playback/state/player_ready.dart';
import '../../playback/state/playing_cover_colors.dart';
import '../../screens/now_playing/now_playing_path.dart';
import '../state/nav_history.dart';
import '../state/right_panel.dart';
import 'chat_host_shell.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';
import 'playback_notice_listener.dart';

/// Frame around every page. The single place that picks Desktop or Mobile.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  NavHistory? _history;
  ProviderSubscription<PlayingCoverColors>? _coverColors;
  final _notices = GlobalKey<PlaybackNoticeListenerState>();

  /// A hand-over of Now Playing from the desktop panel to the mobile page is
  /// under way (set once per width change, cleared after the frame).
  bool _handingOver = false;

  /// The same for the chat, between the right panel and the `/chat` page.
  bool _handingOverChat = false;

  /// Layout of the previous build, to tell a window that just turned narrow
  /// from one that started narrow.
  bool? _wasMobile;

  @override
  void initState() {
    super.initState();
    // Create the player once the shell is up (both shells), so the saved
    // session and the system media controls start at launch, not on the first
    // tap on a mini player. After the first frame: building a provider with
    // side effects is not allowed while widgets build, so the shells and the
    // cover colour sync wait for the player phase and `playerCreatedProvider`
    // before this callback. The current-track and playing providers are not
    // gated that way yet.
    // The notice listener starts in the same callback, so no notice is lost
    // in between.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final player = ref.read(playerControllerProvider);
      unawaited(ref.read(playerPhaseProvider.notifier).attach(player));
      // Keeps the stored theme seed in step with the playing cover. Started
      // here, not in build: it reads the player.
      _coverColors = ref.listenManual(
        playingCoverColorsProvider,
        (_, colors) => syncAppCoverSeed(ref, colors),
        fireImmediately: true,
      );
      _notices.currentState?.start();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _history ??= NavHistory(GoRouter.of(context));
  }

  @override
  void dispose() {
    _coverColors?.close();
    _history?.dispose();
    super.dispose();
  }

  /// The window turned narrow while the desktop Now Playing was open: the
  /// mobile page takes over. Once per change, after the frame.
  void _handOverToMobile() {
    if (_handingOver) return;
    _handingOver = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handingOver = false;
      if (!mounted) return;
      final panel = ref.read(nowPlayingPanelProvider);
      if (!panel.open || FormFactor.of(context) != FormFactor.mobile) return;
      ref.read(nowPlayingPanelProvider.notifier).close();
      GoRouter.of(context).push(nowPlayingPath);
    });
  }

  /// The window turned narrow with the chat in the right panel: the page
  /// takes over (panel closed, `/chat` pushed). Once per change, after the
  /// frame.
  void _chatToPage() {
    if (_handingOverChat) return;
    _handingOverChat = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handingOverChat = false;
      if (!mounted || FormFactor.of(context) != FormFactor.mobile) return;
      if (ref.read(rightPanelProvider) != RightPanelKind.chat) return;
      ref.read(rightPanelProvider.notifier).close();
      openChatPage(GoRouter.of(context));
    });
  }

  /// The window is wide while `/chat` is the top page: the panel takes over
  /// (page popped, chat shown in the panel).
  void _chatToPanel() {
    if (_handingOverChat) return;
    _handingOverChat = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handingOverChat = false;
      if (!mounted || FormFactor.of(context) != FormFactor.desktop) return;
      final router = GoRouter.of(context);
      if (!chatPageOnTop(router)) return;
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/');
      }
      ref.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
    });
  }

  /// Keeps one chat: a window that turned narrow moves the panel's chat to
  /// the page, one that turned wide moves the page's chat to the panel. A
  /// window that starts narrow with the panel saved open on the chat just
  /// closes the panel: the phone does not open the chat by itself.
  void _syncChatPlace(bool mobile) {
    final wasMobile = _wasMobile;
    _wasMobile = mobile;
    final panelOnChat = ref.read(rightPanelProvider) == RightPanelKind.chat;
    if (mobile) {
      if (!panelOnChat) return;
      if (wasMobile == false) {
        _chatToPage();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(rightPanelProvider.notifier).close();
        });
      }
    } else if (chatPageOnTop(GoRouter.of(context))) {
      _chatToPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final registry = ref.watch(extensionRegistryProvider);
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    _syncChatPlace(mobile);
    // Opened while the window is narrow, or the window just turned narrow
    // with the panel open (this build runs on the width change). A listener
    // plus a read, so the shell does not rebuild on every open and close.
    ref.listen(nowPlayingPanelProvider.select((s) => s.open), (_, open) {
      if (open && FormFactor.of(context) == FormFactor.mobile) {
        _handOverToMobile();
      }
    });
    if (mobile && ref.read(nowPlayingPanelProvider).open) _handOverToMobile();
    return AiPlayContextLabelSync(
      child: PlaybackNoticeListener(
        key: _notices,
        autoStart: false,
        child: switch (FormFactor.of(context)) {
          FormFactor.desktop => DesktopShell(
            navigationShell: widget.navigationShell,
            items: registry.navItems,
            history: _history!,
          ),
          FormFactor.mobile => MobileShell(
            navigationShell: widget.navigationShell,
            items: registry.branchNavItems,
            sidebarItems: registry.navItems,
          ),
        },
      ),
    );
  }
}
