import 'package:flutter/painting.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media/domain/cover_colors.dart';
import 'cover_providers.dart';
import 'player_ready.dart';
import 'playback_providers.dart';
import 'track_info_providers.dart';

/// Colours of the cover of what plays now, with the difference between "not
/// known yet" and "known to be none".
sealed class PlayingCoverColors {
  const PlayingCoverColors();

  /// The tint palette: the cover's colours when known, else null.
  List<Color>? get palette => switch (this) {
    PlayingCoverColorsFound(:final colors) => [
      for (final c in colors.palette) Color(c),
    ],
    _ => null,
  };

  /// Not settled yet: a tint keeps what it showed.
  bool get isPending => this is PlayingCoverColorsPending;
}

/// Not settled: the player is not ready, the session restore is not done, or a
/// step of track, track info, cover colours is still loading. Consumers keep
/// what they showed before.
class PlayingCoverColorsPending extends PlayingCoverColors {
  const PlayingCoverColorsPending();

  @override
  bool operator ==(Object other) => other is PlayingCoverColorsPending;

  @override
  int get hashCode => (PlayingCoverColorsPending).hashCode;
}

/// The playing cover has colours.
class PlayingCoverColorsFound extends PlayingCoverColors {
  const PlayingCoverColorsFound(this.colors);

  final CoverColors colors;

  @override
  bool operator ==(Object other) =>
      other is PlayingCoverColorsFound && other.colors == colors;

  @override
  int get hashCode => colors.hashCode;
}

/// Settled with no colours: nothing plays, no cover, a gray cover, or colours
/// not computed (yet) by the scanner.
class PlayingCoverColorsNone extends PlayingCoverColors {
  const PlayingCoverColorsNone();

  @override
  bool operator ==(Object other) => other is PlayingCoverColorsNone;

  @override
  int get hashCode => (PlayingCoverColorsNone).hashCode;
}

/// Colours of the playing cover. Built by watching the chain
/// track id -> track info -> cover colours, so when the track changes the
/// subscriptions of the old track are dropped and a late answer for a skipped
/// track can never reach the result.
///
/// Reading it before the player exists does not create the player: it stays
/// [PlayingCoverColorsPending] until [playerReadyProvider] is true.
final playingCoverColorsProvider = Provider<PlayingCoverColors>((ref) {
  const pending = PlayingCoverColorsPending();
  if (!ref.watch(playerReadyProvider)) return pending;

  final now = ref.watch(
    nowPlayingProvider.select(
      (n) => (
        // An error is settled too: nothing can be shown for it.
        settled: n.hasValue || n.hasError,
        id: n.value?.trackId,
      ),
    ),
  );
  if (!now.settled) return pending;
  final id = now.id;
  if (id == null) return const PlayingCoverColorsNone();

  final info = ref.watch(
    trackInfoProvider(id).select(
      (a) => (
        settled: a.hasValue || a.hasError,
        // Only an answer about the track that plays now counts.
        coverKey: a.value?.id == id ? a.value?.coverKey : null,
      ),
    ),
  );
  if (!info.settled) return pending;
  final coverKey = info.coverKey;
  if (coverKey == null) return const PlayingCoverColorsNone();

  final colors = ref.watch(coverColorsProvider(coverKey));
  if (!colors.hasValue && !colors.hasError) return pending;
  final value = colors.value;
  return value == null
      ? const PlayingCoverColorsNone()
      : PlayingCoverColorsFound(value);
});
