import 'dart:typed_data';

import 'address_rules.dart';

/// Why a fetch failed. The domain holds no UI text: the app maps a kind (plus
/// [FetchFailure.reason] or [FetchFailure.status]) to a message.
enum FetchFailureKind {
  /// No connection, TLS failure (an untrusted certificate included), a
  /// dropped connection, too many redirects, or a malformed answer.
  network,

  /// The connect or total time limit passed.
  timeout,

  /// The body is over its cap.
  tooLarge,

  /// The address broke the address rules; [FetchFailure.reason] says which.
  /// Nothing was sent to the refused address.
  blockedAddress,

  /// The server answered with a status that is not 2xx (and not a followed
  /// redirect); [FetchFailure.status] holds it.
  badStatus,

  /// Not an absolute `http` or `https` URL with a host.
  invalidUrl,

  /// The caller cancelled the fetch.
  cancelled,
}

/// A failed fetch. Carries no address, header or body, so it is safe to log.
class FetchFailure implements Exception {
  const FetchFailure(this.kind, {this.reason, this.status});

  /// A refusal by the address rules; an invalid URL keeps its own kind.
  factory FetchFailure.blocked(AddressProblem problem) =>
      problem == AddressProblem.invalidUrl
      ? const FetchFailure(FetchFailureKind.invalidUrl)
      : FetchFailure(FetchFailureKind.blockedAddress, reason: problem);

  final FetchFailureKind kind;

  /// Set for [FetchFailureKind.blockedAddress].
  final AddressProblem? reason;

  /// Set for [FetchFailureKind.badStatus].
  final int? status;

  @override
  String toString() =>
      'FetchFailure(${kind.name}'
      '${reason == null ? '' : ', ${reason!.name}'}'
      '${status == null ? '' : ', $status'})';
}

/// A fetched body. [finalUrl] is where it came from after redirects (relative
/// references in a catalog resolve against it) and [kind] the class the
/// catalog it belongs to must now obey: `public` once any hop was public.
class FetchResult {
  const FetchResult({
    required this.bytes,
    required this.finalUrl,
    required this.kind,
  });

  final Uint8List bytes;
  final Uri finalUrl;
  final AddressKind kind;
}
