import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import '../../../../ai/state/ai_settings_providers.dart';
import 'ai_confirm_section.dart';
import 'ai_history_section.dart';
import 'ai_instructions_section.dart';
import 'ai_permission_section.dart';
import 'ai_prompts_section.dart';
import 'ai_services_section.dart';
import 'ai_tools_section.dart';

/// Settings › AI chat: the services, the default permission, the standing
/// instructions, the tools, the prompt templates, the history and the
/// confirmation box. Every control applies and saves at once.
class AiSettingsPage extends ConsumerWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.settingsRootAi,
      parentPath: SettingsPaths.root,
      children: [
        const AiServicesSection(),
        const AiPermissionSection(),
        const AiInstructionsSection(),
        const AiToolsSection(),
        const AiPromptsSection(),
        const AiHistorySection(),
        // Only after the user turned the "Bật Tự động?" question off.
        if (!ref.watch(aiAutoAskProvider)) const AiConfirmSection(),
      ],
    );
  }
}
