import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/domain/local_lyrics_pick.dart';
import '../../../../lyrics/state/lyrics_settings.dart';
import '../soon_row.dart';
import 'lyrics_choice_row.dart';

/// "Tìm và lưu lời": which local source wins is live; online search and
/// saving wait for the lyrics plugins.
class LyricsFindSection extends StatelessWidget {
  const LyricsFindSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupSection(
      title: Text(l10n.lyricsSettingsFind),
      children: [
        SoonRow(
          icon: KIcons.search,
          title: Text(l10n.lyricsSettingsAutoFind),
          desc: l10n.lyricsSettingsAutoFindDesc,
        ),
        LyricsChoiceRow<LocalFirst>(
          icon: KIcons.musicFile,
          title: l10n.lyricsSettingsLocalFirst,
          caption: l10n.lyricsSettingsLocalFirstCaption,
          provider: lyricsLocalFirstProvider,
          choices: [
            LyricsChoice(
              LocalFirst.tag,
              l10n.lyricsSettingsLocalTag,
              subtitle: l10n.lyricsSettingsLocalTagSub,
            ),
            LyricsChoice(
              LocalFirst.lrc,
              l10n.lyricsSettingsLocalLrc,
              subtitle: l10n.lyricsSettingsLocalLrcSub,
            ),
          ],
        ),
        SoonRow(
          icon: KIcons.fileExport,
          title: Text(l10n.lyricsSettingsAutoSave),
          desc: l10n.lyricsSettingsAutoSaveDesc,
        ),
      ],
    );
  }
}
