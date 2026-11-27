/// [url] spells a port, even the default one, which [Uri] drops (so
/// `https://a.com:443/` has no `hasPort`). IPv6 literals in brackets do not
/// count as a port.
bool writesPort(String url) {
  final start = url.indexOf('//') + 2;
  var end = url.length;
  for (final mark in const ['/', '?', '#']) {
    final at = url.indexOf(mark, start);
    if (at >= 0 && at < end) end = at;
  }
  final authority = url.substring(start, end);
  final host = authority.substring(authority.lastIndexOf('@') + 1);
  return host.replaceAll(_ipv6Literal, '').contains(':');
}

final _ipv6Literal = RegExp(r'\[[^\]]*\]');
