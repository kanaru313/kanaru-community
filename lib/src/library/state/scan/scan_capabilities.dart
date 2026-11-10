/// Work a scanner does once per session after the first page is shown (the
/// incremental startup scan and the garbage collection).
///
/// A wrapper around the real scanner (a decorator, a composite) opts in by
/// implementing this and forwarding the call.
abstract interface class ScanStartupWork {
  /// Idempotent: later calls in the same session do nothing.
  void ensureStartupWork();
}

/// Where the scan that last finished came from, for readers that stay quiet
/// about scans the user did not ask for.
abstract interface class ScanOrigin {
  /// True when the scan that published the latest `ScanFinished` was asked for
  /// by a caller of `rescan` (the first-run arrow, a user rescan), false when
  /// it was the automatic startup scan.
  bool get lastFinishWasRequested;
}
