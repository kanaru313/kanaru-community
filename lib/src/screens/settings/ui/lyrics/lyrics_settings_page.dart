import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import 'lyrics_display_section.dart';
import 'lyrics_find_section.dart';
import 'lyrics_soon_sections.dart';

/// Settings › Lyrics: five live pickers; every plugin- or engine-dependent
/// row is a "coming soon" row.
class LyricsSettingsPage extends StatelessWidget {
  const LyricsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.settingsRootLyrics,
      parentPath: SettingsPaths.root,
      children: [
        const LyricsDisplaySection(),
        const LyricsFindSection(),
        ...lyricsSoonSections(context),
      ],
    );
  }
}
