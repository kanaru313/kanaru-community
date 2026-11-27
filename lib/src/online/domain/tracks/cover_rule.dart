import '../../../plugins/domain/net/plugin_fetch_rules.dart';
import '../contract/contract_limits.dart';

/// Query parameter names (lower case) that carry a credential or a signature.
/// A link with one of them is never stored.
const coverSecretParams = {
  't',
  's',
  'p',
  'u',
  'token',
  'key',
  'sig',
  'signature',
  'auth',
  'apikey',
  'api_key',
  'access_token',
  'password',
};

/// [url] when it may be kept in a stored row, else null.
///
/// Kept only when the link is `https` to a public name the plugin's manifest
/// lists (a host the user typed never qualifies), writes no port, no
/// fragment, and carries no credential: no query parameter named in
/// [coverSecretParams] and no query value or path segment equal to a
/// non-empty value of the plugin's own settings ([configValues]).
String? persistableCoverUrl(
  String? url, {
  required Set<String> manifestHosts,
  required Iterable<String> configValues,
}) {
  if (url == null || url.length > maxLinkChars) return null;
  final judged = judgePluginUrl(
    url,
    manifestHosts: manifestHosts,
    consentedHosts: manifestHosts,
    userEndpoints: const {},
  );
  if (judged.verdict != PluginUrlVerdict.allowed) return null;
  final uri = judged.uri!;
  if (_writesPort(url) || url.contains('#')) return null;
  final secrets = {
    for (final v in configValues)
      if (v.isNotEmpty) v,
  };
  for (final entry in uri.queryParametersAll.entries) {
    if (coverSecretParams.contains(entry.key.toLowerCase())) return null;
    if (entry.value.any(secrets.contains)) return null;
  }
  if (uri.pathSegments.any(secrets.contains)) return null;
  return url;
}

/// The authority spells a port, even the default one that [Uri] drops.
bool _writesPort(String url) {
  final start = url.indexOf('//') + 2;
  var end = url.length;
  for (final mark in const ['/', '?', '#']) {
    final at = url.indexOf(mark, start);
    if (at >= 0 && at < end) end = at;
  }
  final authority = url.substring(start, end);
  final host = authority.substring(authority.lastIndexOf('@') + 1);
  return host.replaceAll(RegExp(r'\[[^\]]*\]'), '').contains(':');
}
