import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/chat_view/chat_view_state.dart';
import 'chat_header_title.dart';
import 'chat_host.dart';
import 'chat_menu.dart';
import 'chat_surface.dart';
import 'history_page.dart';

/// The chat as a full-screen page on the phone: header (close, name, ⋮) over
/// the chat. Back steps out of rename mode, then the history, then closes.
class ChatPageMobile extends ConsumerWidget {
  const ChatPageMobile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final canPop = ref.watch(
      chatViewProvider.select((s) => !s.renaming && !s.historyOpen),
    );
    final historyOpen = ref.watch(
      chatViewProvider.select((s) => s.historyOpen),
    );
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(chatViewProvider.notifier).back();
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              if (historyOpen)
                ChatHistoryHeader(
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                )
              else
                SizedBox(
                  height: KLayout.minTarget + KSpace.x2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
                    child: Row(
                      children: [
                        KIconButton(
                          icon: KIcons.collapse,
                          tooltip: l10n.aiChatCloseMobile,
                          onPressed: ref.read(chatHostProvider).close,
                        ),
                        Expanded(
                          child: ChatHeaderTitle(
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const ChatMenu(menuWhileRenaming: false),
                      ],
                    ),
                  ),
                ),
              const Expanded(child: ChatSurface()),
            ],
          ),
        ),
      ),
    );
  }
}
