import '../../../database/tables.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/net/address_rules.dart';
import '../store/plugin_repo_rows.dart';
import 'catalog_codec.dart';

/// The parsed catalogs of the stored repositories. A stored catalog is JSON
/// of up to 1 MiB; it is decoded once per revision of its row (the text
/// changes whenever a refresh stores a catalog) and the result is reused by
/// every list and search that asks.
class CatalogCache {
  final _decoded = <int, _Decoded>{};

  /// The catalog of [row], or null when it has none yet or the stored text no
  /// longer reads (shown as a repository to refresh).
  Catalog? catalogOf(PluginRepoRow row) {
    final stored = row.catalogJson;
    if (stored == null) {
      _decoded.remove(row.id);
      return null;
    }
    final known = _decoded[row.id];
    // `==` on equal strings stops at once when they are the same object.
    if (known != null &&
        known.kind == row.addressKind &&
        known.url == row.url &&
        known.text == stored) {
      return known.catalog;
    }
    final catalog = decodeCatalog(
      stored,
      Uri.parse(row.url),
      row.addressKind,
    ).fold<Catalog?>((c) => c, (_) => null);
    _decoded[row.id] = _Decoded(stored, row.url, row.addressKind, catalog);
    return catalog;
  }

  /// The entry [slug] of [row]'s catalog, or null.
  CatalogEntry? entryOf(PluginRepoRow row, String slug) {
    for (final entry in catalogOf(row)?.entries ?? const <CatalogEntry>[]) {
      if (entry.slug == slug) return entry;
    }
    return null;
  }

  /// Forgets a removed repository.
  void forget(int repoId) => _decoded.remove(repoId);
}

class _Decoded {
  const _Decoded(this.text, this.url, this.kind, this.catalog);

  final String text;
  final String url;
  final AddressKind kind;
  final Catalog? catalog;
}
