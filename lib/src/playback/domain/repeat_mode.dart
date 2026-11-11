/// How the queue continues at the end of an entry or of the queue. This is the
/// base mode; a counted repeat (the current entry N more times) sits on top of
/// it and is kept apart by the controller.
enum RepeatMode {
  /// Stop after the last entry.
  off,

  /// Wrap to the first entry in play order.
  all,

  /// Play the current entry again, endlessly (automatic advance only).
  one,

  /// Wrap like [all], and every pass is a fresh random order of the whole
  /// queue (shuffle turns on).
  allShuffled;

  /// Going on past the last entry returns to the first.
  bool get wrapsQueue => this == all || this == allShuffled;
}

/// Most extra plays of the current entry a counted repeat can ask for.
const maxRepeatTimes = 99;
