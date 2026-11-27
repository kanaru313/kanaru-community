import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/ai_settings_providers.dart';

final _log = Logger('ai.auto_mode_confirm');

/// What the "Bật Tự động?" box is about: it only changes the title, the toast
/// and where the user turns the question back on.
enum AutoModeScope {
  /// One conversation (the chat's permission picker).
  conversation,

  /// The permission every new conversation starts with (Settings).
  defaultForNew,
}

/// Asks before the automatic permission is switched on, unless the user
/// turned the question off (`ai.auto_ask`). Returns true when the switch may
/// go ahead: the user confirmed, or no question is asked. Cancel, Esc and Back
/// return false and change nothing.
///
/// The box has a "Hiện lại lần sau" check, ticked at first; confirming with it
/// unticked writes `ai.auto_ask` false. A toast then names the new state
/// (and, when unticked, where the question comes back). Meant as the
/// `confirm:` of a permission picker: the box opens over the picker, which
/// stays open.
Future<bool> confirmAutoMode(
  BuildContext context,
  WidgetRef ref, {
  required AutoModeScope scope,
}) async {
  if (!ref.read(aiAutoAskProvider)) return true;
  // Taken before the await: the picker and this context may be gone after it.
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final askNotifier = ref.read(aiAutoAskProvider.notifier);
  final again = await showKDialog<bool>(
    context,
    builder: (_) => _AutoModeDialog(
      title: switch (scope) {
        AutoModeScope.conversation => l10n.aiSetAutoTitleConversation,
        AutoModeScope.defaultForNew => l10n.aiSetAutoTitleDefault,
      },
      body: l10n.aiSetAutoBody,
      showAgainLabel: l10n.aiSetAutoShowAgain,
      confirmLabel: l10n.aiSetAutoConfirm,
    ),
  );
  if (again == null) return false;
  if (!again) {
    try {
      await askNotifier.set(false);
    } on Object catch (e, st) {
      // The settings store reports a failing write on the page banner; the
      // switch itself still goes ahead.
      _log.warning('saving ai.auto_ask failed', e, st);
    }
  }
  if (messenger != null && messenger.mounted) {
    showAppSnackBarOn(messenger, switch ((scope, again)) {
      (AutoModeScope.conversation, true) => l10n.aiSetAutoToastConversation,
      (AutoModeScope.conversation, false) =>
        l10n.aiSetAutoToastConversationQuiet,
      (AutoModeScope.defaultForNew, true) => l10n.aiSetAutoToastDefault,
      (AutoModeScope.defaultForNew, false) => l10n.aiSetAutoToastDefaultQuiet,
    });
  }
  return true;
}

/// Pops `true` (ask again next time) or `false` when confirmed, null when
/// cancelled.
class _AutoModeDialog extends StatefulWidget {
  const _AutoModeDialog({
    required this.title,
    required this.body,
    required this.showAgainLabel,
    required this.confirmLabel,
  });

  final String title;
  final String body;
  final String showAgainLabel;
  final String confirmLabel;

  @override
  State<_AutoModeDialog> createState() => _AutoModeDialogState();
}

class _AutoModeDialogState extends State<_AutoModeDialog> {
  bool _again = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Scrolls instead of overflowing at a large text scale.
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.body),
          const KGap(KSpace.x3),
          SelectionRow(
            title: Text(widget.showAgainLabel),
            selected: _again,
            multi: true,
            onTap: () => setState(() => _again = !_again),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_again),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
