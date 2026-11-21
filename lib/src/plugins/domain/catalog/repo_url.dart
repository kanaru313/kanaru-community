/// The one spelling of a repository address that identifies it: lower-case
/// scheme and host, default port removed, fragment dropped, a bare root `/`
/// dropped (the request for it is the same). The rest of the path and the
/// query stay as typed (a server may tell `/catalog` from `/catalog/`).
///
/// Returns null when [input] is not an absolute `http` or `https` address
/// with a host and without user info (`user:pass@`): such an address is not a
/// repository the app will talk to.
///
/// This string is the repository identity: it is what `repoInstallId` hashes
/// and what the database keeps as the repository's address.
String? canonicalRepoUrl(String input) {
  final parsed = Uri.tryParse(input.trim());
  if (parsed == null || !parsed.hasAuthority || parsed.host.isEmpty) {
    return null;
  }
  if (parsed.userInfo.isNotEmpty) return null;
  final scheme = parsed.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  final defaultPort = scheme == 'http' ? 80 : 443;
  return Uri(
    scheme: scheme,
    host: parsed.host.toLowerCase(),
    port: parsed.hasPort && parsed.port != defaultPort ? parsed.port : null,
    path: parsed.path == '/' ? '' : parsed.path,
    query: parsed.hasQuery ? parsed.query : null,
  ).toString();
}
