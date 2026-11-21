export 'wildcard_denylist.dart';
import 'wildcard_denylist.dart';

/// The prefix of a wildcard host entry: `*.` + a base host name.
const hostWildcardPrefix = '*.';

/// Most wildcard entries one plugin may list.
const maxHostWildcards = 10;

final _hostChars = RegExp(r'^[a-z0-9.-]+$');
final _digits = RegExp(r'^\d+$');
final _alphaStart = RegExp(r'^[a-z]');

/// One DNS label a wildcard may stand for: 1 to 63 of `[a-z0-9-]`, not
/// starting or ending with `-`.
final _label = RegExp(r'^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$');

const _localSuffixes = [
  '.localhost',
  '.local',
  '.internal',
  '.lan',
  '.home.arpa',
  '.localdomain',
  '.test',
  '.invalid',
  '.example',
  '.onion',
  '.corp',
  '.home',
  '.intranet',
];

/// Why [host] may not be a plugin host, or null when it may. Only a public
/// DNS name passes: no scheme, port or path, no IP literal, no
/// single-label or local name. A public name may still resolve to a private
/// address: resolved addresses are checked when a request is made.
String? publicHostProblem(String host) {
  if (!_hostChars.hasMatch(host)) return 'not a plain host name';
  final labels = host.split('.');
  if (host.length > 253) return 'host name too long';
  if (labels.length < 2) return 'single-label host';
  if (labels.any((l) => l.length > 63)) return 'label too long';
  if (labels.any((l) => l.isEmpty || l.startsWith('-') || l.endsWith('-'))) {
    return 'malformed label';
  }
  if (_digits.hasMatch(labels.last)) return 'IP address';
  // Top-level domains are alphabetic (or `xn--`): this refuses numeric
  // spellings a resolver may read as an address, such as `127.0.0.0x1`.
  if (!_alphaStart.hasMatch(labels.last)) return 'numeric top label';
  if (_localSuffixes.any(host.endsWith)) return 'local name';
  return null;
}

/// Why [pattern] may not be a host entry, or null when it may: a plain public
/// name, or `*.` followed by one (so the base has at least two labels). A `*`
/// anywhere else is refused. The deny list and the per-plugin rules are
/// checked by [hostListProblem].
String? hostPatternProblem(String pattern) {
  if (pattern.startsWith(hostWildcardPrefix)) {
    final base = pattern.substring(hostWildcardPrefix.length);
    if (base.contains('*')) return 'wildcard must be a leading *. label';
    return publicHostProblem(base);
  }
  if (pattern.contains('*')) return 'wildcard must be a leading *. label';
  return publicHostProblem(pattern);
}

/// Why a host entry of a plugin may not be listed.
enum HostRefusal {
  /// Not a public DNS name (an IP, `localhost`, a single label...).
  notPublic,

  /// A `*` that is not one leading `*.` label over a public name.
  badWildcard,

  /// A wildcard in a plugin that is not a streaming plugin.
  wildcardNotAllowed,

  /// A wildcard over a shared-hosting suffix ([deniedWildcardBases]) or a
  /// country registry name such as `co.uk`.
  sharedHostingWildcard,

  /// More than [maxHostWildcards] distinct wildcard entries.
  tooManyWildcards,
}

/// The first entry of [hosts] that may not be listed, with the reason, or
/// null when every entry may. [hosts] are expected trimmed and lower-cased.
///
/// Each entry must pass [hostPatternProblem]. Wildcards are refused unless
/// [wildcardsAllowed], a wildcard base may not be denied by
/// [wildcardBaseDenied],
/// and at most [maxHostWildcards] distinct wildcards are allowed; the entry
/// reported for that is the first one over the cap.
({String entry, HostRefusal reason})? hostListProblem(
  List<String> hosts, {
  required bool wildcardsAllowed,
}) {
  final wildcards = <String>{};
  for (final entry in hosts) {
    if (hostPatternProblem(entry) != null) {
      final reason = entry.contains('*')
          ? HostRefusal.badWildcard
          : HostRefusal.notPublic;
      return (entry: entry, reason: reason);
    }
    if (!entry.startsWith(hostWildcardPrefix)) continue;
    if (!wildcardsAllowed) {
      return (entry: entry, reason: HostRefusal.wildcardNotAllowed);
    }
    final base = entry.substring(hostWildcardPrefix.length);
    if (wildcardBaseDenied(base)) {
      return (entry: entry, reason: HostRefusal.sharedHostingWildcard);
    }
    wildcards.add(entry);
    if (wildcards.length > maxHostWildcards) {
      return (entry: entry, reason: HostRefusal.tooManyWildcards);
    }
  }
  return null;
}

/// One entry of a plugin's `hosts`: a plain public name or a `*.` wildcard.
final class HostPattern {
  const HostPattern._(this.entry, this._wildcardBase);

  /// The entry as written (lower-case).
  final String entry;
  final String? _wildcardBase;

  /// The entry as a pattern, or null when it is not a valid one: a bad name,
  /// a `*` anywhere but a leading `*.`, or a wildcard over a shared-hosting
  /// suffix. [entry] is expected trimmed and lower-cased.
  static HostPattern? tryParse(String entry) {
    if (hostPatternProblem(entry) != null) return null;
    if (!entry.startsWith(hostWildcardPrefix)) {
      return HostPattern._(entry, null);
    }
    final base = entry.substring(hostWildcardPrefix.length);
    if (wildcardBaseDenied(base)) return null;
    return HostPattern._(entry, base);
  }

  bool get isWildcard => _wildcardBase != null;

  /// Whether a request to [host] (a URI's host) matches this entry.
  ///
  /// [host] is lower-cased first and one ending with `.` never matches. A
  /// plain entry matches by equality. A wildcard matches exactly one label
  /// (`[a-z0-9-]{1,63}`, no leading or trailing `-`) in front of its base:
  /// the apex itself and names two or more labels below it do not match.
  bool matches(String host) {
    final name = host.toLowerCase();
    if (name.isEmpty || name.endsWith('.')) return false;
    final base = _wildcardBase;
    if (base == null) return name == entry;
    final dot = name.indexOf('.');
    if (dot <= 0) return false;
    return name.substring(dot + 1) == base &&
        _label.hasMatch(name.substring(0, dot));
  }
}

/// Whether every entry of [candidate] is already allowed by [consented].
///
/// Both are host entry lists as stored (plain names and `*.` wildcards). An
/// entry is covered when [consented] lists it exactly, or when it is a plain
/// name that a consented wildcard matches (the user already agreed to every
/// name one label under that base). A wildcard is covered only by the same
/// wildcard. An empty [candidate] is covered.
bool hostSetCovers(Iterable<String> consented, Iterable<String> candidate) {
  final exact = consented.toSet();
  final wildcards = [
    for (final entry in exact)
      if (HostPattern.tryParse(entry) case final HostPattern p
          when p.isWildcard)
        p,
  ];
  return candidate.every(
    (entry) =>
        exact.contains(entry) ||
        (!entry.startsWith(hostWildcardPrefix) &&
            wildcards.any((p) => p.matches(entry))),
  );
}
