import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/conversation/ai_conversation.dart';
import '../state/chat_view/history_view.dart';
import '../state/chat_view/time_format.dart';
import 'composer/chat_plugin_icon.dart';
import 'composer/permission_picker.dart';

/// Key of the history row of conversation [id].
ValueKey<String> historyRowKey(int id) => ValueKey('chat history row $id');

/// One conversation of the history list: plugin icon, name, and a line with
/// the time (today) or day and month, the plugin and the permission. The open
/// conversation is tinted; ⋮ offers rename (in place) and delete (asks first).
/// While its delete runs the row is dimmed and ignores taps.
class HistoryRow extends ConsumerWidget {
  const HistoryRow({
    super.key,
    required this.conversation,
    required this.today,
    required this.current,
    required this.pluginName,
    required this.pluginRemoved,
    required this.renaming,
    required this.onRenameStart,
    required this.onRenameEnd,
  });

  final AiConversation conversation;

  /// Its last message is from today: the line shows the time, not the date.
  final bool today;

  /// The open conversation.
  final bool current;

  /// The installed plugin's name; null when it is not known.
  final String? pluginName;
  final bool pluginRemoved;

  /// The name is an input.
  final bool renaming;
  final VoidCallback onRenameStart;
  final VoidCallback onRenameEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = conversation.id;
    final busy = ref.watch(chatHistoryActionsProvider).contains(id);
    final actions = ref.read(chatHistoryActionsProvider.notifier);
    final name = conversation.title.trim().isEmpty
        ? l10n.aiChatNewTitle
        : conversation.title;
    return Builder(
      builder: (rowContext) => SelectionRow(
        selected: current,
        enabled: !busy,
        leading: ChatPluginIcon(
          installId: pluginRemoved ? null : conversation.installId,
          size: 32,
        ),
        title: renaming
            ? _RenameField(
                initial: conversation.title,
                onDone: (text) {
                  if (text != null) {
                    unawaited(actions.rename(conversation, text));
                  }
                  onRenameEnd();
                },
              )
            : Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: _DetailLine(
          conversation: conversation,
          today: today,
          pluginName: pluginName,
          pluginRemoved: pluginRemoved,
        ),
        onTap: renaming ? null : () => unawaited(actions.open(id)),
        trailingAction: SelectionRowAction(
          icon: KIcons.moreVert,
          tooltip: l10n.aiChatHistoryRowOptions(name),
          onPressed: busy
              ? null
              : () => unawaited(_openMenu(rowContext, actions, name)),
        ),
      ),
    );
  }

  Future<void> _openMenu(
    BuildContext context,
    ChatHistoryActions actions,
    String name,
  ) {
    final l10n = AppLocalizations.of(context);
    return showKLayeredMenu(
      context,
      root: KMenuPage(
        groups: [
          [
            KMenuRow(
              title: l10n.aiChatMenuRename,
              icon: KIcons.edit,
              onTap: onRenameStart,
            ),
            KMenuRow(
              title: l10n.aiChatDeleteConfirm,
              icon: KIcons.delete,
              danger: true,
              onTap: () => unawaited(_confirmDelete(context, actions)),
            ),
          ],
        ],
      ),
    );
  }

  /// Asks, then deletes. Cancel leaves the conversation as it is.
  Future<void> _confirmDelete(
    BuildContext context,
    ChatHistoryActions actions,
  ) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final ok = await confirmAction(
      context,
      title: l10n.aiChatDeleteTitle,
      message: l10n.aiChatDeleteBody,
      confirmLabel: l10n.aiChatDeleteConfirm,
      destructive: true,
    );
    if (ok) await actions.delete(conversation.id);
  }
}

/// "14:32 · Claude · [eye] Read only": time or day and month, plugin (or the
/// removed note in the error colour), permission with its glyph.
class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.conversation,
    required this.today,
    required this.pluginName,
    required this.pluginRemoved,
  });

  final AiConversation conversation;
  final bool today;
  final String? pluginName;
  final bool pluginRemoved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final when = today
        ? chatClock(conversation.lastMessageAt)
        : chatDayMonth(conversation.lastMessageAt);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: when),
          if (pluginRemoved)
            TextSpan(
              text: ' · ${l10n.aiChatHistoryPluginRemoved}',
              style: TextStyle(color: scheme.error),
            )
          else if (pluginName != null)
            TextSpan(text: ' · $pluginName'),
          const TextSpan(text: ' · '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: KSpace.x1),
              child: Icon(permissionIcon(conversation.permission), size: 13),
            ),
          ),
          TextSpan(text: permissionName(l10n, conversation.permission)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// The name as an input, in place of the title: Enter saves, Esc cancels.
class _RenameField extends StatefulWidget {
  const _RenameField({required this.initial, required this.onDone});

  final String initial;

  /// The typed name, or null when cancelled.
  final ValueChanged<String?> onDone;

  @override
  State<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends State<_RenameField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initial.length,
        );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      // A text field keeps Esc for itself; here Esc cancels the rename.
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDone(null);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          isDense: true,
          hintText: AppLocalizations.of(context).aiChatRenameField,
        ),
        onSubmitted: widget.onDone,
      ),
    );
  }
}
