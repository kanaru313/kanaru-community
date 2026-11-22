import '../domain/package/plugin_kind.dart';
import 'store_filter.dart';

/// The short status line of an installed row (what the user must do, if
/// anything). A missing required setting is no note: the alert dot says it.
enum StoreRowNote {
  none,

  /// The package folder is gone and only the user can pick the file again.
  reinstallFromFile,

  /// A second streaming plugin that needs Pro.
  proRequired,

  /// The package folder is gone; the app downloads it again.
  packageMissing,
}

/// One row of the store list, with no database types: what a screen draws.
class StoreRowView {
  const StoreRowView({
    required this.installId,
    required this.name,
    required this.author,
    required this.kind,
    required this.state,
    this.alerted = false,
    this.note = StoreRowNote.none,
    this.needsReview = false,
    this.fromCatalog = true,
  });

  final String installId;
  final String name;

  /// Empty when the plugin names no author.
  final String author;

  /// Null for a kind this app does not know (a newer app's entry).
  final PluginKind? kind;
  final StoreItemState state;

  /// An installed plugin that needs attention (red dot on its icon).
  final bool alerted;
  final StoreRowNote note;

  /// An update that adds hosts or permissions: the button is "Xem".
  final bool needsReview;

  /// False for a plugin installed from a file or link (no catalog entry).
  final bool fromCatalog;
}

/// The filtered store list, grouped, plus the counts the page needs.
class StoreView {
  const StoreView({
    required this.updates,
    required this.installed,
    required this.notInstalled,
    required this.updateAllCount,
    required this.needsNewerAppCount,
    required this.repoCount,
    required this.installedCount,
  });

  final List<StoreRowView> updates;
  final List<StoreRowView> installed;
  final List<StoreRowView> notInstalled;

  /// Updates "Cập nhật tất cả" installs (the ones without new hosts).
  final int updateAllCount;

  /// Matching entries that need a newer Kanaru: listed by count only.
  final int needsNewerAppCount;

  /// Repositories the user added (not filtered).
  final int repoCount;

  /// Live plugins (not filtered).
  final int installedCount;

  int get shownCount => updates.length + installed.length + notInstalled.length;
  bool get noMatch => shownCount == 0;

  /// No repository and nothing installed: the page shows only its guide card.
  bool get isBare => repoCount == 0 && installedCount == 0;
}

/// A repository for the Repository page.
class RepoView {
  const RepoView({
    required this.id,
    required this.name,
    required this.url,
    required this.pluginCount,
    this.errorKind,
    this.refreshedAt,
  });

  final int id;
  final String name;

  /// As the user entered it (canonical), never masked.
  final String url;
  final int pluginCount;

  /// The kind of the last failed fetch (a `RepoError` name), null when the
  /// last fetch worked.
  final String? errorKind;

  /// Milliseconds since the epoch of the last good fetch; null before one.
  final int? refreshedAt;
}

/// The values the filter offers, from every known plugin (not filtered).
class StoreFacets {
  const StoreFacets({this.languages = const [], this.authors = const []});

  /// Language keys, in the order of their names; a global plugin adds none.
  final List<String> languages;
  final List<String> authors;
}
