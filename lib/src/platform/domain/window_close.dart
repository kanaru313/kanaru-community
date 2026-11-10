/// Takes over the window close button where the engine's own exit request
/// never fires (Linux, where the window manager plugin replaces it).
abstract interface class WindowCloseGuard {
  /// On close: runs [beforeClose] (the caller caps it), then closes the window.
  /// Only the first call counts; later calls do nothing, even if the first
  /// one failed. There is no retry.
  Future<void> install(Future<void> Function() beforeClose);
}
