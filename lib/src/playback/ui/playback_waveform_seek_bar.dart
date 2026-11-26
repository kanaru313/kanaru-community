import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../domain/playback_views.dart';
import '../domain/seek_bar_style.dart';
import '../domain/waveform.dart';
import '../state/playback_position_provider.dart';
import '../state/playback_providers.dart';
import '../state/playback_scrub_provider.dart';
import '../state/seek_bar_style_provider.dart';
import '../state/waveform_providers.dart';
import 'playback_time_label.dart';

/// Waveform seek bar bound to the player: position in, `seek` out. Watching
/// the waveform here is what keeps the decoder busy: it runs only while one of
/// these is mounted in the waveform style. The band shows the dotted row until
/// the playing entry's status is known, then bars or the flat fallback; the flat
/// style does not watch the waveform and passes `none` (the flat track).
///
/// A hold or drag is published as [playbackScrubProvider], so the elapsed
/// labels that follow it and the spoken value show the time under the finger.
/// A seek from the bar (release, tap, keys) keeps its target there while it
/// settles, so they go straight to it instead of showing the old position
/// until the player reports the new one: until the position is within
/// [seekLandedWindow] of the target, the entry changes, or
/// [seekSettleTimeoutProvider] passes.
class PlaybackWaveformSeekBar extends ConsumerStatefulWidget {
  const PlaybackWaveformSeekBar({super.key});

  @override
  ConsumerState<PlaybackWaveformSeekBar> createState() =>
      _PlaybackWaveformSeekBarState();
}

/// A published position this close to the seek target means the seek
/// landed (the controller's own landed window).
const Duration seekLandedWindow = Duration(seconds: 1);

class _PlaybackWaveformSeekBarState
    extends ConsumerState<PlaybackWaveformSeekBar> {
  late final PlaybackScrubNotifier _scrub;

  /// The target this bar wrote while its seek settles; null otherwise.
  PlaybackScrub? _settling;
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    _scrub = ref.read(playbackScrubProvider.notifier);
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    final settling = _settling;
    if (settling != null) {
      // Not while the tree is being torn down: after the frame.
      final scrub = _scrub;
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => scrub.clear(settling),
      );
    }
    super.dispose();
  }

  void _onScrub(int? entryId, Duration? at) {
    _endSettle(clear: false);
    _scrub.report(entryId, at);
  }

  void _onSeek(int? entryId, Duration to) {
    ref.read(playerControllerProvider).seek(to);
    _endSettle(clear: false);
    _settling = _scrub.report(entryId, to);
    if (_settling != null) {
      _settleTimer = Timer(ref.read(seekSettleTimeoutProvider), _endSettle);
    }
  }

  void _onPosition(PlaybackPosition? p) {
    final settling = _settling;
    if (settling == null) return;
    if (p == null ||
        p.entryId != settling.entryId ||
        (p.position - settling.at).abs() <= seekLandedWindow) {
      _endSettle();
    }
  }

  void _endSettle({bool clear = true}) {
    _settleTimer?.cancel();
    _settleTimer = null;
    final settling = _settling;
    _settling = null;
    if (clear && settling != null) _scrub.clear(settling);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(playbackPositionProvider, (_, next) => _onPosition(next.value));
    final pos = ref.watch(playbackPositionProvider).value;
    final position = pos?.position ?? Duration.zero;
    final duration = pos?.duration;
    final positionEntry = pos?.entryId;
    final scrubbed = ref.watch(
      playbackScrubProvider.select((s) => scrubSecondsFor(s, positionEntry)),
    );
    final shown = scrubbed != null ? Duration(seconds: scrubbed) : position;
    final entry = ref.watch(nowPlayingProvider.select((n) => n.value?.entryId));
    final style = ref.watch(seekBarStyleProvider);
    final squiggle = ref.watch(squiggleSeekOptionsProvider);
    final flat = !needsWaveform(style, squiggle);
    // Not watched when no waveform is needed, so the decoder never starts for
    // a flat bar or a squiggle that does not follow the music.
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
              formatClock(shown),
              formatClock(duration),
            ),
      onScrub: (at) => _onScrub(positionEntry, at),
      onSeek: (to) => _onSeek(positionEntry, to),
    );
  }
}
