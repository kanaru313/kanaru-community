import 'package:kanaru_ui/kanaru_ui.dart' show seekBandHeight;
import 'package:material_ui/material_ui.dart';

import '../../../playback/ui/playback_waveform_seek_bar.dart';

/// Height of the seek slot on Now Playing (mobile page, desktop track column,
/// lyrics screen footer): the waveform band of kanaru_ui, one source. The
/// layouts reserve it, so no bar style, waveform state or song moves anything.
const double nowPlayingSeekSlotHeight = seekBandHeight;

/// The seek control of Now Playing (mobile page, desktop track column and the
/// lyrics screen footer): the waveform bar, centred in a fixed-height slot. It
/// repaints on its own, away from the rest of the page. The mini player and
/// the player bar keep the flat bar.
class NowPlayingSeekSlot extends StatelessWidget {
  const NowPlayingSeekSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: SizedBox(
        height: nowPlayingSeekSlotHeight,
        child: Center(child: PlaybackWaveformSeekBar()),
      ),
    );
  }
}
