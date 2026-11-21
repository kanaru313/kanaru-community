import 'address_class.dart';

/// Where a repository lives, which decides what its catalog may point to.
enum AddressKind {
  /// The catalog resolves to the user's own machine or network.
  local,

  /// The catalog resolves to the public internet.
  public,
}

/// Which address rule an address broke. The app maps each value to text.
enum AddressProblem {
  /// Not an absolute `http` or `https` URL with a host.
  invalidUrl,

  /// The URL carries a user name or password.
  userInfo,

  /// A public destination over plain `http`.
  publicNeedsHttps,

  /// A public catalog points at a local address.
  localFromPublic,

  /// The name resolves to an address no one may reach (unspecified,
  /// multicast, broadcast, documentation, reserved ranges).
  refusedAddress,

  /// The name resolves to addresses of different classes.
  mixedAddresses,

  /// A local-looking name (`nas.lan`, `localhost`) resolves to a public
  /// address, which is not what the name promises.
  localNameOnPublic,
}

/// The outcome of one check: [problem] is null when the address is allowed.
/// [kind] is the class of the destination; null when the host was not
/// resolved and so could not be told.
class AddressVerdict {
  const AddressVerdict.allowed(this.kind) : problem = null;
  const AddressVerdict.refused(this.problem) : kind = null;

  final AddressKind? kind;
  final AddressProblem? problem;

  bool get isAllowed => problem == null;
}

/// Decides whether [url] may be fetched, from what its host resolved to
/// ([addresses] as raw bytes, or null when the host was not resolved yet: then
/// only the rules that do not depend on the answer are applied).
///
/// [catalogKind] is the kind of the catalog the URL was taken from, or null
/// when [url] is the repository URL the user typed. Rules, by who chose the
/// host:
///
/// * The repository URL (user typed): `http` or `https`, IP and port allowed;
///   `http` only for a local destination, a public one needs `https`.
/// * A reference inside a catalog (`path`, `icon`, each redirect): a public
///   catalog may point only to public `https` addresses, never to a local
///   address or `http`. A local catalog may point to local addresses (any
///   scheme) and to public `https` ones (an outgoing request only).
/// * No user info; every resolved address must be of one class (a mixed
///   answer is refused); refused ranges are never allowed; a local name must
///   not resolve to a public address.
AddressVerdict judgeAddress(
  Uri url, {
  List<List<int>>? addresses,
  AddressKind? catalogKind,
}) {
  if ((url.scheme != 'http' && url.scheme != 'https') || url.host.isEmpty) {
    return const AddressVerdict.refused(AddressProblem.invalidUrl);
  }
  if (url.userInfo.isNotEmpty) {
    return const AddressVerdict.refused(AddressProblem.userInfo);
  }
  final https = url.scheme == 'https';
  final found = addresses == null
      ? _knownWithoutLookup(url.host)
      : classifyAddresses(addresses);
  switch (found) {
    case AddressClass.refused:
      return const AddressVerdict.refused(AddressProblem.refusedAddress);
    case AddressClass.mixed:
      return const AddressVerdict.refused(AddressProblem.mixedAddresses);
    case AddressClass.local:
      if (catalogKind == AddressKind.public) {
        return const AddressVerdict.refused(AddressProblem.localFromPublic);
      }
      return const AddressVerdict.allowed(AddressKind.local);
    case AddressClass.public:
      if (isLocalHostName(url.host)) {
        return const AddressVerdict.refused(AddressProblem.localNameOnPublic);
      }
      if (!https) {
        return const AddressVerdict.refused(AddressProblem.publicNeedsHttps);
      }
      return const AddressVerdict.allowed(AddressKind.public);
    case null:
      // Not resolved yet and not an IP literal or local name. Only the rule
      // that holds for every answer applies: a public catalog never points
      // to plain `http`.
      if (catalogKind == AddressKind.public && !https) {
        return const AddressVerdict.refused(AddressProblem.publicNeedsHttps);
      }
      return const AddressVerdict.allowed(null);
  }
}

/// The class of [host] when it is known without a lookup: an IP literal, or a
/// local-looking name (taken as local). Otherwise null.
AddressClass? _knownWithoutLookup(String host) {
  final literal = parseIpLiteral(host);
  if (literal != null) return classifyAddress(literal);
  if (isLocalHostName(host)) return AddressClass.local;
  return null;
}

/// The class a later request to a stored repository must obey: the stricter of
/// [stored] (the class at the last good fetch, which holds the redirect
/// narrowing) and a fresh [current] verdict on the repository address. Public
/// wins, so a name that has since started to resolve elsewhere is noticed.
/// Fails closed: a refused [current] gives null and the caller refuses the
/// request; it never falls back to [stored]. A verdict that did not resolve
/// the host (kind null) also gives null.
AddressKind? effectiveAddressKind(AddressKind stored, AddressVerdict current) {
  final fresh = current.kind;
  if (!current.isAllowed || fresh == null) return null;
  return stored == AddressKind.public || fresh == AddressKind.public
      ? AddressKind.public
      : AddressKind.local;
}
