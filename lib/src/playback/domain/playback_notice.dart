import 'playable.dart';

/// Something the player wants the user to hear about once (a toast).
sealed class PlaybackNotice {
  const PlaybackNotice();
}

/// [count] entries were skipped in a row; [title] and [reason] are the first.
class TrackSkipped extends PlaybackNotice {
  const TrackSkipped(this.title, this.reason, this.count);
  final String title;
  final UnplayableReason reason;
  final int count;
}

/// The engine could not play [title].
class TrackFailed extends PlaybackNotice {
  const TrackFailed(this.title);
  final String title;
}

/// Previous at the first entry.
class FirstTrack extends PlaybackNotice {
  const FirstTrack();
}

/// Next at the last entry, or playback reached the end.
class QueueEnd extends PlaybackNotice {
  const QueueEnd();
}

/// Play with nothing queued.
class QueueEmpty extends PlaybackNotice {
  const QueueEmpty();
}

/// The system refused audio focus; playback stays paused.
class FocusDenied extends PlaybackNotice {
  const FocusDenied();
}
