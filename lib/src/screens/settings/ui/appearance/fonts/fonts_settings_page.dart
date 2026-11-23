import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../../l10n/gen/app_localizations.dart';
import '../../../settings_routes.dart';
import '../../settings_scaffold.dart';
import 'builtin_fonts_block.dart';
import 'catalog_fonts_block.dart';

/// Font sub-page of Appearance: the font used for all app text.
class FontsSettingsPage extends ConsumerWidget {
  const FontsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.settingsAppearanceFont,
      parentPath: SettingsPaths.appearance,
      children: const [BuiltInFontsBlock(), CatalogFontsBlock()],
    );
  }
}
