import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The time under the finger while a Now Playing waveform bar is held or
/// dragged (not cancelling), for the entry it was taken on.
class PlaybackScrub {
  const PlaybackScrub({required this.entryId, required this.at});

  final int? entryId;
  final Duration at;
}

/// Written by the Now Playing waveform bar, read by the elapsed labels that
/// follow it. Null when no scrub runs. After a committed seek the bar keeps
/// the target here until the player reports it (see
/// `PlaybackWaveformSeekBar`). A scrub of another entry than the
/// loaded one is ignored by the readers ([scrubSecondsFor]), so a track
/// change never shows the old track's time even before the bar reports the
/// end.
class PlaybackScrubNotifier extends Notifier<PlaybackScrub?> {
  @override
  PlaybackScrub? build() => null;

  /// A scrub at [at] on [entryId] runs; [at] null: it ended. Returns the
  /// value written (null when nothing was).
  PlaybackScrub? report(int? entryId, Duration? at) {
    // The bar reports its end after the frame it left the tree in, which may
    // be the frame that disposed the whole scope.
    if (!ref.mounted) return null;
    return state = at == null ? null : PlaybackScrub(entryId: entryId, at: at);
  }

  /// Ends [written] when it is still the value shown: a later scrub (another
  /// drag) is left alone.
  void clear(PlaybackScrub written) {
    if (ref.mounted && identical(state, written)) state = null;
  }
}

final playbackScrubProvider =
    NotifierProvider<PlaybackScrubNotifier, PlaybackScrub?>(
      PlaybackScrubNotifier.new,
    );

/// How long a seek target stays shown when the player never reports it (a
/// failed or slow seek): the real position shows again after it. A provider
/// so tests can shorten or lengthen it.
final seekSettleTimeoutProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// Whole seconds of [scrub] when it belongs to [entryId], else null. A
/// selector value: listeners rebuild once a second while the finger moves.
int? scrubSecondsFor(PlaybackScrub? scrub, int? entryId) =>
    scrub != null && scrub.entryId == entryId ? scrub.at.inSeconds : null;
