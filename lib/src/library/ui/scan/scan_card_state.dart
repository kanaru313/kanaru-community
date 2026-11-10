import '../../domain/scan_status.dart';

/// How long a finished scan stays worth announcing.
const Duration scanSummaryFreshness = Duration(seconds: 10);

/// How long the finished card stays on screen.
const Duration scanSummaryVisible = Duration(seconds: 4);

/// What the Home scan card shows for a [ScanStatus].
sealed class ScanCardState {
  const ScanCardState();
}

/// Nothing to show (idle, listing, failed, stale, or nothing new).
final class ScanCardHidden extends ScanCardState {
  const ScanCardHidden();
}

/// Reading tags or covers. [progress] runs 0..1 over both phases and never
/// goes back when the tag phase hands over to the cover phase.
final class ScanCardProgress extends ScanCardState {
  const ScanCardProgress({
    required this.done,
    required this.total,
    required this.progress,
  });

  final int done;
  final int total;
  final double progress;
}

/// A fresh scan that added tracks.
final class ScanCardAdded extends ScanCardState {
  const ScanCardAdded({
    required this.finished,
    required this.added,
    required this.albums,
    required this.artists,
  });

  /// The status this card announces; identifies the announcement.
  final ScanFinished finished;
  final int added;
  final int albums;
  final int artists;
}

/// A fresh scan that found no track at all.
final class ScanCardNoTracks extends ScanCardState {
  const ScanCardNoTracks({required this.finished});

  final ScanFinished finished;
}

/// Maps a status to the card. [announceEmpty] says the finished scan was asked
/// for (first run, a user rescan). A scan that only checked a library that did
/// not change stays invisible: the card appears only once there is a total to
/// read, and a summary only when something was added.
ScanCardState scanCardStateOf(
  ScanStatus? status,
  DateTime now, {
  bool announceEmpty = false,
}) {
  switch (status) {
    case ScanRunning(:final phase, :final done, :final total)
        when total > 0 &&
            (phase == ScanPhase.tags || phase == ScanPhase.covers):
      final fraction = (done / total).clamp(0.0, 1.0);
      final progress = phase == ScanPhase.tags
          ? fraction / 2
          : 0.5 + fraction / 2;
      return ScanCardProgress(done: done, total: total, progress: progress);
    case ScanFinished finished when _isFresh(finished, now):
      if (finished.tracks == 0) {
        // Only for a scan somebody asked for: the startup scan of an empty
        // library stays quiet.
        return announceEmpty
            ? ScanCardNoTracks(finished: finished)
            : const ScanCardHidden();
      }
      if (finished.added > 0) {
        return ScanCardAdded(
          finished: finished,
          added: finished.added,
          albums: finished.albums,
          artists: finished.artists,
        );
      }
      return const ScanCardHidden();
    default:
      return const ScanCardHidden();
  }
}

bool _isFresh(ScanFinished finished, DateTime now) =>
    now.difference(finished.at) < scanSummaryFreshness;

/// The announced status of a finished state, null for the others.
ScanFinished? finishedOf(ScanCardState state) => switch (state) {
  ScanCardAdded(:final finished) => finished,
  ScanCardNoTracks(:final finished) => finished,
  _ => null,
};
