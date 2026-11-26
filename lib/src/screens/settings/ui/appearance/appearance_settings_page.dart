import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../fonts/state/font_selector.dart';
import '../../../../playback/domain/seek_bar_style.dart';
import '../../../../playback/state/seek_bar_style_provider.dart';
import '../../settings_routes.dart';
import '../../state/appearance_settings.dart';
import '../../state/display_settings.dart';
import '../settings_scaffold.dart';
import '../soon_row.dart';
import 'fonts/font_labels.dart';
import 'theme_language_rows.dart';

/// Text size step shown as "Default".
const int _defaultTextScale = 100;

/// Appearance: theme and language (the first-run rows), colour and motion,
/// text, and the seek bar.
class AppearanceSettingsPage extends ConsumerStatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  ConsumerState<AppearanceSettingsPage> createState() =>
      _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState
    extends ConsumerState<AppearanceSettingsPage> {
  final _textSizeKey = GlobalKey();

  Future<void> _pickTextSize(AppLocalizations l10n, int current) async {
    final notifier = ref.read(appTextScaleProvider.notifier);
    final chosen = await showSelectionPicker<int>(
      context,
      anchor: _textSizeKey,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.settingsAppearanceTextSize),
      selected: current,
      options: [
        for (final step in textScaleSteps)
          SelectionOption(
            value: step,
            title: Text(l10n.settingsPercent(step)),
            subtitle: step == _defaultTextScale
                ? Text(l10n.settingsAppearanceTextSizeDefault)
                : null,
          ),
      ],
    );
    if (chosen != null) await notifier.set(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ref.watch(themeChoiceProvider);
    final pureBlack = ref.watch(pureBlackProvider);
    final motion = ref.watch(appMotionProvider);
    final textScale = ref.watch(appTextScaleProvider);
    final seekStyle = ref.watch(seekBarStyleProvider);
    final font = ref.watch(activeFontProvider);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    // Pure black only changes the dark theme.
    final pureBlackLocked = theme == ThemeChoice.light;
    return SettingsScaffold(
      title: l10n.settingsRootAppearance,
      parentPath: SettingsPaths.root,
      children: [
        SetupSection(
          title: Text(l10n.scanSetupAppearanceTitle),
          children: const [ThemeLanguageRows()],
        ),
        SetupSection(
          title: Text(l10n.settingsAppearanceColorMotionTitle),
          children: [
            KSwitchRow(
              leading: const Icon(KIcons.pureBlack),
              title: Text(l10n.settingsAppearancePureBlack),
              // Locked: the reason replaces the desc.
              subtitle: Text(
                pureBlackLocked
                    ? l10n.settingsAppearancePureBlackNeedsDark
                    : l10n.settingsAppearancePureBlackDesc,
              ),
              lockedLabel: l10n.settingsAppearancePureBlackNeedsDark,
              switchLabel: l10n.settingsAppearancePureBlack,
              value: pureBlack,
              onChanged: pureBlackLocked
                  ? null
                  : (v) => ref.read(pureBlackProvider.notifier).set(v),
            ),
            KSwitchRow(
              leading: const Icon(KIcons.motion),
              title: Text(l10n.settingsAppearanceMotion),
              subtitle: Text(l10n.settingsAppearanceMotionDesc),
              switchLabel: l10n.settingsAppearanceMotion,
              value: motion,
              onChanged: (v) => ref.read(appMotionProvider.notifier).set(v),
            ),
          ],
        ),
        SetupSection(
          title: Text(l10n.settingsAppearanceTextTitle),
          children: [
            SetupValueRow(
              icon: KIcons.font,
              title: Text(l10n.settingsAppearanceFont),
              value: Text(fontLabel(l10n, font)),
              onTap: () => context.push(SettingsPaths.fonts),
            ),
            SetupValueRow(
              anchorKey: _textSizeKey,
              icon: KIcons.textSize,
              title: Text(l10n.settingsAppearanceTextSize),
              value: Text(l10n.settingsPercent(textScale)),
              onTap: () => _pickTextSize(l10n, textScale),
            ),
          ],
        ),
        SetupSection(
          title: Text(l10n.settingsAppearanceDisplayTitle),
          children: [
            SetupValueRow(
              icon: KIcons.seekBar,
              title: Text(l10n.settingsAppearanceSeekBar),
              value: Text(switch (seekStyle) {
                SeekBarStyle.bars => l10n.settingsSeekBarStyleBars,
                SeekBarStyle.dots => l10n.settingsSeekBarStyleDots,
                SeekBarStyle.line => l10n.settingsSeekBarStyleLine,
                SeekBarStyle.mirror => l10n.settingsSeekBarStyleMirror,
                SeekBarStyle.squiggle => l10n.settingsSeekBarStyleSquiggle,
                SeekBarStyle.flat => l10n.settingsSeekBarFlat,
              }),
              onTap: () => context.push(SettingsPaths.seekBar),
            ),
            if (desktop)
              SoonRow(
                icon: KIcons.windowFrame,
                title: Text(l10n.settingsAppearanceWindowFrame),
                desc:
                    '${l10n.settingsAppearanceWindowFrameDesc}\n'
                    '${l10n.settingsAppearanceWindowFrameApply}',
              ),
          ],
        ),
      ],
    );
  }
}
