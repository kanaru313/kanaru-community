import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_providers.dart';
import '../state/playback_settings_providers.dart';

export 'repeat_button.dart' show RepeatButton;

/// Next track. Reads the controller on tap only.
class NextButton extends ConsumerWidget {
  const NextButton({super.key, this.iconSize});

  final double? iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(KIcons.skipNext),
    iconSize: iconSize,
    tooltip: AppLocalizations.of(context).playbackNext,
    onPressed: () => ref.read(playerControllerProvider).next(),
  );
}

/// Previous track (always the previous one; at the first it restarts and
/// the controller raises the "first track" notice).
class PreviousButton extends ConsumerWidget {
  const PreviousButton({super.key, this.iconSize});

  final double? iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(KIcons.skipPrevious),
    iconSize: iconSize,
    tooltip: AppLocalizations.of(context).playbackPrevious,
    onPressed: () => ref.read(playerControllerProvider).previous(),
  );
}

/// Shuffle on/off, shown with the dot cue when on.
class ShuffleButton extends ConsumerWidget {
  const ShuffleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(shuffleSettingProvider);
    return KToggleIconButton(
      icon: KIcons.shuffle,
      active: on,
      tooltip: AppLocalizations.of(context).playbackShuffle,
      onPressed: () => ref.read(playerControllerProvider).setShuffle(!on),
    );
  }
}
