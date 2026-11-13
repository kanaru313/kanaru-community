import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player_controller.dart';

/// How far the player's start has come. The player is created by the shell
/// after its first frame (never while a widget builds), then it restores the
/// saved session as its first task.
enum PlayerPhase {
  /// Nothing created the player yet: reading it now would create it during a
  /// build.
  notCreated,

  /// The player exists and still restores the saved session; it reports
  /// "nothing playing" until that is done.
  restoring,

  /// The saved session is back (or there was none). Known limit: this waits
  /// for the player's command chain to go idle, which includes the first
  /// engine load of the restored track, so it can lag the restore itself.
  ready,
}

/// Tracks [PlayerPhase]. It never creates the player: the shell does, then
/// hands it to [attach].
class PlayerPhaseNotifier extends Notifier<PlayerPhase> {
  @override
  PlayerPhase build() => PlayerPhase.notCreated;

  /// Follows [player] from creation to the end of its restore. Once only.
  Future<void> attach(PlayerController player) async {
    if (state != PlayerPhase.notCreated) return;
    state = PlayerPhase.restoring;
    // The restore is the first task of the player's chain, so this ends after
    // it. The chain never completes `settled` with an error (a failed restore
    // is logged by the player and leaves "nothing playing", which is settled).
    await player.settled();
    if (ref.mounted) state = PlayerPhase.ready;
  }
}

final playerPhaseProvider = NotifierProvider<PlayerPhaseNotifier, PlayerPhase>(
  PlayerPhaseNotifier.new,
);

/// True once the player exists, so reading what it publishes is safe in a
/// build. Starts false; the shell flips it right after the first frame.
final playerCreatedProvider = Provider<bool>(
  (ref) =>
      ref.watch(playerPhaseProvider.select((p) => p != PlayerPhase.notCreated)),
);

/// True once the player exists and the saved session is restored: what it
/// publishes now is the real state, not the empty one it starts with.
final playerReadyProvider = Provider<bool>(
  (ref) => ref.watch(playerPhaseProvider.select((p) => p == PlayerPhase.ready)),
);
