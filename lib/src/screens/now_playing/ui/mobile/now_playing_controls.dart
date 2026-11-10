import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../playback/ui/play_pause_button.dart';
import '../../../../playback/ui/playback_time_label.dart';
import '../../../../playback/ui/transport_buttons.dart';
import '../../../../playback/ui/flight_source.dart';

/// `elapsed · Previous · Play/Pause (72) · Next · total` in one row.
class NowPlayingControls extends StatelessWidget {
  const NowPlayingControls({super.key, required this.flight});

  final FlightSource flight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: KSpace.x9,
          child: PlaybackTimeLabel(textAlign: TextAlign.start),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: KSpace.x3,
            children: [
              const PreviousButton(iconSize: 32),
              FlightPieceHost(
                source: flight,
                piece: FlightPiece.play,
                child: const PlayPauseButton(
                  filled: true,
                  iconSize: 36,
                  size: 72,
                ),
              ),
              FlightPieceHost(
                source: flight,
                piece: FlightPiece.next,
                child: const NextButton(iconSize: 32),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: KSpace.x9,
          child: PlaybackTimeLabel(total: true, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
