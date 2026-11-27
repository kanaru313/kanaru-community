import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/online/domain/contract/online_card.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';

import '../../plugins/data/store_test_support.dart';
import '../../plugins/domain/plugin_test_support.dart';

const repoSource = PluginSource.repo(
  'https://repo.example.com/plugins.json',
  'audius',
);

/// A streaming manifest with the hosts and config fields given.
Map<String, Object?> streamingWith({
  String name = 'Audius',
  List<String> hosts = const ['*.audius.co', 'cdn.example.com'],
  Map<String, Object?> config = const {},
  Map<String, Object?>? script,
}) {
  final json = streamingManifest(hosts: hosts, script: script);
  (json['metadata']! as Map<String, Object?>)['name'] = name;
  if (config.isNotEmpty) json['config'] = config;
  return json;
}

/// Installs a streaming plugin; returns its row.
Future<PluginRow> installStreaming(
  PluginRows rows, {
  String? installId,
  PluginSource source = repoSource,
  Map<String, Object?>? manifest,
}) async {
  final id = installId ?? testInstallId();
  final json = manifest ?? streamingWith();
  final scripts = (json['script']! as Map<String, Object?>).values;
  final package = packageOf(json, {
    for (final file in scripts)
      'src/$file': 'function execute(i) { return i; }',
  });
  final (_, row) = await rows.installOrRevive(id, draftOf(package), source);
  return row;
}

/// The id a file or link install of [name] gets.
String fileId(String name) => fileInstallId(name, null);

OnlineCard track(
  String id, {
  String title = 'Shape of You',
  String? artist,
  CardRef? album,
  Duration? duration,
  String? artworkUrl,
  OnlineCardKind kind = OnlineCardKind.track,
}) => OnlineCard(
  kind: kind,
  id: id,
  title: title,
  artist: artist,
  album: album,
  duration: duration,
  artworkUrl: artworkUrl,
);

/// Everything the database holds that the writer may touch.
Future<({int sources, int tracks, int playlists})> counts(
  AppDatabase db,
) async {
  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');
  return (
    sources: await count('sources'),
    tracks: await count('tracks'),
    playlists: await count('playlists'),
  );
}

PluginConfigStore configOf(AppDatabase db, PluginRows rows) =>
    PluginConfigStore(db, rows);
