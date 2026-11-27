import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ai/ui/chat_host.dart';
import '../../playback/state/mini_player_flight.dart';
import '../../screens/now_playing/ui/mobile/queue_sheet.dart';
import '../state/right_panel.dart';

/// Whether the phone's chat page is the top route.
bool chatPageOnTop(GoRouter router) =>
    router.routerDelegate.currentConfiguration.last.matchedLocation == chatPath;

/// Whether the chat page is anywhere in the stack.
bool chatPageInStack(GoRouter router) => router
    .routerDelegate
    .currentConfiguration
    .matches
    .any((m) => m.matchedLocation == chatPath);

/// The location of the page the chat covers: the top route while the chat page
/// is not in the stack. Null once it is (it is on top, or a page opened from
/// inside the chat sits above it): the page it was opened over was written
/// earlier and stays.
String? pageUnderChat(GoRouter router) {
  if (chatPageInStack(router)) return null;
  return router.routerDelegate.currentConfiguration.last.matchedLocation;
}

/// Shows the phone's chat page once: pushed when it is not open, brought back
/// to the top when it is already below other pages, left alone when it is on
/// top.
void openChatPage(GoRouter router) {
  if (chatPageOnTop(router)) return;
  if (chatPageInStack(router)) {
    // Pages (a sheet's route, a detail) were pushed over the chat: pop them.
    // maybePop respects the pages' own guards (an unsaved edit): stop when
    // one refuses.
    unawaited(_popToChat(router));
    return;
  }
  router.push(chatPath);
}

Future<void> _popToChat(GoRouter router) async {
  final navigator = router.routerDelegate.navigatorKey.currentState;
  while (navigator != null && !chatPageOnTop(router) && router.canPop()) {
    if (!await navigator.maybePop()) return;
  }
}

/// The shell's [ChatHost]: the chat is the right panel on desktop and a page
/// on the root navigator on the phone. [router] is read when needed, so the
/// host works whichever router is current.
class ChatHostShell implements ChatHost {
  ChatHostShell(this._ref, this._router);

  final Ref _ref;
  final GoRouter Function() _router;

  @override
  // The shell decides, not the route stack: a page above the phone's chat
  // page must not make `close` shut the (closed) panel.
  bool get isPanel => _ref.read(rightPanelProvider) == RightPanelKind.chat;

  @override
  void close() {
    if (isPanel) {
      _ref.read(rightPanelProvider.notifier).close();
      return;
    }
    final router = _router();
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/');
    }
  }

  @override
  void openQueue() {
    if (isPanel) {
      _ref.read(rightPanelProvider.notifier).show(RightPanelKind.queue);
      return;
    }
    final context = _router().routerDelegate.navigatorKey.currentContext;
    if (context == null) return;
    showQueueSheet(context, from: _ref.read(miniPlayerFlightProvider));
  }

  @override
  void openSettings(String location) => _router().go(location);
}
