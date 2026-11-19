import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../platform/state/platform_providers.dart';
import '../../settings_routes.dart';
import '../../state/app_edition.dart';
import '../settings_scaffold.dart';

/// The licence id shown on the page; the same as the repository's.
const String kanaruLicenseId = 'GPL-3.0-or-later';

/// About: name and edition, licence, and the native libraries in use.
class AboutSettingsPage extends ConsumerWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final edition = ref.watch(appEditionProvider);
    final native = ref.watch(nativeVersionsProvider);
    return SettingsScaffold(
      title: l10n.settingsAbout,
      parentPath: SettingsPaths.root,
      children: [
        _Header(
          edition: switch (edition) {
            AppEdition.free => l10n.settingsAboutEditionFree,
            AppEdition.pro => l10n.settingsAboutEditionPro,
          },
        ),
        SettingsBlock(
          children: [
            KListRow(
              leading: const Icon(KIcons.license),
              title: Text(l10n.settingsAboutLicense),
              subtitle: const Text(kanaruLicenseId),
            ),
            KListRow(
              leading: const Icon(KIcons.openSourceLicenses),
              title: Text(l10n.settingsAboutLicenses),
              trailing: const Icon(KIcons.chevronRight),
              onTap: () =>
                  showLicensePage(context: context, applicationName: 'Kanaru'),
            ),
          ],
        ),
        SetupSection(
          title: Text(l10n.settingsNativeVersions),
          children: [SetupNote(child: Text(native))],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.edition});

  final String edition;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        const KGap(KSpace.x4),
        DecoratedBox(
          decoration: ShapeDecoration(
            shape: KShape.of(KRadius.lg),
            color: scheme.primary,
          ),
          child: SizedBox.square(
            dimension: KSpace.x10,
            child: Icon(
              KIcons.appLogo,
              size: KIconSize.xl,
              color: scheme.onPrimary,
            ),
          ),
        ),
        const KGap(KSpace.x3),
        Text('Kanaru', style: textTheme.headlineSmall),
        const KGap(KSpace.x1),
        Text(
          edition,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
