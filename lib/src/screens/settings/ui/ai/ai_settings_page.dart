import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import 'ai_instructions_section.dart';
import 'ai_permission_section.dart';
import 'ai_services_section.dart';
import 'ai_tools_section.dart';

/// Settings › AI chat: the services, the default permission, the standing
/// instructions and the tools. Every control applies and saves at once.
class AiSettingsPage extends ConsumerWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.settingsRootAi,
      parentPath: SettingsPaths.root,
      children: const [
        AiServicesSection(),
        AiPermissionSection(),
        AiInstructionsSection(),
        AiToolsSection(),
      ],
    );
  }
}
