import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_providers.dart';
import '../state/playback_settings_providers.dart';

/// Desktop volume: mute button and an 84 dp slider. The value is the
/// persisted setting (0-100); changes go through the controller.
class VolumeControl extends ConsumerStatefulWidget {
  const VolumeControl({super.key});

  static const double sliderWidth = 84;

  @override
  ConsumerState<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<VolumeControl> {
  /// Volume to return to when unmuting; never 0.
  int _beforeMute = 100;

  void _set(int volume) => ref.read(playerControllerProvider).setVolume(volume);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final volume = ref.watch(volumeSettingProvider);
    final muted = volume == 0;
    if (!muted) _beforeMute = volume;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(muted ? KIcons.volumeOff : KIcons.volume),
          tooltip: muted ? l10n.playbackUnmute : l10n.playbackMute,
          onPressed: () => _set(muted ? _beforeMute : 0),
        ),
        SizedBox(
          width: VolumeControl.sliderWidth,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: volume.toDouble(),
              max: 100,
              semanticFormatterCallback: (v) => '${v.round()}%',
              label: l10n.playbackVolume,
              onChanged: (v) => _set(v.round()),
            ),
          ),
        ),
      ],
    );
  }
}
