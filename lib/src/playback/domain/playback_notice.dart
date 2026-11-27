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

/// Why an online track could not be played (track-level failures: only this
/// entry is affected and the queue moves on).
enum RemoteFailureCause {
  /// The source answered but gave no usable stream link.
  linkRefused,

  /// The stream is in a format the engine cannot play yet.
  formatUnsupported,

  /// The track no longer exists on the source.
  gone,

  /// Any other failure of one track.
  other,
}

/// The engine could not play [title]. Without [cause] it is a local file
/// failure. With one, [sourceName] names the source and [code] is a short code
/// such as `403` (never a host, URL or plugin message). The emitter supplies
/// [retry] when trying the same track again makes sense.
class TrackFailed extends PlaybackNotice {
  const TrackFailed(
    this.title, {
    this.sourceName,
    this.cause,
    this.code,
    this.retry,
  });
  final String title;
  final String? sourceName;
  final RemoteFailureCause? cause;
  final String? code;
  final void Function()? retry;
}

/// Playback paused at the same entry because a source or the network failed,
/// nothing skipped (source- and network-level failures). One notice stands for
/// the whole queue. The emitter supplies the callbacks that act on it.
sealed class PlaybackPaused extends PlaybackNotice {
  const PlaybackPaused();
}

/// The network is down: online tracks cannot play. [retry] tries again.
class PausedOffline extends PlaybackPaused {
  const PausedOffline({required this.retry});
  final void Function() retry;
}

/// The source answered 429 (a run paused). It can resume after [remaining];
/// [pauseLength] is the whole pause. [retry] resumes playback.
class PausedRateLimited extends PlaybackPaused {
  const PausedRateLimited({
    required this.sourceName,
    required this.pauseLength,
    required this.remaining,
    required this.retry,
  });
  final String sourceName;
  final Duration pauseLength;
  final Duration remaining;
  final void Function() retry;
}

/// The source's plugin needs a setting before it can play; the notice opens
/// the page of the installed plugin [installId].
class PausedNeedsConfig extends PlaybackPaused {
  const PausedNeedsConfig({required this.sourceName, required this.installId});
  final String sourceName;
  final String installId;
}

/// The source did not answer (admission busy, stream timeout, run cancelled by
/// an update or repair, runtime not ready). [retry] tries again.
class PausedSourceBusy extends PlaybackPaused {
  const PausedSourceBusy({required this.sourceName, required this.retry});
  final String sourceName;
  final void Function() retry;
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
