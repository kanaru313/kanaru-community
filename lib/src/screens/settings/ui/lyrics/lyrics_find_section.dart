import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/domain/local_lyrics_pick.dart';
import '../../../../lyrics/state/lyrics_settings.dart';
import '../../../../lyrics/state/online/lyrics_sources_provider.dart';
import '../soon_row.dart';
import 'lyrics_choice_row.dart';

/// "Tìm và lưu lời": the automatic online search switch and which local
/// source wins are live; saving found lyrics waits for its own work.
class LyricsFindSection extends ConsumerWidget {
  const LyricsFindSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final autoSearch = ref.watch(lyricsAutoSearchProvider);
    // Until the sources are read, "none on" would be a guess.
    final noneOn =
        ref.watch(lyricsSourcesLoadedProvider) &&
        !ref.watch(lyricsSourcesProvider).any((s) => s.enabled);
    return SetupSection(
      title: Text(l10n.lyricsSettingsFind),
      children: [
        KSwitchRow(
          leading: const Icon(KIcons.search),
          title: Text(l10n.lyricsSettingsAutoFind),
          subtitle: Text(
            noneOn
                ? '${l10n.lyricsSettingsAutoFindDesc}\n'
                      '${l10n.lyricsSettingsAutoFindNone}'
                : l10n.lyricsSettingsAutoFindDesc,
          ),
          switchLabel: l10n.lyricsSettingsAutoFind,
          value: autoSearch,
          onChanged: (v) => ref.read(lyricsAutoSearchProvider.notifier).set(v),
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
