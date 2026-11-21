/// Where an address leads. Decided on the numeric address a name resolved to,
/// never on the name alone. Works on raw address bytes (4 for IPv4, 16 for
/// IPv6) so the domain layer needs no `dart:io`.
enum AddressClass {
  /// Globally routable unicast: neither reserved nor private.
  public,

  /// The user's own machine or network: loopback, RFC 1918, CGNAT
  /// (`100.64.0.0/10`), link-local (`169.254.0.0/16`, `fe80::/10`),
  /// unique-local (`fc00::/7`) and the deprecated site-local (`fec0::/10`).
  local,

  /// Never a valid destination: `0.0.0.0/8`, `::`, multicast, broadcast and
  /// the reserved, documentation and transition ranges.
  ///
  /// `198.18.0.0/15` is not in this list: fake-ip proxies (Clash, mihomo,
  /// sing-box in TUN mode) answer every DNS query from that block and route
  /// the connection to the real host, so refusing it would break every public
  /// destination for those users. The block holds no real services.
  refused,

  /// Only for a set of addresses ([classifyAddresses]): the answers do not
  /// agree. Never returned for a single address.
  mixed,
}

/// The class of [bytes], 4 (IPv4) or 16 (IPv6) long; any other length is
/// refused. An IPv4-mapped IPv6 address (`::ffff:0:0/96`) and a NAT64 address
/// (`64:ff9b::/96`) take the class of the IPv4 address they carry, so
/// `::ffff:127.0.0.1` is loopback.
AddressClass classifyAddress(List<int> bytes) {
  if (bytes.length == 4) return _classifyV4(bytes);
  if (bytes.length != 16) return AddressClass.refused;
  return _classifyV6(bytes);
}

/// The class shared by every address of [addresses]: the class itself when
/// they all agree, [AddressClass.mixed] when they do not, and
/// [AddressClass.refused] when any one is refused or the list is empty. A name
/// that answers with both a public and a local address is never accepted as
/// either.
AddressClass classifyAddresses(Iterable<List<int>> addresses) {
  AddressClass? shared;
  for (final address in addresses) {
    final found = classifyAddress(address);
    if (found == AddressClass.refused) return AddressClass.refused;
    if (shared != null && shared != found) return AddressClass.mixed;
    shared = found;
  }
  return shared ?? AddressClass.refused;
}

/// The bytes of an IP literal (`host` of a `Uri`, without brackets), or null
/// when [host] is a name.
List<int>? parseIpLiteral(String host) {
  if (host.isEmpty) return null;
  try {
    if (host.contains(':')) return Uri.parseIPv6Address(host);
    return Uri.parseIPv4Address(host);
  } on FormatException {
    return null;
  }
}

const _local = AddressClass.local;
const _public = AddressClass.public;
const _refused = AddressClass.refused;

AddressClass _classifyV4(List<int> b) {
  final a = b[0];
  final second = b[1];
  final third = b[2];
  if (a == 0) return _refused; // "this network"
  if (a == 10) return _local;
  if (a == 100 && (second & 0xC0) == 64) return _local; // CGNAT
  if (a == 127) return _local;
  if (a == 169 && second == 254) return _local;
  if (a == 172 && (second & 0xF0) == 16) return _local;
  if (a == 192) {
    if (second == 168) return _local;
    if (second == 0 && (third == 0 || third == 2)) return _refused;
    if (second == 88 && third == 99) return _refused; // 6to4 relay anycast
  }
  if (a == 198 && second == 51 && third == 100) return _refused; // docs
  if (a == 203 && second == 0 && third == 113) return _refused; // docs
  // 224/4 multicast, 240/4 reserved and 255.255.255.255 broadcast.
  if (a >= 224) return _refused;
  return _public;
}

AddressClass _classifyV6(List<int> b) {
  final leadingZero = b.take(10).every((v) => v == 0);
  // ::ffff:a.b.c.d
  if (leadingZero && b[10] == 0xff && b[11] == 0xff) {
    return _classifyV4(b.sublist(12));
  }
  // 64:ff9b::a.b.c.d
  if (b[0] == 0 &&
      b[1] == 0x64 &&
      b[2] == 0xff &&
      b[3] == 0x9b &&
      b.sublist(4, 12).every((v) => v == 0)) {
    return _classifyV4(b.sublist(12));
  }
  if (b.sublist(0, 15).every((v) => v == 0) && b[15] == 1) return _local;
  // ::, IPv4-compatible and the rest of ::/8, which includes the local-use
  // NAT64 prefix 64:ff9b:1::/48: its IPv4 address sits at an offset that
  // depends on the operator's prefix length, so it cannot be read safely.
  if (b[0] == 0) return _refused;
  if (b[0] == 0xff) return _refused; // multicast
  if ((b[0] & 0xFE) == 0xFC) return _local; // fc00::/7
  if (b[0] == 0xfe && (b[1] & 0xC0) == 0x80) return _local; // fe80::/10
  if (b[0] == 0xfe && (b[1] & 0xC0) == 0xC0) return _local; // fec0::/10
  // Only 2000::/3 is global unicast; everything else is not routable.
  if ((b[0] & 0xE0) != 0x20) return _refused;
  // 2001::/23 IETF protocol assignments (Teredo, benchmarking, ORCHID).
  if (b[0] == 0x20 && b[1] == 0x01 && (b[2] & 0xFE) == 0) return _refused;
  // 2001:db8::/32 documentation.
  if (b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x0d && b[3] == 0xb8) {
    return _refused;
  }
  if (b[0] == 0x20 && b[1] == 0x02) return _refused; // 2002::/16 6to4
  // 3fff::/20 documentation.
  if (b[0] == 0x3f && b[1] == 0xff && (b[2] & 0xF0) == 0) return _refused;
  return _public;
}

const _localSuffixes = [
  '.local',
  '.lan',
  '.home.arpa',
  '.internal',
  '.localdomain',
  '.localhost',
];

/// Whether [host] is a name that, by convention, belongs to the user's own
/// network: `localhost` and the `.local`, `.lan`, `.home.arpa`, `.internal`,
/// `.localdomain` and `.localhost` zones. Case and one trailing dot are
/// ignored. A hint only: what the name resolves to decides, and a local name
/// that resolves to a public address is not trusted.
bool isLocalHostName(String host) {
  var name = host.toLowerCase();
  if (name.endsWith('.')) name = name.substring(0, name.length - 1);
  if (name == 'localhost') return true;
  return _localSuffixes.any(name.endsWith);
}
