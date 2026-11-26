import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/chat_conversation_providers.dart';
import '../state/chat_session.dart';
import '../state/chat_view/chat_view_state.dart';

/// The name of the open conversation, as shown in the header: the empty name
/// of a new conversation reads "Cuộc trò chuyện mới".
String chatTitleOf(WidgetRef ref, AppLocalizations l10n) {
  final id = ref.watch(chatSessionProvider.select((s) => s.conversationId));
  final title = id == null
      ? null
      : ref.watch(chatConversationProvider(id)).value?.title;
  return title == null || title.trim().isEmpty ? l10n.aiChatNewTitle : title;
}

/// Title of the chat header. A tap turns it into an input (Enter saves, Esc
/// cancels; the ✓ button of the menu saves too). The rename state lives in
/// `chatViewProvider`, so the shell's Esc and the phone's Back can reach it.
class ChatHeaderTitle extends ConsumerWidget {
  const ChatHeaderTitle({super.key, required this.style});

  /// Text style of the title; the panel and the phone page differ.
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final renaming = ref.watch(chatViewProvider.select((s) => s.renaming));
    final title = chatTitleOf(ref, l10n);
    if (renaming) return _RenameField(style: style);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Tooltip(
        message: l10n.aiChatMenuRename,
        child: InkWell(
          borderRadius: BorderRadius.circular(KSpace.x2),
          onTap: () => ref.read(chatViewProvider.notifier).startRename(title),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KSpace.x2,
              vertical: KSpace.x1,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ),
      ),
    );
  }
}

class _RenameField extends ConsumerStatefulWidget {
  const _RenameField({required this.style});

  final TextStyle? style;

  @override
  ConsumerState<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends ConsumerState<_RenameField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(chatViewProvider).renameText,
  );

  @override
  void initState() {
    super.initState();
    // Select the whole name, so typing replaces it.
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.read(chatViewProvider.notifier);
    return Focus(
      // A text field keeps Esc for itself; here Esc cancels the rename.
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          view.cancelRename();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 1,
        style: widget.style,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          isDense: true,
          hintText: AppLocalizations.of(context).aiChatRenameField,
        ),
        onChanged: view.setRenameText,
        onSubmitted: (text) {
          view.setRenameText(text);
          view.commitRename();
        },
      ),
    );
  }
}
