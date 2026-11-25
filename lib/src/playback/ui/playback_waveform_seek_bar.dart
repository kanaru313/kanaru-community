import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/seek_bar_style.dart';
import '../domain/waveform.dart';
import '../state/playback_position_provider.dart';
import '../state/playback_providers.dart';
import '../state/seek_bar_style_provider.dart';
import '../state/waveform_providers.dart';
import 'playback_time_label.dart';

/// Waveform seek bar bound to the player: position in, `seek` out. Watching
/// the waveform here is what keeps the decoder busy: it runs only while one of
/// these is mounted in the waveform style. The band shows the dotted row until
/// the playing entry's status is known, then bars or the flat fallback; the flat
/// style does not watch the waveform and passes `none` (the flat track).
class PlaybackWaveformSeekBar extends ConsumerWidget {
  const PlaybackWaveformSeekBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pos = ref.watch(playbackPositionProvider).value;
    final position = pos?.position ?? Duration.zero;
    final duration = pos?.duration;
    final entry = ref.watch(nowPlayingProvider.select((n) => n.value?.entryId));
    final flat = ref.watch(seekBarStyleProvider) == SeekBarStyle.flat;
    // Not watched when flat, so the decoder never starts for a flat bar.
    final loaded = flat ? null : ref.watch(waveformProvider);
    final view = loaded?.value;
    // A view of another entry (or none yet, while the provider loads) is no
    // decision about this track: `unknown`, never the previous track's.
    final mine = view != null && view.entryId == entry;
    final ready = mine && view.status == WaveformStatus.ready;
    final status = flat
        ? KWaveformStatus.none
        : !mine
        ? KWaveformStatus.unknown
        : switch (view.status) {
            WaveformStatus.computing => KWaveformStatus.computing,
            WaveformStatus.ready => KWaveformStatus.ready,
            WaveformStatus.none => KWaveformStatus.none,
          };
    return KWaveformSeekBar(
      track: entry ?? pos?.entryId,
      position: position,
      duration: duration,
      status: status,
      playing: ref.watch(isPlayingProvider),
      levels: ready ? view.levels : null,
      levelsDuration: ready ? Duration(milliseconds: view.durationMs) : null,
      semanticLabel: l10n.playbackSeek,
      // Hold or drag shows the time under the finger; a drag up cancels.
      bubbleLabel: formatClock,
      cancelLabel: l10n.playbackSeekCancel,
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
