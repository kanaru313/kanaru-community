import 'package:material_ui/material_ui.dart';

import '../../../playback/ui/playback_waveform_seek_bar.dart';

/// Height of the seek slot on Now Playing: the waveform's track height. The
/// layouts reserve it, so the waveform replacing the flat bar moves nothing.
const double nowPlayingSeekSlotHeight = 48;

/// The seek control of Now Playing (mobile page and desktop track column): the
/// waveform bar, centred in a fixed-height slot. It repaints on its own, away
/// from the rest of the page. The mini player and the player bar keep the flat
/// bar.
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
