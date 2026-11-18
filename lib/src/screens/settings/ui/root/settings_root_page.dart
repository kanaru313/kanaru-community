import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../extension/state/extension_providers.dart';
import '../../../../platform/domain/media_permissions.dart';
import '../../../../platform/state/media_permissions_provider.dart';
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
    return SettingsScaffold(
      title: l10n.navSettings,
      children: [
        SettingsBlock(
          children: [
            SetupValueRow(
              icon: KIcons.theme,
              title: Text(l10n.settingsRootAppearance),
              value: Text(l10n.settingsRootAppearanceDesc),
              onTap: () => context.push(SettingsPaths.appearance),
            ),
            // The library pages come with the library settings; until then
            // the row is a "coming soon" one.
            SoonRow(
              icon: KIcons.library,
              title: Text(l10n.settingsRootLibrary),
              desc:
                  l10n.settingsRootLibraryDesc +
                  (musicMissing
                      ? l10n.settingsRootLibraryMissingPermission
                      : ''),
            ),
            SoonRow(
              icon: KIcons.playCircle,
              title: Text(l10n.settingsRootPlayback),
              desc: l10n.settingsRootPlaybackDesc,
            ),
            SoonRow(
              icon: KIcons.lyrics,
              title: Text(l10n.settingsRootLyrics),
              desc: l10n.settingsRootLyricsDesc,
            ),
          ],
        ),
        SettingsBlock(
          children: [
            SoonRow(
              icon: KIcons.extension,
              title: Text(l10n.settingsRootPlugins),
              desc: l10n.settingsRootPluginsDesc,
            ),
            SoonRow(
              icon: KIcons.ai,
              title: Text(l10n.settingsRootAi),
              desc: l10n.settingsRootAiDesc,
            ),
            SoonRow(
              icon: KIcons.bolt,
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
              icon: KIcons.sdCard,
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
        icon: KIcons.boltSelected,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(l10n.settingsRootPro)),
            const KGap(KSpace.x2),
            const ProBadge(),
          ],
        ),
        desc: l10n.settingsRootProFreeDesc,
      ),
      AppEdition.pro => SetupValueRow(
        icon: KIcons.boltSelected,
        title: Text(l10n.settingsRootPro),
        value: Text(l10n.settingsRootProActive),
        onTap: null,
      ),
    };
  }
}
