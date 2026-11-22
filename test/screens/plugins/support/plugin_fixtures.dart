import 'package:flutter/widgets.dart' show Size;
import 'package:material_ui/material_ui.dart' show ThemeData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/install/update_candidates.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog.dart';
import 'package:kanaru/src/plugins/domain/install/repo_results.dart';
import 'package:kanaru/src/plugins/domain/install/update_diff.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:kanaru/src/plugins/state/store_items_provider.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart';
import 'package:kanaru/src/plugins/state/store_view_models.dart';
import 'package:kanaru/src/plugins/state/updates_provider.dart';

import '../../../database/support/test_db.dart';
import '../../settings/support/settings_host.dart';

PluginRepoRow repoRow(int id, {String name = 'Kho', String? lastError}) =>
    PluginRepoRow(
      id: id,
      url: 'https://repo$id.example.com/plugins.json',
      name: name,
      lastError: lastError,
      addedAt: 1,
      addressClass: 'public',
    );

CatalogEntry entryOf(
  String slug, {
  String? name,
  PluginKind? kind = PluginKind.lyrics,
  String author = 'kanaru313',
  List<String> languages = const [],
}) => CatalogEntry(
  slug: slug,
  kind: kind,
  name: name ?? slug,
  version: 3,
  apiVersion: 1,
  hosts: const [],
  path: Uri.parse('https://x.example.com/$slug.zip'),
  author: author,
  languages: languages,
);

PluginRow liveRow(
  String id, {
  String name = 'Demo',
  String kind = 'lyrics',
  String? author = 'kanaru313',
  String origin = 'repo',
}) => PluginRow(
  installId: id,
  kind: kind,
  name: name,
  author: author,
  version: 3,
  apiVersion: 1,
  manifestJson: '{}',
  packageSha256: 'a' * 64,
  origin: origin,
  originLabel: origin == 'file' ? '$name.zip' : null,
  consentedHostsJson: '[]',
  installedAt: 1,
  updatedAt: 1,
);

StoreItem itemOf(
  String slug,
  StoreItemState state, {
  PluginRepoRow? repo,
  String? name,
  PluginKind? kind = PluginKind.lyrics,
  String author = 'kanaru313',
  List<String> languages = const [],
}) {
  final id = 'id-$slug';
  return StoreItem(
    repo: repo ?? repoRow(1),
    entry: entryOf(
      slug,
      name: name,
      kind: kind,
      author: author,
      languages: languages,
    ),
    installId: id,
    state: state,
    installed:
        state == StoreItemState.installed ||
            state == StoreItemState.updateAvailable
        ? liveRow(id, name: name ?? slug)
        : null,
  );
}

/// Records what the screens ask of the repositories.
class FakeStoreOps implements StoreOps {
  int opens = 0;
  int refreshAlls = 0;
  final refreshed = <int>[];

  /// A refresh that finds the repository gone (`null`).
  bool refreshFails = false;
  final added = <String>[];
  final removed = <int>[];
  RepoAddResult Function(String input) onAdd = (_) => const RepoAdded(1);
  RepoRemoveResult removeResult = RepoRemoveResult.removed;
  Future<void>? addGate;
  RepoView? described = const RepoView(
    id: 1,
    name: 'Nhạc Việt Plugins',
    url: 'https://x.example.com/plugins.json',
    pluginCount: 6,
  );

  @override
  Future<void> onOpen() async => opens++;

  @override
  Future<List<RepoRefreshResult>> refreshAll() async {
    refreshAlls++;
    return const [];
  }

  @override
  Future<RepoRefreshResult?> refresh(int repoId) async {
    refreshed.add(repoId);
    return refreshFails ? null : RepoRefreshResult(repoId);
  }

  @override
  Future<RepoAddResult> add(String input) async {
    added.add(input);
    await addGate;
    return onAdd(input);
  }

  @override
  Future<RepoView?> describe(int repoId) async => described;

  @override
  Future<RepoRemoveResult> remove(int repoId) async {
    removed.add(repoId);
    return removeResult;
  }
}

/// The store as the providers below the screens would hand it out.
class StoreFixture {
  StoreFixture({
    this.items = const [],
    this.live = const [],
    this.repos = const [],
    this.alerts = const {},
    this.reviewIds = const [],
    this.updateAllCount = 0,
    FakeStoreOps? ops,
  }) : ops = ops ?? FakeStoreOps();

  final List<StoreItem> items;
  final List<PluginRow> live;
  final List<RepoView> repos;
  final Map<String, Set<PluginAlert>> alerts;

  /// Install ids of updates that add hosts.
  final List<String> reviewIds;
  final int updateAllCount;
  final FakeStoreOps ops;

  late final AppDatabase _db = openTestDb();

  Future<void> close() => _db.close();

  List<Override> get overrides {
    final reviews = [
      for (final id in reviewIds)
        PluginUpdate(
          row: liveRow(id),
          repo: repoRow(1),
          entry: entryOf('r'),
          diff: const UpdateDiff(
            newHosts: ['new.example.com'],
            versionOrder: VersionOrder.newer,
            kindChange: KindChange.none,
          ),
        ),
    ];
    return [
      storeItemsProvider.overrideWithValue(AsyncData(items)),
      installedPluginsProvider.overrideWith((ref) => Stream.value(live)),
      pluginReposProvider.overrideWith(
        (ref) => Stream.value([
          for (final r in repos)
            repoRow(r.id, name: r.name, lastError: r.errorKind),
        ]),
      ),
      pluginRowsProvider.overrideWithValue(PluginRows(_db)),
      pluginAlertsProvider.overrideWithValue(AsyncData(PluginAlerts(alerts))),
      updatesProvider.overrideWithValue(
        AsyncData(
          PluginUpdates(
            silent: [
              for (var i = 0; i < updateAllCount; i++)
                PluginUpdate(
                  row: liveRow('s$i'),
                  repo: repoRow(1),
                  entry: entryOf('s$i'),
                  diff: const UpdateDiff(
                    newHosts: [],
                    versionOrder: VersionOrder.newer,
                    kindChange: KindChange.none,
                  ),
                ),
            ],
            needsReview: reviews,
          ),
        ),
      ),
      repoViewsProvider.overrideWithValue(AsyncData(repos)),
      pluginIconProvider.overrideWith((ref, id) async => null),
      storeOpsProvider.overrideWithValue(ops),
      pluginRestoreProvider.overrideWith((ref) async => const []),
    ];
  }
}

/// An empty plugin store with nothing to attend to, for pages that only read
/// it in passing (the Settings root).
List<Override> quietPluginOverrides() => [
  pluginAlertsProvider.overrideWithValue(const AsyncData(PluginAlerts({}))),
  updatesProvider.overrideWithValue(
    const AsyncData(PluginUpdates(silent: [], needsReview: [])),
  ),
  pluginRestoreProvider.overrideWith((ref) async => const []),
];

/// Pumps the Settings routes at [location] over [fixture].
Future<SettingsHarness> pumpPlugins(
  WidgetTester tester,
  StoreFixture fixture, {
  String location = '/settings/plugins',
  Size size = const Size(400, 900),
  double textScale = 1,
  List<Override> overrides = const [],
  ThemeData? theme,
  bool reduceMotion = false,
}) async {
  addTearDown(fixture.close);
  return pumpSettings(
    tester,
    location: location,
    size: size,
    textScale: textScale,
    theme: theme,
    reduceMotion: reduceMotion,
    scaffold: true,
    quietPlugins: false,
    overrides: [...fixture.overrides, ...overrides],
  );
}
