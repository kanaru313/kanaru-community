import '../package/host_rules.dart';
import 'address_class.dart';

/// Largest response body a plugin fetch may read (4 MiB).
const pluginMaxResponseBytes = 4 * 1024 * 1024;

/// Bound for lookup, dial and TLS handshake of one plugin request.
const pluginConnectTimeout = Duration(seconds: 10);

/// The fixed pause between the request starts of one plugin.
const pluginSpacing = Duration(milliseconds: 100);

/// A `Retry-After` is read as at least this long.
const minRetryAfter = Duration(seconds: 1);

/// A `Retry-After` is read as at most this long.
const maxRetryAfter = Duration(minutes: 15);

/// Used when the answer gives no usable `Retry-After`.
const defaultRetryAfter = Duration(seconds: 60);

/// What the rules say about the URL of one request.
enum PluginUrlVerdict {
  /// Not a URL at all.
  invalid,

  /// A URL the plugin may not reach.
  blocked,

  /// May be requested (the address is still judged after the lookup).
  allowed,
}

/// [verdict] and, when allowed, the parsed [uri] (fragment removed).
class PluginUrlJudgement {
  const PluginUrlJudgement._(this.verdict, this.uri);

  const PluginUrlJudgement.invalid() : this._(PluginUrlVerdict.invalid, null);
  const PluginUrlJudgement.blocked() : this._(PluginUrlVerdict.blocked, null);
  const PluginUrlJudgement.allowed(Uri uri)
    : this._(PluginUrlVerdict.allowed, uri);

  final PluginUrlVerdict verdict;
  final Uri? uri;
}

/// Whether a plugin may request [raw], decided before any lookup.
///
/// The URL must be `https` without user info, name a host that is not an IP
/// literal and not a local-looking name, and carry no explicit port. Then the
/// host (no port) must be covered by both [manifestHosts] and
/// [consentedHosts]; failing that, host and port must equal those of a value
/// the user saved in a `format: url` field ([userEndpoints]), which may carry
/// a port. Nothing else is allowed.
PluginUrlJudgement judgePluginUrl(
  String raw, {
  required Set<String> manifestHosts,
  required Set<String> consentedHosts,
  required Set<String> userEndpoints,
}) {
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
    return const PluginUrlJudgement.invalid();
  }
  if (!_isPublicHttpsName(uri)) return const PluginUrlJudgement.blocked();
  final host = uri.host;
  final covered =
      !uri.hasPort &&
      hostSetCovers(consentedHosts, [host]) &&
      hostSetCovers(manifestHosts, [host]);
  if (covered || _isUserEndpoint(uri, userEndpoints)) {
    return PluginUrlJudgement.allowed(uri.removeFragment());
  }
  return const PluginUrlJudgement.blocked();
}

/// `https`, no user info, a real public-looking name, a usable port.
bool _isPublicHttpsName(Uri uri) {
  if (uri.scheme != 'https' || uri.userInfo.isNotEmpty) return false;
  final host = uri.host;
  if (parseIpLiteral(host) != null) return false;
  // A public name has at least two labels; `localhost`, `nas.lan` and the
  // like are refused here, and what a name resolves to is judged later.
  if (!_hostName.hasMatch(host)) return false;
  if (isLocalHostName(host)) return false;
  return uri.port >= 1 && uri.port <= 65535;
}

// Letters, digits and hyphens in at least two dot-separated labels: no `*`,
// no trailing dot, no single-label name.
final _hostName = RegExp(
  r'^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$',
);

bool _isUserEndpoint(Uri request, Set<String> endpoints) {
  for (final saved in endpoints) {
    final uri = Uri.tryParse(saved);
    if (uri == null || !uri.hasAuthority || !_isPublicHttpsName(uri)) continue;
    if (uri.host == request.host && uri.port == request.port) return true;
  }
  return false;
}

/// Request headers a script may not set: the host owns them.
const _droppedHeaders = {
  'accept-encoding',
  'host',
  'connection',
  'content-length',
  'transfer-encoding',
  'te',
  'upgrade',
  'keep-alive',
  'trailer',
  'expect',
};

// RFC 9110 token.
final _tokenName = RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

bool _validValue(String value) {
  for (final unit in value.codeUnits) {
    // ASCII only, no control character (CR and LF included) except tab, no DEL.
    if ((unit < 0x20 && unit != 0x09) || unit >= 0x7f) return false;
  }
  return true;
}

/// Shorter values are not masked: they would blank ordinary log text.
const _minSecretLength = 8;

/// The headers to send for the script's [requested] ones, and the values to
/// hide in logs.
class PluginRequestHeaders {
  const PluginRequestHeaders(this.headers, this.secrets);

  /// Lower-case names; names that differ only in case keep the last value.
  final Map<String, String> headers;

  /// Values of `authorization`, `cookie` and names holding `token` or `key`.
  final Set<String> secrets;
}

/// Applies the header rules to [requested]; null when a name is not an RFC
/// 9110 token or a value has a control or non-ASCII character (the request is
/// invalid, nothing is sent). Dropped names are removed silently (`host`,
/// `content-length`, `accept-encoding`, every `proxy-*` and the like).
PluginRequestHeaders? pluginRequestHeaders(List<(String, String)> requested) {
  final headers = <String, String>{};
  for (final (rawName, value) in requested) {
    final name = rawName.toLowerCase();
    if (!_tokenName.hasMatch(name) || !_validValue(value)) return null;
    if (_droppedHeaders.contains(name) || name.startsWith('proxy-')) continue;
    headers[name] = value;
  }
  final secrets = <String>{};
  for (final MapEntry(key: name, value: value) in headers.entries) {
    if (value.length < _minSecretLength) continue;
    if (name == 'authorization' ||
        name == 'cookie' ||
        name.contains('token') ||
        name.contains('key')) {
      secrets.add(value);
      // The credential alone, without its scheme ("Bearer abc").
      final space = value.indexOf(' ');
      if (name == 'authorization' &&
          space > 0 &&
          value.length - space - 1 >= _minSecretLength) {
        secrets.add(value.substring(space + 1));
      }
    }
  }
  return PluginRequestHeaders(headers, secrets);
}

/// The part of a `Set-Cookie` value worth hiding: the whole line and its
/// `name=value` pair, when long enough to be a secret.
Set<String> setCookieSecrets(String value) {
  final out = <String>{};
  if (value.length >= _minSecretLength) out.add(value);
  final pair = value.split(';').first.trim();
  if (pair.length >= _minSecretLength) out.add(pair);
  return out;
}

/// Whether every address of one DNS answer is globally routable: the check
/// of plugin traffic, which never reaches the user's own network. Mixed
/// answers, local, reserved and empty answers fail. `198.18.0.0/15` counts as
/// public (fake-ip proxies), IPv4-mapped and NAT64 addresses take the class
/// of the IPv4 address they carry.
bool isPublicOnly(Iterable<List<int>> addresses) =>
    classifyAddresses(addresses) == AddressClass.public;

/// The wait a `Retry-After` header asks for, clamped to
/// [minRetryAfter] .. [maxRetryAfter]; [defaultRetryAfter] when [value] is
/// missing or neither seconds nor an HTTP date (`Sun, 06 Nov 1994 08:49:37
/// GMT`). [now] is the clock for the date form.
Duration parseRetryAfter(String? value, {DateTime? now}) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return defaultRetryAfter;
  Duration? wait;
  if (RegExp(r'^\d+$').hasMatch(text)) {
    final seconds = int.tryParse(text);
    // Too many digits for an int is far beyond the cap.
    wait = seconds == null ? maxRetryAfter : _seconds(seconds);
  } else {
    final at = _parseHttpDate(text);
    if (at != null) wait = at.difference((now ?? DateTime.now()).toUtc());
  }
  if (wait == null) return defaultRetryAfter;
  if (wait < minRetryAfter) return minRetryAfter;
  if (wait > maxRetryAfter) return maxRetryAfter;
  return wait;
}

Duration _seconds(int seconds) => seconds > maxRetryAfter.inSeconds
    ? maxRetryAfter
    : Duration(seconds: seconds);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

final _httpDate = RegExp(
  r'^[A-Za-z]{3}, (\d{2}) ([A-Za-z]{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
);

/// The IMF-fixdate form, the one servers send.
DateTime? _parseHttpDate(String text) {
  final m = _httpDate.firstMatch(text);
  if (m == null) return null;
  final month = _months.indexOf(m[2]!);
  if (month < 0) return null;
  final parts = [
    for (final i in [3, 1, 4, 5, 6]) int.parse(m[i]!),
  ];
  final (year, day, hour, minute, second) = (
    parts[0],
    parts[1],
    parts[2],
    parts[3],
    parts[4],
  );
  final date = DateTime.utc(year, month + 1, day, hour, minute, second);
  // `DateTime.utc` rolls 31 Feb or 99:99:99 over: such a date is no date.
  final same =
      date.day == day &&
      date.hour == hour &&
      date.minute == minute &&
      date.second == second &&
      date.month == month + 1;
  return same ? date : null;
}
