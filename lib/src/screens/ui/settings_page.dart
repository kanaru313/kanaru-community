import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_providers.dart';
import '../../platform/state/platform_providers.dart';

/// Settings: sections contributed by extensions, then "About".
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sections = ref.watch(extensionRegistryProvider).settingsSections;
    final native = ref.watch(nativeVersionsProvider);
    final textTheme = Theme.of(context).textTheme;
    final isMobile = FormFactor.of(context) == FormFactor.mobile;
    return KPage(
      maxWidth: KLayout.settings,
      children: [
        PageHeader(
          title: l10n.navSettings,
          // Mobile shows no bottom bar here, so it needs a way back.
          onBack: isMobile ? () => context.go('/') : null,
          backTooltip: l10n.tooltipBack,
        ),
        for (final section in sections) ...[
          section.builder(context),
          const SizedBox(height: KSpace.x4),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(KSpace.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KSpace.x1,
              children: [
                Text(l10n.settingsAbout, style: textTheme.titleMedium),
                Text('Kanaru', style: textTheme.bodyLarge),
                Text(l10n.settingsNativeVersions, style: textTheme.labelMedium),
                Text(native, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
