import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/domain/seek_bar_style.dart';
import '../../../../playback/state/seek_bar_style_provider.dart';
import '../../../../playback/ui/playback_time_label.dart';
import 'seek_bar_preview_clock.dart';
import 'seek_bar_previews.dart';

/// A seek bar of [style] at the stored options of its group, moved by
/// [clock], with the elapsed and total time under it. Touch, drag, drag up to
/// cancel and the keys seek the pretend clock; nothing reaches the player.
/// While a finger holds the bar the elapsed time follows it and the clock
/// waits. Used by the preview block and by the customise sheet.
class SeekDemoBar extends ConsumerStatefulWidget {
  const SeekDemoBar({super.key, required this.clock, required this.style});

  final SeekPreviewClock clock;
  final SeekBarStyle style;

  @override
  ConsumerState<SeekDemoBar> createState() => _SeekDemoBarState();
}

class _SeekDemoBarState extends ConsumerState<SeekDemoBar> {
  Duration? _scrub;

  void _onScrub(Duration? at) {
    widget.clock.hold(at != null);
    setState(() => _scrub = at);
  }

  @override
  void dispose() {
    widget.clock.hold(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final wave = ref.watch(waveSeekOptionsProvider);
    final squiggle = ref.watch(squiggleSeekOptionsProvider);
    final flat = ref.watch(flatSeekOptionsProvider);
    return ListenableBuilder(
      listenable: widget.clock,
      builder: (context, _) {
        final clock = widget.clock;
        final shown = _scrub ?? clock.position;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: seekBandHeight,
              child: buildSeekStyleBar(
                style: widget.style,
                position: clock.position,
                duration: clock.duration,
                onSeek: clock.seekTo,
                wave: wave,
                squiggle: squiggle,
                flat: flat,
                playing: clock.playing,
                semanticLabel: l10n.playbackSeek,
                semanticValue: l10n.playbackPositionValue(
                  formatClock(shown),
                  formatClock(clock.duration),
                ),
                bubbleLabel: formatClock,
                cancelLabel: l10n.playbackSeekCancel,
                onScrub: _onScrub,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatClock(shown), style: text),
                  Text(formatClock(clock.duration), style: text),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The "Xem trước" block of the seek bar page: the chosen style on the pretend
/// clock, a small play / pause button and the one line that says how to try
/// seeking.
class SeekPreviewCard extends ConsumerWidget {
  const SeekPreviewCard({super.key, required this.clock});

  final SeekPreviewClock clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = ref.watch(seekBarStyleProvider);
    return Material(
      color: scheme.surfaceContainerLow,
      shape: KShape.of(KRadius.lg),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x3,
          KSpace.x3,
          KSpace.x3,
          KSpace.x2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SeekDemoBar(clock: clock, style: style),
            const KGap(6),
            Row(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: clock.playingListenable,
                  // The filled disc of the Now Playing button, 40 dp.
                  builder: (context, playing, _) => KIconButton.yieldSpace(
                    child: IconButton.filled(
                      icon: Icon(playing ? KIcons.pause : KIcons.play),
                      style: IconButton.styleFrom(
                        fixedSize: const Size.square(40),
                      ),
                      tooltip: playing ? l10n.playbackPause : l10n.playbackPlay,
                      onPressed: clock.togglePlaying,
                    ),
                  ),
                ),
                const KGap(KSpace.x3),
                Expanded(
                  child: Text(
                    l10n.settingsSeekBarPreviewHint,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
