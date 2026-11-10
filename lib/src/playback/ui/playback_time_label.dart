import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_position_provider.dart';
import '../state/playback_providers.dart';

/// `m:ss`, or `h:mm:ss` from one hour.
String formatClock(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

/// Elapsed or total time of the loaded entry. It selects whole seconds, so it
/// rebuilds once a second, not on every tick.
class PlaybackTimeLabel extends ConsumerWidget {
  const PlaybackTimeLabel({super.key, this.total = false, this.textAlign});

  /// Show the duration instead of the position.
  final bool total;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(
      playbackPositionProvider.select(
        (p) =>
            (total
                ? p.value?.duration?.inSeconds
                : p.value?.position.inSeconds) ??
            0,
      ),
    );
    return Text(
      formatClock(Duration(seconds: seconds)),
      textAlign: textAlign,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Flat seek bar bound to the player: position in, `seek` out.
class PlaybackSeekBar extends ConsumerWidget {
  const PlaybackSeekBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pos = ref.watch(playbackPositionProvider).value;
    final position = pos?.position ?? Duration.zero;
    final duration = pos?.duration;
    return KSeekBar(
      position: position,
      duration: duration,
      semanticLabel: l10n.playbackSeek,
      semanticValue: duration == null
          ? null
          : l10n.playbackPositionValue(
              formatClock(position),
              formatClock(duration),
            ),
      onSeek: (to) => ref.read(playerControllerProvider).seek(to),
    );
  }
}
