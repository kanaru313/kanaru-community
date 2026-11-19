import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../state/appearance_settings.dart';

/// The theme and language rows: the row shows the value, a tap opens the
/// picker, the choice applies at once. Shared by first-run and Settings; the
/// caller supplies the section around them.
class ThemeLanguageRows extends ConsumerStatefulWidget {
  const ThemeLanguageRows({super.key});

  @override
  ConsumerState<ThemeLanguageRows> createState() => _ThemeLanguageRowsState();
}

class _ThemeLanguageRowsState extends ConsumerState<ThemeLanguageRows> {
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

  IconData _themeIcon(ThemeChoice c) => switch (c) {
    ThemeChoice.system => KIcons.themeSystem,
    ThemeChoice.dark => KIcons.themeDark,
    ThemeChoice.light => KIcons.themeLight,
  };

  Future<void> _pickTheme(AppLocalizations l10n, ThemeChoice current) async {
    // Taken before the await: the picker may outlive this row.
    final notifier = ref.read(themeChoiceProvider.notifier);
    final chosen = await showSelectionPicker<ThemeChoice>(
      context,
      anchor: _themeKey,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.scanSetupThemeLabel),
      selected: current,
      options: [
        for (final c in ThemeChoice.values)
          SelectionOption(
            value: c,
            leading: Icon(_themeIcon(c)),
            title: Text(_themeName(l10n, c)),
          ),
      ],
    );
    if (chosen != null) await notifier.set(chosen);
  }

  Future<void> _pickLanguage(AppLocalizations l10n, AppLanguage current) async {
    final notifier = ref.read(appLanguageProvider.notifier);
    final chosen = await showSelectionPicker<AppLanguage>(
      context,
      anchor: _languageKey,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.scanSetupLanguageLabel),
      selected: current,
      options: [
        for (final l in AppLanguage.values)
          SelectionOption(value: l, title: Text(_languageName(l10n, l))),
      ],
    );
    if (chosen != null) await notifier.set(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeChoiceProvider);
    final language = ref.watch(appLanguageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
