/// How a trigger ended.
sealed class DriverStart {
  const DriverStart();
}

/// The turn runs; [done] completes when it parks or ends (never with an
/// error: failures are reported through `onInternalError` and the state).
final class DriverStarted extends DriverStart {
  const DriverStarted(this.done, {this.userMessageId});

  final Future<void> done;

  /// The id of the message `send` stored.
  final int? userMessageId;
}

/// A turn is in flight: the trigger was dropped.
final class DriverBusy extends DriverStart {
  const DriverBusy();
}

/// The message could not be stored.
final class DriverFailed extends DriverStart {
  const DriverFailed();
}

/// The driver was disposed.
final class DriverClosed extends DriverStart {
  const DriverClosed();
}

/// What an Allow or a Deny did.
enum CardAnswer {
  /// Allowed or denied; the turn goes on.
  accepted,

  /// No such pending card (answered already, or from an older turn).
  notPending,

  /// The card was past its 24 hours and is now `expired`.
  expired,

  /// Not allowed now (the chat is read-only): the card was denied.
  refused,
}
