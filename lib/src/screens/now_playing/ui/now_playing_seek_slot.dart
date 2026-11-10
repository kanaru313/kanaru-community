import 'package:material_ui/material_ui.dart';

import '../../../playback/ui/playback_time_label.dart';

/// Height of the seek slot on Now Playing: the waveform's track height. The
/// layouts reserve it, so swapping the flat bar for the waveform moves
/// nothing.
const double nowPlayingSeekSlotHeight = 48;

/// The seek control of Now Playing (mobile page and desktop track column),
/// centred in a fixed-height slot. It repaints on its own, away from the
/// rest of the page.
class NowPlayingSeekSlot extends StatelessWidget {
  const NowPlayingSeekSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: SizedBox(
        height: nowPlayingSeekSlotHeight,
        child: Center(child: PlaybackSeekBar()),
      ),
    );
  }
}
