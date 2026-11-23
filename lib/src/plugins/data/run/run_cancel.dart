import '../../domain/net/cancel_token.dart';

/// A caller's request to stop a run. `cancel()` is idempotent; a run that has
/// not been dispatched yet never starts, a running one is cancelled in the
/// runtime.
final class RunCancel extends CancelToken {}
