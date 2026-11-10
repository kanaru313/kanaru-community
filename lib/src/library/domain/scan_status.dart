/// What the library scan is doing, for the scan card and banners.
sealed class ScanStatus {
  const ScanStatus();
}

final class ScanIdle extends ScanStatus {
  const ScanIdle();
}

enum ScanPhase { listing, tags, covers }

final class ScanRunning extends ScanStatus {
  const ScanRunning({
    required this.phase,
    required this.done,
    required this.total,
  });

  final ScanPhase phase;
  final int done;

  /// 0 = not known yet.
  final int total;
}

final class ScanFinished extends ScanStatus {
  const ScanFinished({
    required this.tracks,
    required this.albums,
    required this.artists,
    required this.added,
    required this.at,
  });

  final int tracks;
  final int albums;
  final int artists;

  /// Tracks new since the previous scan.
  final int added;
  final DateTime at;
}

final class ScanFailed extends ScanStatus {
  const ScanFailed(this.kind);

  /// Error kind, e.g. `permission`, `io`; the UI maps it to a message.
  final String kind;
}

/// What other modules may ask the scanner to do.
abstract interface class LibraryScanCommands {
  /// Asks for a scan of every enabled folder; [full] re-reads files that did
  /// not change. A scan already running absorbs the request. Completes once
  /// the request is accepted or queued; never waits for the scan to finish.
  /// Failures surface through `scanStatusProvider` (`ScanFailed`), never as a
  /// thrown error.
  Future<void> rescan({bool full = false});
}
