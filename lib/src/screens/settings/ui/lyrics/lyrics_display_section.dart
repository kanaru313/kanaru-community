import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/domain/lyrics_display_prefs.dart';
import '../../../../lyrics/state/lyrics_settings.dart';
import '../soon_row.dart';
import 'lyrics_choice_row.dart';

/// "Hiển thị lời": four live pickers, then the rows that wait for plugins or
/// the engine.
class LyricsDisplaySection extends StatelessWidget {
  const LyricsDisplaySection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mobile = FormFactor.of(context) != FormFactor.desktop;
    final dflt = l10n.lyricsSettingsDefault;
    return SetupSection(
      title: Text(l10n.lyricsSettingsDisplay),
      children: [
        LyricsChoiceRow<LyricsFontScale>(
          icon: KIcons.textSize,
          title: l10n.lyricsSettingsFontSize,
          caption: l10n.lyricsSettingsFontSizeCaption,
          provider: lyricsFontScaleProvider,
          choices: [
            LyricsChoice(LyricsFontScale.small, l10n.lyricsSettingsSizeSmall),
            LyricsChoice(
              LyricsFontScale.medium,
              l10n.lyricsSettingsSizeMedium,
              subtitle: dflt,
            ),
            LyricsChoice(LyricsFontScale.large, l10n.lyricsSettingsSizeLarge),
          ],
        ),
        LyricsChoiceRow<LyricsAlign>(
          icon: KIcons.flatList,
          title: l10n.lyricsSettingsAlign,
          provider: lyricsAlignProvider,
          choices: [
            LyricsChoice(
              LyricsAlign.start,
              l10n.lyricsSettingsAlignStart,
              subtitle: dflt,
            ),
            LyricsChoice(LyricsAlign.center, l10n.lyricsSettingsAlignCenter),
          ],
        ),
        LyricsChoiceRow<LyricsAutoReturn>(
          icon: KIcons.rescan,
          title: l10n.lyricsSettingsAutoReturn,
          caption: l10n.lyricsSettingsAutoReturnCaption,
          provider: lyricsAutoReturnProvider,
          choices: [
            LyricsChoice(
              LyricsAutoReturn.off,
              l10n.lyricsSettingsAutoReturnOff,
              subtitle: dflt,
            ),
            LyricsChoice(LyricsAutoReturn.s3, l10n.lyricsSettingsAutoReturn3),
            LyricsChoice(LyricsAutoReturn.s5, l10n.lyricsSettingsAutoReturn5),
            LyricsChoice(LyricsAutoReturn.s10, l10n.lyricsSettingsAutoReturn10),
          ],
        ),
        LyricsChoiceRow<LyricsDim>(
          icon: KIcons.hideFromLibrary,
          title: l10n.lyricsSettingsDim,
          provider: lyricsDimProvider,
          choices: [
            LyricsChoice(
              LyricsDim.light,
              l10n.lyricsSettingsDimLight,
              subtitle: dflt,
            ),
            LyricsChoice(LyricsDim.strong, l10n.lyricsSettingsDimStrong),
            LyricsChoice(LyricsDim.off, l10n.lyricsSettingsDimOff),
          ],
        ),
        SoonRow(
          icon: KIcons.languages,
          title: Text(l10n.lyricsSettingsRomanize),
          desc: l10n.lyricsSettingsRomanizeDesc,
        ),
        if (mobile)
          SoonRow(
            icon: KIcons.themeLight,
            title: Text(l10n.lyricsSettingsKeepAwake),
            desc: l10n.lyricsSettingsKeepAwakeDesc,
          ),
      ],
    );
  }
}
