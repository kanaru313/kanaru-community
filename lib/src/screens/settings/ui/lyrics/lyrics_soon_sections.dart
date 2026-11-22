import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../soon_row.dart';

/// Sections whose rows all wait for plugins or the engine: online sources,
/// where lyrics show, translation, lyrics from audio.
List<Widget> lyricsSoonSections(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final desktop = FormFactor.of(context) == FormFactor.desktop;
  return [
    SetupSection(
      title: Text(l10n.lyricsSettingsSources),
      children: [
        SoonRow(icon: KIcons.add, title: Text(l10n.lyricsSettingsAddSource)),
      ],
    ),
    SetupSection(
      title: Text(l10n.lyricsSettingsWhere),
      children: [
        if (desktop)
          SoonRow(
            icon: KIcons.openInNew,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(l10n.lyricsSettingsFloating)),
                const KGap(KSpace.x2),
                const ProBadge(),
              ],
            ),
            desc: l10n.lyricsSettingsFloatingDesc,
          )
        else
          SoonRow(
            icon: KIcons.lyrics,
            title: Text(l10n.lyricsSettingsLockScreen),
            desc: l10n.lyricsSettingsLockScreenDesc,
          ),
      ],
    ),
    SetupSection(
      title: Text(l10n.lyricsSettingsTranslation),
      children: [
        SoonRow(
          icon: KIcons.extension,
          title: Text(l10n.lyricsSettingsTrService),
          desc: l10n.lyricsSettingsTrServiceNone,
        ),
        SoonRow(
          icon: KIcons.language,
          title: Text(l10n.lyricsSettingsTrTarget),
          desc: l10n.lyricsSettingsTrTargetApp,
        ),
        SoonRow(
          icon: KIcons.playlistPlay,
          title: Text(l10n.lyricsSettingsTrAhead),
          desc: l10n.lyricsSettingsTrAheadNow,
        ),
        SoonRow(icon: KIcons.add, title: Text(l10n.lyricsSettingsAddTrService)),
      ],
    ),
    SetupSection(
      title: Text(l10n.lyricsSettingsSpeech),
      hint: l10n.lyricsSettingsSpeechHint,
      hintTooltip: l10n.settingsSectionHintTooltip(l10n.lyricsSettingsSpeech),
      hintTitle: l10n.lyricsSettingsSpeech,
      children: [
        SoonRow(icon: KIcons.add, title: Text(l10n.lyricsSettingsAddSpeech)),
      ],
    ),
  ];
}
