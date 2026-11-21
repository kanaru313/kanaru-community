import '../../../foundation/result.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/catalog_parser.dart';
import '../../domain/install/repo_results.dart';
import '../../domain/net/address_rules.dart';
import '../../domain/net/cancel_token.dart';
import '../../domain/net/fetch_failure.dart';
import '../../domain/net/net_policy.dart';
import '../net/fetcher.dart';
import 'catalog_codec.dart';

/// A catalog fetched and parsed, in the form the repository row stores.
class FetchedCatalog {
  const FetchedCatalog({
    required this.catalog,
    required this.stored,
    required this.kind,
  });

  final Catalog catalog;

  /// `encodeCatalog(catalog)`.
  final String stored;

  /// The address class the fetch ended with (`public` once any hop was
  /// public).
  final AddressKind kind;
}

/// The error of a failed catalog fetch with its details.
class CatalogFetchError {
  const CatalogFetchError(this.error, {this.reason, this.status});

  final RepoError error;
  final AddressProblem? reason;
  final int? status;
}

/// Fetches [url] under the `repo` policy and parses the answer with the
/// address rules of the class the fetch ended with. Never throws.
Future<Result<FetchedCatalog, CatalogFetchError>> fetchCatalog(
  HttpFetcher fetcher,
  Uri url, {
  CancelToken? cancel,
}) async {
  final Result<FetchResult, FetchFailure> got;
  try {
    got = await fetcher.get(url, NetPolicy.repo, cancel: cancel);
  } on Object {
    return const Err(CatalogFetchError(RepoError.network));
  }
  switch (got) {
    case Err(:final error):
      return Err(_asError(error));
    case Ok(:final value):
      final fetched = value;
      return switch (parseCatalog(
        fetched.bytes,
        fetched.finalUrl,
        isReferenceAllowed: isCatalogReferenceAllowed(fetched.kind),
      )) {
        Ok(:final value) => Ok(
          FetchedCatalog(
            catalog: value,
            stored: encodeCatalog(value),
            kind: fetched.kind,
          ),
        ),
        Err(:final error) => Err(
          CatalogFetchError(
            error == CatalogProblem.tooLarge
                ? RepoError.tooLarge
                : RepoError.notACatalog,
          ),
        ),
      };
  }
}

CatalogFetchError _asError(FetchFailure failure) => switch (failure.kind) {
  FetchFailureKind.network => const CatalogFetchError(RepoError.network),
  FetchFailureKind.timeout => const CatalogFetchError(RepoError.timeout),
  FetchFailureKind.tooLarge => const CatalogFetchError(RepoError.tooLarge),
  FetchFailureKind.invalidUrl => const CatalogFetchError(RepoError.invalidUrl),
  FetchFailureKind.cancelled => const CatalogFetchError(RepoError.cancelled),
  FetchFailureKind.badStatus => CatalogFetchError(
    RepoError.badStatus,
    status: failure.status,
  ),
  FetchFailureKind.blockedAddress =>
    failure.reason == AddressProblem.publicNeedsHttps
        ? const CatalogFetchError(RepoError.needsHttps)
        : CatalogFetchError(RepoError.blocked, reason: failure.reason),
};
