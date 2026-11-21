import 'dart:convert';
import 'dart:typed_data';

import '../../../foundation/result.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/catalog/catalog_parser.dart';
import '../../domain/net/address_rules.dart';
import '../../domain/net/net_policy.dart';

/// The text kept in `plugin_repos.catalog_json`: the parsed catalog written
/// back in the catalog wire format with every reference already absolute, so
/// it reads the same whatever address the catalog was fetched from (a
/// redirect changes what a relative path resolves against).
///
/// An entry of an unknown type is written with the type `unknown`: it stays
/// listed as "needs a newer app".
String encodeCatalog(Catalog catalog) => jsonEncode({
  'metadata': {'name': catalog.name, 'author': catalog.author},
  'data': [
    for (final e in catalog.entries)
      {
        'slug': e.slug,
        'type': e.kind?.wire ?? 'unknown',
        'name': e.name,
        'version': e.version,
        'apiVersion': e.apiVersion,
        'hosts': e.hosts,
        'path': e.path.toString(),
        if (e.icon != null) 'icon': e.icon.toString(),
        'description': e.description,
        'author': e.author,
        'languages': e.languages,
        if (e.sha256 != null) 'sha256': e.sha256,
        if (e.size != null) 'size': e.size,
      },
  ],
});

/// Reads a stored catalog again with the address rules of [kind] (what the
/// repository row stored), so a stored reference that no longer passes is
/// dropped like a fresh one.
Result<Catalog, CatalogProblem> decodeCatalog(
  String stored,
  Uri repoUrl,
  AddressKind kind,
) => parseCatalog(
  Uint8List.fromList(utf8.encode(stored)),
  repoUrl,
  isReferenceAllowed: isCatalogReferenceAllowed(kind),
);
