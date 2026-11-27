import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show ScaffoldMessenger;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/chat_session.dart';
import '../state/chat_view/chat_view_state.dart';
import 'chat_header_title.dart';
import 'chat_host.dart';
import 'ai_settings_link.dart';

/// The header's buttons: the ⋮ menu, and while the title is being renamed the
/// ✓ that saves the name. The phone's header has room for one of them
/// ([menuWhileRenaming] false), the panel's keeps both.
class ChatMenu extends ConsumerWidget {
  const ChatMenu({super.key, this.menuWhileRenaming = true});

  final bool menuWhileRenaming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final renaming = ref.watch(chatViewProvider.select((s) => s.renaming));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (renaming)
          KIconButton(
            icon: KIcons.check,
            tooltip: l10n.aiChatRenameSave,
            onPressed: () =>
                unawaited(ref.read(chatViewProvider.notifier).commitRename()),
          ),
        if (!renaming || menuWhileRenaming)
          KMoreButton(
            tooltip: l10n.aiChatMenuTooltip,
            onPressed: ({required viaKeyboard}) =>
                unawaited(_open(context, ref, viaKeyboard: viaKeyboard)),
          ),
      ],
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref, {
    required bool viaKeyboard,
  }) {
    final l10n = AppLocalizations.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final view = ref.read(chatViewProvider.notifier);
    final host = ref.read(chatHostProvider);
    final storedTitle = chatStoredTitleOf(ref);
    // The menu and the dialog outlive this widget (a hand-over may rebuild
    // it), so they work on the container, not on `ref`.
    final container = ProviderScope.containerOf(context, listen: false);
    return showKLayeredMenu(
      context,
      viaKeyboard: viaKeyboard,
      root: KMenuPage(
        groups: [
          [
            KMenuRow(
              title: l10n.aiChatNewTitle,
              icon: KIcons.compose,
              shortcutLabel: desktop ? 'Ctrl+Shift+O' : null,
              onTap: () => unawaited(view.startNewConversation()),
            ),
            KMenuRow(
              title: l10n.aiChatMenuHistory,
              icon: KIcons.history,
              onTap: view.openHistory,
            ),
            KMenuRow(
              title: l10n.aiChatMenuRename,
              icon: KIcons.edit,
              onTap: () => view.startRename(storedTitle),
            ),
            KMenuRow(
              title: l10n.aiChatMenuDelete,
              icon: KIcons.delete,
              danger: true,
              onTap: () => unawaited(_confirmDelete(context, container)),
            ),
            KMenuRow(
              title: l10n.aiChatMenuSettings,
              icon: KIcons.settings,
              onTap: () => host.openSettings(aiSettingsLocation),
            ),
          ],
        ],
      ),
    );
  }

  /// Asks, then deletes the open conversation (its turn is stopped and a new
  /// empty one opens: the controller does both).
  Future<void> _confirmDelete(
    BuildContext context,
    ProviderContainer container,
  ) async {
    final l10n = AppLocalizations.of(context);
    final id = container.read(chatSessionProvider).conversationId;
    if (id == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(
      Navigator.of(context, rootNavigator: true).context,
    );
    final ok = await confirmAction(
      context,
      title: l10n.aiChatDeleteTitle,
      message: l10n.aiChatDeleteBody,
      confirmLabel: l10n.aiChatDeleteConfirm,
      destructive: true,
    );
    if (!ok) return;
    final deleted = await container
        .read(chatViewProvider.notifier)
        .deleteConversation(id);
    if (deleted && messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.aiChatDeleted);
    }
  }
}
