import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../extension/state/extension_providers.dart';
import '../../../../platform/domain/media_permissions.dart';
import '../../../../platform/state/media_permissions_provider.dart';
import '../../../../plugins/state/alerts_provider.dart';
import '../../../../plugins/state/updates_provider.dart';
import '../../../plugins/common/restore_trigger.dart';
import '../../../plugins/plugin_paths.dart';
import '../../settings_routes.dart';
import '../../state/app_edition.dart';
import '../settings_scaffold.dart';
import '../soon_row.dart';

/// Root of Settings: four untitled blocks of rows, each row a short summary
/// of what its page holds, then one block per section that extensions add.
class SettingsRootPage extends ConsumerWidget {
  const SettingsRootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final edition = ref.watch(appEditionProvider);
    final permission = ref.watch(mediaPermissionStateProvider).value;
    final musicMissing =
        permission != null &&
        permission.applies &&
        permission.audio != MediaPermissionStatus.granted;
    final sections = ref.watch(extensionRegistryProvider).settingsSections;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    watchPluginRestore(ref);
    // A loading or failing database shows no dot: only a known problem does.
    final pluginNeedsAttention =
        (ref.watch(pluginAlertsProvider).value?.any ?? false) ||
        (ref.watch(updatesProvider).value?.needsReview.isNotEmpty ?? false);
    return SettingsScaffold(
      title: l10n.navSettings,
      children: [
        SettingsBlock(
          children: [
            SetupValueRow(
              icon: KIcons.appearance,
              title: Text(l10n.settingsRootAppearance),
              value: Text(l10n.settingsRootAppearanceDesc),
              onTap: () => context.push(SettingsPaths.appearance),
            ),
            SetupValueRow(
              icon: KIcons.library,
              title: Text(l10n.settingsRootLibrary),
              value: Text.rich(
                TextSpan(
                  text: l10n.settingsRootLibraryDesc,
                  children: [
                    if (musicMissing)
                      TextSpan(
                        text: l10n.settingsRootLibraryMissingPermission,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              onTap: () => context.push(SettingsPaths.library),
            ),
            SetupValueRow(
              icon: KIcons.playCircle,
              title: Text(l10n.settingsRootPlayback),
              value: Text(l10n.settingsRootPlaybackDesc),
              onTap: () => context.push(SettingsPaths.playback),
            ),
            SetupValueRow(
              icon: KIcons.lyrics,
              title: Text(l10n.settingsRootLyrics),
              value: Text(l10n.settingsRootLyricsDesc),
              onTap: () => context.push(SettingsPaths.lyrics),
            ),
          ],
        ),
        SettingsBlock(
          children: [
            SetupValueRow(
              icon: KIcons.extension,
              title: Text(l10n.settingsRootPlugins),
              value: Text(l10n.settingsRootPluginsDesc),
              alert: pluginNeedsAttention,
              alertLabel: l10n.pluginsRootAlertLabel,
              onTap: () => context.push(PluginPaths.store),
            ),
            SetupValueRow(
              icon: KIcons.ai,
              title: Text(l10n.settingsRootAi),
              value: Text(l10n.settingsRootAiDesc),
              onTap: () => context.push(SettingsPaths.ai),
            ),
            SoonRow(
              icon: KIcons.integrations,
              title: Text(l10n.settingsRootIntegrations),
              desc: desktop
                  ? l10n.settingsRootIntegrationsDescDesktop
                  : l10n.settingsRootIntegrationsDescMobile,
            ),
          ],
        ),
        SettingsBlock(
          children: [
            SoonRow(
              icon: KIcons.dataStorage,
              title: Text(l10n.settingsRootData),
              desc: l10n.settingsRootDataDesc,
            ),
            SoonRow(
              icon: KIcons.advanced,
              title: Text(l10n.settingsRootAdvanced),
              desc: l10n.settingsRootAdvancedDesc,
            ),
          ],
        ),
        SettingsBlock(
          children: [
            _proRow(l10n, edition),
            SetupValueRow(
              icon: KIcons.info,
              title: Text(l10n.settingsAbout),
              value: Text(l10n.settingsRootAboutDesc),
              onTap: () => context.push(SettingsPaths.about),
            ),
          ],
        ),
        for (final section in sections) section.builder(context),
      ],
    );
  }

  /// The Pro row. Free: a "coming soon" row with the Pro badge until the Pro
  /// page exists. Pro: the activated state.
  Widget _proRow(AppLocalizations l10n, AppEdition edition) {
    return switch (edition) {
      AppEdition.free => SoonRow(
        icon: KIcons.proEdition,
        // Wraps instead of overflowing when the "Coming soon" label takes
        // most of the row (large text scale).
        title: Wrap(
          spacing: KSpace.x2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [Text(l10n.settingsRootPro), const ProBadge()],
        ),
        desc: l10n.settingsRootProFreeDesc,
      ),
      AppEdition.pro => SetupValueRow(
        icon: KIcons.proEdition,
        title: Text(l10n.settingsRootPro),
        value: Text(l10n.settingsRootProActive),
        onTap: null,
      ),
    };
  }
}
