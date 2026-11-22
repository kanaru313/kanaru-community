import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/data/install/sweep_and_restore.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_manifest.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/plugin_page_provider.dart';

import '../../../plugins/domain/plugin_test_support.dart';
import 'install_fixtures.dart';

const repoAddress = 'https://repo1.example.com/plugins.json';

/// An installed row for the page: [origin] `repo` (default), `file` or
/// `link`; the dates are epoch ms.
PluginRow pageRow({
  String origin = 'repo',
  String name = 'Demo',
  String kind = 'lyrics',
  String? author = 'kanaru313',
  List<String> hosts = const ['music.example.com'],
  int installedAt = 1762041600000,
  int updatedAt = 1762041600000,
}) => PluginRow(
  installId: 'id-demo',
  kind: kind,
  name: name,
  author: author,
  version: 3,
  apiVersion: 2,
  manifestJson: '{}',
  packageSha256: 'a' * 64,
  origin: origin,
  repoUrl: origin == 'repo' ? repoAddress : null,
  repoSlug: origin == 'repo' ? 'demo' : null,
  originLabel: switch (origin) {
    'file' => 'demo-3.zip',
    'link' => 'https://files.example.com/dl/demo.zip',
    _ => null,
  },
  consentedHostsJson: '[${hosts.map((h) => '"$h"').join(',')}]',
  installedAt: installedAt,
  updatedAt: updatedAt,
);

PluginManifest pageManifest({String description = 'Demo plugin'}) =>
    parseOk(withMeta((m) => m['description'] = description));

PluginPageData pageData({
  PluginRow? row,
  PluginManifest? manifest,
  Set<PluginAlert> alerts = const {},
  bool updating = false,
  PluginPageUpdate? update,
  List<PageEndpoint> endpoints = const [],
  List<String> missingConfig = const [],
  RestoreAction? missing,
}) => PluginPageData(
  row: row ?? pageRow(),
  manifest: manifest ?? pageManifest(),
  alerts: alerts,
  updating: updating,
  waitingReview: update?.needsReview ?? false,
  missing: missing,
  update: update,
  endpoints: endpoints,
  missingConfig: missingConfig,
);

/// What the page provider answers in a test; change it with [set].
class PageHolder extends Notifier<AsyncValue<PluginPageData?>> {
  PageHolder(this.initial);

  final AsyncValue<PluginPageData?> initial;

  @override
  AsyncValue<PluginPageData?> build() => initial;

  void set(AsyncValue<PluginPageData?> value) => state = value;
}

final pageHolder = NotifierProvider<PageHolder, AsyncValue<PluginPageData?>>(
  () => throw UnimplementedError('override pageHolder'),
);

/// Overrides that make the page read [initial] and run its flows on [ops];
/// [onBuild] counts how often the page provider is built (a retry builds it
/// again).
List<Override> pageOverrides(
  AsyncValue<PluginPageData?> initial, {
  FakeInstallOps? ops,
  void Function()? onBuild,
}) => [
  pageHolder.overrideWith(() => PageHolder(initial)),
  pluginPageProvider.overrideWith((ref, id) {
    onBuild?.call();
    return ref.watch(pageHolder);
  }),
  if (ops != null) installOpsProvider.overrideWithValue(ops),
];

const pagePath = '/settings/plugins/p/id-demo';
