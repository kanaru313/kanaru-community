import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/permission.dart';
import '../../../../ai/state/ai_settings_providers.dart';
import '../../../../ai/ui/auto_mode_confirm.dart';
import '../lyrics/lyrics_choice_row.dart';

/// "Quyền": the permission a new conversation starts with. Choosing
/// "Tự động" asks first (unless the user turned the question off).
class AiPermissionSection extends ConsumerWidget {
  const AiPermissionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SetupSection(
      title: Text(l10n.aiSetPermTitle),
      children: [
        LyricsChoiceRow<AiPermission>(
          icon: KIcons.permission,
          title: l10n.aiSetPermRow,
          caption: l10n.aiSetPermCaption,
          provider: aiDefaultPermissionProvider,
          choices: [
            LyricsChoice(
              AiPermission.readOnly,
              l10n.aiSetPermReadOnly,
              subtitle: l10n.aiSetPermReadOnlyDesc,
              icon: KIcons.eye,
            ),
            LyricsChoice(
              AiPermission.ask,
              l10n.aiSetPermAsk,
              subtitle: l10n.aiSetPermAskDesc,
              icon: KIcons.permission,
            ),
            LyricsChoice(
              AiPermission.auto,
              l10n.aiSetPermAuto,
              subtitle: l10n.aiSetPermAutoDesc,
              icon: KIcons.bolt,
            ),
          ],
          confirm: (value) async =>
              value != AiPermission.auto ||
              ref.read(aiDefaultPermissionProvider) == AiPermission.auto ||
              await confirmAutoMode(
                context,
                ref,
                scope: AutoModeScope.defaultForNew,
              ),
        ),
      ],
    );
  }
}
