import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/online/data/run/streaming_run_client.dart';
import 'package:kanaru/src/online/data/tracks/online_track_writer.dart';
import 'package:kanaru/src/online/state/online_data_providers.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../database/support/test_db.dart';
import '../../lyrics/support/fake_plugin_runner.dart';
import '../../plugins/data/store_test_support.dart';
import '../tracks/tracks_test_support.dart';

void main() {
  late AppDatabase db;
  late PluginRows rows;
  late ProviderContainer container;

  Future<void> start() async {
    final live = await rows.live();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        pluginRowsProvider.overrideWithValue(rows),
        pluginConfigStoreProvider.overrideWithValue(
          PluginConfigStore(db, rows),
        ),
        pluginRunnerProvider.overrideWithValue(FakePluginRunner()),
        installedPluginsProvider.overrideWith((ref) => Stream.value(live)),
      ],
    );
    addTearDown(container.dispose);
    // Lets the overridden stream deliver its rows.
    container.listen(installedPluginsProvider, (_, _) {});
    await pumpEventQueue();
  }

  setUp(() {
    db = openTestDb();
    rows = PluginRows(db);
  });
  tearDown(() => db.close());

  test('capabilities of a streaming plugin follow its script keys', () async {
    await installStreaming(
      rows,
      manifest: streamingWith(
        script: {
          'search': 'search.js',
          'stream': 'stream.js',
          'autocomplete': 'autocomplete.js',
          'home': 'home.js',
          'genre': 'genre.js',
          'album': 'album.js',
          'playlist': 'playlist.js',
          'artist': 'artist.js',
          'related': 'related.js',
          'resolve': 'resolve.js',
        },
      ),
    );
    await start();
    final caps = container.read(onlineCapabilitiesProvider(testInstallId()))!;
    expect([
      caps.autocomplete,
      caps.home,
      caps.genre,
      caps.album,
      caps.playlist,
      caps.artist,
      caps.related,
      caps.resolve,
    ], everyElement(isTrue));
  });

  test('a streaming plugin with only the required scripts', () async {
    await installStreaming(rows);
    await start();
    final caps = container.read(onlineCapabilitiesProvider(testInstallId()))!;
    expect(caps.autocomplete, isFalse);
    expect(caps.resolve, isFalse);
  });

  test('a lyrics plugin and an unknown id give null', () async {
    final id = testInstallId(2);
    await rows.installOrRevive(
      id,
      draftOf(packageOf()),
      const PluginSource.file('lyrics.zip'),
    );
    await start();
    expect(container.read(onlineCapabilitiesProvider(id)), isNull);
    expect(
      container.read(onlineCapabilitiesProvider(testInstallId(9))),
      isNull,
    );
  });

  test('the writer and the client build from the overridden parts', () async {
    await start();
    expect(container.read(onlineTrackWriterProvider), isA<OnlineTrackWriter>());
    expect(
      container.read(streamingRunClientProvider),
      isA<StreamingRunClient>(),
    );
  });
}
