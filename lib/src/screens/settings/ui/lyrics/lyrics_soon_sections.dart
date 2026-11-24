import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../soon_row.dart';
import 'pro_title.dart';

/// "Nơi hiện lời": every row waits for the engine.
Widget lyricsWhereSection(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final desktop = FormFactor.of(context) == FormFactor.desktop;
  return SetupSection(
    title: Text(l10n.lyricsSettingsWhere),
    children: [
      if (desktop)
        SoonRow(
          icon: KIcons.openInNew,
          title: ProTitle(l10n.lyricsSettingsFloating),
          desc: l10n.lyricsSettingsFloatingDesc,
        )
      else
        SoonRow(
          icon: KIcons.lyrics,
          title: Text(l10n.lyricsSettingsLockScreen),
          desc: l10n.lyricsSettingsLockScreenDesc,
        ),
    ],
  );
}

/// "Tạo lời từ âm thanh": its only row waits for the speech plugins.
Widget lyricsSpeechSection(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return SetupSection(
    title: Text(l10n.lyricsSettingsSpeech),
    hint: l10n.lyricsSettingsSpeechHint,
    hintTooltip: l10n.settingsSectionHintTooltip(l10n.lyricsSettingsSpeech),
    hintTitle: l10n.lyricsSettingsSpeech,
    children: [
      SoonRow(icon: KIcons.add, title: Text(l10n.lyricsSettingsAddSpeech)),
    ],
  );
}
