import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../settings/ui/appearance/theme_language_rows.dart';

/// Theme and language on the first-run page; the rows are shared with
/// Settings.
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SetupSection(
      title: Text(AppLocalizations.of(context).scanSetupAppearanceTitle),
      children: const [ThemeLanguageRows()],
    );
  }
}
