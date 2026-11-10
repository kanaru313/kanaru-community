/// Audio focus, as the player needs it. The media-controls bridge implements
/// it; Linux always grants.
abstract interface class PlaybackFocus {
  /// Asks for focus before a transition to playing. False = denied.
  Future<bool> activate();

  /// Gives focus back (stop).
  Future<void> deactivate();
}

/// Grants everything.
class AlwaysFocus implements PlaybackFocus {
  const AlwaysFocus();

  @override
  Future<bool> activate() async => true;

  @override
  Future<void> deactivate() async {}
}
