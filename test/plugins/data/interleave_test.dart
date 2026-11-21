import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/remover.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';

import '../domain/plugin_test_support.dart';
import '../fixtures/zip_builders.dart';
import 'install_test_support.dart';

/// Each test stops a write half way and checks that the next mutation has not
/// started, then lets both finish.
void main() {
  final id = fileInstallId('Demo', 'someone');
  const form = {
    'region': {'title': 'Region', 'mode': 'input', 'format': 'text'},
  };
  Map<String, Object?> manifest(int v) =>
      withMeta((m) => m['version'] = v)..['config'] = form;

  test('a config save waits for the update that is writing', () async {
    final blocked = BlockedWrites();
    final h = InstallHarness(writeFile: blocked.write);
    addTearDown(h.dispose);
    await h.actions.installer.install(
      (await h.prepareFile(validZip(manifest: manifest(3)))).token,
    );
    final held = await h.prepareFile(validZip(manifest: manifest(4)));
    blocked.arm();

    final update = h.actions.installer.install(held.token);
    await blocked.entered;
    var saved = false;
    final save = h.actions.configWrites.setValue(id, 'region', 'vn').then((r) {
      saved = true;
      return r;
    });
    await turns();

    // The update is mid-write: the save has not touched the database.
    expect(saved, isFalse);
    expect((await h.config.read(id)).values, isEmpty);
    expect((await h.rows.liveById(id))!.version, 3);

    blocked.release();
    expect(await update, isA<Installed>());
    expect(await save, ConfigWrite.written);
    expect((await h.config.read(id)).values, {'region': 'vn'});
    expect((await h.rows.liveById(id))!.version, 4);
  });

  test('a remove waits for the update that is writing', () async {
    final blocked = BlockedWrites();
    final h = InstallHarness(writeFile: blocked.write);
    addTearDown(h.dispose);
    final repo = await h.addRepo({'netease': {}});
    final repoId = await h.installFromRepo(repo, 'netease');
    await h.setCatalog(repo, {
      'netease': {'version': 4},
    });
    h.zips['https://cdn.example.com/netease/plugin.zip'] = InstallHarness.zipOf(
      version: 4,
    );
    blocked.arm();

    final update = h.actions.updater.update(repoId);
    await blocked.entered;
    var removed = false;
    final remove = h.actions.remover.remove(repoId).then((r) {
      removed = true;
      return r;
    });
    await turns();

    expect(removed, isFalse);
    expect((await h.rows.liveById(repoId))!.version, 3);

    blocked.release();
    expect(await update, isA<Installed>());
    expect(await remove, RemoveResult.removed);
    expect(await h.rows.liveById(repoId), isNull);
    // Both the old and the new folder are gone.
    expect(await h.files.listFolders(), isEmpty);
  });

  test(
    'two streaming installs racing for the slot: exactly one wins',
    () async {
      final h = InstallHarness();
      addTearDown(h.dispose);
      Map<String, Object?> streaming(String name) => {
        'metadata': {
          ...(streamingManifest()['metadata']! as Map<String, Object?>),
          'name': name,
        },
        'script': streamingManifest()['script'],
      };
      final a = await h.prepareFile(
        validZip(manifest: streaming('One'), extra: {'src/stream.js': 'x'}),
        'one.zip',
      );
      final b = await h.prepareFile(
        validZip(manifest: streaming('Two'), extra: {'src/stream.js': 'x'}),
        'two.zip',
      );

      final results = await Future.wait([
        h.actions.installer.install(a.token),
        h.actions.installer.install(b.token),
      ]);

      expect(results.whereType<Installed>().length, 1);
      final refused = results.whereType<InstallRefused>().single;
      expect(refused.failure, InstallFailure.proRequired);
      expect((await h.rows.live()).length, 1);
    },
  );

  test('two packages for one plugin run one after the other', () async {
    final h = InstallHarness();
    addTearDown(h.dispose);
    await h.actions.installer.install(
      (await h.prepareFile(InstallHarness.zipOf(version: 3))).token,
    );
    final first = await h.prepareFile(InstallHarness.zipOf(version: 4));
    final second = await h.prepareFile(InstallHarness.zipOf(version: 5));

    final results = await Future.wait([
      h.actions.installer.install(first.token),
      h.actions.installer.install(second.token),
    ]);

    expect(results[0], isA<Installed>());
    // The second was reviewed against v3; the row is v4 now.
    expect((results[1] as InstallRefused).failure, InstallFailure.reviewStale);
    expect((await h.rows.liveById(id))!.version, 4);
  });
}
