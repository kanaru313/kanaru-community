/// The "clean up the queue" choices.
enum CleanupKind {
  /// Repeated tracks (the first stays; the current entry always stays).
  duplicates,

  /// Entries before the current one.
  before,

  /// Entries after the current one.
  after,

  /// Everything except the current entry.
  allButCurrent,
}
