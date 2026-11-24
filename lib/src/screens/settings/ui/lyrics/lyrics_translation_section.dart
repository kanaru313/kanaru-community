import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/domain/translation/translation_size.dart';
import '../../../../lyrics/state/translation/translation_settings.dart';
import '../../../plugins/plugin_paths.dart';
import '../soon_row.dart';
import 'lyrics_choice_row.dart';
import 'lyrics_translation_rows.dart';
import 'pro_title.dart';

/// "Dịch lời": the default service and language are live; "Dịch trước" is a
/// Pro feature for later (an inert "Sắp có" row on every edition); the add
/// row opens the plugin store on the translate plugins.
class LyricsTranslationSection extends StatelessWidget {
  const LyricsTranslationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupSection(
      title: Text(l10n.lyricsSettingsTranslation),
      children: [
        const TranslationServiceRow(),
        const TranslationTargetRow(),
        LyricsChoiceRow<TranslationSize>(
          icon: KIcons.textSize,
          title: l10n.lyricsSettingsTrSize,
          caption: l10n.lyricsSettingsTrSizeCaption,
          provider: translationSizeProvider,
          choices: [
            LyricsChoice(TranslationSize.small, l10n.lyricsSettingsSizeSmall),
            LyricsChoice(
              TranslationSize.medium,
              l10n.lyricsSettingsSizeMedium,
              subtitle: l10n.lyricsSettingsDefault,
            ),
            LyricsChoice(TranslationSize.large, l10n.lyricsSettingsSizeLarge),
          ],
        ),
        SoonRow(
          icon: KIcons.playlistPlay,
          title: ProTitle(l10n.lyricsSettingsTrAhead),
          desc: l10n.lyricsSettingsTrAheadNow,
        ),
        SetupAddRow(
          icon: KIcons.add,
          label: Text(l10n.lyricsSettingsAddTrService),
          onTap: () => context.push(PluginPaths.storeForKind('translate')),
        ),
      ],
    );
  }
}
