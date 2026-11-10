import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../settings/state/appearance_settings.dart';

/// Theme and language: the row shows the value, a tap opens the picker, the
/// choice applies at once (to this page too).
class AppearanceSection extends ConsumerStatefulWidget {
  const AppearanceSection({super.key});

  @override
  ConsumerState<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends ConsumerState<AppearanceSection> {
  final _themeKey = GlobalKey();
  final _languageKey = GlobalKey();

  String _themeName(AppLocalizations l10n, ThemeChoice c) => switch (c) {
    ThemeChoice.system => l10n.scanSetupThemeSystem,
    ThemeChoice.dark => l10n.scanSetupThemeDark,
    ThemeChoice.light => l10n.scanSetupThemeLight,
  };

  String _languageName(AppLocalizations l10n, AppLanguage l) => switch (l) {
    AppLanguage.vi => l10n.scanSetupLanguageVietnamese,
    AppLanguage.en => l10n.scanSetupLanguageEnglish,
  };

  Future<void> _pickTheme(AppLocalizations l10n, ThemeChoice current) async {
    final chosen = await showSelectionPicker<ThemeChoice>(
      context,
      anchor: _themeKey,
      title: Text(l10n.scanSetupThemeLabel),
      selected: current,
      options: [
        for (final c in ThemeChoice.values)
          SelectionOption(value: c, title: Text(_themeName(l10n, c))),
      ],
    );
    if (chosen != null) {
      await ref.read(themeChoiceProvider.notifier).set(chosen);
    }
  }

  Future<void> _pickLanguage(AppLocalizations l10n, AppLanguage current) async {
    final chosen = await showSelectionPicker<AppLanguage>(
      context,
      anchor: _languageKey,
      title: Text(l10n.scanSetupLanguageLabel),
      selected: current,
      options: [
        for (final l in AppLanguage.values)
          SelectionOption(value: l, title: Text(_languageName(l10n, l))),
      ],
    );
    if (chosen != null) {
      await ref.read(appLanguageProvider.notifier).set(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeChoiceProvider);
    final language = ref.watch(appLanguageProvider);
    return SetupSection(
      title: Text(l10n.scanSetupAppearanceTitle),
      children: [
        SetupValueRow(
          anchorKey: _themeKey,
          icon: KIcons.theme,
          title: Text(l10n.scanSetupThemeLabel),
          value: Text(_themeName(l10n, theme)),
          onTap: () => _pickTheme(l10n, theme),
        ),
        SetupValueRow(
          anchorKey: _languageKey,
          icon: KIcons.language,
          title: Text(l10n.scanSetupLanguageLabel),
          value: Text(_languageName(l10n, language)),
          onTap: () => _pickLanguage(l10n, language),
        ),
      ],
    );
  }
}
