import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_providers.dart';

/// Play/pause toggle bound to the player. It rebuilds only when `playing`
/// flips and reads the controller on tap, never while building.
class PlayPauseButton extends ConsumerWidget {
  const PlayPauseButton({
    super.key,
    this.filled = false,
    this.iconSize,
    this.size,
  });

  /// Primary filled button (the desktop player bar's main control).
  final bool filled;
  final double? iconSize;

  /// Width and height of the button when it must be bigger than the icon
  /// needs (the 72 dp button of Now Playing).
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playing = ref.watch(isPlayingProvider);
    final icon = Icon(playing ? KIcons.pause : KIcons.play);
    void toggle() => ref.read(playerControllerProvider).playPause();
    final tooltip = playing ? l10n.playbackPause : l10n.playbackPlay;
    final style = size == null
        ? null
        : IconButton.styleFrom(fixedSize: Size.square(size!));
    return filled
        ? IconButton.filled(
            icon: icon,
            iconSize: iconSize,
            style: style,
            tooltip: tooltip,
            onPressed: toggle,
          )
        : IconButton(
            icon: icon,
            iconSize: iconSize,
            style: style,
            tooltip: tooltip,
            onPressed: toggle,
          );
  }
}
