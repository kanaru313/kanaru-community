import '../package/manifest_parser.dart' show supportedApiVersion;
import '../package/package_limits.dart';
import '../package/plugin_kind.dart';

export '../package/plugin_kind.dart';

/// Most entries a catalog may list.
const maxCatalogEntries = 500;

/// Most bytes a catalog file may have.
const maxCatalogBytes = 1024 * 1024;

/// Why a catalog is refused as a whole.
enum CatalogProblem {
  /// The body is over [maxCatalogBytes].
  tooLarge,

  /// Not UTF-8 JSON of the right shape, no usable name, more than
  /// [maxCatalogEntries] entries, or a non-empty `data` of which no entry is
  /// usable.
  invalidCatalog,
}

/// One plugin a catalog offers. The fields come from the catalog and are only
/// shown before install; what gets installed is read from the zip's own
/// manifest, which must agree (`catalogMatches`).
class CatalogEntry {
  const CatalogEntry({
    required this.slug,
    required this.kind,
    required this.name,
    required this.version,
    required this.apiVersion,
    required this.hosts,
    required this.path,
    this.icon,
    this.description = '',
    this.author = '',
    this.languages = const [],
    this.sha256,
    this.size,
  });

  /// `^[a-z0-9_-]{1,64}$`, unique within the catalog.
  final String slug;

  /// What the plugin does, or null for a `type` this app does not know (a
  /// newer app may): such an entry is listed but cannot be installed.
  final PluginKind? kind;
  final String name;
  final int version;

  /// May be newer than this app understands.
  final int apiVersion;

  /// Lower-case host entries, each checked like a manifest host (wildcards
  /// for streaming only; an unknown kind may list them).
  final List<String> hosts;

  /// Absolute address of the plugin zip, resolved against the catalog.
  final Uri path;

  /// Absolute address of the icon, or null when absent or refused.
  final Uri? icon;
  final String description;
  final String author;

  /// Normalized language keys; empty means global (any language).
  final List<String> languages;

  /// Lower-case hex SHA-256 of the zip, when the catalog gives one.
  final String? sha256;

  /// Size of the zip in bytes (1 to [maxPackageBytes]), when given.
  final int? size;

  /// The store lists the entry under "Cần Kanaru mới hơn" and offers no
  /// install: the app does not know its type or its API version.
  bool get needsNewerApp => kind == null || apiVersion > supportedApiVersion;
}

/// A parsed catalog: its display [name] and [author], the usable [entries]
/// and how many entries were [dropped] (invalid, refused address or a
/// repeated slug).
class Catalog {
  const Catalog({
    required this.name,
    required this.author,
    required this.entries,
    required this.dropped,
  });

  final String name;
  final String author;
  final List<CatalogEntry> entries;
  final int dropped;
}
