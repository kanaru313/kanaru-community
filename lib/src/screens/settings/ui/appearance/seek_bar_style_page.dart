import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/domain/seek_bar_style.dart';
import '../../../../playback/state/seek_bar_style_provider.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import 'seek_bar_customise_sheet.dart';
import 'seek_bar_preview_card.dart';
import 'seek_bar_preview_clock.dart';
import 'seek_bar_previews.dart';
import 'seek_bar_style_labels.dart';

export 'seek_bar_style_labels.dart' show seekBarStyleTitle;

/// Seek bar sub-page of Appearance: a live preview on a pretend clock, then
/// one card per style. A tap on a card applies the style; the ★ on Squiggle
/// and Flat bar picks the style shown while a track has no waveform; the
/// chosen card's button (or a second tap) opens its options.
class SeekBarStylePage extends ConsumerStatefulWidget {
  const SeekBarStylePage({super.key});

  @override
  ConsumerState<SeekBarStylePage> createState() => _SeekBarStylePageState();
}

class _SeekBarStylePageState extends ConsumerState<SeekBarStylePage>
    with TickerProviderStateMixin {
  late final SeekPreviewClock _clock = SeekPreviewClock(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clock.motionAllowed = !MediaQuery.disableAnimationsOf(context);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  // Focus goes back to whatever opened the sheet (the card or its button).
  void _customise(SeekBarStyle style) => showSeekBarCustomiseSheet(
    context,
    style: style,
    clock: _clock,
    returnFocus: FocusManager.instance.primaryFocus,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.settingsSeekBarStylesTitle;
    return SettingsScaffold(
      title: l10n.settingsAppearanceSeekBar,
      parentPath: SettingsPaths.appearance,
      maxWidth: KLayout.settingsWide,
      children: [
        SeekPreviewCard(clock: _clock),
        SetupSection(
          card: false,
          title: Text(title),
          hint: l10n.settingsSeekBarStylesHint,
          hintTooltip: l10n.settingsSectionHintTooltip(title),
          hintTitle: title,
          children: [_cards(l10n)],
        ),
      ],
    );
  }

  Widget _cards(AppLocalizations l10n) {
    final style = ref.watch(seekBarStyleProvider);
    final fallback = ref.watch(seekBarFallbackProvider);
    final wave = ref.watch(waveSeekOptionsProvider);
    final squiggle = ref.watch(squiggleSeekOptionsProvider);
    final flat = ref.watch(flatSeekOptionsProvider);
    KFallbackMark? mark(SeekBarStyle kind) {
      final target = switch (kind) {
        SeekBarStyle.squiggle => SeekBarFallback.squiggle,
        SeekBarStyle.flat => SeekBarFallback.flat,
        _ => null,
      };
      if (target == null) return null;
      final active = fallback == target;
      return KFallbackMark(
        active: active,
        onActivate: () =>
            ref.read(seekBarFallbackProvider.notifier).set(target),
        tooltip: active
            ? l10n.settingsSeekBarFallbackActive
            : l10n.settingsSeekBarFallbackUse(seekBarStyleTitle(l10n, kind)),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _clock.playingListenable,
      builder: (context, playing, _) => KPreviewCardGroup<SeekBarStyle>(
        selected: style,
        onChanged: (value) =>
            ref.read(seekBarStyleProvider.notifier).set(value),
        options: [
          for (final kind in SeekBarStyle.values)
            KPreviewOption(
              value: kind,
              preview: SeekStylePreview(
                style: kind,
                wave: wave,
                squiggle: squiggle,
                flat: flat,
                playing: playing,
              ),
              title: seekBarStyleTitle(l10n, kind),
              caption: seekBarStyleCaption(l10n, kind),
              fallback: mark(kind),
              action: KCardAction(
                label: l10n.settingsSeekBarCustomise,
                onPressed: () => _customise(kind),
              ),
              onReselect: () => _customise(kind),
            ),
        ],
      ),
    );
  }
}
