import 'package:material_ui/material_ui.dart';
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
    return KPage(
      maxWidth: KLayout.settings,
      children: [
        PageHeader(
          title: l10n.navSettings,
          // Root of the Settings branch: no back button here. The mobile
          // shell supplies its own leading back (to Home); desktop walks
          // the history.
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

/// Stand-in sub-page of Settings: proves a page can push inside the branch.
class SettingsSubPagePlaceholder extends StatelessWidget {
  const SettingsSubPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return KPage(
      maxWidth: KLayout.settings,
      children: [
        PageHeader(
          title: l10n.navSettings,
          onBack: context.pop,
          backTooltip: l10n.tooltipBack,
        ),
      ],
    );
  }
}
