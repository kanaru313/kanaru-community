/// How the queue continues at the end of an entry or of the queue.
enum RepeatMode {
  /// Stop after the last entry.
  off,

  /// Wrap to the first entry in play order.
  all,

  /// Play the current entry again (automatic advance only).
  one,
}
