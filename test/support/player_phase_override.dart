import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/playback/state/player_ready.dart';

class _FixedPhase extends PlayerPhaseNotifier {
  _FixedPhase(this._phase);
  final PlayerPhase _phase;

  @override
  PlayerPhase build() => _phase;
}

/// For a test host that mounts a shell without `AppShell` and supplies its
/// own player: the player exists from the start, as it does once `AppShell`
/// has attached it. Pass [PlayerPhase.notCreated] to see the shell before.
Override playerPhaseOverride([PlayerPhase phase = PlayerPhase.ready]) =>
    playerPhaseProvider.overrideWith(() => _FixedPhase(phase));
