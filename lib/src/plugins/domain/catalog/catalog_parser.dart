import 'dart:convert';
import 'dart:typed_data';

import '../../../foundation/result.dart';
import '../package/host_rules.dart';
import '../package/json_read.dart';
import '../package/manifest_rules.dart';
import '../package/package_limits.dart';
import '../package/package_problem.dart';
import '../package/plugin_languages.dart';
import 'catalog.dart';

final _slug = RegExp(r'^[a-z0-9_-]{1,64}$');
final _sha256 = RegExp(r'^[0-9a-fA-F]{64}$');
const _maxReferenceLength = 2048;

/// Parses a catalog fetched from [url] (the final address after redirects,
/// which relative `path` and `icon` are resolved against).
///
/// Returns `tooLarge` for a body over [maxCatalogBytes] and `invalidCatalog`
/// for bad JSON or shape, a missing name, more than [maxCatalogEntries]
/// entries, or a non-empty `data` of which no entry is usable. An entry that
/// is not valid is dropped and counted in [Catalog.dropped]: the entry rules
/// are those of the manifest (name, version, hosts, text cleaning) plus the
/// slug rule, an `https` / `http` `path` of at most 2048 characters once
/// absolute, and `sha256` / `size` when present. A bad `icon` only drops the
/// icon; a bad `languages` means global.
///
/// An entry whose `apiVersion` is newer, or whose `type` is not one of the
/// four kinds, is kept with [CatalogEntry.needsNewerApp] true.
///
/// [isReferenceAllowed] is the caller's address policy (public against local
/// addresses); it gets each resolved `path` and `icon`. The parser itself
/// only checks scheme, host and absence of user info.
Result<Catalog, CatalogProblem> parseCatalog(
  Uint8List bytes,
  Uri url, {
  required bool Function(Uri reference) isReferenceAllowed,
}) {
  if (bytes.length > maxCatalogBytes) return const Err(CatalogProblem.tooLarge);
  const invalidCatalog = Err<Catalog, CatalogProblem>(
    CatalogProblem.invalidCatalog,
  );
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(bytes));
  } on FormatException {
    return invalidCatalog;
  }
  final root = asObject(json);
  final metadata = asObject(root?['metadata']);
  final data = root?['data'];
  if (metadata == null || data is! List || data.length > maxCatalogEntries) {
    return invalidCatalog;
  }
  final name = _text(metadata['name'], min: 1, max: 80);
  final author = _text(metadata['author'], max: 80, optional: true);
  if (name == null || author == null) return invalidCatalog;

  bool allowed(Uri reference) => isReferenceAllowed(reference);
  final entries = <CatalogEntry>[];
  final slugs = <String>{};
  var dropped = 0;
  for (final raw in data) {
    final object = asObject(raw);
    final entry = object == null ? null : _entry(object, url, allowed);
    if (entry == null || !slugs.add(entry.slug)) {
      dropped++;
      continue;
    }
    entries.add(entry);
  }
  if (data.isNotEmpty && entries.isEmpty) return invalidCatalog;
  return Ok(
    Catalog(
      name: name,
      author: author,
      entries: List.unmodifiable(entries),
      dropped: dropped,
    ),
  );
}

CatalogEntry? _entry(JsonObject json, Uri url, bool Function(Uri) allowed) {
  final slug = json['slug'];
  if (slug is! String || !_slug.hasMatch(slug)) return null;
  final type = json['type'];
  if (type is! String) return null;
  // An unknown type is kept (see `needsNewerApp`); its host rules cannot be
  // known, so it may list wildcards (still public names only).
  final kind = PluginKind.fromWire(type);
  final name = _text(json['name'], min: 1, max: 80);
  final version = json['version'];
  final apiVersion = json['apiVersion'];
  if (name == null) return null;
  if (version is! int || version < 1 || version > 2147483647) return null;
  if (apiVersion is! int || apiVersion < 1) return null;
  final hosts = _hosts(
    json['hosts'],
    wildcardsAllowed: kind?.allowsWildcardHosts ?? true,
  );
  final author = _text(json['author'], max: 80, optional: true);
  final description = _text(
    json['description'],
    max: 500,
    optional: true,
    keepNewlines: true,
  );
  if (hosts == null || author == null || description == null) return null;
  final path = _reference(json['path'], url, allowed);
  if (path == null) return null;
  final iconField = json['icon'];
  final sha256 = json['sha256'];
  final size = json['size'];
  if (sha256 != null && (sha256 is! String || !_sha256.hasMatch(sha256))) {
    return null;
  }
  if (size != null && (size is! int || size < 1 || size > maxPackageBytes)) {
    return null;
  }
  return CatalogEntry(
    slug: slug,
    kind: kind,
    name: name,
    version: version,
    apiVersion: apiVersion,
    hosts: hosts,
    path: path,
    icon: iconField == null ? null : _reference(iconField, url, allowed),
    description: description,
    author: author,
    languages: parsePluginLanguages(json['languages']),
    sha256: (sha256 as String?)?.toLowerCase(),
    size: size as int?,
  );
}

/// Resolves [value] against the catalog address; null when it is not an
/// `http(s)` address with a host and no user info, is over 2048 characters
/// once absolute (what is accepted here is what reads back), or is refused
/// by the caller's policy. A fragment is dropped.
Uri? _reference(Object? value, Uri url, bool Function(Uri) allowed) {
  if (value is! String || value.isEmpty || value.length > _maxReferenceLength) {
    return null;
  }
  final parsed = Uri.tryParse(value);
  if (parsed == null) return null;
  final resolved = url.resolveUri(parsed).removeFragment();
  if (resolved.toString().length > _maxReferenceLength) return null;
  final scheme = resolved.scheme;
  if ((scheme != 'http' && scheme != 'https') ||
      resolved.host.isEmpty ||
      resolved.userInfo.isNotEmpty) {
    return null;
  }
  return allowed(resolved) ? resolved : null;
}

List<String>? _hosts(Object? value, {required bool wildcardsAllowed}) {
  if (value is! List || value.isEmpty || value.length > maxHosts) return null;
  final hosts = <String>{};
  for (final item in value) {
    if (item is! String) return null;
    hosts.add(item.trim().toLowerCase());
  }
  final problem = hostListProblem(
    hosts.toList(),
    wildcardsAllowed: wildcardsAllowed,
  );
  return problem == null ? List.unmodifiable(hosts) : null;
}

/// Same cleaning and length rules as the manifest fields. Null when the
/// value breaks them; a missing optional value gives ''.
String? _text(
  Object? value, {
  int min = 0,
  required int max,
  bool optional = false,
  bool keepNewlines = false,
}) {
  try {
    return readText(
      value,
      'catalog',
      min: min,
      max: max,
      optional: optional,
      keepNewlines: keepNewlines,
    );
  } on PackageProblemError {
    return null;
  }
}
