import '../net/address_rules.dart';

/// Why adding or refreshing a repository failed. The dialog maps each to a
/// line of text.
enum RepoError {
  /// Not an absolute `http` or `https` address with a host.
  invalidUrl,

  /// A public address must use `https`.
  needsHttps,

  /// The repository is added already (add only).
  duplicate,

  /// No connection, TLS failure, dropped connection, odd answer.
  network,
  timeout,

  /// The server answered with an error status.
  badStatus,

  /// The answer is not a catalog.
  notACatalog,

  /// The catalog is over its size cap.
  tooLarge,

  /// The address broke the address rules; the result's `reason` says which.
  blocked,

  /// The caller cancelled.
  cancelled,

  /// The database refused or failed the write.
  storageFailed,
}

/// The result of adding a repository.
sealed class RepoAddResult {
  const RepoAddResult();
}

final class RepoAdded extends RepoAddResult {
  const RepoAdded(this.repoId);

  final int repoId;
}

final class RepoAddFailed extends RepoAddResult {
  const RepoAddFailed(this.error, {this.reason, this.status});

  final RepoError error;

  /// Set for [RepoError.blocked].
  final AddressProblem? reason;

  /// Set for [RepoError.badStatus].
  final int? status;
}

/// How a repository removal ended.
enum RepoRemoveResult { removed, missing, failed }

/// The outcome of refreshing one repository: [error] null means a fresh
/// catalog was stored.
class RepoRefreshResult {
  const RepoRefreshResult(this.repoId, [this.error]);

  final int repoId;
  final RepoError? error;
}
