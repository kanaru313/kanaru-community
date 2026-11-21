import '../catalog/catalog.dart';
import '../package/package_limits.dart';
import 'address_rules.dart';

/// What a request is for. It decides the body cap and which address rule
/// applies: the user's own repository address, or a reference taken from a
/// catalog (which must obey the catalog's kind).
enum NetPolicy {
  /// The catalog the user typed. The address is the user's choice, so `http`
  /// is allowed for a local destination.
  repo(maxBytes: maxCatalogBytes, fromCatalog: false),

  /// A plugin zip a catalog points to.
  package(maxBytes: maxPackageBytes, fromCatalog: true),

  /// An icon a catalog points to.
  icon(maxBytes: maxIconBytes, fromCatalog: true),

  /// A link the user opens to install a package: the package rules, but the
  /// address is the user's own choice.
  link(maxBytes: maxPackageBytes, fromCatalog: false);

  const NetPolicy({required this.maxBytes, required this.fromCatalog});

  /// Body cap in bytes; reading stops as soon as it is passed.
  final int maxBytes;

  /// Whether the address came from a catalog and so is judged against the
  /// catalog's [AddressKind].
  final bool fromCatalog;
}

/// The reference check for `parseCatalog(isReferenceAllowed:)`: a reference
/// inside a catalog of [catalogKind] must pass the address rules that can be
/// applied before any lookup (scheme, user info, IP literal, local name; for a
/// public catalog also plain `http`). The connection judges it again on the
/// resolved address.
bool Function(Uri reference) isCatalogReferenceAllowed(
  AddressKind catalogKind,
) =>
    (reference) => judgeAddress(reference, catalogKind: catalogKind).isAllowed;
