import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../state/playback_position_provider.dart';
import '../state/playback_providers.dart';
import '../state/waveform_providers.dart';
import 'playback_time_label.dart';

/// Waveform seek bar bound to the player: position in, `seek` out. Watching
/// the waveform here is what keeps the decoder busy: it runs only while one of
/// these is mounted. Flat until the levels of the playing entry arrive.
class PlaybackWaveformSeekBar extends ConsumerWidget {
  const PlaybackWaveformSeekBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pos = ref.watch(playbackPositionProvider).value;
    final position = pos?.position ?? Duration.zero;
    final duration = pos?.duration;
    final entry = ref.watch(nowPlayingProvider.select((n) => n.value?.entryId));
    final view = ref.watch(waveformProvider).value;
    // A view of another entry is the previous track's: draw it flat.
    final mine = view != null && entry != null && view.entryId == entry;
    return KWaveformSeekBar(
      track: entry ?? pos?.entryId,
      position: position,
      duration: duration,
      levels: mine ? view.levels : null,
      levelsDuration: mine && view.levels != null
          ? Duration(milliseconds: view.durationMs)
          : null,
      instant: mine && view.instant,
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
