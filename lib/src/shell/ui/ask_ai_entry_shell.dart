import 'package:flutter/widgets.dart' show BuildContext, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../ai/state/chat_attachments.dart';
import '../../ai/state/chat_view/chat_view_state.dart';
import '../../ai/state/chat_view/composer_draft.dart';
import '../../library/domain/ask_ai_target.dart';
import '../../library/ui/menus/ask_ai_entry.dart';
import '../state/right_panel.dart';
import 'chat_host_shell.dart';

/// The shell's "Ask AI" entry: attaches the chip of the target, shows the
/// chat and asks for the cursor in its composer. On desktop the chat is the
/// shared right panel (it replaces the queue when that is showing); on the
/// phone it is the `/chat` page, pushed once (asking from a song row inside
/// the chat leaves the page where it is).
class AskAiEntryShell implements AskAiEntry {
  AskAiEntryShell(this._ref, this._router);

  final Ref _ref;
  final GoRouter Function() _router;

  @override
  Future<void> ask(BuildContext context, AskAiTarget target) async {
    final desktop = _isDesktop(context);
    _ref.read(chatAttachmentsProvider.notifier).attachTarget(target);
    // The conversation, not the history list, must be in front.
    _ref.read(chatViewProvider.notifier).closeHistory();
    if (desktop) {
      _ref.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
    } else {
      openChatPage(_router());
    }
    _ref.read(composerFocusRequestProvider.notifier).request();
  }

  /// The shell for the current window. A context that is already gone (a
  /// menu that closed) falls back to the window's own size, so a caller can
  /// never break the entry with a dead context.
  bool _isDesktop(BuildContext context) {
    if (context.mounted) return FormFactor.of(context) == FormFactor.desktop;
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return FormFactor.fromWidth(
          view.physicalSize.width / view.devicePixelRatio,
        ) ==
        FormFactor.desktop;
  }
}
