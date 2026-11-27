import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../extension/kanaru_extension.dart';
import '../extension/state/extension_registry.dart';
import 'state/chat_flush.dart';
import 'ui/chat_host.dart';
import 'ui/chat_page_mobile.dart';

/// The AI module's entries in the app's extension points: the flush hook that
/// writes the text streamed so far when the app pauses or exits, and the
/// phone's chat page (`/chat`, on the root navigator, above the shell).
class AiExtension implements KanaruExtension {
  const AiExtension();

  @override
  String get id => 'ai';

  @override
  void register(ExtensionRegistry registry) {
    registry
      ..addFlushHook(flushChat)
      ..addLiveFlushHook(flushChat)
      ..addRoute(
        GoRoute(
          path: chatPath,
          pageBuilder: (context, state) {
            // Reduced motion: the page appears at once.
            final instant =
                MediaQuery.maybeDisableAnimationsOf(context) ?? false;
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: const ChatPageMobile(),
              transitionDuration: instant
                  ? Duration.zero
                  : KMotion.chatPageSlide,
              reverseTransitionDuration: instant
                  ? Duration.zero
                  : KMotion.chatPageSlide,
              transitionsBuilder: chatPageTransition,
            );
          },
        ),
      );
  }
}

/// Slides the chat page up from the bottom edge and back down.
Widget chatPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: animation,
        curve: KMotion.chatPageSlideCurve,
        reverseCurve: KMotion.chatPageSlideCurve.flipped,
      ),
    ),
    child: child,
  );
}
