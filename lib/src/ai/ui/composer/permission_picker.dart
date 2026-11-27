import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/permission.dart';
import '../../state/chat_session.dart';
import '../../state/chat_view/composer_view.dart';
import '../auto_mode_confirm.dart';
import '../chat_auto_confirm_provider.dart';

/// The glyph of a permission level: an eye, a shield, a bolt.
IconData permissionIcon(AiPermission permission) => switch (permission) {
  AiPermission.readOnly => KIcons.eye,
  // The shield glyph; kanaru_ui has no name for this use yet.
  AiPermission.ask => KIcons.clipping,
  AiPermission.auto => KIcons.bolt,
};

String permissionName(AppLocalizations l10n, AiPermission permission) =>
    switch (permission) {
      AiPermission.readOnly => l10n.aiChatPermissionReadOnly,
      AiPermission.ask => l10n.aiChatPermissionAsk,
      AiPermission.auto => l10n.aiChatPermissionAuto,
    };

String permissionDescription(AppLocalizations l10n, AiPermission permission) =>
    switch (permission) {
      AiPermission.readOnly => l10n.aiChatPermissionReadOnlyHint,
      AiPermission.ask => l10n.aiChatPermissionAskHint,
      AiPermission.auto => l10n.aiChatPermissionAutoHint,
    };

/// Picks how far the assistant may act in this chat (icon rows). Choosing
/// "Tự động" asks first, through the shared confirm; Cancel keeps the picker
/// open. Read-only denies pending and allowed-but-not-run calls (the session
/// does that).
Future<void> showPermissionPicker(
  BuildContext context,
  WidgetRef ref, {
  GlobalKey? anchor,
}) async {
  final l10n = AppLocalizations.of(context);
  final current = ref.read(composerViewProvider).permission;
  final session = ref.read(chatSessionProvider.notifier);
  final confirmAuto = ref.read(chatAutoModeConfirmProvider);
  final chosen = await showSelectionPicker<AiPermission>(
    context,
    anchor: anchor,
    selected: current,
    header: Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x4,
        KSpace.x2,
        KSpace.x4,
        KSpace.x2,
      ),
      child: Text(l10n.aiChatPermissionPickerCaption),
    ),
    options: [
      for (final p in AiPermission.values)
        SelectionOption<AiPermission>(
          value: p,
          title: Text(permissionName(l10n, p)),
          subtitle: Text(permissionDescription(l10n, p)),
          leading: Icon(permissionIcon(p)),
        ),
    ],
    confirm: (value) async {
      if (value != AiPermission.auto || value == current) return true;
      return confirmAuto(context, ref, scope: AutoModeScope.conversation);
    },
  );
  if (chosen != null && chosen != current) await session.setPermission(chosen);
}
