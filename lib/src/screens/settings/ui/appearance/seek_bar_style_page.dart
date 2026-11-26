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
    final style = ref.watch(seekBarStyleProvider);
    return SettingsScaffold(
      title: l10n.settingsAppearanceSeekBar,
      parentPath: SettingsPaths.appearance,
      children: [
        KPreviewCardGroup<SeekBarStyle>(
          selected: style,
          onChanged: (value) =>
              ref.read(seekBarStyleProvider.notifier).set(value),
          options: [
            for (final kind in SeekBarStyle.values)
              KPreviewOption(
                value: kind,
                preview: SeekStylePreview(style: kind),
                title: seekBarStyleTitle(l10n, kind),
                caption: _caption(l10n, kind),
              ),
          ],
        ),
      ],
    );
  }
}

/// Style names, the same ones the Appearance row shows.
String seekBarStyleTitle(AppLocalizations l10n, SeekBarStyle style) =>
    switch (style) {
      SeekBarStyle.bars => l10n.settingsSeekBarStyleBars,
      SeekBarStyle.dots => l10n.settingsSeekBarStyleDots,
      SeekBarStyle.line => l10n.settingsSeekBarStyleLine,
      SeekBarStyle.mirror => l10n.settingsSeekBarStyleMirror,
      SeekBarStyle.squiggle => l10n.settingsSeekBarStyleSquiggle,
      SeekBarStyle.flat => l10n.settingsSeekBarFlat,
    };

String _caption(AppLocalizations l10n, SeekBarStyle style) => switch (style) {
  SeekBarStyle.bars => l10n.settingsSeekBarStyleBarsCaption,
  SeekBarStyle.dots => l10n.settingsSeekBarStyleDotsCaption,
  SeekBarStyle.line => l10n.settingsSeekBarStyleLineCaption,
  SeekBarStyle.mirror => l10n.settingsSeekBarStyleMirrorCaption,
  SeekBarStyle.squiggle => l10n.settingsSeekBarStyleSquiggleCaption,
  SeekBarStyle.flat => l10n.settingsSeekBarFlatCaption,
};
