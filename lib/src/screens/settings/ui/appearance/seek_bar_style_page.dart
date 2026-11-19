import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/domain/seek_bar_style.dart';
import '../../../../playback/state/seek_bar_style_provider.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import 'seek_bar_previews.dart';

/// Seek bar sub-page of Appearance: one preview card per style.
class SeekBarStylePage extends ConsumerWidget {
  const SeekBarStylePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = ref.watch(seekBarStyleProvider);
    return SettingsScaffold(
      title: l10n.settingsAppearanceSeekBar,
      parentPath: SettingsPaths.appearance,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KSpace.x3,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpace.x1),
              child: Text(
                l10n.settingsSeekBarCaption,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            KPreviewCardGroup<SeekBarStyle>(
              selected: style,
              onChanged: (value) =>
                  ref.read(seekBarStyleProvider.notifier).set(value),
              options: [
                KPreviewOption(
                  value: SeekBarStyle.waveform,
                  preview: const WaveformSeekPreview(),
                  title: l10n.settingsSeekBarWaveform,
                  caption: l10n.settingsSeekBarWaveformCaption,
                ),
                KPreviewOption(
                  value: SeekBarStyle.flat,
                  preview: const FlatSeekPreview(),
                  title: l10n.settingsSeekBarFlat,
                  caption: l10n.settingsSeekBarFlatCaption,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
